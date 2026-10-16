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

GRANT EXECUTE ON FUNCTION test_support.create_auth_user(uuid, text) TO PUBLIC;

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

GRANT EXECUTE ON FUNCTION test_support.authenticate_as(uuid) TO PUBLIC;

CREATE OR REPLACE FUNCTION test_support.clear_auth()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claim.role', 'anon', true);
  PERFORM set_config('role', 'anon', true);
END;
$$;

GRANT EXECUTE ON FUNCTION test_support.clear_auth() TO PUBLIC;

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

GRANT EXECUTE ON FUNCTION test_support.authenticate_as_claims(uuid) TO PUBLIC;

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

GRANT EXECUTE ON FUNCTION test_support.alice_sync_epoch() TO PUBLIC;

SELECT plan(18);

SELECT has_extension('uuid-ossp', 'uuid-ossp extension is available');

SELECT is(
  app_private.derive_occurrence_id(
    'fda923dc-3ebd-489e-a655-37e04fef3163'::uuid,
    '2026-10-14'::date
  ),
  '55a014c9-4d95-5e15-9d2b-aac1953f81b8'::uuid,
  'occurrence UUID matches shared vector'
);

SELECT test_support.create_auth_user(
  '11111111-1111-4111-8111-111111111111'::uuid,
  'alice@example.com'
);
SELECT test_support.create_auth_user(
  '22222222-2222-4222-8222-222222222222'::uuid,
  'bob@example.com'
);

SELECT test_support.authenticate_as('11111111-1111-4111-8111-111111111111'::uuid);

SELECT ok(
  (public.ensure_profile(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'data', jsonb_build_object(
        'display_name', 'Alice',
        'planning_timezone', 'UTC'
      )
    )
  ) ->> 'ok')::boolean,
  'ensure_profile succeeds for user A'
);

SELECT ok(
  (public.create_quest(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'data', jsonb_build_object(
        'definition_id', 'fda923dc-3ebd-489e-a655-37e04fef3163',
        'schedule_version_id', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'title', 'Write migration tests',
        'planning_timezone', 'UTC',
        'anchor_date', '2026-10-14'
      )
    )
  ) ->> 'ok')::boolean,
  'create_quest materializes one-off occurrence'
);

SELECT test_support.authenticate_as('22222222-2222-4222-8222-222222222222'::uuid);

SELECT is(
  (
    SELECT count(*)::integer
    FROM public.quest_occurrences
    WHERE definition_id = 'fda923dc-3ebd-489e-a655-37e04fef3163'::uuid
  ),
  0,
  'user B cannot read user A occurrences through RLS'
);

SELECT test_support.clear_auth();

SELECT throws_ok(
  $$ SELECT count(*) FROM public.profiles $$,
  '42501',
  NULL,
  'anonymous role cannot read profiles'
);

SELECT test_support.authenticate_as('11111111-1111-4111-8111-111111111111'::uuid);

SELECT throws_ok(
  $$
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
      timing_kind
    )
    VALUES (
      extensions.gen_random_uuid(),
      '11111111-1111-4111-8111-111111111111',
      'fda923dc-3ebd-489e-a655-37e04fef3163',
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      '2026-10-14',
      '2026-10-14',
      'quest',
      'Blocked',
      '',
      'personal',
      'side',
      false,
      'untimed'
    );
  $$,
  '42501',
  NULL,
  'direct occurrence insert is denied for authenticated users'
);

SELECT ok(
  (public.complete_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '1',
      'data', jsonb_build_object(
        'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8',
        'observed_at', '2026-10-14T12:00:00Z',
        'observed_timezone', 'UTC'
      )
    )
  ) ->> 'ok')::boolean,
  'complete_occurrence awards quest reward'
);

SELECT is(
  (
    SELECT count(*)::integer
    FROM public.completion_rewards
    WHERE occurrence_id = '55a014c9-4d95-5e15-9d2b-aac1953f81b8'::uuid
      AND reversed_at IS NULL
  ),
  1,
  'exactly one active reward exists after completion'
);

