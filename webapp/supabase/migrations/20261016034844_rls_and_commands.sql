-- Grants, RLS, controlled command RPCs for the foundation slice.

CREATE OR REPLACE FUNCTION app_private.jwt_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

REVOKE ALL ON FUNCTION app_private.jwt_user_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_private.jwt_user_id() TO authenticated, anon, gamecal_command_executor;

REVOKE ALL ON TABLE public.profiles FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.quest_definitions FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.quest_schedule_versions FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.quest_occurrences FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.completion_rewards FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE app_private.mutation_receipts FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT ON TABLE public.profiles TO authenticated;
GRANT SELECT ON TABLE public.quest_definitions TO authenticated;
GRANT SELECT ON TABLE public.quest_schedule_versions TO authenticated;
GRANT SELECT ON TABLE public.quest_occurrences TO authenticated;
GRANT SELECT ON TABLE public.completion_rewards TO authenticated;

GRANT SELECT, INSERT, UPDATE ON TABLE public.profiles TO gamecal_command_executor;
GRANT SELECT, INSERT, UPDATE ON TABLE public.quest_definitions TO gamecal_command_executor;
GRANT SELECT, INSERT, UPDATE ON TABLE public.quest_schedule_versions TO gamecal_command_executor;
GRANT SELECT, INSERT, UPDATE ON TABLE public.quest_occurrences TO gamecal_command_executor;
GRANT SELECT, INSERT, UPDATE ON TABLE public.completion_rewards TO gamecal_command_executor;
GRANT SELECT, INSERT, UPDATE ON TABLE app_private.mutation_receipts TO gamecal_command_executor;

GRANT SELECT ON TABLE public.quest_occurrences TO gamecal_invariant_reader;
GRANT SELECT ON TABLE public.completion_rewards TO gamecal_invariant_reader;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quest_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quest_schedule_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quest_occurrences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completion_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_private.mutation_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_private.mutation_receipts FORCE ROW LEVEL SECURITY;

CREATE POLICY profiles_owner_read ON public.profiles
FOR SELECT TO authenticated
USING ((SELECT app_private.jwt_user_id()) = id);

CREATE POLICY quest_definitions_owner_read ON public.quest_definitions
FOR SELECT TO authenticated
USING ((SELECT app_private.jwt_user_id()) = owner_id);

CREATE POLICY quest_schedule_versions_owner_read ON public.quest_schedule_versions
FOR SELECT TO authenticated
USING ((SELECT app_private.jwt_user_id()) = owner_id);

CREATE POLICY quest_occurrences_owner_read ON public.quest_occurrences
FOR SELECT TO authenticated
USING ((SELECT app_private.jwt_user_id()) = owner_id);

CREATE POLICY completion_rewards_owner_read ON public.completion_rewards
FOR SELECT TO authenticated
USING ((SELECT app_private.jwt_user_id()) = owner_id);

CREATE POLICY profiles_executor_select ON public.profiles
FOR SELECT TO gamecal_command_executor
USING (id = (SELECT app_private.jwt_user_id()));

CREATE POLICY profiles_executor_insert ON public.profiles
FOR INSERT TO gamecal_command_executor
WITH CHECK (id = (SELECT app_private.jwt_user_id()));

CREATE POLICY profiles_executor_update ON public.profiles
FOR UPDATE TO gamecal_command_executor
USING (id = (SELECT app_private.jwt_user_id()))
WITH CHECK (id = (SELECT app_private.jwt_user_id()));

CREATE POLICY quest_definitions_executor_all ON public.quest_definitions
FOR ALL TO gamecal_command_executor
USING (owner_id = (SELECT app_private.jwt_user_id()))
WITH CHECK (owner_id = (SELECT app_private.jwt_user_id()));

CREATE POLICY quest_schedule_versions_executor_all ON public.quest_schedule_versions
FOR ALL TO gamecal_command_executor
USING (owner_id = (SELECT app_private.jwt_user_id()))
WITH CHECK (owner_id = (SELECT app_private.jwt_user_id()));

