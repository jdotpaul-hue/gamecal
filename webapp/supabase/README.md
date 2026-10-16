# Disposable local Supabase workspace

Initialized with the pinned Supabase CLI. `project_id` identifies local containers only; there is no linked hosted project or application migration.

From `webapp`, run `pnpm db:start` after a compatible container engine is ready (Docker Desktop, Colima, OrbStack, or equivalent). Keep email verification enabled and use the CLI's local email capture service. Initial allowed origin is `http://localhost:3000`; add exact callback/recovery destinations when those routes exist. Do not bypass verification for tests.

After `pnpm db:start`, copy credentials into an ignored `.env.local`:

```sh
pnpm db:start
pnpm exec supabase status -o env | rg '^NEXT_PUBLIC_'
```

Paste `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` into `.env.local` (see `.env.example`). Legacy anonymous JWT keys remain unsupported.

Apply migrations and prove the foundation slice:

```sh
pnpm exec supabase db reset
pnpm test:db
pnpm db:types
```

The local stack configuration disables unused realtime, Storage, analytics and seeding for this foundation. Enable a service deliberately with its feature/lifecycle tests. The API exposes only `public`; inspect grants/extensions again when adding tables.

Foundation migrations cover profiles, one-off quests (definitions/versions/occurrences), completion rewards, mutation receipts, RLS, and controlled RPCs (`ensure_profile`, `create_quest`, `complete_occurrence`, `undo_occurrence`, `skip_occurrence`, `unskip_occurrence`). pgTAP coverage lives in `supabase/tests/foundation_security_test.sql`. Generate types only after `db reset` succeeds; `pnpm db:types:check` belongs in CI once the stack runs remotely.

Do not run project login/linking, remote pushes, or real email/provider calls for local scaffold verification.
