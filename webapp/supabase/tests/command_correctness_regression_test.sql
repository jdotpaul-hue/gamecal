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

CREATE OR REPLACE FUNCTION test_support.authenticate_as_claims(user_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM set_config(
    'request.jwt.claims',
    json_build_object('sub', user_id::text, 'role', 'authenticated')::text,
    true
  );
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

SELECT plan(7);

SELECT test_support.create_auth_user(
  '11111111-1111-4111-8111-111111111111'::uuid,
  'alice-regression@example.com'
);

SELECT test_support.authenticate_as_claims('11111111-1111-4111-8111-111111111111'::uuid);

SELECT ok(
  (public.ensure_profile(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'a1000000-0000-4000-8000-000000000001',
      'sync_epoch', NULL,
      'expected_revision', NULL,
      'data', jsonb_build_object(
        'display_name', 'Alice',
        'planning_timezone', 'UTC'
      )
    )
  ) ->> 'ok')::boolean,
  'ensure_profile accepts bootstrap envelope'
);

SELECT throws_ok(
  $$
    SELECT public.complete_occurrence(
      jsonb_build_object(
        'contract_version', 1,
        'operation_id', 'a2000000-0000-4000-8000-000000000002',
        'sync_epoch', test_support.alice_sync_epoch()::text,
        'data', jsonb_build_object(
          'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8',
          'observed_at', '2026-10-14T12:00:00Z',
          'observed_timezone', 'UTC'
        )
      )
    );
  $$,
  'P0001',
  'validation',
  'complete_occurrence rejects missing expected_revision'
);

SELECT throws_ok(
  $$
    SELECT public.complete_occurrence(
      jsonb_build_object(
        'contract_version', 1,
        'operation_id', 'a3000000-0000-4000-8000-000000000003',
        'sync_epoch', '00000000-0000-4000-8000-000000000099',
        'expected_revision', '1',
        'data', jsonb_build_object(
          'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8',
          'observed_at', '2026-10-14T12:00:00Z',
          'observed_timezone', 'UTC'
        )
      )
    );
  $$,
  'P0001',
  'restore_requires_review',
  'complete_occurrence rejects mismatched sync_epoch'
);

SELECT ok(
  (public.create_quest(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'a4000000-0000-4000-8000-000000000004',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', NULL,
      'data', jsonb_build_object(
        'definition_id', 'fda923dc-3ebd-489e-a655-37e04fef3163',
        'schedule_version_id', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'title', 'Regression quest',
        'planning_timezone', 'UTC',
        'anchor_date', '2026-10-14'
      )
    )
  ) ->> 'ok')::boolean,
  'create_quest accepts contract envelope'
);

SELECT ok(
  (public.complete_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'a5000000-0000-4000-8000-000000000005',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '1',
      'data', jsonb_build_object(
        'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8',
        'observed_at', '2026-10-14T12:00:00Z',
        'observed_timezone', 'UTC'
      )
    )
  ) ->> 'ok')::boolean,
  'complete_occurrence advances occurrence revision'
);

SELECT ok(
  (public.undo_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'a6000000-0000-4000-8000-000000000006',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '2',
      'data', jsonb_build_object(
        'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8'
      )
    )
  ) ->> 'ok')::boolean,
  'undo after complete succeeds'
);

SELECT ok(
  (public.complete_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'a7000000-0000-4000-8000-000000000007',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '3',
      'data', jsonb_build_object(
        'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8',
        'observed_at', '2026-10-14T15:00:00Z',
        'observed_timezone', 'UTC'
      )
    )
  ) ->> 'ok')::boolean,
  'complete after undo reactivates reward without duplicate-key failure'
);

SELECT * FROM finish();

ROLLBACK;