CREATE POLICY quest_occurrences_executor_all ON public.quest_occurrences
FOR ALL TO gamecal_command_executor
USING (owner_id = (SELECT app_private.jwt_user_id()))
WITH CHECK (owner_id = (SELECT app_private.jwt_user_id()));

CREATE POLICY completion_rewards_executor_all ON public.completion_rewards
FOR ALL TO gamecal_command_executor
USING (owner_id = (SELECT app_private.jwt_user_id()))
WITH CHECK (owner_id = (SELECT app_private.jwt_user_id()));

CREATE POLICY mutation_receipts_executor_all ON app_private.mutation_receipts
FOR ALL TO gamecal_command_executor
USING (owner_id = (SELECT app_private.jwt_user_id()))
WITH CHECK (owner_id = (SELECT app_private.jwt_user_id()));

CREATE POLICY quest_occurrences_invariant_read ON public.quest_occurrences
FOR SELECT TO gamecal_invariant_reader
USING (true);

CREATE POLICY completion_rewards_invariant_read ON public.completion_rewards
FOR SELECT TO gamecal_invariant_reader
USING (true);

CREATE OR REPLACE FUNCTION app_private.raise_command_error(error_code text)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION '%', error_code USING ERRCODE = 'P0001', DETAIL = error_code;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.require_actor_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  actor uuid;
BEGIN
  actor := app_private.jwt_user_id();
  IF actor IS NULL THEN
    PERFORM app_private.raise_command_error('unauthenticated');
  END IF;
  RETURN actor;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.canonical_payload_hash(
  command_name text,
  command_schema_version integer,
  payload jsonb
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT encode(
    extensions.digest(
      command_name || ':' || command_schema_version::text || ':' || payload::text,
      'sha256'
    ),
    'hex'
  );
$$;

CREATE OR REPLACE FUNCTION app_private.lock_profile(actor_id uuid)
RETURNS public.profiles
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  profile_row public.profiles;
BEGIN
  SELECT *
  INTO profile_row
  FROM public.profiles p
  WHERE p.id = actor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    PERFORM app_private.raise_command_error('not_found');
  END IF;

  IF profile_row.deletion_requested_at IS NOT NULL THEN
    PERFORM app_private.raise_command_error('account_deleting');
  END IF;

  RETURN profile_row;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.claim_or_replay_receipt(
  actor_id uuid,
  p_operation_id uuid,
  command_name text,
  command_schema_version integer,
  payload_hash text
)
RETURNS app_private.mutation_receipts
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  existing app_private.mutation_receipts;
BEGIN
  SELECT *
  INTO existing
  FROM app_private.mutation_receipts r
  WHERE r.owner_id = actor_id AND r.operation_id = p_operation_id;

  IF FOUND THEN
    IF existing.canonical_payload_hash <> payload_hash THEN
      PERFORM app_private.raise_command_error('operation_payload_mismatch');
    END IF;
    RETURN existing;
  END IF;

  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.insert_receipt(
  actor_id uuid,
  p_operation_id uuid,
  command_name text,
  command_schema_version integer,
  payload_hash text,
  accepted_result jsonb
)
RETURNS void
LANGUAGE sql
SET search_path = ''
AS $$
  INSERT INTO app_private.mutation_receipts (
    owner_id,
    operation_id,
    command_name,
    command_schema_version,
    canonical_payload_hash,
    accepted_result
  )
  VALUES (
    actor_id,
    p_operation_id,
    command_name,
    command_schema_version,
    payload_hash,
    accepted_result
  );
$$;

CREATE OR REPLACE FUNCTION app_private.profile_dto(profile_row public.profiles)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'entity', 'profile',
    'record', jsonb_build_object(
      'id', profile_row.id,
      'display_name', profile_row.display_name,
      'planning_timezone', profile_row.planning_timezone,
      'revision', profile_row.revision::text,
      'account_data_revision', profile_row.account_data_revision::text,
      'sync_epoch', profile_row.sync_epoch
    )
  );
