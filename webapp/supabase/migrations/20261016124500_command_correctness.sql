-- Correct JWT identity, envelope guards, replay canonical state, and reward reactivation.

CREATE OR REPLACE FUNCTION app_private.jwt_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT COALESCE(
    NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid,
    (NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid
  );
$$;

CREATE OR REPLACE FUNCTION app_private.assert_only_keys(
  payload jsonb,
  allowed_keys text[]
)
RETURNS void
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  extra_key text;
BEGIN
  IF payload IS NULL OR jsonb_typeof(payload) <> 'object' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  SELECT key
  INTO extra_key
  FROM jsonb_object_keys(payload) AS key
  WHERE NOT (key = ANY (allowed_keys))
  LIMIT 1;

  IF extra_key IS NOT NULL THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.parse_contract_version(request jsonb)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  version integer;
BEGIN
  IF request ->> 'contract_version' IS NULL THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  version := (request ->> 'contract_version')::integer;
  IF version IS DISTINCT FROM 1 THEN
    PERFORM app_private.raise_command_error('unsupported_contract');
  END IF;

  RETURN version;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.parse_operation_id(request jsonb)
RETURNS uuid
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  operation_id uuid;
BEGIN
  BEGIN
    operation_id := (request ->> 'operation_id')::uuid;
  EXCEPTION
    WHEN invalid_text_representation THEN
      PERFORM app_private.raise_command_error('validation');
  END;

  IF operation_id IS NULL THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  RETURN operation_id;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.assert_mutation_envelope(request jsonb, bootstrap boolean)
RETURNS void
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
BEGIN
  PERFORM app_private.assert_only_keys(
    request,
    ARRAY[
      'contract_version',
      'operation_id',
      'sync_epoch',
      'expected_revision',
      'expected_related_revisions',
      'data'
    ]
  );

  PERFORM app_private.parse_contract_version(request);
  PERFORM app_private.parse_operation_id(request);

  IF request -> 'data' IS NULL OR jsonb_typeof(request -> 'data') <> 'object' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF bootstrap THEN
    IF request ? 'sync_epoch' AND request -> 'sync_epoch' IS DISTINCT FROM 'null'::jsonb THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;
    IF request ? 'expected_revision' AND request -> 'expected_revision' IS DISTINCT FROM 'null'::jsonb THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;
  ELSE
    IF request ->> 'sync_epoch' IS NULL THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;
    BEGIN
      IF (request ->> 'sync_epoch')::uuid IS NULL THEN
        PERFORM app_private.raise_command_error('validation');
      END IF;
    EXCEPTION
      WHEN invalid_text_representation THEN
        PERFORM app_private.raise_command_error('validation');
    END;
  END IF;

  IF request ? 'expected_related_revisions' THEN
    IF jsonb_typeof(request -> 'expected_related_revisions') <> 'object'
      OR request -> 'expected_related_revisions' <> '{}'::jsonb
    THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.assert_profile_sync_epoch(
  request jsonb,
  profile_row public.profiles,
  bootstrap boolean
)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  observed_epoch uuid;
BEGIN
  IF bootstrap THEN
    RETURN;
  END IF;

  observed_epoch := (request ->> 'sync_epoch')::uuid;
  IF observed_epoch IS DISTINCT FROM profile_row.sync_epoch THEN
    PERFORM app_private.raise_command_error('restore_requires_review');
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.parse_expected_revision(
  request jsonb,
  creation_command boolean
)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  revision_text text;
  revision_value bigint;
BEGIN
  IF creation_command THEN
    IF request ? 'expected_revision' AND request -> 'expected_revision' IS DISTINCT FROM 'null'::jsonb THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;
    RETURN NULL;
  END IF;

  revision_text := request ->> 'expected_revision';
  IF revision_text IS NULL OR btrim(revision_text) = '' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF revision_text !~ '^[0-9]+$' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  revision_value := revision_text::bigint;
  IF revision_value <= 0 THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  RETURN revision_value;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.command_request_hash(
  command_name text,
  command_schema_version integer,
  request jsonb
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT encode(
    extensions.digest(
      command_name || ':' || command_schema_version::text || ':' || jsonb_build_object(
        'sync_epoch', request -> 'sync_epoch',
        'expected_revision', request -> 'expected_revision',
        'expected_related_revisions', request -> 'expected_related_revisions',
        'data', request -> 'data'
      )::text,
      'sha256'
    ),
    'hex'
  );
$$;

CREATE OR REPLACE FUNCTION app_private.derive_completion_local_date(
  observed_at timestamptz,
  observed_timezone text
)
RETURNS date
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
BEGIN
  IF observed_at IS NULL OR observed_timezone IS NULL OR btrim(observed_timezone) = '' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  RETURN (observed_at AT TIME ZONE observed_timezone)::date;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.canonical_records_for_occurrence(
  actor_id uuid,
  v_occurrence_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  profile_row public.profiles;
  occurrence_row public.quest_occurrences;
  reward_row public.completion_rewards;
  records jsonb;
BEGIN
  SELECT *
  INTO profile_row
  FROM public.profiles
  WHERE id = actor_id;

  records := jsonb_build_array(app_private.profile_dto(profile_row));

  SELECT *
  INTO occurrence_row
  FROM public.quest_occurrences o
  WHERE o.owner_id = actor_id AND o.id = v_occurrence_id;

  IF FOUND THEN
    records := records || jsonb_build_array(app_private.occurrence_dto(occurrence_row));

    SELECT *
    INTO reward_row
    FROM public.completion_rewards r
    WHERE r.owner_id = actor_id
      AND r.occurrence_id = v_occurrence_id
      AND r.reversed_at IS NULL;

    IF FOUND THEN
      records := records || jsonb_build_array(app_private.reward_dto(reward_row));
    END IF;
  END IF;

  RETURN records;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.canonical_records_for_create_quest(
  actor_id uuid,
  outcome jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  profile_row public.profiles;
  occurrence_row public.quest_occurrences;
  records jsonb;
BEGIN
  SELECT *
  INTO profile_row
  FROM public.profiles
  WHERE id = actor_id;

  SELECT *
  INTO occurrence_row
  FROM public.quest_occurrences o
  WHERE o.owner_id = actor_id
    AND o.id = (outcome ->> 'occurrence_id')::uuid;

  records := jsonb_build_array(app_private.profile_dto(profile_row));
  IF FOUND THEN
    records := records || jsonb_build_array(app_private.occurrence_dto(occurrence_row));
  END IF;

  RETURN records;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.award_or_reactivate_quest_reward(
  actor_id uuid,
  v_occurrence_id uuid
)
RETURNS public.completion_rewards
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  reward_row public.completion_rewards;
BEGIN
  SELECT *
  INTO reward_row
  FROM public.completion_rewards r
  WHERE r.owner_id = actor_id AND r.occurrence_id = v_occurrence_id
  FOR UPDATE;

  IF FOUND THEN
    IF reward_row.reversed_at IS NOT NULL THEN
      UPDATE public.completion_rewards
      SET
        reversed_at = NULL,
        reactivated_at = now(),
        revision = revision + 1
      WHERE owner_id = actor_id AND occurrence_id = v_occurrence_id
      RETURNING * INTO reward_row;
    END IF;
    RETURN reward_row;
  END IF;

  INSERT INTO public.completion_rewards (
    id,
    owner_id,
    occurrence_id,
    awarded_xp,
    rule_version
  )
  VALUES (
    extensions.gen_random_uuid(),
    actor_id,
    v_occurrence_id,
    20,
    'initial_v1'
  )
  RETURNING * INTO reward_row;

  RETURN reward_row;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.parse_create_quest_schedule(data jsonb)
RETURNS TABLE (
  anchor_date date,
  planning_timezone text,
  timing_kind text,
  entry_kind text,
  title text,
  notes text,
  category text,
  priority text,
  blocks_time boolean
)
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  schedule jsonb;
  timing jsonb;
BEGIN
  PERFORM app_private.assert_only_keys(
    data,
    ARRAY[
      'definition_id',
      'schedule_version_id',
      'entry_kind',
      'title',
      'notes',
      'category',
      'priority',
      'blocks_time',
      'schedule',
      'anchor_date',
      'planning_timezone',
      'timing_kind'
    ]
  );

  IF data ->> 'definition_id' IS NULL OR data ->> 'schedule_version_id' IS NULL OR data ->> 'title' IS NULL THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF data ? 'schedule' THEN
    schedule := data -> 'schedule';
    PERFORM app_private.assert_only_keys(
      schedule,
      ARRAY[
        'anchor_date',
        'planning_timezone',
        'timing',
        'recurrence'
      ]
    );
    anchor_date := (schedule ->> 'anchor_date')::date;
    planning_timezone := schedule ->> 'planning_timezone';
    timing := schedule -> 'timing';
    IF timing IS NULL OR jsonb_typeof(timing) <> 'object' THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;
    PERFORM app_private.assert_only_keys(
      timing,
      ARRAY[
        'kind',
        'start_local_time',
        'end_local_time',
        'start_ambiguity_choice',
        'end_ambiguity_choice'
      ]
    );
    timing_kind := COALESCE(timing ->> 'kind', 'untimed');
  ELSE
    anchor_date := (data ->> 'anchor_date')::date;
    planning_timezone := data ->> 'planning_timezone';
    timing_kind := COALESCE(data ->> 'timing_kind', 'untimed');
  END IF;

  IF anchor_date IS NULL OR planning_timezone IS NULL OR btrim(planning_timezone) = '' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  entry_kind := COALESCE(data ->> 'entry_kind', 'quest');
  title := data ->> 'title';
  notes := COALESCE(data ->> 'notes', '');
  category := COALESCE(data ->> 'category', 'personal');
  priority := COALESCE(data ->> 'priority', 'side');
  blocks_time := COALESCE((data ->> 'blocks_time')::boolean, false);

  RETURN NEXT;
END;
$$;
