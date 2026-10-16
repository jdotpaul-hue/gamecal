-- Sync-prep fixes: schedule validation, undo canonical/progression, receipt-before-epoch, envelope invalidations.

DROP FUNCTION IF EXISTS app_private.success_envelope(
  uuid,
  text,
  boolean,
  timestamptz,
  jsonb,
  jsonb,
  public.profiles
);

CREATE OR REPLACE FUNCTION app_private.success_envelope(
  operation_id uuid,
  command_name text,
  replayed boolean,
  accepted_at timestamptz,
  acknowledgment jsonb,
  canonical_records jsonb,
  profile_row public.profiles,
  invalidations jsonb DEFAULT '[]'::jsonb,
  progression jsonb DEFAULT NULL
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
    'canonical', jsonb_strip_nulls(
      jsonb_build_object(
        'sync_epoch', profile_row.sync_epoch,
        'account_data_revision', profile_row.account_data_revision::text,
        'records', canonical_records,
        'progression', progression
      )
    ),
    'invalidations', COALESCE(invalidations, '[]'::jsonb)
  );
$$;

CREATE OR REPLACE FUNCTION app_private.progression_snapshot(actor_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'entity', 'progression',
    'record', jsonb_build_object(
      'total_xp',
      COALESCE(
        (
          SELECT SUM(r.awarded_xp)::text
          FROM public.completion_rewards r
          WHERE r.owner_id = actor_id AND r.reversed_at IS NULL
        ),
        '0'
      ),
      'level',
      (
        1 + COALESCE(
          (
            SELECT SUM(r.awarded_xp)
            FROM public.completion_rewards r
            WHERE r.owner_id = actor_id AND r.reversed_at IS NULL
          ),
          0
        ) / 100
      )::text
    )
  );
$$;

CREATE OR REPLACE FUNCTION app_private.calendar_invalidation()
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_array(jsonb_build_object('scope', 'calendar'));
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
    WHERE r.owner_id = actor_id AND r.occurrence_id = v_occurrence_id
    ORDER BY r.awarded_at DESC
    LIMIT 1;

    IF FOUND THEN
      records := records || jsonb_build_array(app_private.reward_dto(reward_row));
    END IF;
  END IF;

  RETURN records;
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
  recurrence jsonb;
  recurrence_kind text;
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

    IF schedule ? 'recurrence' THEN
      recurrence := schedule -> 'recurrence';
      IF jsonb_typeof(recurrence) <> 'object' THEN
        PERFORM app_private.raise_command_error('validation');
      END IF;
      recurrence_kind := COALESCE(recurrence ->> 'kind', 'none');
      IF recurrence_kind IS DISTINCT FROM 'none' THEN
        PERFORM app_private.raise_command_error('validation');
      END IF;
    END IF;
  ELSE
    anchor_date := (data ->> 'anchor_date')::date;
    planning_timezone := data ->> 'planning_timezone';
    timing_kind := COALESCE(data ->> 'timing_kind', 'untimed');
    timing := NULL;
  END IF;

  IF anchor_date IS NULL OR planning_timezone IS NULL OR btrim(planning_timezone) = '' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF timing_kind IS DISTINCT FROM 'untimed' THEN
    PERFORM app_private.raise_command_error('validation');
  END IF;

  IF timing IS NOT NULL THEN
    IF timing ->> 'start_local_time' IS NOT NULL
      OR timing ->> 'end_local_time' IS NOT NULL
      OR (timing ->> 'kind') IS DISTINCT FROM 'untimed'
    THEN
      PERFORM app_private.raise_command_error('validation');
    END IF;
  END IF;

  IF data ? 'timing_kind' AND (data ->> 'timing_kind') IS DISTINCT FROM 'untimed' THEN
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