$$;

CREATE OR REPLACE FUNCTION app_private.occurrence_dto(occ public.quest_occurrences)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'entity', 'quest_occurrence',
    'record', jsonb_build_object(
      'id', occ.id,
      'owner_id', occ.owner_id,
      'definition_id', occ.definition_id,
      'schedule_version_id', occ.schedule_version_id,
      'original_scheduled_date', occ.original_scheduled_date,
      'effective_date', occ.effective_date,
      'entry_kind', occ.entry_kind,
      'title', occ.title,
      'status', occ.status,
      'revision', occ.revision::text
    )
  );
$$;

CREATE OR REPLACE FUNCTION app_private.reward_dto(reward public.completion_rewards)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'entity', 'completion_reward',
    'record', jsonb_build_object(
      'id', reward.id,
      'occurrence_id', reward.occurrence_id,
      'awarded_xp', reward.awarded_xp,
      'rule_version', reward.rule_version,
      'reversed_at', reward.reversed_at
    )
  );
$$;

CREATE OR REPLACE FUNCTION app_private.success_envelope(
  operation_id uuid,
  command_name text,
  replayed boolean,
  accepted_at timestamptz,
  acknowledgment jsonb,
  canonical_records jsonb,
  profile_row public.profiles
)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'ok', true,
    'contract_version', 1,
    'acknowledgment', jsonb_build_object(
      'operation_id', operation_id,
      'command_name', command_name,
      'replayed', replayed,
      'accepted_at', accepted_at,
      'outcome', acknowledgment
    ),
    'canonical', jsonb_build_object(
      'sync_epoch', profile_row.sync_epoch,
      'account_data_revision', profile_row.account_data_revision::text,
      'records', canonical_records
    ),
    'invalidations', jsonb_build_array()
  );
$$;

CREATE OR REPLACE FUNCTION app_private.ensure_profile_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  profile_row public.profiles;
  operation_id uuid;
  data jsonb;
  payload_hash text;
  existing_receipt app_private.mutation_receipts;
  result jsonb;
  contract_version integer;
BEGIN
  actor_id := app_private.require_actor_id();
  contract_version := (request ->> 'contract_version')::integer;
  IF contract_version IS DISTINCT FROM 1 THEN
    PERFORM app_private.raise_command_error('unsupported_contract');
  END IF;

  operation_id := (request ->> 'operation_id')::uuid;
  data := request -> 'data';
  payload_hash := app_private.canonical_payload_hash('ensure_profile', 1, data);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'ensure_profile', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    profile_row := app_private.lock_profile(actor_id);
    RETURN app_private.success_envelope(
      operation_id,
      'ensure_profile',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      jsonb_build_array(app_private.profile_dto(profile_row)),
      profile_row
    );
  END IF;

  SELECT *
  INTO profile_row
  FROM public.profiles p
  WHERE p.id = actor_id
  FOR UPDATE;

  IF FOUND THEN
    result := jsonb_build_object('created', false, 'profile_revision', profile_row.revision::text);
  ELSE
    INSERT INTO public.profiles (
      id,
      display_name,
      planning_timezone,
      reduced_motion,
      show_streaks,
      celebrations_enabled,
      temperature_unit
    )
    VALUES (
      actor_id,
      data ->> 'display_name',
      data ->> 'planning_timezone',
      COALESCE((data ->> 'reduced_motion')::boolean, false),
      COALESCE((data ->> 'show_streaks')::boolean, false),
      COALESCE((data ->> 'celebrations_enabled')::boolean, true),
      COALESCE(data ->> 'temperature_unit', 'celsius')
    )
    RETURNING * INTO profile_row;

    result := jsonb_build_object('created', true, 'profile_revision', profile_row.revision::text);
  END IF;

  PERFORM app_private.insert_receipt(
    actor_id,
    operation_id,
    'ensure_profile',
    1,
    payload_hash,
    jsonb_build_object('outcome', result)
  );

  RETURN app_private.success_envelope(
    operation_id,
    'ensure_profile',
    false,
    now(),
    result,
    jsonb_build_array(app_private.profile_dto(profile_row)),
    profile_row
  );
