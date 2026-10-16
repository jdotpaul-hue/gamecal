# Gamecal web app foundation

Next.js App Router, React, strict TypeScript, Tailwind CSS, Zod, Supabase Auth adapters and a Dexie persistence boundary. This scaffold has an unstyled root page and `/api/health`; product UI/UX has not started.

The product/architecture documents remain in the [repository root](../README.md). Vercel's future application root is this `webapp` folder; no hosting or remote project has been configured.

## Run locally

**Authoritative bootstrap** (new machine, zip copy, prerequisites, what not to copy): [Development setup — Getting started on a new machine](../DEVELOPMENT_SETUP.md#getting-started-on-a-new-machine).

Select Node `24.22.0` (`nvm use` reads `.nvmrc`) and pnpm `11.25.0` (`corepack prepare pnpm@11.25.0 --activate`), then from this directory:

```sh
pnpm install --frozen-lockfile
pnpm verify    # recommended first run on a new machine
pnpm dev
```

The placeholder starts at `http://localhost:3000`. Builds succeed without `.env.local`; Supabase public env is validated when an Auth factory runs. There is no automatic Auth call, account creation, or `.env.local` generation on startup.

**Local database (Docker required):** see [supabase/README.md](supabase/README.md). After `pnpm db:start`, create `.env.local` from `pnpm exec supabase status -o env`, then `pnpm test:db` and `pnpm db:types`.

## Structure and boundaries

```text
src/
  app/                         minimal framework shell and health route
  features/
    calendar/domain/           validated date/time concepts and explicit DST rules
    quests/domain/             permanent occurrence UUID derivation
    progression/domain/        display calculations from accepted XP
  lib/
    env/                       public config parsing and server-only boundary
    local-db/                  account-partitioned, versioned IndexedDB metadata
    supabase/                  browser/server Auth factories and response decoding
    validation/                branded IDs and exact decimal revisions/counters
    result.ts                  discriminated result type and exhaustive failure helper
scripts/database.ts            local-only type generation/drift/database-test guards
supabase/                      local config, SQL migrations, pgTAP tests
tests/e2e/                     production-server smoke test
tests/types/                   compile-time negative boundary checks
```

Feature entry points expose useful operations; pure domain files cannot import React, Next.js, Supabase, Dexie or environment adapters. Future Account, Itinerary, Sync, Weather and Room modules should be added when they contain implemented behavior. Avoid empty service classes, generic repositories, a second backend or a second sync system.

The time helpers implement the documented routine/appointment DST distinction and all-day deadline semantics using the Temporal polyfill. They do not implement recurrence generation or server parity. Progression functions only interpret accepted totals and cannot award XP.

## Type safety and verification

Compiler options include strict mode, checked indexed access, exact optional properties and explicit return/fallthrough/catch checks. Type-aware lint rejects unsafe values, explicit `any`, non-null assertions and unhandled promises. Maintained tests/scripts are type-checked too; `skipLibCheck` is limited to dependency declaration checking. Negative cases are confined to dedicated type tests.

Zod validates values at runtime. JSON/JSONB RPCs still need feature-specific response schemas when implemented; the decoder here supplies failure semantics without inventing endpoint shapes. Decoder failure never proves a write failed or authorizes queue removal. SQL/RLS remains an independent required layer.

| Command                                 | Current purpose                                                             |
| --------------------------------------- | --------------------------------------------------------------------------- |
| `pnpm dev`                              | Local development server                                                    |
| `pnpm build` / `pnpm start`             | Build / serve production output                                             |
| `pnpm lint` / `pnpm typecheck`          | Type-aware ESLint / compiler and negative type checks                       |
| `pnpm format:check` / `pnpm format`     | Check / apply formatting                                                    |
| `pnpm test`                             | Deterministic domain/boundary/IndexedDB tests                               |
| `pnpm verify`                           | Lint, types, formatting, unit tests and production build                    |
| `pnpm test:e2e`                         | Smoke test against production output; build first                           |
| `pnpm db:start` / `pnpm db:stop`        | Start / stop the disposable local stack; requires Docker-compatible runtime |
| `pnpm db:types` / `pnpm db:types:check` | Generate / compare types after real local migrations                        |
| `pnpm test:db`                          | Run real SQL tests after migrations/tests exist                             |

Install the Playwright Chromium runtime once with `pnpm exec playwright install chromium` before browser checks. The root GitHub Actions workflow installs exact locked dependencies, runs verification and the smoke test. It needs no application secrets; it has not been executed on a remote runner.

TypeScript `6.0.3` is pinned because the installed typed linter supports versions below `6.1`. ESLint `9.39.5` satisfies the Next.js plugin peers; npm marks that line deprecated. Revisit the pair when those plugins support the current ESLint major; do not override peer constraints or weaken checks merely to select the newest versions. Node/pnpm and all direct dependencies are pinned; build-script execution is allowlisted in `pnpm-workspace.yaml`.

## Supabase and local data status

Local SQL migrations implement the foundation slice (profiles, one-off quests, occurrences, rewards, receipts, RLS, and controlled RPCs) with pgTAP tests in `supabase/tests/`. A compatible container runtime is still required to run `pnpm db:start`, `supabase db reset`, `pnpm test:db`, and `pnpm db:types`. No remote project, buckets, or hosted connection exist yet. Callback/session-refresh routes are not implemented; add/test their exact redirect allowlist in the Auth slice.

Copy `.env.example` to an ignored `.env.local` only when local services are ready. Supply the actual local URL and `sb_publishable_...` public key. Legacy anonymous JWTs are deliberately rejected until a tested decoder is added. No privileged key is required by this scaffold.

Auth factories expose `{ auth, client }` with generated `Database` types. Run `pnpm db:types` after local migrations to refresh `src/types/database.generated.ts` (prettier-ignored; regenerate rather than hand-edit). Typed read/command helpers live in `src/lib/supabase/rpc.ts` with Zod contracts under `src/lib/api/contracts/`.

The account database exposes initialization and close operations over `sync_meta` only. It validates persisted identity/version before trusting metadata and leaves unsupported records untouched. Initialization rejects on storage/transaction failure; callers must retain input and handle that failure. Confirmed quest records, a durable outbox, sender leases, lifecycle locking, cache cleanup and reconciliation are not implemented. Local partitioning is not encryption or authentication.

## Next implementation gate

Make the local container runtime available, then implement local SQL/RLS and the verified account/profile foundations with generated types. Follow with the one-off quest -> complete/undo -> interrupted-request recovery slice in [the first-session plan](../FIRST_SESSION_PLAN.md). Add product screens only when requested. Optional 3D, Motion, shadcn/ui, provider integrations and publishing dependencies are not installed yet.

## Verification recorded on 16 October 2026

- Typed lint, compiler/negative type cases, formatting, 53 unit/boundary tests across seven files and production build passed locally.
- One Chromium smoke test passed against the built production server, checking the root shell and non-sensitive/no-store health response.
- Temporary invalid-code probes confirmed compiler rejection of unsafe indexed access and imprecise optional fields, plus lint rejection of explicit/propagated `any` and unhandled promises. Those probes were removed.
- The dependency graph has no peer conflicts. Local TOML and documentation links/fences/JSON examples were checked.
- `pnpm db:types` correctly fails on missing application migrations; database/RLS and integrated Auth/sync behavior were not tested. The GitHub workflow has not run remotely.

Verification used Node `24.22.0` and pinned pnpm from temporary task runtimes. System Node remains unchanged; select the `.nvmrc` version before running the app yourself.
