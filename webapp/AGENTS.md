# Webapp contributor guide

Consult the [repository coding guide](../AGENTS.md), [technical design](../TECHNICAL_DESIGN.md) and [personal AI proposal](../PERSONAL_AI_PLAN.md). Run application commands from this folder. The pinned package manifest/lockfile describe the installed stack; planning version candidates are historical.

- Keep domain rules in `src/features/*/domain`, shared validation/transport/storage in `src/lib`, and routes as framework composition. Use feature entry points for cross-feature imports.
- The root page is an unstyled framework placeholder. Local calendar SQL/RLS/read and command RPCs exist; product UI, complete Auth journeys, queue sending and assistant/voice/People integrations have separate implementation gates.
- Supabase factories expose Auth and generated-`Database` clients. Do not widen them with `any`, a fabricated database definition or a generic SDK override. Regenerate `src/types/database.generated.ts` after local migrations; use per-command request/response schemas and entity-specific DTOs. Broad JSON types alone do not validate domain contracts.
- `src/lib/local-db` currently persists versioned account metadata only. It is not a working quest cache/outbox or an authentication boundary. Call it only with the verified account identity once Auth is implemented; preserve invalid records for recovery.
- Public environment configuration accepts publishable keys only. Never substitute a secret/service-role key. A legacy anonymous key requires an explicit, tested compatibility decoder before support is claimed.
- `pnpm verify` runs typed lint, type checking (including negative type cases), formatting, unit tests and production build. `pnpm test:e2e` tests that built app. `pnpm test:db` and `pnpm db:types:check` verify the running local database; keep type drift checks independent of generation. Existing tests do not cover every Auth/sync/product journey.
- Keep `server-only`/`client-only` markers on their boundaries. The unit-test client marker substitute exists only in Vitest; do not copy it into the application build.
- No remote project is linked. Local Supabase migrations and tests run through Docker. Do not deploy, provide privileged credentials, or execute remote SQL as part of scaffold cleanup.
