-- Receipt lookup before sync_epoch checks; progression/invalidations on reward-changing commands.

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
  parsed RECORD;
  definition_id uuid;
  version_id uuid;
  occurrence_id uuid;
  definition_row public.quest_definitions;
  version_row public.quest_schedule_versions;
  occurrence_row public.quest_occurrences;
  outcome jsonb;
  records jsonb;
BEGIN
  actor_id := app_private.require_actor_id();
  PERFORM app_private.assert_mutation_envelope(request, false);
  operation_id := app_private.parse_operation_id(request);
  PERFORM app_private.parse_expected_revision(request, true);
  data := request -> 'data';
  payload_hash := app_private.command_request_hash('create_quest', 1, request);

  profile_row := app_private.lock_profile(actor_id);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'create_quest', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    outcome := existing_receipt.accepted_result -> 'outcome';
    RETURN app_private.success_envelope(
      operation_id,
      'create_quest',
      true,
      existing_receipt.accepted_at,
      outcome,
      app_private.canonical_records_for_create_quest(actor_id, outcome),
      profile_row,
      app_private.calendar_invalidation()
    );
  END IF;

  PERFORM app_private.assert_profile_sync_epoch(request, profile_row, false);

  SELECT p.*
  INTO parsed
  FROM app_private.parse_create_quest_schedule(data) AS p;

  definition_id := (data ->> 'definition_id')::uuid;
  version_id := (data ->> 'schedule_version_id')::uuid;
  occurrence_id := app_private.derive_occurrence_id(definition_id, parsed.anchor_date);

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
    parsed.anchor_date,
    parsed.entry_kind,
    parsed.title,
    parsed.notes,
    parsed.category,
    parsed.priority,
    parsed.blocks_time,
    parsed.anchor_date,
    'none',
    parsed.timing_kind,
    parsed.planning_timezone
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
    parsed.anchor_date,
    parsed.anchor_date,
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

  records := app_private.canonical_records_for_create_quest(actor_id, outcome);

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
    profile_row,
    app_private.calendar_invalidation()
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
  v_occurrence_id uuid;
  expected_revision bigint;
  occurrence_row public.quest_occurrences;
  reward_row public.completion_rewards;
  outcome jsonb;
  records jsonb;
  observed_at timestamptz;
  observed_timezone text;
  v_completion_local_date date;
BEGIN
  actor_id := app_private.require_actor_id();
  PERFORM app_private.assert_mutation_envelope(request, false);
  operation_id := app_private.parse_operation_id(request);
  expected_revision := app_private.parse_expected_revision(request, false);
  data := request -> 'data';
  PERFORM app_private.assert_only_keys(
    data,
    ARRAY['occurrence_id', 'observed_at', 'observed_timezone']
  );
  payload_hash := app_private.command_request_hash('complete_occurrence', 1, request);

  profile_row := app_private.lock_profile(actor_id);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'complete_occurrence', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    v_occurrence_id := (data ->> 'occurrence_id')::uuid;
    RETURN app_private.success_envelope(
      operation_id,
      'complete_occurrence',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      app_private.canonical_records_for_occurrence(actor_id, v_occurrence_id),
      profile_row,
      app_private.calendar_invalidation(),
      app_private.progression_snapshot(actor_id)
    );
  END IF;

  PERFORM app_private.assert_profile_sync_epoch(request, profile_row, false);

  v_occurrence_id := (data ->> 'occurrence_id')::uuid;
  observed_at := (data ->> 'observed_at')::timestamptz;
  observed_timezone := data ->> 'observed_timezone';
  v_completion_local_date := app_private.derive_completion_local_date(
    observed_at,
    observed_timezone
  );

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

  IF occurrence_row.status = 'completed' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  IF occurrence_row.status <> 'pending' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  UPDATE public.quest_occurrences
  SET
    status = 'completed',
    completed_at = observed_at,
    completion_timezone = observed_timezone,
    completion_local_date = v_completion_local_date,
    completion_accepted_at = now(),
    revision = revision + 1
  WHERE owner_id = actor_id AND id = v_occurrence_id
  RETURNING * INTO occurrence_row;

  IF occurrence_row.entry_kind = 'quest' THEN
    reward_row := app_private.award_or_reactivate_quest_reward(actor_id, v_occurrence_id);
  END IF;

  UPDATE public.profiles
  SET account_data_revision = account_data_revision + 1
  WHERE id = actor_id
  RETURNING * INTO profile_row;

  outcome := jsonb_build_object(
    'occurrence_id', v_occurrence_id,
    'occurrence_revision', occurrence_row.revision::text,
    'status', occurrence_row.status,
    'completion_local_date', v_completion_local_date
  );

  records := app_private.canonical_records_for_occurrence(actor_id, v_occurrence_id);

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
    profile_row,
    app_private.calendar_invalidation(),
    app_private.progression_snapshot(actor_id)
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
  PERFORM app_private.assert_mutation_envelope(request, false);
  operation_id := app_private.parse_operation_id(request);
  expected_revision := app_private.parse_expected_revision(request, false);
  data := request -> 'data';
  PERFORM app_private.assert_only_keys(data, ARRAY['occurrence_id']);
  payload_hash := app_private.command_request_hash('undo_occurrence', 1, request);

  profile_row := app_private.lock_profile(actor_id);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'undo_occurrence', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    v_occurrence_id := (data ->> 'occurrence_id')::uuid;
    RETURN app_private.success_envelope(
      operation_id,
      'undo_occurrence',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      app_private.canonical_records_for_occurrence(actor_id, v_occurrence_id),
      profile_row,
      app_private.calendar_invalidation(),
      app_private.progression_snapshot(actor_id)
    );
  END IF;

  PERFORM app_private.assert_profile_sync_epoch(request, profile_row, false);

  v_occurrence_id := (data ->> 'occurrence_id')::uuid;

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

  records := app_private.canonical_records_for_occurrence(actor_id, v_occurrence_id);

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
    profile_row,
    app_private.calendar_invalidation(),
    app_private.progression_snapshot(actor_id)
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
  v_occurrence_id uuid;
  expected_revision bigint;
  occurrence_row public.quest_occurrences;
  outcome jsonb;
  records jsonb;