END;
$$;

CREATE OR REPLACE FUNCTION app_private.create_quest_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  profile_row public.profiles;
  operation_id uuid;
  data jsonb;
  payload_hash text;
  existing_receipt app_private.mutation_receipts;
  definition_id uuid;
  version_id uuid;
  anchor_date date;
  occurrence_id uuid;
  definition_row public.quest_definitions;
  version_row public.quest_schedule_versions;
  occurrence_row public.quest_occurrences;
  outcome jsonb;
  records jsonb;
BEGIN
  actor_id := app_private.require_actor_id();
  IF (request ->> 'contract_version')::integer IS DISTINCT FROM 1 THEN
    PERFORM app_private.raise_command_error('unsupported_contract');
  END IF;

  profile_row := app_private.lock_profile(actor_id);
  operation_id := (request ->> 'operation_id')::uuid;
  data := request -> 'data';
  payload_hash := app_private.canonical_payload_hash('create_quest', 1, data);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'create_quest', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    RETURN app_private.success_envelope(
      operation_id,
      'create_quest',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      existing_receipt.accepted_result -> 'canonical_records',
      profile_row
    );
  END IF;

  definition_id := (data ->> 'definition_id')::uuid;
  version_id := (data ->> 'schedule_version_id')::uuid;
  anchor_date := (data ->> 'anchor_date')::date;
  occurrence_id := app_private.derive_occurrence_id(definition_id, anchor_date);

  IF EXISTS (
    SELECT 1
    FROM public.quest_definitions d
    WHERE d.id = definition_id
  ) THEN
    PERFORM app_private.raise_command_error('identity_conflict');
  END IF;

  INSERT INTO public.quest_definitions (id, owner_id)
  VALUES (definition_id, actor_id)
  RETURNING * INTO definition_row;

  INSERT INTO public.quest_schedule_versions (
    id,
    owner_id,
    definition_id,
    effective_from,
    entry_kind,
    title,
    notes,
    category,
    priority,
    blocks_time,
    anchor_date,
    recurrence_kind,
    timing_kind,
    planning_timezone
  )
  VALUES (
    version_id,
    actor_id,
    definition_id,
    anchor_date,
    COALESCE(data ->> 'entry_kind', 'quest'),
    data ->> 'title',
    COALESCE(data ->> 'notes', ''),
    COALESCE(data ->> 'category', 'personal'),
    COALESCE(data ->> 'priority', 'side'),
    COALESCE((data ->> 'blocks_time')::boolean, false),
    anchor_date,
    'none',
    COALESCE(data ->> 'timing_kind', 'untimed'),
    data ->> 'planning_timezone'
  )
  RETURNING * INTO version_row;

  INSERT INTO public.quest_occurrences (
    id,
    owner_id,
    definition_id,
    schedule_version_id,
    original_scheduled_date,
    effective_date,
    entry_kind,
    title,
    notes,
    category,
    priority,
    blocks_time,
    timing_kind,
    start_timezone
  )
  VALUES (
    occurrence_id,
    actor_id,
    definition_id,
    version_id,
    anchor_date,
    anchor_date,
    version_row.entry_kind,
    version_row.title,
    version_row.notes,
    version_row.category,
    version_row.priority,
    version_row.blocks_time,
    version_row.timing_kind,
    version_row.planning_timezone
  )
  RETURNING * INTO occurrence_row;

  UPDATE public.profiles
  SET account_data_revision = account_data_revision + 1
  WHERE id = actor_id
  RETURNING * INTO profile_row;

  outcome := jsonb_build_object(
    'definition_id', definition_id,
    'schedule_version_id', version_id,
    'occurrence_id', occurrence_id,
    'occurrence_revision', occurrence_row.revision::text
  );

  records := jsonb_build_array(
    app_private.occurrence_dto(occurrence_row),
    app_private.profile_dto(profile_row)
  );

  PERFORM app_private.insert_receipt(
    actor_id,
    operation_id,
    'create_quest',
    1,
    payload_hash,
    jsonb_build_object('outcome', outcome, 'canonical_records', records)
  );

  RETURN app_private.success_envelope(
    operation_id,
    'create_quest',
    false,
    now(),
    outcome,
    records,
    profile_row
  );
