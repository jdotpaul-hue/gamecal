-- Owner read RPCs, snapshot tokens, and RPC-only table access for authenticated clients.

CREATE OR REPLACE FUNCTION app_private.assert_read_envelope(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
BEGIN
  PERFORM app_private.assert_only_keys(request, ARRAY['contract_version', 'data']);
  PERFORM app_private.parse_contract_version(request);

  IF request -> 'data' IS NULL OR jsonb_typeof(request -> 'data') <> 'object' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  RETURN request -> 'data';
END;
$$;

CREATE OR REPLACE FUNCTION app_private.read_success(data jsonb)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'ok', true,
    'contract_version', 1,
    'data', data
  );
$$;

CREATE OR REPLACE FUNCTION app_private.definition_dto(definition_row public.quest_definitions)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'entity', 'quest_definition',
    'record', jsonb_build_object(
      'id', definition_row.id,
      'state', definition_row.state,
      'revision', definition_row.revision::text
    )
  );
$$;

CREATE OR REPLACE FUNCTION app_private.schedule_version_dto(version_row public.quest_schedule_versions)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'entity', 'quest_schedule_version',
    'record', jsonb_build_object(
      'id', version_row.id,
      'definition_id', version_row.definition_id,
      'effective_from', version_row.effective_from,
      'anchor_date', version_row.anchor_date,
      'entry_kind', version_row.entry_kind,
      'title', version_row.title,
      'recurrence_kind', version_row.recurrence_kind,
      'timing_kind', version_row.timing_kind,
      'planning_timezone', version_row.planning_timezone,
      'revision', version_row.revision::text
    )
  );
$$;