BEGIN
  actor_id := app_private.require_actor_id();
  PERFORM app_private.assert_mutation_envelope(request, false);
  operation_id := app_private.parse_operation_id(request);
  expected_revision := app_private.parse_expected_revision(request, false);
  data := request -> 'data';
  PERFORM app_private.assert_only_keys(data, ARRAY['occurrence_id']);
  payload_hash := app_private.command_request_hash('skip_occurrence', 1, request);

  profile_row := app_private.lock_profile(actor_id);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'skip_occurrence', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    v_occurrence_id := (data ->> 'occurrence_id')::uuid;
    RETURN app_private.success_envelope(
      operation_id,
      'skip_occurrence',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      app_private.canonical_records_for_occurrence(actor_id, v_occurrence_id),
      profile_row,
      app_private.calendar_invalidation()
    );
  END IF;

  PERFORM app_private.assert_profile_sync_epoch(request, profile_row, false);

  v_occurrence_id := (data ->> 'occurrence_id')::uuid;

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

  IF occurrence_row.status <> 'pending' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  UPDATE public.quest_occurrences
  SET status = 'skipped', revision = revision + 1
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

  records := app_private.canonical_records_for_occurrence(actor_id, v_occurrence_id);

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
    profile_row,
    app_private.calendar_invalidation()
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
  v_occurrence_id uuid;
  expected_revision bigint;
  occurrence_row public.quest_occurrences;
  outcome jsonb;
  records jsonb;
BEGIN
  actor_id := app_private.require_actor_id();
  PERFORM app_private.assert_mutation_envelope(request, false);
  operation_id := app_private.parse_operation_id(request);
  expected_revision := app_private.parse_expected_revision(request, false);
  data := request -> 'data';
  PERFORM app_private.assert_only_keys(data, ARRAY['occurrence_id']);
  payload_hash := app_private.command_request_hash('unskip_occurrence', 1, request);

  profile_row := app_private.lock_profile(actor_id);

  existing_receipt := app_private.claim_or_replay_receipt(
    actor_id, operation_id, 'unskip_occurrence', 1, payload_hash
  );
  IF existing_receipt IS NOT NULL THEN
    v_occurrence_id := (data ->> 'occurrence_id')::uuid;
    RETURN app_private.success_envelope(
      operation_id,
      'unskip_occurrence',
      true,
      existing_receipt.accepted_at,
      existing_receipt.accepted_result -> 'outcome',
      app_private.canonical_records_for_occurrence(actor_id, v_occurrence_id),
      profile_row,
      app_private.calendar_invalidation()
    );
  END IF;

  PERFORM app_private.assert_profile_sync_epoch(request, profile_row, false);

  v_occurrence_id := (data ->> 'occurrence_id')::uuid;

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

  IF occurrence_row.status <> 'skipped' THEN
    PERFORM app_private.raise_command_error('invalid_transition');
  END IF;

  UPDATE public.quest_occurrences
  SET status = 'pending', revision = revision + 1
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

  records := app_private.canonical_records_for_occurrence(actor_id, v_occurrence_id);

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
    profile_row,
    app_private.calendar_invalidation()
  );
END;
$$;
