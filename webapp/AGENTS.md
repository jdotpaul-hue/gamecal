# Webapp contributor guide

Consult the [repository coding guide](../AGENTS.md) and [technical design](../TECHNICAL_DESIGN.md). Run application commands from this folder. The pinned package manifest/lockfile describe the installed stack; planning version candidates are historical.

- Keep domain rules in `src/features/*/domain`, shared validation/transport/storage in `src/lib`, and routes as framework composition. Use feature entry points for cross-feature imports.
- The current request establishes infrastructure and pure helpers only. The root page is an unstyled framework placeholder. Product UI, quests, Auth journeys, queue sending and integrations have separate implementation gates.
- Supabase factories expose only Auth. Do not widen them with `any`, a fabricated database definition or a generic SDK override. After actual local SQL migrations exist, generate `src/types/database.generated.ts`, specialize data clients with it and add per-command request/response schemas.
- `src/lib/local-db` currently persists versioned account metadata only. It is not a working quest cache/outbox or an authentication boundary. Call it only with the verified account identity once Auth is implemented; preserve invalid records for recovery.
- Public environment configuration accepts publishable keys only. Never substitute a secret/service-role key. A legacy anonymous key requires an explicit, tested compatibility decoder before support is claimed.
- `pnpm verify` runs typed lint, type checking (including negative type cases), formatting, unit tests and production build. `pnpm test:e2e` tests that built app. Database scripts intentionally fail until actual migrations/tests/local services exist; never report that as database proof.
- Keep `server-only`/`client-only` markers on their boundaries. The unit-test client marker substitute exists only in Vitest; do not copy it into the application build.
- No remote project is linked. Local Supabase initialization is configuration only. Do not deploy, provide privileged credentials, or execute remote SQL as part of scaffold cleanup.