CREATE OR REPLACE FUNCTION app_private.calendar_scope_fingerprint(
  from_date date,
  until_date date,
  display_timezone text
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT from_date::text || '|' || until_date::text || '|' || display_timezone;
$$;

CREATE OR REPLACE FUNCTION app_private.encode_snapshot_token(payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT payload::text;
$$;

CREATE OR REPLACE FUNCTION app_private.decode_snapshot_token(token text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  parsed jsonb;
BEGIN
  IF token IS NULL OR btrim(token) = '' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  BEGIN
    parsed := token::jsonb;
  EXCEPTION
    WHEN invalid_text_representation THEN
      PERFORM app_private.raise_command_error('validation');
  END;

  IF jsonb_typeof(parsed) <> 'object' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  RETURN parsed;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.assert_calendar_snapshot_token(
  actor_id uuid,
  profile_row public.profiles,
  token text,
  from_date date,
  until_date date,
  display_timezone text
)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  parsed jsonb;
  as_of timestamptz;
BEGIN
  parsed := app_private.decode_snapshot_token(token);

  IF (parsed ->> 'kind') IS DISTINCT FROM 'calendar' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF (parsed ->> 'owner_id')::uuid IS DISTINCT FROM actor_id THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF (parsed ->> 'sync_epoch')::uuid IS DISTINCT FROM profile_row.sync_epoch THEN
    PERFORM app_private.raise_command_error('snapshot_changed');
  END IF;

  IF (parsed ->> 'account_data_revision')::bigint IS DISTINCT FROM profile_row.account_data_revision THEN
    PERFORM app_private.raise_command_error('snapshot_changed');
  END IF;

  IF parsed ->> 'scope_fingerprint'
    IS DISTINCT FROM app_private.calendar_scope_fingerprint(from_date, until_date, display_timezone)
  THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  as_of := (parsed ->> 'as_of')::timestamptz;
  IF as_of IS NULL OR now() > as_of + interval '5 minutes' THEN
    PERFORM app_private.raise_command_error('snapshot_expired');
  END IF;

  RETURN parsed;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.get_profile_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  profile_row public.profiles;
BEGIN
  PERFORM app_private.assert_read_envelope(request);
  actor_id := app_private.require_actor_id();

  SELECT *
  INTO profile_row
  FROM public.profiles
  WHERE id = actor_id;

  IF NOT FOUND THEN
    RETURN app_private.read_success(
      jsonb_build_object(
        'scope', jsonb_build_object('kind', 'profile'),
        'bootstrap_needed', true,
        'records', '[]'::jsonb,
        'snapshot_token', NULL,
        'next_cursor', NULL,
        'page_set_complete', true,
        'coverage', jsonb_build_object('generation_complete', true),
        'summary', NULL
      )
    );
  END IF;

  RETURN app_private.read_success(
    jsonb_build_object(
      'scope', jsonb_build_object('kind', 'profile'),
      'bootstrap_needed', false,
      'records', jsonb_build_array(app_private.profile_dto(profile_row)),
      'snapshot_token', app_private.encode_snapshot_token(
        jsonb_build_object(
          'kind', 'profile',
          'owner_id', actor_id,
          'sync_epoch', profile_row.sync_epoch,
          'account_data_revision', profile_row.account_data_revision::text,
          'as_of', now()
        )
      ),
      'next_cursor', NULL,
      'page_set_complete', true,
      'coverage', jsonb_build_object('generation_complete', true),
      'summary', jsonb_build_object('as_of', now(), 'profile', app_private.profile_dto(profile_row))
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION app_private.get_progression_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  profile_row public.profiles;
  progression jsonb;
  as_of timestamptz := now();
BEGIN
  PERFORM app_private.assert_read_envelope(request);
  actor_id := app_private.require_actor_id();

  SELECT *
  INTO profile_row
  FROM public.profiles
  WHERE id = actor_id;

  IF NOT FOUND THEN
    PERFORM app_private.raise_command_error('not_found');
  END IF;

  progression := app_private.progression_snapshot(actor_id);

  RETURN app_private.read_success(
    jsonb_build_object(
      'scope', jsonb_build_object('kind', 'progression'),
      'records', jsonb_build_array(progression),
      'snapshot_token', app_private.encode_snapshot_token(
        jsonb_build_object(
          'kind', 'progression',
          'owner_id', actor_id,
          'sync_epoch', profile_row.sync_epoch,
          'account_data_revision', profile_row.account_data_revision::text,
          'as_of', as_of
        )
      ),
      'next_cursor', NULL,
      'page_set_complete', true,
      'coverage', jsonb_build_object('generation_complete', true),
      'summary', jsonb_build_object('as_of', as_of, 'progression', progression)
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION app_private.get_own_operation_result_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  data jsonb;
  p_operation_id uuid;
  existing app_private.mutation_receipts;
BEGIN
  data := app_private.assert_read_envelope(request);
  actor_id := app_private.require_actor_id();

  PERFORM app_private.assert_only_keys(data, ARRAY['operation_id']);

  BEGIN
    p_operation_id := (data ->> 'operation_id')::uuid;
  EXCEPTION
    WHEN invalid_text_representation THEN
      PERFORM app_private.raise_command_error('validation');
  END;

  IF p_operation_id IS NULL THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  SELECT *
  INTO existing
  FROM app_private.mutation_receipts r
  WHERE r.owner_id = actor_id AND r.operation_id = p_operation_id;

  IF NOT FOUND THEN
    RETURN app_private.read_success(
      jsonb_build_object('status', 'not_seen')
    );
  END IF;

  RETURN app_private.read_success(
    jsonb_build_object(
      'status', 'accepted',
      'acknowledgment', jsonb_build_object(
        'operation_id', existing.operation_id,
        'command_name', existing.command_name,
        'accepted_at', existing.accepted_at,
        'outcome', existing.accepted_result -> 'outcome',
        'canonical_records', existing.accepted_result -> 'canonical_records'
      )
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION app_private.get_calendar_scope_impl(request jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid;
  data jsonb;
  from_date date;
  until_date date;
  display_timezone text;
  page_size integer;
  snapshot_token text;
  cursor_text text;
  profile_row public.profiles;
  token_payload jsonb;
  as_of timestamptz;
  cursor_date date;
  cursor_id uuid;
  records jsonb := '[]'::jsonb;
  occurrence_row public.quest_occurrences;
  reward_row public.completion_rewards;
  definition_row public.quest_definitions;
  version_row public.quest_schedule_versions;
  fetched integer := 0;
  limit_rows integer;
  next_cursor text := NULL;
  page_set_complete boolean := false;
  seen_definition_ids uuid[] := ARRAY[]::uuid[];
  seen_version_ids uuid[] := ARRAY[]::uuid[];
BEGIN
  data := app_private.assert_read_envelope(request);
  actor_id := app_private.require_actor_id();

  PERFORM app_private.assert_only_keys(
    data,
    ARRAY[
      'from_date',
      'until_date',
      'display_timezone',
      'page_size',
      'snapshot_token',
      'cursor'
    ]
  );

  from_date := (data ->> 'from_date')::date;
  until_date := (data ->> 'until_date')::date;
  display_timezone := data ->> 'display_timezone';
  page_size := COALESCE((data ->> 'page_size')::integer, 50);
  snapshot_token := data ->> 'snapshot_token';
  cursor_text := data ->> 'cursor';

  IF from_date IS NULL OR until_date IS NULL OR until_date <= from_date THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF until_date - from_date > 93 THEN
    PERFORM app_private.raise_command_error('scope_too_large');
  END IF;

  IF display_timezone IS NULL OR btrim(display_timezone) = '' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF page_size < 1 OR page_size > 100 THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  SELECT *
  INTO profile_row
  FROM public.profiles
  WHERE id = actor_id;

  IF NOT FOUND THEN
    PERFORM app_private.raise_command_error('not_found');
  END IF;

  IF snapshot_token IS NULL OR btrim(snapshot_token) = '' THEN
    as_of := now();
    token_payload := jsonb_build_object(
      'kind', 'calendar',
      'owner_id', actor_id,
      'sync_epoch', profile_row.sync_epoch,
      'account_data_revision', profile_row.account_data_revision::text,
      'scope_fingerprint', app_private.calendar_scope_fingerprint(from_date, until_date, display_timezone),
      'as_of', as_of
    );
    snapshot_token := app_private.encode_snapshot_token(token_payload);
    cursor_date := NULL;
    cursor_id := NULL;
  ELSE
    token_payload := app_private.assert_calendar_snapshot_token(
      actor_id,
      profile_row,
      snapshot_token,
      from_date,
      until_date,
      display_timezone
    );
    as_of := (token_payload ->> 'as_of')::timestamptz;

    IF cursor_text IS NULL OR btrim(cursor_text) = '' THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;

    BEGIN
      cursor_date := ((cursor_text::jsonb) ->> 'last_effective_date')::date;
      cursor_id := ((cursor_text::jsonb) ->> 'last_id')::uuid;
    EXCEPTION
      WHEN invalid_text_representation THEN
        PERFORM app_private.raise_command_error('validation');
    END;

    IF cursor_date IS NULL OR cursor_id IS NULL THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;
  END IF;

  limit_rows := page_size + 1;

  FOR occurrence_row IN
    SELECT o.*
    FROM public.quest_occurrences o
    WHERE o.owner_id = actor_id
      AND o.deleted_at IS NULL
      AND o.effective_date >= from_date
      AND o.effective_date < until_date
      AND (
        cursor_id IS NULL
        OR (o.effective_date, o.id) > (cursor_date, cursor_id)
      )
    ORDER BY o.effective_date, o.id
    LIMIT limit_rows
  LOOP
    fetched := fetched + 1;
    IF fetched > page_size THEN
      next_cursor := jsonb_build_object(
        'last_effective_date', occurrence_row.effective_date,
        'last_id', occurrence_row.id
      )::text;
      EXIT;
    END IF;

    records := records || jsonb_build_array(app_private.occurrence_dto(occurrence_row));

    SELECT *
    INTO reward_row
    FROM public.completion_rewards r
    WHERE r.owner_id = actor_id
      AND r.occurrence_id = occurrence_row.id
    ORDER BY r.awarded_at DESC
    LIMIT 1;

    IF FOUND THEN
      records := records || jsonb_build_array(app_private.reward_dto(reward_row));
    END IF;

    IF NOT occurrence_row.definition_id = ANY (seen_definition_ids) THEN
      seen_definition_ids := seen_definition_ids || occurrence_row.definition_id;
      SELECT *
      INTO definition_row
      FROM public.quest_definitions d
      WHERE d.owner_id = actor_id AND d.id = occurrence_row.definition_id;
      IF FOUND THEN
        records := records || jsonb_build_array(app_private.definition_dto(definition_row));
      END IF;
    END IF;

    IF NOT occurrence_row.schedule_version_id = ANY (seen_version_ids) THEN
      seen_version_ids := seen_version_ids || occurrence_row.schedule_version_id;
      SELECT *
      INTO version_row
      FROM public.quest_schedule_versions v
      WHERE v.owner_id = actor_id AND v.id = occurrence_row.schedule_version_id;
      IF FOUND THEN
        records := records || jsonb_build_array(app_private.schedule_version_dto(version_row));
      END IF;
    END IF;
  END LOOP;

  page_set_complete := next_cursor IS NULL;

  RETURN app_private.read_success(
    jsonb_build_object(
      'scope', jsonb_build_object(
        'kind', 'calendar',
        'from_date', from_date,
        'until_date', until_date,
        'display_timezone', display_timezone
      ),
      'snapshot_token', snapshot_token,
      'records', records,
      'next_cursor', next_cursor,
      'page_set_complete', page_set_complete,
      'coverage', jsonb_build_object(
        'generation_complete', true,
        'historical_catchup_complete', true
      ),
      'summary', jsonb_build_object(
        'as_of', as_of,
        'progression', app_private.progression_snapshot(actor_id)
      )
    )
  );
END;
$$;

ALTER FUNCTION app_private.get_profile_impl(jsonb) OWNER TO gamecal_command_executor;
ALTER FUNCTION app_private.get_progression_impl(jsonb) OWNER TO gamecal_command_executor;
ALTER FUNCTION app_private.get_own_operation_result_impl(jsonb) OWNER TO gamecal_command_executor;
ALTER FUNCTION app_private.get_calendar_scope_impl(jsonb) OWNER TO gamecal_command_executor;

REVOKE ALL ON FUNCTION app_private.get_profile_impl(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_private.get_progression_impl(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_private.get_own_operation_result_impl(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_private.get_calendar_scope_impl(jsonb) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION app_private.get_profile_impl(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.get_progression_impl(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.get_own_operation_result_impl(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.get_calendar_scope_impl(jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_profile(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.get_profile_impl(request);
$$;

CREATE OR REPLACE FUNCTION public.get_progression(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.get_progression_impl(request);
$$;

CREATE OR REPLACE FUNCTION public.get_own_operation_result(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.get_own_operation_result_impl(request);
$$;

CREATE OR REPLACE FUNCTION public.get_calendar_scope(request jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT app_private.get_calendar_scope_impl(request);
$$;

REVOKE ALL ON FUNCTION public.get_profile(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_progression(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_own_operation_result(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_calendar_scope(jsonb) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_profile(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_progression(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_own_operation_result(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_calendar_scope(jsonb) TO authenticated;

REVOKE SELECT ON TABLE public.profiles FROM authenticated;
REVOKE SELECT ON TABLE public.quest_definitions FROM authenticated;
REVOKE SELECT ON TABLE public.quest_schedule_versions FROM authenticated;
REVOKE SELECT ON TABLE public.quest_occurrences FROM authenticated;
REVOKE SELECT ON TABLE public.completion_rewards FROM authenticated;