END;
$$;

CREATE OR REPLACE FUNCTION app_private.complete_occurrence_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  profile_row public.profiles;
  operation_id uuid;
  data jsonb;
  payload_hash text;
  existing_receipt app_private.mutation_receipts;
  occurrence_id uuid;
  expected_revision bigint;
  occurrence_row public.quest_occurrences;
  reward_row public.completion_rewards;
  outcome jsonb;
  records jsonb;
BEGIN
  actor_id := app_private.require_actor_id();
  IF (request ->> 'contract_version')::integer IS DISTINCT FROM 1 THEN
    PERFORM app_private.raise_command_error('unsupported_contract');
  END IF;

  profile_row := app_private.lock_profile(actor_id);
  operation_id := (request ->> 'operation_id')::uuid;
  data := request -> 'data';
  payload_hash := app_private.canonical_payload_hash('complete_occurrence', 1, data);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'complete_occurrence', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    SELECT *
    INTO occurrence_row
    FROM public.quest_occurrences o
    WHERE o.owner_id = actor_id AND o.id = (data ->> 'occurrence_id')::uuid;

    records := jsonb_build_array(app_private.profile_dto(profile_row));
    IF FOUND THEN
      records := records || jsonb_build_array(app_private.occurrence_dto(occurrence_row));
      SELECT *
      INTO reward_row
      FROM public.completion_rewards r
      WHERE r.owner_id = actor_id AND r.occurrence_id = occurrence_row.id;
      IF FOUND AND reward_row.reversed_at IS NULL THEN
        records := records || jsonb_build_array(app_private.reward_dto(reward_row));
      ELSIF FOUND AND reward_row.reversed_at IS NOT NULL THEN
        records := records;
      END IF;
    END IF;

    RETURN app_private.success_envelope(
      operation_id,
      'complete_occurrence',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      records,
      profile_row
    );
  END IF;

  occurrence_id := (data ->> 'occurrence_id')::uuid;
  expected_revision := (data ->> 'expected_revision')::bigint;

  SELECT *
  INTO occurrence_row
  FROM public.quest_occurrences o
  WHERE o.owner_id = actor_id AND o.id = occurrence_id
  FOR UPDATE;

  IF NOT FOUND THEN
    PERFORM app_private.raise_command_error('not_found');
  END IF;

  IF occurrence_row.revision <> expected_revision THEN
    PERFORM app_private.raise_command_error('revision_conflict');
  END IF;

  IF occurrence_row.status = 'completed' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  IF occurrence_row.status <> 'pending' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  UPDATE public.quest_occurrences
  SET
    status = 'completed',
    completed_at = (data ->> 'observed_at')::timestamptz,
    completion_timezone = data ->> 'observed_timezone',
    completion_local_date = (data ->> 'completion_local_date')::date,
    completion_accepted_at = now(),
    revision = revision + 1
  WHERE owner_id = actor_id AND id = occurrence_id
  RETURNING * INTO occurrence_row;

  IF occurrence_row.entry_kind = 'quest' THEN
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
      occurrence_id,
      20,
      'initial_v1'
    )
    RETURNING * INTO reward_row;
  END IF;

  UPDATE public.profiles
  SET account_data_revision = account_data_revision + 1
  WHERE id = actor_id
  RETURNING * INTO profile_row;

  outcome := jsonb_build_object(
    'occurrence_id', occurrence_id,
    'occurrence_revision', occurrence_row.revision::text,
    'status', occurrence_row.status
  );

  records := jsonb_build_array(
    app_private.occurrence_dto(occurrence_row),
    app_private.profile_dto(profile_row)
  );
  IF reward_row.id IS NOT NULL THEN
    records := records || jsonb_build_array(app_private.reward_dto(reward_row));
  END IF;

  PERFORM app_private.insert_receipt(
    actor_id,
    operation_id,
    'complete_occurrence',
    1,
    payload_hash,
    jsonb_build_object('outcome', outcome)
  );

  RETURN app_private.success_envelope(
    operation_id,
    'complete_occurrence',
    false,
    now(),
    outcome,
    records,
    profile_row
  );
