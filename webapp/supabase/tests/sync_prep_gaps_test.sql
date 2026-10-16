BEGIN;

CREATE SCHEMA IF NOT EXISTS test_support;
GRANT USAGE ON SCHEMA test_support TO PUBLIC;

CREATE OR REPLACE FUNCTION test_support.create_auth_user(
  user_id uuid,
  email text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, public, extensions
AS $$
BEGIN
  INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  VALUES (
    user_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    email,
    crypt('password', gen_salt('bf')),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION test_support.authenticate_as(user_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', user_id::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  PERFORM set_config('role', 'authenticated', true);
END;
$$;

CREATE OR REPLACE FUNCTION test_support.alice_sync_epoch()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT sync_epoch
  FROM public.profiles
  WHERE id = '11111111-1111-4111-8111-111111111111'::uuid;
$$;

CREATE OR REPLACE FUNCTION test_support.bump_alice_sync_epoch()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  previous_epoch uuid;
BEGIN
  SELECT sync_epoch
  INTO previous_epoch
  FROM public.profiles
  WHERE id = '11111111-1111-4111-8111-111111111111'::uuid;

  UPDATE public.profiles
  SET sync_epoch = extensions.gen_random_uuid()
  WHERE id = '11111111-1111-4111-8111-111111111111'::uuid;

  RETURN previous_epoch;
END;
$$;

SELECT plan(6);

SELECT test_support.create_auth_user(
  '11111111-1111-4111-8111-111111111111'::uuid,
  'alice-gaps@example.com'
);
SELECT test_support.authenticate_as('11111111-1111-4111-8111-111111111111'::uuid);

SELECT ok(
  (public.ensure_profile(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'b1000000-0000-4000-8000-000000000001',
      'data', jsonb_build_object(
        'display_name', 'Alice',
        'planning_timezone', 'UTC'
      )
    )
  ) ->> 'ok')::boolean,
  'profile bootstrap for gap tests'
);

SELECT throws_ok(
  $$
    SELECT public.create_quest(
      jsonb_build_object(
        'contract_version', 1,
        'operation_id', 'b2000000-0000-4000-8000-000000000002',
        'sync_epoch', test_support.alice_sync_epoch()::text,
        'data', jsonb_build_object(
          'definition_id', 'fda923dc-3ebd-489e-a655-37e04fef3163',
          'schedule_version_id', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          'title', 'Timed quest',
          'schedule', jsonb_build_object(
            'anchor_date', '2026-10-14',
            'planning_timezone', 'UTC',
            'timing', jsonb_build_object(
              'kind', 'timed',
              'start_local_time', '10:00:00',
              'end_local_time', '10:30:00'
            ),
            'recurrence', jsonb_build_object('kind', 'none')
          )
        )
      )
    );
  $$,
  'P0001',
  'validation',
  'timed create_quest is rejected in the foundation slice'
);

SELECT ok(
  (public.create_quest(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'b3000000-0000-4000-8000-000000000003',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'data', jsonb_build_object(
        'definition_id', '84915f93-ef45-4617-a753-0b072ab89ccd',
        'schedule_version_id', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'title', 'Untimed quest',
        'planning_timezone', 'UTC',
        'anchor_date', '2026-11-01'
      )
    )
  ) ->> 'ok')::boolean,
  'untimed create_quest still succeeds'
);

SELECT ok(
  (public.complete_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'b4000000-0000-4000-8000-000000000004',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '1',
      'data', jsonb_build_object(
        'occurrence_id', '0a8f3101-1700-521b-bffe-423311e7b732',
        'observed_at', '2026-11-01T12:00:00Z',
        'observed_timezone', 'UTC'
      )
    )
  ) -> 'canonical' -> 'progression' -> 'record' ->> 'total_xp') = '20',
  'complete returns progression snapshot'
);

SELECT ok(
  (
    WITH undo_response AS (
      SELECT public.undo_occurrence(
        jsonb_build_object(
          'contract_version', 1,
          'operation_id', 'b5000000-0000-4000-8000-000000000005',
          'sync_epoch', test_support.alice_sync_epoch()::text,
          'expected_revision', '2',
          'data', jsonb_build_object(
            'occurrence_id', '0a8f3101-1700-521b-bffe-423311e7b732'
          )
        )
      ) AS body
    )
    SELECT body -> 'canonical' -> 'progression' -> 'record' ->> 'total_xp' = '0'
      AND jsonb_array_length(body -> 'invalidations') = 1
      AND EXISTS (
        SELECT 1
        FROM jsonb_array_elements(body -> 'canonical' -> 'records') AS elem
        WHERE elem ->> 'entity' = 'completion_reward'
          AND (elem -> 'record' ->> 'reversed_at') IS NOT NULL
      )
    FROM undo_response
  ),
  'undo returns reversed reward, zero progression, and calendar invalidation'
);

SELECT ok(
  (
    WITH bumped AS (
      SELECT test_support.bump_alice_sync_epoch()::text AS stale_epoch
    )
    SELECT (
      public.complete_occurrence(
        jsonb_build_object(
          'contract_version', 1,
          'operation_id', 'b4000000-0000-4000-8000-000000000004',
          'sync_epoch', (SELECT stale_epoch FROM bumped),
          'expected_revision', '1',
          'data', jsonb_build_object(
            'occurrence_id', '0a8f3101-1700-521b-bffe-423311e7b732',
            'observed_at', '2026-11-01T12:00:00Z',
            'observed_timezone', 'UTC'
          )
        )
      ) -> 'acknowledgment' ->> 'replayed'
    )::boolean
  ),
  'stale sync_epoch retries replay an existing receipt before rejecting'
);

SELECT * FROM finish();

ROLLBACK;