SELECT ok(
  (public.complete_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '1',
      'data', jsonb_build_object(
        'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8',
        'observed_at', '2026-10-14T12:00:00Z',
        'observed_timezone', 'UTC'
      )
    )
  ) -> 'acknowledgment' ->> 'replayed')::boolean,
  'identical completion operation replays without duplicating reward'
);

SELECT throws_ok(
  $$
    SELECT public.complete_occurrence(
      jsonb_build_object(
        'contract_version', 1,
        'operation_id', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        'sync_epoch', test_support.alice_sync_epoch()::text,
        'expected_revision', '2',
        'data', jsonb_build_object(
          'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8',
          'observed_at', '2026-10-14T12:00:00Z',
          'observed_timezone', 'UTC'
        )
      )
    );
  $$,
  'P0001',
  'invalid_transition',
  'second completion with a new operation id is rejected'
);

SELECT throws_ok(
  $$
    SELECT public.complete_occurrence(
      jsonb_build_object(
        'contract_version', 1,
        'operation_id', 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        'sync_epoch', test_support.alice_sync_epoch()::text,
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
  'revision_conflict',
  'stale revision completion rolls back without leaving a receipt'
);

SELECT is(
  (
    SELECT revision::text
    FROM public.quest_occurrences
    WHERE id = '55a014c9-4d95-5e15-9d2b-aac1953f81b8'::uuid
  ),
  '2',
  'stale revision completion leaves occurrence revision unchanged'
);

SELECT ok(
  (public.undo_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', '10101010-1010-4101-8101-101010101010',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '2',
      'data', jsonb_build_object(
        'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8'
      )
    )
  ) ->> 'ok')::boolean,
  'undo_occurrence returns completed quest to pending'
);

SELECT isnt(
  (
    SELECT reversed_at
    FROM public.completion_rewards
    WHERE occurrence_id = '55a014c9-4d95-5e15-9d2b-aac1953f81b8'::uuid
  ),
  NULL,
  'undo reverses the active reward'
);

SELECT ok(
  (public.skip_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', '20202020-2020-4202-8202-202020202020',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '3',
      'data', jsonb_build_object(
        'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8'
      )
    )
  ) ->> 'ok')::boolean,
  'skip_occurrence marks pending quest as skipped'
);

SELECT ok(
  (public.unskip_occurrence(
    jsonb_build_object(
      'contract_version', 1,
      'operation_id', '30303030-3030-4303-8303-303030303030',
      'sync_epoch', test_support.alice_sync_epoch()::text,
      'expected_revision', '4',
      'data', jsonb_build_object(
        'occurrence_id', '55a014c9-4d95-5e15-9d2b-aac1953f81b8'
      )
    )
  ) ->> 'ok')::boolean,
  'unskip_occurrence restores skipped quest to pending'
);

SELECT test_support.authenticate_as_claims('11111111-1111-4111-8111-111111111111'::uuid);

SELECT is(
  (
    SELECT elem -> 'record' ->> 'revision'
    FROM jsonb_array_elements(
      public.create_quest(
        jsonb_build_object(
          'contract_version', 1,
          'operation_id', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          'sync_epoch', test_support.alice_sync_epoch()::text,
          'data', jsonb_build_object(
            'definition_id', 'fda923dc-3ebd-489e-a655-37e04fef3163',
            'schedule_version_id', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            'title', 'Write migration tests',
            'planning_timezone', 'UTC',
            'anchor_date', '2026-10-14'
          )
        )
      ) -> 'canonical' -> 'records'
    ) AS elem
    WHERE elem ->> 'entity' = 'quest_occurrence'
  ),
  '5',
  'create_quest replay returns current occurrence revision'
);

SELECT * FROM finish();

ROLLBACK;