END;
$$;

CREATE OR REPLACE FUNCTION app_private.undo_occurrence_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  profile_row public.profiles;
  operation_id uuid;
  data jsonb;
  payload_hash text;
  existing_receipt app_private.mutation_receipts;
  v_occurrence_id uuid;
  expected_revision bigint;
  occurrence_row public.quest_occurrences;
  reward_row public.completion_rewards;
  outcome jsonb;
  records jsonb;
BEGIN
  actor_id := app_private.require_actor_id();
  IF (request ->> 'contract_version')::integer IS DISTINCT FROM 1 THEN
    PERFORM app_private.raise_command_error('unsupported_contract');
  END IF;

  profile_row := app_private.lock_profile(actor_id);
  operation_id := (request ->> 'operation_id')::uuid;
  data := request -> 'data';
  payload_hash := app_private.canonical_payload_hash('undo_occurrence', 1, data);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'undo_occurrence', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    RETURN app_private.success_envelope(
      operation_id,
      'undo_occurrence',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      existing_receipt.accepted_result -> 'canonical_records',
      profile_row
    );
  END IF;

  v_occurrence_id := (data ->> 'occurrence_id')::uuid;
  expected_revision := (data ->> 'expected_revision')::bigint;

  SELECT *
  INTO occurrence_row
  FROM public.quest_occurrences o
  WHERE o.owner_id = actor_id AND o.id = v_occurrence_id
  FOR UPDATE;

  IF NOT FOUND THEN
    PERFORM app_private.raise_command_error('not_found');
  END IF;

  IF occurrence_row.revision <> expected_revision THEN
    PERFORM app_private.raise_command_error('revision_conflict');
  END IF;

  IF occurrence_row.status <> 'completed' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  UPDATE public.completion_rewards
  SET reversed_at = now(), revision = revision + 1
  WHERE owner_id = actor_id
    AND completion_rewards.occurrence_id = v_occurrence_id
    AND reversed_at IS NULL
  RETURNING * INTO reward_row;

  UPDATE public.quest_occurrences
  SET
    status = 'pending',
    completed_at = NULL,
    completion_timezone = NULL,
    completion_local_date = NULL,
    completion_accepted_at = NULL,
    revision = revision + 1
  WHERE owner_id = actor_id AND id = v_occurrence_id
  RETURNING * INTO occurrence_row;

  UPDATE public.profiles
  SET account_data_revision = account_data_revision + 1
  WHERE id = actor_id
  RETURNING * INTO profile_row;

  outcome := jsonb_build_object(
    'occurrence_id', v_occurrence_id,
    'occurrence_revision', occurrence_row.revision::text,
    'status', occurrence_row.status
  );

  records := jsonb_build_array(
    app_private.occurrence_dto(occurrence_row),
    app_private.profile_dto(profile_row)
  );
  IF reward_row.id IS NOT NULL THEN
    records := records || jsonb_build_array(app_private.reward_dto(reward_row));
  END IF;

  PERFORM app_private.insert_receipt(
    actor_id,
    operation_id,
    'undo_occurrence',
    1,
    payload_hash,
    jsonb_build_object('outcome', outcome, 'canonical_records', records)
  );

  RETURN app_private.success_envelope(
    operation_id,
    'undo_occurrence',
    false,
    now(),
    outcome,
    records,
    profile_row
  );
