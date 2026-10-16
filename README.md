# Gamecal

A planned web-first gamified calendar with personal/business itineraries, supportive progression and a small evolving fantasy room.

**Current state:** The [web app foundation](webapp/README.md) runs in `webapp/`: Next.js/React, strict TypeScript, domain helpers, Dexie account metadata, local Supabase migrations (foundation schema/RLS/RPCs), pgTAP database tests, and a CI workflow. Product UI/UX, Auth journeys, typed data clients, and the Dexie sync queue are not implemented yet. Local Supabase is disposable via Docker; no hosted Supabase or Vercel project is linked.

## Get started locally

All application commands run from **`webapp/`**. Full steps (prerequisites, Docker, environment files, verification, and copying the repo to another machine) are in [Development setup](DEVELOPMENT_SETUP.md#getting-started-on-a-new-machine).

**Short path after prerequisites are installed:**

```sh
cd webapp
corepack enable
corepack prepare pnpm@11.25.0 --activate
nvm use    # reads .nvmrc → Node 24.22.0
pnpm install --frozen-lockfile

# Optional but required for database work and Auth env validation:
# Start Docker Desktop, then:
pnpm db:start
pnpm exec supabase status -o env   # copy NEXT_PUBLIC_* into .env.local (see .env.example)

pnpm verify        # lint, types, unit tests, production build
pnpm test:db       # pgTAP RLS/command tests (needs db:start)
pnpm db:types      # writes src/types/database.generated.ts from local schema
pnpm dev           # http://localhost:3000
```

Do not copy `node_modules`, `.next`, or local Docker volumes when moving the tree; reinstall dependencies and run `pnpm db:start` on the new machine. `.env.local` is machine-specific and is not committed—recreate it from `supabase status` after the local stack starts.

## Document ownership

| Question | Authoritative document |
| --- | --- |
| What are we building and what must launch? | [Product plan](PRODUCT_PLAN.md) |
| How do we apply CUPID and organize modules? | [Software design principles](ARCHITECTURE_PRINCIPLES.md) |
| Who owns each fact, and how is it modeled? | [Data architecture](DATA_ARCHITECTURE.md) |
| What stack, boundaries and delivery order do we use? | [Technical design](TECHNICAL_DESIGN.md) |
| What must be ready for the first local build? | [Development setup and readiness](DEVELOPMENT_SETUP.md) |
| What coding/review baseline should a contributor consult? | [Agent guide](AGENTS.md) |
| What are the exact SQL fields, keys and constraints? | [Database schema plan](DATABASE_SCHEMA_PLAN.md) |
| Who may read/write/execute each object? | [RLS and grants](RLS_PLAN.md) |
| What are the wire shapes, errors and command contracts? | [API contracts](API_CONTRACTS.md) |
| How are local intentions, cloud state and conflicts reconciled? | [Local sync](LOCAL_SYNC_DESIGN.md) |
| How do deletion, budgets, cache cleanup and backups work? | [Operations](OPERATIONS_PLAN.md) |
| What does a first-time user see and how is it verified? | [First-session flow](FIRST_SESSION_PLAN.md) |
| How do split views, mascots and reviewed planning work? | [Workspace UX](UI_UX_PLAN.md) |
| What supports the product hypotheses and what remains unverified? | [Research review](RESEARCH_REVIEW.md) |
| Which review findings are resolved or still open? | [Review register](DOCS_REVIEW.md) |

Feature plans: [Itineraries](ITINERARY_PLAN.md), [WeatherAPI](WEATHER_PLAN.md), [optional Pexels covers](PHOTO_PLAN.md), [later creator/manga pilot](CREATOR_PLAN.md), and [parked radio](RADIO_PLAN.md).

Keep contract details in their owning document and link summaries to it. Explicit user decisions take precedence; resolve conflicts by updating stale summaries rather than maintaining two competing versions of a rule.

The [development checklist](DEVELOPMENT_SETUP.md) records prerequisites, local bootstrap, and remaining gates. Run application commands from `webapp`; its `package.json` and lockfile supersede historical dependency candidates. Next: wire generated database types and the durable local queue, then the profile → one-off quest → complete/undo → reconciliation slice with UI. Remote Supabase and Vercel remain a separate release gate.
