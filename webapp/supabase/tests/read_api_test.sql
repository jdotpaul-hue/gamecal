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
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT sync_epoch
  FROM public.profiles
  WHERE id = '11111111-1111-4111-8111-111111111111'::uuid;
$$;

SELECT plan(8);

SELECT test_support.create_auth_user(
  '11111111-1111-4111-8111-111111111111'::uuid,
  'alice-read@example.com'
);
SELECT test_support.authenticate_as('11111111-1111-4111-8111-111111111111'::uuid);

SELECT throws_ok(
  $$ SELECT count(*) FROM public.profiles $$,
  '42501',
  NULL,
  'authenticated users cannot SELECT application tables directly'
);

SELECT ok(
  (public.ensure_profile(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'c1000000-0000-4000-8000-000000000001',
      'data', jsonb_build_object(
        'display_name', 'Alice',
        'planning_timezone', 'UTC'
      )
    )
  ) ->> 'ok')::boolean,
  'profile bootstrap for read tests'
);

SELECT ok(
  (public.get_profile(
    jsonb_build_object('contract_version', 1, 'data', '{}'::jsonb)
  ) -> 'data' ->> 'bootstrap_needed')::boolean IS FALSE
    AND jsonb_array_length(
      public.get_profile(
        jsonb_build_object('contract_version', 1, 'data', '{}'::jsonb)
      ) -> 'data' -> 'records'
    ) = 1,
  'get_profile returns profile record'
);

SELECT ok(
  (public.create_quest(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'c2000000-0000-4000-8000-000000000002',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'data', jsonb_build_object(
        'definition_id', '84915f93-ef45-4617-a753-0b072ab89ccd',
        'schedule_version_id', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'title', 'Read quest',
        'planning_timezone', 'UTC',
        'anchor_date', '2026-11-01'
      )
    )
  ) ->> 'ok')::boolean,
  'create quest for calendar read'
);

SELECT ok(
  (
    SELECT count(*)::integer
    FROM jsonb_array_elements(
      public.get_calendar_scope(
        jsonb_build_object(
          'contract_version', 1,
          'data', jsonb_build_object(
            'from_date', '2026-11-01',
            'until_date', '2026-11-08',
            'display_timezone', 'UTC',
            'page_size', 50,
            'snapshot_token', NULL,
            'cursor', NULL
          )
        )
      ) -> 'data' -> 'records'
    ) elem
    WHERE elem ->> 'entity' = 'quest_occurrence'
  ) = 1,
  'get_calendar_scope returns occurrence in window'
);

SELECT ok(
  (public.complete_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'c3000000-0000-4000-8000-000000000003',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '1',
      'data', jsonb_build_object(
        'occurrence_id', '0a8f3101-1700-521b-bffe-423311e7b732',
        'observed_at', '2026-11-01T12:00:00Z',
        'observed_timezone', 'UTC'
      )
    )
  ) ->> 'ok')::boolean,
  'complete occurrence for progression read'
);

SELECT is(
  public.get_progression(
    jsonb_build_object('contract_version', 1, 'data', '{}'::jsonb)
  ) -> 'data' -> 'summary' -> 'progression' -> 'record' ->> 'total_xp',
  '20',
  'get_progression reports accepted XP'
);

SELECT ok(
  (public.get_own_operation_result(
    jsonb_build_object(
      'contract_version', 1,
      'data', jsonb_build_object(
        'operation_id', 'c3000000-0000-4000-8000-000000000003'
      )
    )
  ) -> 'data' ->> 'status') = 'accepted'
    AND (
      public.get_own_operation_result(
        jsonb_build_object(
          'contract_version', 1,
          'data', jsonb_build_object(
            'operation_id', 'c3000000-0000-4000-8000-000000000003'
          )
        )
      ) -> 'data' -> 'acknowledgment' ->> 'command_name'
    ) = 'complete_occurrence',
  'get_own_operation_result returns stored receipt'
);

SELECT * FROM finish();

ROLLBACK;