END;
$$;

CREATE OR REPLACE FUNCTION app_private.unskip_occurrence_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  profile_row public.profiles;
  operation_id uuid;
  data jsonb;
  payload_hash text;
  existing_receipt app_private.mutation_receipts;
  occurrence_id uuid;
  expected_revision bigint;
  occurrence_row public.quest_occurrences;
  outcome jsonb;
  records jsonb;
BEGIN
  actor_id := app_private.require_actor_id();
  IF (request ->> 'contract_version')::integer IS DISTINCT FROM 1 THEN
    PERFORM app_private.raise_command_error('unsupported_contract');
  END IF;

  profile_row := app_private.lock_profile(actor_id);
  operation_id := (request ->> 'operation_id')::uuid;
  data := request -> 'data';
  payload_hash := app_private.canonical_payload_hash('unskip_occurrence', 1, data);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'unskip_occurrence', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    RETURN app_private.success_envelope(
      operation_id,
      'unskip_occurrence',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      existing_receipt.accepted_result -> 'canonical_records',
      profile_row
    );
  END IF;

  occurrence_id := (data ->> 'occurrence_id')::uuid;
  expected_revision := (data ->> 'expected_revision')::bigint;

  SELECT *
  INTO occurrence_row
  FROM public.quest_occurrences o
  WHERE o.owner_id = actor_id AND o.id = occurrence_id
  FOR UPDATE;

  IF NOT FOUND THEN
    PERFORM app_private.raise_command_error('not_found');
  END IF;

  IF occurrence_row.revision <> expected_revision THEN
    PERFORM app_private.raise_command_error('revision_conflict');
  END IF;

  IF occurrence_row.status <> 'skipped' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  UPDATE public.quest_occurrences
  SET status = 'pending', revision = revision + 1
  WHERE owner_id = actor_id AND id = occurrence_id
  RETURNING * INTO occurrence_row;

  UPDATE public.profiles
  SET account_data_revision = account_data_revision + 1
  WHERE id = actor_id
  RETURNING * INTO profile_row;

  outcome := jsonb_build_object(
    'occurrence_id', occurrence_id,
    'occurrence_revision', occurrence_row.revision::text,
    'status', occurrence_row.status
  );

  records := jsonb_build_array(
    app_private.occurrence_dto(occurrence_row),
    app_private.profile_dto(profile_row)
  );

  PERFORM app_private.insert_receipt(
    actor_id,
    operation_id,
    'unskip_occurrence',
    1,
    payload_hash,
    jsonb_build_object('outcome', outcome, 'canonical_records', records)
  );

  RETURN app_private.success_envelope(
    operation_id,
    'unskip_occurrence',
    false,
    now(),
    outcome,
    records,
    profile_row
  );
END;
$$;

CREATE OR REPLACE FUNCTION app_private.skip_occurrence_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  profile_row public.profiles;
  operation_id uuid;
  data jsonb;
  payload_hash text;
  existing_receipt app_private.mutation_receipts;
  occurrence_id uuid;
  expected_revision bigint;
  occurrence_row public.quest_occurrences;
  outcome jsonb;
  records jsonb;
