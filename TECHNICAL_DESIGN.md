# Gamecal Technical Design

**Updated:** 16 October 2026

**Status:** The [webapp foundation](webapp/README.md) implements framework configuration, strict types/lint, pure helpers, generated/typed clients and a tested local SQL/RLS/read-and-command foundation. Product routes/UX, complete Auth journeys, durable sync and assistant/voice/People features remain intended work. [The review register](DOCS_REVIEW.md#7-review-of-commits-35b6a5b-and-6a160ed) records current correctness gaps. Application paths are relative to `webapp/`.

**Latest assistant direction:** [PERSONAL_AI_PLAN.md](PERSONAL_AI_PLAN.md) records personal AI as the main product, Calendar/People tools, user-controlled memory and a voice-led home proposal. Its architecture reuses this modular monolith and canonical calendar path. The older optional text-planner/voice exclusion is not the new AI-first pilot scope. Provider/model, voice budgets, memory/social SQL models and the exact pilot contract remain to be selected/implemented.

**Personalization boundary:** [PERSONALIZATION_PLAN.md](PERSONALIZATION_PLAN.md) owns the proposed charter, typed rules, teaching, permissions and template lifecycle. Compile bounded context from accepted versioned values; enforce constraints/permissions independently at tool execution. Share one small rule evaluator across suggestions and saves. Exact settings/memory SQL and API mapping remain to be designed before migrations; this adds no general rule engine, background worker, vector store or agent framework.

**Knowledge boundary:** [SECOND_BRAIN_PLAN.md](SECOND_BRAIN_PLAN.md) proposes Markdown bodies in owner-scoped canonical note records, Dexie local intentions/snapshots and derived link/search indexes. Preserve typed Calendar/People/settings authority; do not use frontmatter as a command surface. Save source text before optional organization/indexing, version all derived output and invalidate it on correction/forgetting. Prefer existing PostgreSQL search and optional pgvector after evaluation; no graph database or second vector service is selected. Direct folder access and background briefing are separate lifecycle designs.

**Organization workflow:** Eligible captures trigger automatic bounded extraction, owner-scoped candidate lookup, validation and persistence of generated summaries/topics/links. No manual linking or routine per-item approval is required. Keep derived output separate from source/user-authored content, respect unlink/correction overrides, use idempotent source/revision/processor identities, and clarify only consequential uncertainty. This foreground product pipeline does not imply an always-on runner or autonomous calendar writes.

**Memory engine candidate:** [The Mem0 assessment](SECOND_BRAIN_PLAN.md#11-mem0-evaluation-optional-memory-engine) recommends an optional bounded comparison before building a broad custom memory engine. Mem0 is not selected or required. Keep canonical account/domain records in Supabase and any memory-engine output derived/versioned behind an authenticated server boundary. Managed and open-source variants have different integration/operating considerations; validate correction/forgetting, source citations, tenancy, retries and costs before adoption. No package, store or service is added here.

**Related documents:** [Product plan](PRODUCT_PLAN.md) · [Agent coding guide](AGENTS.md)

**Design baseline:** [ARCHITECTURE_PRINCIPLES.md](ARCHITECTURE_PRINCIPLES.md) applies CUPID through domain modules, explicit dependencies and predictable operations. [DATA_ARCHITECTURE.md](DATA_ARCHITECTURE.md) defines fact ownership, normalization/snapshots, consistency and lifecycle. [README.md](README.md) identifies contract ownership. These refine the existing stack and thirteen-table pilot plan without adding services or implementation.

**Database planning baseline:** [DATABASE_SCHEMA_PLAN.md](DATABASE_SCHEMA_PLAN.md) defines nine owner-readable tables, two private sync tables and two private operating tables by pilot readiness, column/relationship contracts, account snapshot versioning, and later creator migrations. [RLS_PLAN.md](RLS_PLAN.md) defines grants, owner policies, invoker RPC wrappers/private restricted implementations, public publishing boundaries, and planned tests. Local migrations implement a foundation subset; full pilot readiness and remote deployment still require separate proof. This review/pivot pass changes documentation only.

**API planning baseline:** [API_CONTRACTS.md](API_CONTRACTS.md) defines named RPC/request/response envelopes, decimal-string bigint revisions, acknowledgment versus current canonical state, bounded/versioned reads, itinerary aggregate revisions, normalized errors, provider routes and review-only planning proposals. Local foundation RPCs and initial runtime schemas exist; broader contracts and integrated acceptance remain planned.

**First-session baseline:** [FIRST_SESSION_PLAN.md](FIRST_SESSION_PLAN.md) defines the account/setup and one-off quest/reward/undo journey with truthful loading, storage, sync, conflict and auth states. FS-01–FS-15 are the foundational UX/integration gates; FS-16 is the subsequent room-milestone fixture. These are planned checks, not passing tests or a replacement for full pilot readiness.

**Research decisions:** [RESEARCH_REVIEW.md](RESEARCH_REVIEW.md) explains the proposed appointment/quest distinction, editable time blocks, weekly consistency, and supportive reflection. These are user-benefit design hypotheses, not claims that XP measures real-world skill.

**Local/cloud contract:** [LOCAL_SYNC_DESIGN.md](LOCAL_SYNC_DESIGN.md) defines account-scoped IndexedDB storage, the durable command queue, retries, reconciliation, and lifecycle behavior. It supersedes the former online-only write path.

**Operating contract:** [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md) settles keep-work sign-out, cache cleanup, two-step deletion/retry status, shared PostgreSQL budgets, proposed Vercel/Supabase pilot hosting, backup/restore epochs and required proof. These requirements are not yet implemented.

**Itinerary contract:** [ITINERARY_PLAN.md](ITINERARY_PLAN.md) extends the same calendar to leisure/day trips and business/events, using shared occurrences and explicit endpoint timezones. It defines the manual MVP, privacy, complete-trip cache, and later offline-reopening gate.

**Weather contract:** [WEATHER_PLAN.md](WEATHER_PLAN.md) defines the requested WeatherAPI integration, supported-date handling, transient caching, location selection, secret boundaries, attribution, and usage control.

**Photo experiment:** [PHOTO_PLAN.md](PHOTO_PLAN.md) defines optional Pexels cover suggestions, public-context query rules, attribution, stable metadata-only selections, and remote-image fallback. It is separate from the required weather integration and core MVP gates.

**Creator extension:** [CREATOR_PLAN.md](CREATOR_PLAN.md) defines the requested Creator Studio, hosted/external chapters, weekly release slots, private artwork storage, server publication, and dedicated reader UX. It is a separately gated module after the calendar MVP, using the same Next.js/Supabase stack.

**Parked radio extension:** [RADIO_PLAN.md](RADIO_PLAN.md) records an unselected RapidAPI directory candidate and the proposed browser-audio path. When activated, use server-only bounded directory requests and one user-started native audio player with direct broadcaster streams. Audio bytes/playback commands never enter Supabase Storage or the calendar outbox; no packages, schemas, keys, or MVP dependencies are added while parked.

**Workspace/assistant contract:** [UI_UX_PLAN.md](UI_UX_PLAN.md) defines the initial Calendar-left/AI-right split, focus modes, twin hidden-panel mascots, and review-only planning proposals. AI is an online capability independent of the calendar queue; provider/model selection remains open.

## 1. Goal and boundaries

Build a mobile-first web app using Next.js App Router, React, TypeScript, Tailwind CSS, Dexie/IndexedDB, and Supabase Auth/PostgreSQL. A user signs in online, schedules quests through local saves, syncs in the background while the app is open, and sees confirmed XP and a small illustrated fantasy room improve.

Supabase holds canonical accepted account data and progression. Dexie holds confirmed snapshots and durable pending operations; their projection drives the calendar. Include interactive UI motion and one optional 3D prop. Launch with queued writes during connection interruptions but without guaranteed offline startup, service workers, closed-app sync, push reminders, realtime subscriptions, a full 3D world, or multiplayer. These boundaries follow the [initial product scope](PRODUCT_PLAN.md#5-release-scope).

This design adopts Next.js for implementation. Check supported stable versions at bootstrap, pin dependencies in one lockfile, and document the runtime version. Do not treat documentation examples as permission to install unrelated tooling.

The creator extension adds Supabase Storage and Cron when its pilot is implemented. This does not change the calendar's foreground-only queue lifecycle: a confirmed publication is a backend job, while a pending local draft is not an accepted release. Keep public reading and private planning independently usable.

## 2. Stack and dependency policy

| Concern | Baseline |
| --- | --- |
| Application | Next.js App Router, React, strict TypeScript |
| UI | Tailwind CSS and CSS design tokens; semantic HTML |
| UI controls | Selected shadcn/ui components with Radix primitives; do not mix primitive families for the same controls |
| UI motion | `motion` imported through `motion/react`; CSS for simple transitions |
| Optional 3D | `three`, `@react-three/fiber`, and selected `@react-three/drei` helpers |
| Database | Supabase PostgreSQL with checked-in SQL migrations |
| Local data | IndexedDB through `dexie` and `dexie-react-hooks`; versioned local schema |
| Synchronization | One application-owned durable outbox and authenticated Supabase command/snapshot path |
| Weather | WeatherAPI.com through authenticated Next.js Route Handlers, native fetch, validated normalization, and transient caches |
| Optional itinerary covers | Pexels photo API through server search and normalized CDN URL/credit metadata |
| Authentication | Supabase Auth; email/password, verification, and recovery initially |
| Session integration | `@supabase/supabase-js` and `@supabase/ssr` |
| Input/output validation | Zod schemas at untrusted boundaries, with inferred DTO types and explicit domain mappings |
| Unit/component tests | Vitest; React Testing Library for behavior that needs a DOM |
| Browser tests | Playwright for the critical user journey |
| Database tests | Supabase local stack and SQL integration checks; pgTAP where useful |
| Formatting/linting | ESLint and Prettier, configured once at bootstrap |
| Deployment | Managed Next.js hosting; Vercel is the proposed default |

Start from the [Supabase Next.js quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs) and adapt the starter to the repo. Do not overwrite these documents during scaffolding. Add dependencies only when an implemented requirement needs them; use direct Supabase clients rather than adding an ORM, separate API framework, or global state library by default.

### End-to-end type safety

The goal is checked application code plus validated external/persisted boundaries. Strict TypeScript is one layer; runtime schemas, canonical SQL constraints and Auth/RLS establish different properties. The [agent guide](AGENTS.md#typescript-and-validation) owns coding/compiler/lint rules and [development setup](DEVELOPMENT_SETUP.md#8-type-safety-bootstrap-gate) owns their bootstrap/CI gate. Compiler and typed-lint enforcement exist in the scaffold; full feature/SQL contracts are not implemented yet.

| Boundary | Required proof before trusted use |
| --- | --- |
| Form, URL and environment values | Zod parsing with bounded fields and explicit missing/null semantics; separate public/server environment schemas |
| Feature command -> local enqueue | Schema-derived command/payload union and typed mapper; valid IDs/time/revisions; atomic durable write before local success |
| Supabase client and SQL rows | Generated `Database` type on browser/server/test clients; explicit row-to-domain mappings; generated-type drift check after migrations |
| RPC requests, responses and JSONB metadata | Per-command versioned Zod schemas for requests and success envelopes/tagged canonical records; SDK/SQL errors normalized separately; validated counters remain decimal strings |
| IndexedDB hydration | Typed Dexie tables plus version-specific decoding at the persistence ingress; invalid/unsupported rows cannot enter trusted projections or sending; retain pending evidence for recovery |
| Weather, photos and model output | Bounded provider-specific response schemas and normalized feature DTOs; model proposals also require user review and normal save |
| Application/UI state | Explicit domain types and exhaustive discriminated unions for async, sync, conflict and layout states; no unchecked transport objects in components |

The [Supabase type generator](https://supabase.com/docs/guides/api/rest/generating-types) supplies SQL-facing definitions. Our RPCs deliberately return JSON envelopes, so a generated broad `Json` type does not describe each command's complete response contract. A transport adapter takes the raw result as `unknown`, validates the expected command/version/record union and then maps it into domain data. Type assertions, SDK generic overrides and typed Dexie table declarations cannot replace that validation.

Keep runtime schemas with their owning feature/adapter and infer their TypeScript DTOs using [Zod's input/output inference](https://zod.dev/basics). Validate a raw request before enqueue/freeze; validate server response fields before acknowledging/removing queued work or updating confirmed caches. An invalid or unsupported response is a protocol/reconciliation failure, not proof of rejection or acceptance: retain the original command and use the established receipt/retry/recovery path. Never discard work to make a decoder succeed.

SQL independently validates requests/ownership and enforces transitions, constraints and reward transactions. Browser schemas do not run inside PostgreSQL; meaningful contract fixtures prove agreement rather than claiming one TypeScript schema generates or guarantees SQL behavior. Preserve the schema, RPC envelope and migration authority already defined; no ORM, new transport framework or duplicate schema registry is required.

## 3. Application structure

Suggested structure; create directories when they contain real code, not as empty scaffolding:

```text
src/
  app/
    (public)/                 landing page
    (auth)/                   sign-in, verification, recovery
    (app)/                    protected Today, Calendar, Room, Review, Settings
    auth/                     required auth callback handlers
    api/                      weather search/forecast; export/deletion when HTTP endpoints are needed
    layout.tsx
    globals.css
  features/
    quests/                   quest components, validation, queries, commands
    calendar/                 scheduling rules, date operations, agenda components
    progression/              level calculations and milestone presentation
    room/                     illustrated room and reveal behavior
    account/                  profile, export, deletion operations
    itineraries/              trip grouping, metadata, timeline and print view
    weather/                  normalized types, location picker, forecast cards
    imagery/                  optional cover selection, picker and attribution
  components/ui/              genuinely shared controls
  lib/
    supabase/                 browser/server clients and session integration
    local-db/                 account-scoped Dexie schema and projection queries
    sync/                     sender, receipts, dependencies, reconciliation
    weatherapi/               server-only provider requests, validation and cache
    pexels/                   optional server-only photo requests and normalization
    env/                      separate public and server environment validation
  types/database.ts           generated Supabase database types
supabase/
  migrations/                 ordered schema, grants, policies, functions
  tests/                     database behavior and isolation checks
tests/e2e/                   cross-feature browser flows
public/room/                 optimized room artwork
```

Route files compose features and handle navigation; they do not contain XP or recurrence algorithms. Feature modules own their UI and application operations. Share components and functions when reuse or a clear responsibility warrants extraction. Avoid generic repository/service hierarchies.

Use a modular monolith: one Next.js application with clear Planning, Progression, Itinerary, Account, Sync, Integration and Operations boundaries. Keep related code near its feature. Calendar navigation and quest operations collaborate within Planning, with pure shared timing rules in the calendar feature. Provider adapters normalize data before features consume it; room/mascot UI consumes accepted state.

Pure rule modules depend on explicit values/date helpers; application operations coordinate validation and local enqueue; concrete adapters own Dexie, RPC and provider I/O. Canonical SQL retains final authority for ownership, transitions and reward invariants. Completion plus reward is one complete purpose and one transaction. Use the CUPID review questions rather than adding a class/service layer per table.

## 4. Rendering, reads, and state

- Use Server Components for layouts, authenticated bootstrap, and privileged workflows. Calendar data renders from a client-side reactive local read model. Keep IndexedDB access browser-only and the client boundary scoped to the interactive app; follow [Next.js component guidance](https://nextjs.org/docs/app/getting-started/server-and-client-components).
- Establish a Supabase browser client and a per-request server client using the documented SSR cookie integration. Protect privileged modules with `server-only`.
- Keep drafts, selected dates, modal state, and pending requests in component state. Put navigable calendar dates in validated URL search parameters.
- Read active calendar data locally; the sync module fetches bounded owner-scoped snapshots/coverage using the authenticated user's client so RLS applies. Never use a privileged key for normal reads or treat uncached data as an empty schedule.
- Persist commands before UI success, drain the durable queue in dependency order, and refresh on authenticated startup, reconnect, focus/navigation, and conservatively while visible. Coalesce refreshes; no realtime subscription or closed-app sync in the MVP.
- Never cache private rows in shared/public caches. Any later cache must include user identity and an explicit invalidation policy.
- Immediate checkmark feedback confirms a durable local completion with pending-sync status. XP and room unlock feedback waits for server acceptance and is suppressed if later queued actions supersede it.
- On connection loss, continue valid cached-calendar operations through the durable queue. Local write failure preserves drafts and reports failure. Cloud conflicts/auth failures preserve recoverable pending work and show the correct sync state.

## 5. Authentication and trust boundaries

Retain the product plan's proposed email/password, email verification and recovery as the single first method. Setup confirms the valid browser-suggested planning zone, accepts the profile bootstrap online, and skips already completed setup on return. Verify local/hosted confirmation configuration, callbacks and actual email-delivery capability before pilot use. The first-session plan defines safe resend/expired-link/session/error states; do not implement a separate credential API or disable verification merely to pass a test.

Follow the [Supabase SSR auth guide](https://supabase.com/docs/guides/auth/server-side/creating-a-client?queryGroups=framework&framework=nextjs) for the installed versions. Verify server identity using the supported verified-user/claims mechanism; do not trust an unverified session object, client-supplied user ID, or route protection alone.

- Public routes contain no private user data. Protected routes require a verified session; each server mutation independently verifies identity.
- Every exposed user table has RLS and least-privilege grants. Ownership policies apply to reads and any permitted writes. See [Supabase RLS guidance](https://supabase.com/docs/guides/database/postgres/row-level-security).
- Browser access uses the public project URL and publishable key with the user's session. Public keys are not substitutes for ownership policies.
- Privileged keys are server-only and limited to operations such as Auth account deletion. Never put them in `NEXT_PUBLIC_*`, client imports, responses, logs, or tracked files.
- Validate auth callback/return destinations against a local-route allowlist. Configure allowed deployment redirect URLs and test verification/recovery on the deployed origin.
- Do not log passwords, tokens, quest notes, or complete request payloads. Logs may include operation type, sanitized error code, duration, and a non-sensitive correlation ID.

## 6. Database model

Names and columns are proposed migration contracts, not existing tables. Use UUID primary keys and UTC `timestamptz` audit fields. All mutable records include an integer `revision`, incremented by accepted mutations. The authenticated user is the owner; client input cannot choose a different owner.

These are server tables. Local snapshots/outbox have a separately versioned Dexie schema described in the local sync design. Deletable cached entities require retained tombstones; local migrations must preserve queued payloads and schema versions.

Creator tables are a later migration set defined in [the creator model](CREATOR_PLAN.md#6-technical-architecture-and-data-model), including separate public pen names, series, chapters/pages, release slots, publication events, and private occurrence links. Do not add them speculatively while scaffolding the calendar schema. Public projections use explicit field/published-state allowlists rather than exposing private owner records.

| Table | Essential fields and constraints |
| --- | --- |
| `profiles` | `id` references `auth.users`; display name, IANA planning timezone, reduced-motion preference, `show_streaks` default false, `celebrations_enabled`, server-owned sync epoch and deletion-request timestamp, revision, timestamps |
| `quest_definitions` | UUID, owner, active/archived state, timestamps; stable identity of a one-off quest or recurring series |
| `quest_schedule_versions` | UUID, definition/owner, effective date interval, entry kind (`quest` or `appointment`), title/notes/category/priority, local endpoint dates/times/zones, optional all-day end boundary, `blocks_time`, repetition rule, revision; versions preserve historical scheduling |
| `quest_occurrences` | Deterministic occurrence UUID, definition/schedule-version/owner, original scheduled date, effective date, endpoint/time/content/kind/blocking snapshots, UTC start/end/due instants, status, validated observed completion time/zone and derived local completion date, server acceptance timestamp, revision, deletion timestamp |
| `completion_rewards` | UUID, owner, unique occurrence UUID, awarded XP, rule version, awarded timestamp, reversed timestamp |
| `app_private.mutation_receipts` | Owner + operation UUID compound key, command/schema version, canonical payload hash, compact successful result, timestamp; internal retry deduplication, no client table grant |
| `app_private.schedule_materialization` | Owner + definition compound key, contiguous historical catch-up date, revision/timestamps; future generation does not advance past coverage |
| `app_private.request_budgets` | Fixed allowlisted account/global keys, server UTC windows and atomic counters; private operating metadata, excluded from sync/export |
| `app_private.account_deletion_jobs` | Job/operation identity, verified owner, status-secret digest, reauthentication deadline, state/lease/retries; survives Auth/profile deletion |
| `weekly_reflections` | UUID, owner, Monday week-start local date, planning-zone snapshot, optional takeaway and next-action text, revision, deletion timestamp, timestamps; unique `(owner_id, week_start_date)` |
| `itineraries` | UUID, owner, title, inclusive local date envelope, display IANA zone, optional destination/notes, archive state, revision, timestamps/tombstone |
| `itinerary_entries` | UUID, owner, itinerary/occurrence UUIDs, logistics type, place/address, optional booking/map links and reference, revision, timestamps/tombstone; one active itinerary membership per occurrence |
| `itinerary_weather_locations` | UUID, owner, itinerary UUID, itinerary-local date, selected weather label/coordinates and optional provider metadata, revision, timestamps/tombstone; unique active itinerary/date |

Profiles additionally have optional weather-home location and temperature-unit preference; itineraries have an optional base weather location. Validate location coordinate bounds and the selected object shape at application/database boundaries. Owner equality applies to dated overrides. Weather settings are durable user choices; provider forecast payloads are not SQL rows or mutation receipt contents.

Profiles also contain a server-owned `account_data_revision` counter independent of preference `revision`. Accepted scoped changes lock the owner's profile first and advance that counter in the same transaction. It supplies a consistent pagination token, not a writable client preference or change feed. The detailed schema names/types and constraints are defined in the database plan.

If the cover experiment ships, itinerary records additionally have cover mode (`auto`, `manual`, `none`), optional validated photo selection, and public-context/rules version. Keep source/photo/photographer credit with the image reference; image bytes are neither Supabase objects nor outbox payloads. Validate the selection schema and exact HTTPS provider page/image hosts on both application and canonical persistence boundaries.

Use SQL checks for allowed category/priority/status values, nonempty bounded titles, positive awarded XP, and valid schedules. Validate timed endpoints by resolved UTC order; local clocks from different dates/zones cannot be compared directly. Proposed field limits: title 200 characters, notes 5,000, display name 80. These are technical defaults to validate during implementation.

Entry kind is validated in schedule versions and occurrence snapshots. Reflection text is bounded to 500 characters per field; at least one field must contain text when saving, and users may delete the record to clear it. Reflection and preference writes are owner-scoped and revision-checked; reflections are included in export/deletion and excluded from analytics/log payloads.

Required consistency rules:

1. Parent/child ownership must agree. Use composite foreign keys where denormalized owner columns support RLS; do not allow a child to reference another user's definition or occurrence.
2. One logical occurrence per `(definition_id, original_scheduled_date)`, including after rescheduling. Re-generating cannot replace outcomes or restore deleted occurrences.
3. A definition's schedule-version intervals must not overlap. Lock the definition when changing the series and enforce the interval invariant in the database.
4. One reward record per occurrence. Undo marks it reversed; recompletion reactivates the original awarded amount and rule version.
5. A completed quest has one active reward; a completed appointment has none. Non-completed/deleted occurrences have no active reward. Controlled operations own these fields; direct browser writes cannot create XP or bypass completion rules. Changing a completed occurrence's kind requires undo first; series changes preserve historical kind snapshots.
6. Soft-deleted occurrences are excluded from planning/review and have no active reward. Archiving a series preserves past occurrences and rewards.
7. An itinerary membership and its linked occurrence/itinerary must have the same owner. A partial unique constraint permits at most one active membership per occurrence; detached/deleted metadata remains tombstoned without preventing explicit future attachment.
8. Itinerary metadata cannot contain an independent event schedule, status, or reward. Calendar and itinerary commands modify the shared occurrence. `blocks_time` affects planning only, never reward eligibility.

Index ownership and queried date fields, definition/date uniqueness, and occurrence foreign keys. Choose additional indexes from actual queries rather than indexing every column. Generate TypeScript database types from migrations; don't maintain a second handwritten SQL schema in TypeScript.

### Progression source of truth

Total XP is the sum of active rewards for the user. Level is `1 + floor(totalXP / 100)` and room milestones follow the product plan. Do not persist separate writable XP, level, or room-stage balances.

The database owns the award amount: initially 20 XP per valid quest completion, no category or priority multiplier. Attendance, elapsed time, reflection, and app usage award zero XP. TypeScript owns presentation calculations such as progress-to-next-level; integration fixtures verify that displayed values match database rewards. SQL returns authoritative accepted values rather than trusting a browser calculation.

## 7. Mutation contracts and concurrency

Typed feature commands first persist their local operation atomically; the sync module sends controlled PostgreSQL RPCs for invariant-bearing mutations. The table below defines canonical server behavior. Authenticated Route Handlers own the documented account-deletion prepare/confirm/status workflow; avoid a second API around every ordinary read. Authentication uses Supabase Auth rather than custom credential storage.

Use the API contract's one named `request jsonb` argument per allowlisted wrapper and runtime-validated versioned envelope. Complex schedule objects are complete field replacements; protected fields/unknown inputs are rejected. Serialize bigint revisions/account counters as strict decimal strings. SDK/PostgREST errors require an adapter; they are not already the application's normalized error union.

| Command | Behavior |
| --- | --- |
| Create quest | Validate fields; insert definition, first schedule version, and needed occurrences atomically |
| Edit occurrence | Check expected revision; update this occurrence's snapshot without changing its original identity |
| Edit series | Lock definition; close/split schedule interval at the effective date; reconcile affected future occurrences while preserving outcomes |
| Complete/mark attended | Lock occurrence; check state/revision/kind; validate observed completion time, record server acceptance time, and activate one server-assigned reward only for a quest; appointment attendance has no reward |
| Undo | Lock occurrence; check state/revision; return to pending and reverse its reward if present, atomically |
| Skip/reschedule | Check revision; skip only pending occurrences, or move a pending occurrence without changing its identity; undo completion first |
| Undo skip | Revision-check skipped -> pending, retaining identity/source; zero XP; order after any queued Skip |
| Delete occurrence | Mark deleted and reverse any reward in one transaction; user confirms deletion of completed work |
| Archive series | Stop future scheduling and remove pending future instances; preserve historical and completed/skipped outcomes |
| Export | Return one consistent owner-scoped snapshot with format version and export timestamp; include history and rewards |
| Delete account | Fresh reauthentication, explicit prepare/confirm, retained private job/operator marker, server Admin deletion and status reconciliation; clear locally only after confirmed removal |
| Save/delete reflection | Validate owner, week date, text, and expected revision; persist or tombstone a private record without any reward operation |
| Create/edit/archive itinerary | Validate owner/date envelope/display zone and revisions; preserve linked occurrences; no reward operation |
| Add itinerary appointment | Atomically create the standard appointment occurrence and its owner-matched itinerary metadata; preserve UUIDs through sync |
| Attach/detach itinerary entry | Lock the occurrence and check ownership/current membership; create or tombstone metadata without duplicating/deleting the calendar occurrence |
| Delete itinerary | Tombstone itinerary/memberships while retaining calendar history; separate occurrence deletion requires explicit commands |
| Set itinerary weather location | Validate owner/date/location/revision, update base or dated override, and preserve all occurrence times/status/rewards |

Weather forecast/search reads use their own authenticated server routes, not the user-mutation outbox. They can use a locally selected location before settings synchronization finishes; never send private itinerary payloads to WeatherAPI.

Optional photo candidate retrieval is likewise a best-effort authenticated read. Applying or removing a cover uses the normal revision-checked itinerary command. An automatic callback must check the current cover mode/context before enqueueing; late results cannot overwrite a manual choice or removed cover. Core mutations do not require a Pexels network round trip.

A multi-table command runs in one database transaction. Next.js code making several independent requests is not a transaction.

### Retry-safe operation sequence

1. Validate the request at the application boundary and again for database invariants. Require the authenticated owner, operation UUID, and expected revision where applicable.
2. Claim a mutation receipt inside the transaction. A duplicate operation UUID with the same canonical payload reuses the successful outcome; reuse with a different payload is rejected. Serialize competing claims with the unique constraint.
3. Lock the relevant definition/occurrence in a consistent order; check owner, deletion state, expected revision, and allowed transition.
4. Apply the change, reward adjustment, revision increment, and successful receipt together. A failure rolls back all writes.
5. Return a typed result and refresh current quest/progression data. A replayed receipt may describe an earlier accepted state, so never overwrite a newer UI state with an old snapshot or replay the celebration.

After an ambiguous network timeout, retry with the same operation UUID and payload. After a new deliberate action, use a new UUID. A delayed completion retry must not recreate XP after a later undo; its original receipt identifies it as already handled. Keep receipts for the MVP lifetime; design retention before pruning them.

Local outbox processing freezes transmitted requests, resolves predecessor revisions, coordinates tabs, and atomically handles acknowledgments. Retain tombstones and receipts for stale/queued devices. Follow [the sync protocol](LOCAL_SYNC_DESIGN.md#4-sender-protocol) rather than adding a separate optimistic mutation path in each component.

Creator metadata uses that protocol when the module ships. Artwork transfers and intentional schedule/publish/cancel/withdraw actions use separate online paths; they do not queue automatic future publication intentions. Flush relevant metadata, validate finalized assets, check canonical revision, then record an accepted frozen version/slot and command receipt atomically. Reconcile ambiguous responses with the original receipt. See [creator release contracts](CREATOR_PLAN.md#7-server-release-and-access-contracts).

Prefer invoker-security functions when grants permit. When restricted mutations need a security-definer function, explicitly verify `auth.uid()`, use a fixed safe search path and qualified identifiers, restrict execution to the required role, and grant the function owner only necessary privileges. Revoke default public/anonymous execution and arbitrary table writes. See [Supabase database function security](https://supabase.com/docs/guides/database/functions).

Concrete planned access: authenticated owner SELECT on the nine public application tables, no direct browser table writes, and explicit public invoker RPC wrappers calling unexposed private implementations under a non-login/non-owner/non-bypass command role. Enable RLS on both public and private tables, with separate owner policies for the required executor operations. Keep receipts/materialization unexposed and return only narrow own results/coverage. Follow the RLS plan's exact role/grant boundary instead of placing a broad postgres-owned definer into the public API.

Multi-table/paginated snapshots verify the account counter and fetch each deterministic page in one SQL snapshot. A changed token restarts the confirmed scope while pending local overlays remain. The same consistency contract applies to complete-trip reads and exports. Add composite ownership/version-parent constraints and deferred reward invariants; owner RLS alone cannot enforce those domain relationships.

Separate materialization from read RPCs; scope reads cannot silently mutate between pages. Tokens bind scope/account counter and first-page `as_of` for time-derived summaries, with explicit expiry and incomplete-generation coverage. Large command reconciliation returns bounded canonical roots plus scope invalidations, never a false complete row set. Structural itinerary membership commands bump itinerary and linked occurrence revisions; metadata/weather membership aggregates use the itinerary revision, while ordinary occurrence edits do not unnecessarily bump trip metadata. The API contract supplies command-specific related revision guards.

Return a small error union such as `validation`, `unauthenticated`, `conflict`, `unavailable`, or `unexpected`. Treat missing and inaccessible records equivalently to avoid disclosing another user's data. Keep detailed database errors on the server; preserve user input on recoverable failures.

## 8. Recurrence and time semantics

- Support one-off, daily, and selected-weekday rules with inclusive optional end dates. Use ISO weekday numbering consistently in storage and tests.
- Store local dates as PostgreSQL `date`, wall-clock times as `time`, planning zones as IANA names, and resolved instants as `timestamptz`.
- Choose a maintained timezone-aware date library during bootstrap. Centralize conversions; don't use `new Date('YYYY-MM-DD')` as the representation of an all-day date.
- Recurrence advances calendar dates in the planning zone, not fixed 24-hour intervals. For recurring routines, proposed DST policy is to shift a nonexistent wall time forward through the gap and use the earlier instant for an ambiguous time. Booked itinerary appointments instead require explicit correction/offset confirmation for invalid or ambiguous times; never silently change a reservation's wall time.
- Untimed quests become overdue at the next local midnight. Timed quests use the resolved end, or start if there is no end. Late completion counts toward consistency on its actual local completion date.
- All-day quests cover one local date; their exclusive end is the next calendar date, and due time is that date's first valid local instant in the quest zone. Midnight gaps advance to the first valid instant and folds choose the earlier one. Date-only display stays date-only; do not count an assumed 24-hour block. All-day appointments may span dates and do not affect quest overdue metrics.
- Ordinary quests and recurring entries remain single-day in the MVP. One-off appointments support cross-midnight/multi-day endpoints and independent start/end IANA zones; all-day appointment ranges use an exclusive end date.
- Profile timezone changes may update future routine scheduling only through an explicit command. Itinerary display-zone changes are view settings; fixed appointment endpoint zones/instants and historical snapshots remain unchanged unless edited explicitly.

Timed version/occurrence snapshots retain `start_ambiguity_choice`/`end_ambiguity_choice` (null/earlier/later). One-off appointments require explicit choices for ambiguous endpoints and correction of nonexistent clocks; display the resulting offset. Routine/recurring entries use null and the gap-duration shift/earlier-fold policy. SQL/client fixtures must agree, including midnight and non-hour DST changes.

Profile timezone update changes display/new-entry defaults only. Review future routines previews selected active quest series, then uses existing `edit_series` commands, preserving wall clocks/weekday rules. The initial effective date is the later of tomorrow in the old series zone and tomorrow in the new zone; this avoids creating already-elapsed replacements across the date line. Each acceptance is shown separately; no bulk atomic or preserve-instant routine rewrite is promised. Appointment instants and historical/completed/skipped snapshots remain fixed.

### Itinerary day membership and blocking

For timed appointments, include an occurrence on every local day whose resolved interval intersects it: `start < dayEnd && end > dayStart`. Clip only the display continuation; keep one occurrence ID and status. All-day ranges use local start-inclusive/end-exclusive date comparisons in their declared date context. Start-only entries use their labeled local anchor without invented duration.

Itinerary days use the itinerary display zone; the main calendar uses the profile zone. Show original endpoint local dates/zones in transport details and date-change/continuation indicators where relevant. Compare endpoints in UTC; date-line travel may have an arrival local date/clock earlier than departure while still having a valid positive duration.

Transport, meetings, and timed activities default to `blocks_time = true`; lodging/reference spans default false. Users can edit the flag, but neither value confers XP. Lodging spans remain visible without creating blanket conflicts or planned-hour totals across the entire stay.

### Time blocks and conflicts

A time block is an ordinary quest occurrence with a start and end; its duration is derived rather than stored as an additional task or earning multiplier. Proposed shortcuts are 15, 30, and 60 minutes, subject to the quest single-day constraint. One-off appointments extend the endpoint representation to multiple dates/zones but never earn XP automatically.

Use half-open resolved intervals `[start, end)`: two entries overlap when `a.start < b.end && b.start < a.end`. Query all owner-scoped intervals intersecting the affected window, including entries that began on an earlier day. Exclude the edited occurrence, deleted/skipped entries, and nonblocking spans. Adjacent blocks do not overlap. Entries missing a known duration show that limitation rather than receiving an invented end time.

Warnings list conflicting entries and offer edit or keep overlap. They are advisory personal-planning feedback, not resource reservations or a guarantee against double-booking. Concurrent saves may change the result; refresh warnings after a save/focus update. Label coverage as Gamecal-only until provider integration is implemented.

Planned-time totals clip blocking timed intervals to the selected display-day boundaries, then merge overlaps before summing duration; exclude deleted/skipped/nonblocking entries, include completed commitments, and display untimed quests separately. Never label this union as productive hours, elapsed focus, or a complete free-time estimate. No focus-timer model is required for this MVP.

### Reflection, consistency, and recovery

- Use Monday-start local weeks for initial review; expose the date range explicitly. Weekly quest completion uses effective scheduled dates and the product plan's due-time eligibility; exclude appointments and display numerator/denominator.
- Recent-week consistency counts local dates with at least one valid completed quest during the seven-day window ending today. Appointment attendance, saving a reflection, and app visits cannot contribute.
- Consecutive/best runs are derived from valid quest-completion history and hidden unless `show_streaks` is enabled. Inactivity resets only the current run, not XP; undo may change both derived runs and earned XP.
- Reflection stores a takeaway and next action, not a validated skill score. Creating a quest from a next action requires an explicit user action and the standard editor; do not schedule or reward it automatically.
- Interpret system reduced motion and celebration preference together. Disabling celebrations removes decorative feedback while preserving pending/success/error state communication.
- Show the planning timezone when editing timed entries; when the device zone differs, offer a preview and explicit future-schedule change. Do not silently shift commitments based on travel.

### Materialization without a background scheduler

Generate occurrences for bounded requested windows through an authenticated operation; proposed maximum is 42 days per call. Unique constraints make repeated requests safe. Initial/review loading also catches up scheduled dates that became due since the last materialization, in bounded batches, so absence from the app does not hide missed commitments. Use a transactional cursor per definition or an equivalent tested coverage record; do not truncate past obligations silently.

During interrupted connections, the local scheduler uses the cached schedule versions and the same deterministic occurrence identity/rules. On sync, the server validates/materializes the canonical occurrence before dependent transitions. Missing historical coverage is explicit until fetched; device-observed action times remain separate from server acceptance times.

Before a series edit, materialize affected historical dates under the prior schedule. Keep historical and completed/skipped occurrence snapshots. Replace only pending future instances affected by the new interval, preserving occurrence identity where the original date remains eligible. Retain deletion markers. When changing a series from a historical selection, the proposed UI applies the series change from today; editing that historical occurrence remains a separate action.

After moving an occurrence, the generator must not recreate it on its original date. Any change affecting title/time/category at series scope must follow the same historical-preservation rule.

## 9. UI, accessibility, and performance

- Main workspace starts at 50/50 Calendar-left/AI-right. Narrow phones show compact previews, then full-width focus mode; usable agenda/editor input takes priority over squeezing a full grid into half a phone. Keep the room preview compact and public reading independent.
- Use shared spacing, color, typography, and radius tokens. Add shared controls only when they serve real usage.
- Editors need visible labels, inline validation, correct focus return, escape dismissal, keyboard-safe sizing, and draft preservation on failure.
- Use real buttons and links. Announce completion/error changes accessibly without repeating them on refresh. Honor reduced motion and avoid animations that block input.
- Render the room from current level/milestones using optimized illustrations or SVG. A missing room asset must never block quest operations.
- Bound and paginate data queries; avoid loading the user's full history for every agenda view. Keep room assets outside the critical calendar bundle where practical.
- Before pilot release, name a reference phone and network profile and measure the proposed three-second cold-load target for a usable agenda. Report measured results; do not claim the target is met without evidence.

### Motion and control ownership

Workspace state is a small reducer/local state with `split`, `calendar_focus`, and `assistant_focus`. Calendar exits left when hidden; AI exits right. Derive mascot presence from the hidden panel, revealing it after the exit settles. Mascot Open restores split; Ask planner opens assistant focus/composer. Persistent labeled mode controls and deliberate panel focus areas provide accessible alternatives. Normal interactive controls/scroll gestures cannot accidentally collapse either half.

Preserve drafts/date/scroll/conversation state above conditional panel lifetimes. Move focus before making hidden content inert; offscreen transforms alone are insufficient. Rapid/interrupting transitions resolve to the latest mode, and optional hidden renderers pause. Use existing Motion ownership/tokens with immediate/faded reduced-motion equivalents. See the UX plan for the full touch, keyboard, and narrow-screen contract.

Use [Motion for React](https://motion.dev/docs/react) for coordinated layout changes, entry/exit transitions, tap feedback, and progression reveals. Use CSS for independent hover, focus, and color transitions. Add selected [shadcn/ui Radix controls](https://ui.shadcn.com/docs/components/radix/dialog) as editable shared components, preserving their focus and keyboard behavior. Do not install a full component catalog.

| Interaction | Proposed behavior |
| --- | --- |
| Quest completion | Checkmark/list feedback after atomic local save; pending-sync marker until acknowledgment |
| Quest editor | Short sheet/dialog transition; autofocus and keyboard handling take priority |
| Date navigation | Subtle content transition; preserve focus and predictable navigation |
| XP update | Progress bar/number change after an accepted reward; never imply XP during a failed request |
| Room milestone | Brief object reveal; replay only for a new accepted unlock, not focus refresh or a retry |

Initial motion tokens: roughly 120–180 ms for control feedback, 180–260 ms for sheets/list transitions, and 400–700 ms for occasional milestone reveals. These are design proposals, not fixed acceptance thresholds. Define shared tokens instead of scattered timing values. Do not delay navigation or saving for an animation to finish, and keep reduced-motion equivalents immediate or limited to a short opacity change.

Avoid overlapping CSS and Motion control of the same transform, unconditional route-wide transitions, and adding GSAP/Lottie or another animation engine without a concrete unmet requirement. Animation must tolerate interruption, rerendering, and rapid navigation without losing state.

### Optional 3D object path

Recommend React Three Fiber as the React rendering layer over Three.js, with selected Drei helpers for model loading and controls. Check React/Fiber peer-version compatibility before installation; see [Fiber installation](https://r3f.docs.pmnd.rs/getting-started/installation) and [Drei introduction](https://drei.docs.pmnd.rs/getting-started/introduction).

- Start with one small low-poly prop in a single canvas. Use optimized local GLB assets with documented provenance; prototype with basic geometry when no asset exists.
- Load the canvas/model lazily through a client boundary; don't put Three.js in the critical calendar bundle. Reserve its layout space and show the illustrated placeholder while loading.
- Prefer on-demand rendering for idle objects, explicitly requesting frames during motion. Pause or unmount rendering when hidden or when the document is inactive. Cap pixel ratio/quality for the target device. See [Fiber performance guidance](https://r3f.docs.pmnd.rs/advanced/scaling-performance).
- Keep React state updates out of the per-frame loop. The scene receives accepted progression as props; it never computes, grants, or persists XP.
- Keep essential controls in accessible HTML. A decorative object's tap animation must not capture agenda scrolling or be required to access a reward.
- Provide a static fallback for WebGL failure, loading errors, reduced-motion preference, and an explicit lightweight-visuals setting. Test scene mount/unmount for resource cleanup.
- Validate phone responsiveness and input latency with the scene active. Proposed scene target: at least 30 fps during a short interaction on the named reference device; no sustained idle/hidden render loop. Measure asset transfer size and cold load alongside the agenda target before shipping.

Spline is a design-driven alternative for a visually authored prototype; its [Web Code API](https://docs.spline.design/exporting-your-scene/web/code-api-for-web) supports React/Next.js integration and scene interaction. React Three Fiber is the recommendation for objects whose appearance evolves from application state and assets controlled in the repo. Use one renderer in the shipped app; if Spline is chosen later, update the decision rather than installing both.

The illustration plus UI motion is the guaranteed baseline. Shipping the first 3D prop depends on performance/accessibility checks; building a complete 3D fantasy room does not become an MVP requirement merely because the renderer exists.

### Planning assistant boundary

Add a narrow authenticated server planning operation only after choosing the actual provider, cost/data-handling contract, and structured response schema. Never call the model on panel/mascot navigation. Minimize explicit selected calendar/itinerary context, exclude unrelated notes/account data, and use acknowledged canonical context initially. Relevant pending local edits prevent schedule-specific suggestions until sync; missing coverage/external availability remains explicit.

Live AI is independently gated and does not block the calendar pilot. Ship the split workspace with truthful deterministic guidance while disabled; keep itinerary/weather in the required pilot scope and Pexels/3D optional. Apply the operations plan's shared cost reservations before enabling generation.

Validate model proposals at runtime and show date/time/zone plus before/after changes. Accept prefills the existing editor; normal save follows the existing owner/revision/queue path. Capture the source revision/context and require re-review on changes; no direct model-to-database writes, completion/XP operations, publication, or bookings. The model's text cannot authorize an operation.

Keep first conversation state session-scoped/account-isolated; preserve it across panel switches and clear it on sign-out/account change. Abort/ignore obsolete requests and bound token/context/request costs. AI failure cannot block local calendar operations. No provider SDK, persistent chat schema, multi-agent framework, or model credential is implied by the shell prototype.

### Creator and reader layout extension

Authenticated `/studio` routes compose series, chapter editor, owner-only preview, and release-slot confirmation. Public `/read/[seriesSlug]` and chapter routes use a dedicated reader layout. Reuse semantic controls, tokens, and Motion; comic pages render as accessible HTML/images, not a 3D canvas. Keep studio/reader code outside the critical calendar bundle.

Support continuous scroll and paged RTL/LTR modes with zoom, keyboard/touch controls, aspect-ratio reservation, bounded image lookahead, artist descriptions/transcripts, and device-local resume. External chapters display an explicit destination link rather than attempting to embed/scrape the external reader. Do not claim cross-device reading progress or offline chapter access in this pilot.

## 10. Environment and deployment

Track an `.env.example` with placeholders; ignore real environment files. Validate required configuration at startup without printing values. Initial variables:

```text
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
SUPABASE_SECRET_KEY            # server only; only if privileged workflows need it
CRON_SECRET                    # server only; deletion retry runner before hosted pilot
WEATHERAPI_KEY                # server only; required to enable forecast retrieval
PEXELS_API_KEY                # server only; only for the optional cover experiment
```

Use the actual key type supported by the provisioned project; never rename a privileged key into a public variable. Keep local tests and previews off production data. Track one package manager/lockfile and a Node runtime declaration. Do not pin versions in this design document; the installed versions and lockfile are authoritative.

Weather routes use verified sessions, bounded inputs, fixed HTTPS provider endpoints, upstream timeout/error mapping, request coalescing, and usage limits. Keep the key and complete upstream query string out of responses/logs/client bundles. Missing weather configuration disables weather reads with a safe unavailable state, not calendar/auth functionality. Recheck the provisioned plan's forecast horizon and provider retention/source-credit requirements before launch.

Use transient in-memory forecast caches in the MVP, independent of Dexie user records. Retain the original upstream fetch timestamp through server/browser cache hits; enforce fresh/stale/expired states under the weather contract. Do not add a durable weather archive, shared private-request cache, or a weather database solely for this feature. Existing deployment caching may be used only with verified isolation/retention semantics.

Pexels calls use the fixed photo API host, server-side Authorization, bounded public-context queries, caching/coalescing, and rate-limit handling under the photo plan. Missing photo configuration uses the neutral fallback. For the first experiment, render supplied responsive CDN variants directly, or use an unoptimized Next.js image, rather than silently introducing image-optimization storage/transformation costs. If an optimizer is chosen later, measure deployment costs and set a strict remote host/path allowlist.

Before deployment: apply tested migrations to the intended environment, configure auth origins/redirects, verify isolation and auth flows, set secrets in hosting configuration, and verify recovery procedures. Use forward-compatible migrations and plan rollback/recovery for schema changes; never reset a shared database as a deployment step.

Account deletion is a retryable server workflow: app-owned rows cascade with Auth user deletion, and partial errors are handled without reporting success falsely. Reauthentication precedes the destructive action; log no personal content. Export omits tokens, password data, privileged metadata, and other users' records.

Use the operations plan's prepare/confirm/status routes, independent private job, operator-only `operations-recovery` Storage markers and protected Vercel Cron retry runner. Keep-work sign-out retains a locked queue; exporting cannot purge it. Shared provider budgets use the existing PostgreSQL database; Data API pre-request limits deny direct table endpoints while owner SELECT remains available inside invoker RPCs. Transactional failed-call counting limitations are explicit in that plan.

Use the database plan's owner cascades and deferred NO ACTION domain foreign keys, and prove the full deletion graph in the local suite. Normal domain operations tombstone; neither the browser nor the command executor has a physical DELETE grant. Future hosted-artwork cleanup needs a backend-only job that survives the account-row deletion until its Storage work succeeds.

If hosted creator content ships, account deletion also needs explicit Storage-object cleanup: row cascades alone are insufficient. Preserve a retryable owner-object manifest through cleanup and report completion only when both metadata and assets are handled. Creator exports may include owned content metadata and authorized original downloads through a separate bounded workflow; never include signed preview tokens in ordinary calendar recovery bundles.

Operational backup/recovery must specify the Supabase environment, backup mechanism, retention, responsible operator, and a demonstrated restore into an isolated environment. Choose these before the invited pilot; hosting/database plan features are not assumed.

The selected planning baseline is daily backups/seven-day retention on proposed Supabase Pro, owned by the project operator, with 24-hour data-loss/four-hour recovery targets requiring rehearsal. Restore reconciles deletion markers and remints surviving profiles' sync epochs before opening access. Old-epoch commands without retained receipts require review; no blind replay after restore. The operations plan records limits and the separate creator-object backup gate.

### Publishing infrastructure — separate creator pilot

Use private Supabase Storage with owner-only upload policies, immutable versioned paths, verified JPEG/PNG/WebP payloads, finalization, and bounded byte/dimension quotas. Add a narrow resumable TUS client only when implementing uploads; do not put binary art into Dexie or the calendar outbox. Server media code verifies current publication eligibility before signing nearby page URLs; short-lived URLs and their expiration are specified in the creator plan. Never proxy arbitrary supplied URLs or accept an object path without resolving it from an authorized chapter manifest.

Use one proposed minute-level Supabase Cron scanner running a restricted SQL publication function over due accepted slots. Keep transactions/batches bounded, lock rows, enforce unique publication events, and record target versus actual release time. Catch-up and error visibility are required; no browser execution or per-artist weekday cron job. Owner cancel/withdraw commands share locks/revisions with the scanner. Publication state and signed media access are driven by server time.

Public series fields may be cached only with explicit visibility invalidation. Keep owner previews and chapter manifests/media signing uncached initially; withdrawal blocks new access, while previously issued URLs expire under their stated lifetime. Provision monitoring/backlog checks, rate limits, upload/object cleanup, reporting/withdrawal controls, and a measured media budget before the invited creator pilot. External mode schedules only the Gamecal card/link; it makes no guarantee about publication on another platform.

## 11. Verification and development commands

The scripts below exist in `webapp/package.json`; run them from that folder using pinned pnpm. Database scripts fail explicitly until actual migrations/tests and the disposable local stack exist. See [the implementation command list](webapp/README.md#type-safety-and-verification) for additional generation and aggregate checks:

| Script | Purpose |
| --- | --- |
| `dev` | Local Next.js server |
| `build` | Production build |
| `lint` | ESLint directly, without assuming an obsolete framework lint command |
| `typecheck` | TypeScript checking without output |
| `format:check` | Formatting validation |
| `test` | Focused unit/component tests |
| `test:db` | SQL integration tests against the disposable local Supabase environment |
| `test:e2e` | Playwright critical browser flow |

Focused cases:

- XP thresholds; repeated completion; undo/recomplete; retry after later undo; concurrent completion from two devices.
- Ownership violations through direct Data API/RPC requests; anonymous function execution; protected columns; owner/parent mismatches.
- Recurrence duplication; one-occurrence edits; series edits; deleted/rescheduled occurrences; catch-up after inactivity.
- UTC/date-only boundaries; DST gap/overlap; explicit timezone changes; invalid time ranges.
- Failed saves, expired sessions, stale revisions, focus refresh, and preserved editor text.
- Appointment attendance/undo yields zero XP; kind changes cannot retain an invalid reward; appointments are excluded from quest consistency/rates.
- Half-open conflict boundaries, edited-entry exclusion, intentionally retained overlap, and union-based planned-time totals without double counting.
- Optional streak/celebration preferences preserve functionality; rest/missed days never reduce XP; reflection edits/export/deletion obey owner isolation and never grant XP.
- Itinerary leisure/business flows; shared occurrence identity; independent endpoint zones/date-line/overnight spans; nonblocking lodging; metadata ownership; attach/detach/archive/delete with pending commands; complete-trip cache and print layout.
- Weather provider fixtures and request bounds; selected city/forecast-zone date alignment; unsupported dates; missing readings; unit switching; original cache timestamp/expiry; errors/quotas; attribution; secrets; and independently functioning local saves/sync.
- If imagery ships: query privacy, candidate normalization/hosts, late-result suppression, none/manual mode, metadata-only persistence, credit, crop/contrast, mobile bytes, and provider/CDN failure fallback.
- When creator publishing ships: both chapter modes, Wednesday/timezone/DST slots, closed-browser release, empty/not-ready slots, scanner retry/backlog, cancellation races, direct draft/media isolation, immutable published versions, storage cleanup/quotas, and reader navigation/accessibility/resume. Follow the creator plan's separate gates; do not add these as calendar MVP dependencies.
- Workspace checks: all three modes/exit directions, correct mascot-only visibility, popover restore/dismiss, normal calendar/control/scroll behavior, phone/keyboard/resize, reduced motion, hidden focus exclusion, and draft preservation. Working AI adds context/account/request isolation, malformed responses, stale proposals/pending sync, provider failure/limits, and reviewed saves through the existing queue.
- First-session journeys FS-01–FS-15, including real account/profile setup, one-off local write, accepted completion/undo, lost acknowledgment, quota/conflict/auth recovery and truthful asset/AI failure. FS-16 uses a disposable 80 XP fixture to verify the lamp threshold; do not inject onboarding rewards into production.
- Fresh migration application; complete export; account deletion and cascades.
- All queue/reconciliation cases in [LOCAL_SYNC_DESIGN.md](LOCAL_SYNC_DESIGN.md#8-required-proof-before-the-pilot), including local upgrades/quota errors, lost acknowledgments, tabs, account changes, and retained conflicting edits.
- Browser flow: verification/sign-in -> create -> repeat -> complete -> milestone -> undo -> reload -> export.

Run checks appropriate to the changed layer. Before pilot release, run the complete relevant suite plus a production build and real-device UI checks. A document-only change needs link/content verification, not an invented application test result.

## 12. Implementation order and unresolved setup

**Current boundary:** Database/RLS planning precedes project connection, migration authoring/execution, and table/policy creation. The order below describes later authorized implementation; it is not permission to connect or execute now. Review [the schema](DATABASE_SCHEMA_PLAN.md) and [permissions](RLS_PLAN.md), then prepare/test migrations locally before proposing any remote application.

First prove the API slice in [API_CONTRACTS.md](API_CONTRACTS.md#11-contract-verification-and-implementation-stop-condition) through the [first-session acceptance journeys](FIRST_SESSION_PLAN.md#7-acceptance-journeys-and-observable-proof): ensure profile, create/read a one-off quest, complete/undo, and reconcile interrupted requests. Add recurrence/itineraries/providers after that path works. [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) now defines bootstrap version candidates, local prerequisites, Auth/email test configuration and shared fixtures; installation and compatibility checks remain pending.

1. Baseline scaffold now established in `webapp` without overwriting the planning documents: scripts, strict typing/typed lint, environment parsing and initial helper/adapter boundaries. Product design tokens and UI remain deferred by the user's scaffold-only request.
2. Implement migrations, generated types, verified local Auth/email capture, and RLS isolation tests in a disposable local Supabase environment; do not link a remote project yet.
3. Establish Dexie/projection/outbox and deliver one vertical slice: sign in -> create locally -> interrupt network -> complete/undo -> reload online -> sync once -> verify canonical XP.
4. Add recurrence, revision conflicts, calendar navigation, review, and room milestones.
5. Deliver the manual itinerary slice and endpoint time semantics on shared occurrences; validate both personal and business/event examples before optional visual expansion.
6. Add WeatherAPI server routes and location settings/cards under the weather contract; validate plan limits, cache/error states, and provider key isolation.
7. Add export, retained-queue sign-out, deletion jobs, cache cleanup, shared budgets, print/accessibility and local device QA. Review local results before separately authorized remote project selection/linking, migration application, hosting/SMTP/backup configuration and pilot deployment. Prioritize saved-itinerary offline reopening as a follow-up with its own lifecycle proof.

For the separate creator pilot, follow [the creator delivery slices](CREATOR_PLAN.md#9-delivery-slices-and-acceptance): private series/cadence planning, external scheduled release cards, hosted upload/reader, then full hosted scheduling and operational checks. Reuse verified auth/ownership/timezone foundations; add no alternate backend, drawing engine, or generic publishing framework.

Still to establish during implementation: verified installed dependency graph/lockfile, local runtime and environment, actual pilot SMTP provider, reference device/network, and provisioning/verification of the operating baseline. Initial version candidates and the shared Temporal adapter choice are recorded in the setup guide. Proposed hosting/backups/budgets and account cleanup are specified in the operations plan; no deployment or paid plan has been configured. These are setup tasks, not reasons to create alternate providers or speculative configuration systems.