BEGIN
  actor_id := app_private.require_actor_id();
  IF (request ->> 'contract_version')::integer IS DISTINCT FROM 1 THEN
    PERFORM app_private.raise_command_error('unsupported_contract');
  END IF;

  profile_row := app_private.lock_profile(actor_id);
  operation_id := (request ->> 'operation_id')::uuid;
  data := request -> 'data';
  payload_hash := app_private.canonical_payload_hash('skip_occurrence', 1, data);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'skip_occurrence', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    RETURN app_private.success_envelope(
      operation_id,
      'skip_occurrence',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      existing_receipt.accepted_result -> 'canonical_records',
      profile_row
    );
  END IF;

  occurrence_id := (data ->> 'occurrence_id')::uuid;
  expected_revision := (data ->> 'expected_revision')::bigint;

  SELECT *
  INTO occurrence_row
  FROM public.quest_occurrences o
  WHERE o.owner_id = actor_id AND o.id = occurrence_id
  FOR UPDATE;

  IF NOT FOUND THEN
    PERFORM app_private.raise_command_error('not_found');
  END IF;

  IF occurrence_row.revision <> expected_revision THEN
    PERFORM app_private.raise_command_error('revision_conflict');
  END IF;

  IF occurrence_row.status <> 'pending' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  UPDATE public.quest_occurrences
  SET status = 'skipped', revision = revision + 1
  WHERE owner_id = actor_id AND id = occurrence_id
  RETURNING * INTO occurrence_row;

  UPDATE public.profiles
  SET account_data_revision = account_data_revision + 1
  WHERE id = actor_id
  RETURNING * INTO profile_row;

  outcome := jsonb_build_object(
    'occurrence_id', occurrence_id,
    'occurrence_revision', occurrence_row.revision::text,
    'status', occurrence_row.status
  );

  records := jsonb_build_array(
    app_private.occurrence_dto(occurrence_row),
    app_private.profile_dto(profile_row)
  );

  PERFORM app_private.insert_receipt(
    actor_id,
    operation_id,
    'skip_occurrence',
    1,
    payload_hash,
    jsonb_build_object('outcome', outcome, 'canonical_records', records)
  );

  RETURN app_private.success_envelope(
    operation_id,
    'skip_occurrence',
    false,
    now(),
    outcome,
    records,
    profile_row
  );
END;
$$;

ALTER FUNCTION app_private.ensure_profile_impl(jsonb) OWNER TO gamecal_command_executor;
ALTER FUNCTION app_private.create_quest_impl(jsonb) OWNER TO gamecal_command_executor;
ALTER FUNCTION app_private.complete_occurrence_impl(jsonb) OWNER TO gamecal_command_executor;
ALTER FUNCTION app_private.undo_occurrence_impl(jsonb) OWNER TO gamecal_command_executor;
ALTER FUNCTION app_private.unskip_occurrence_impl(jsonb) OWNER TO gamecal_command_executor;
ALTER FUNCTION app_private.skip_occurrence_impl(jsonb) OWNER TO gamecal_command_executor;

REVOKE ALL ON FUNCTION app_private.ensure_profile_impl(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_private.create_quest_impl(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_private.complete_occurrence_impl(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_private.undo_occurrence_impl(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_private.unskip_occurrence_impl(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_private.skip_occurrence_impl(jsonb) FROM PUBLIC;

GRANT USAGE ON SCHEMA app_private TO authenticated;

GRANT EXECUTE ON FUNCTION app_private.ensure_profile_impl(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.create_quest_impl(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.complete_occurrence_impl(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.undo_occurrence_impl(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.unskip_occurrence_impl(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.skip_occurrence_impl(jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.ensure_profile(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.ensure_profile_impl(request);
$$;

CREATE OR REPLACE FUNCTION public.create_quest(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.create_quest_impl(request);
$$;

CREATE OR REPLACE FUNCTION public.complete_occurrence(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.complete_occurrence_impl(request);
$$;

CREATE OR REPLACE FUNCTION public.undo_occurrence(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.undo_occurrence_impl(request);
$$;

CREATE OR REPLACE FUNCTION public.unskip_occurrence(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.unskip_occurrence_impl(request);
$$;

CREATE OR REPLACE FUNCTION public.skip_occurrence(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.skip_occurrence_impl(request);
$$;

REVOKE ALL ON FUNCTION public.ensure_profile(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_quest(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_occurrence(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.undo_occurrence(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.unskip_occurrence(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.skip_occurrence(jsonb) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.ensure_profile(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_quest(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_occurrence(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.undo_occurrence(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unskip_occurrence(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.skip_occurrence(jsonb) TO authenticated;
