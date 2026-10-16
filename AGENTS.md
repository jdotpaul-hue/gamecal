# Gamecal Agent Guide

This guide applies to coding work throughout this repository. Follow the user's current task and applicable higher-priority instructions; use this file as the shared engineering baseline. A future narrower directory guide may refine local conventions.

## Read first and stay in scope

- Read [PRODUCT_PLAN.md](PRODUCT_PLAN.md) for outcomes/scope and [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) for architecture/contracts. Read only relevant sections again when needed.
- Read [PERSONAL_AI_PLAN.md](PERSONAL_AI_PLAN.md) for the latest personal-AI-first direction: Calendar and People capabilities, relationship support, voice-led outcomes and explicit memory control. Distinguish confirmed user direction from proposed home/pilot details. Older optional-AI/voice-excluded calendar-pilot assumptions are historical. New assistant work still uses validated tools, real authorization and reviewed durable actions; personalization cannot grant permissions.
- Read [PERSONALIZATION_PLAN.md](PERSONALIZATION_PLAN.md) before assistant settings, teaching, memory, tool permissions or template work. Persona/charter text cannot grant authority; hard rules use accepted typed settings and execution-time checks. A one-time correction is not a standing rule. Explicit memory, opt-in later observation and public templates have distinct lifecycle/privacy contracts. Templates never carry grants, connections or private memories. Do not infer approval for autonomy or background jobs from this planning proposal.
- Read [SECOND_BRAIN_PLAN.md](SECOND_BRAIN_PLAN.md) before note capture, knowledge links, retrieval, Markdown import/export or companion-driven knowledge work. Organization/linking is automatic within configured capture scope; do not require manual links or approval of every generated summary/edge. Preserve source attribution and owner/revision checks; distinguish generated relationships from confirmed facts. Clarify only consequential ambiguity, respect corrections/unlinking during reprocessing, and never overwrite source/user-authored text. Notes cannot mutate calendars or permissions by themselves. Match People by supported identity/context, not just names/embeddings. Derived indexing follows edits/forgetting/deletion; imported Markdown/frontmatter is untrusted. Do not add a vector service, filesystem vault, background job or agent federation from the concept alone.
- Consult [ARCHITECTURE_PRINCIPLES.md](ARCHITECTURE_PRINCIPLES.md) for CUPID and feature boundaries, and [DATA_ARCHITECTURE.md](DATA_ARCHITECTURE.md) for ownership, representations, consistency and lifecycle. [README.md](README.md) identifies the authoritative document for each contract.
- Consult [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) before bootstrap for local prerequisites, dependency candidates, Auth/email fixtures, fixed occurrence identity and script/CI contracts. Candidates are not installed compatibility proof; preserve existing docs when scaffolding and use the verified lockfile afterward.
- Read [LOCAL_SYNC_DESIGN.md](LOCAL_SYNC_DESIGN.md) before changing persistence, account lifecycle, completion feedback, or sync behavior.
- Read [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md) for keep-work sign-out, safe cache cleanup, deletion prepare/confirm/status, shared budgets and backup/restore gates. Export never permits purging unsynced work. The thirteen-table pilot schema adds two private operating tables to the eleven-table foundation; no provisioning/execution is implied.
- Read [DATABASE_SCHEMA_PLAN.md](DATABASE_SCHEMA_PLAN.md) and [RLS_PLAN.md](RLS_PLAN.md) before database/security work. They define tables/types/constraints, account snapshot versioning, grants, owner policies, controlled RPCs, and later public-content boundaries. The current database task is planning-only; connecting a project or executing table/policy creation requires a later user instruction authorizing that work.
- Read [API_CONTRACTS.md](API_CONTRACTS.md) before API, command, snapshot, provider-route or model-proposal work. Use named allowlisted RPCs/versioned validated envelopes, decimal-string bigint revisions, original acknowledgment versus current canonical state, and explicit scope invalidations. Provider routes are separate reads/generation, not a duplicate calendar CRUD layer. All APIs remain proposed until implementation is authorized.
- Read [ITINERARY_PLAN.md](ITINERARY_PLAN.md) before changing trip grouping, travel metadata, endpoint timezones, or saved-itinerary access. Both leisure and business/events use the same basic model.
- Read [WEATHER_PLAN.md](WEATHER_PLAN.md) before changing forecast retrieval, weather settings, caching, or weather UI. WeatherAPI.com is the selected provider.
- Read [PHOTO_PLAN.md](PHOTO_PLAN.md) for the optional Pexels cover experiment. It is destination-based enhancement, not a required MVP gate or an unrestricted photo/wallpaper product.
- Read [CREATOR_PLAN.md](CREATOR_PLAN.md) before implementing content series, artwork uploads, release scheduling, or public reader routes. Both hosted and external chapters are requested; this is a separate creator pilot, not a prerequisite for the private calendar MVP.
- [RADIO_PLAN.md](RADIO_PLAN.md) records a radio idea explicitly parked by the user. Do not implement it as part of calendar/creator work. When activated, verify the candidate provider's current terms/quota, keep directory credentials server-only, require intentional playback, and keep stream bytes/play commands outside storage/sync and XP.
- Read [UI_UX_PLAN.md](UI_UX_PLAN.md) before changing the main shell, panel transitions, mascots or planning assistance. The former mandatory Calendar/AI split is historical; the personal-AI plan proposes a voice-led Today canvas. Planning proposals require review and normal validated saves; no model/provider has been selected yet.
- Read [FIRST_SESSION_PLAN.md](FIRST_SESSION_PLAN.md) for account/setup, editor, completion/Undo, loading/sync/conflict/recovery states and FS acceptance journeys. Preserve the existing email/password proposal, truthful local/accepted feedback and room thresholds; no forced tutorial, seeded reward or requirement to finish five quests in onboarding.
- The baseline app is in `webapp/`; read [its implementation status and commands](webapp/README.md) and its narrower guide before coding. Local SQL/RLS/read and command foundations exist; product UI, complete Auth journeys, queue sending and assistant features remain incomplete. Never claim a route, migration, package, or test exists without inspecting it.
- Baseline stack: Next.js App Router, React, strict TypeScript, Tailwind CSS, Dexie/IndexedDB, Supabase Auth/PostgreSQL; selected shadcn/ui Radix controls and Motion for React. Optional 3D uses Three.js/React Three Fiber with selected Drei helpers. Use the installed versions and lockfile as the source of truth once scaffolded.
- Initial release has local-first IndexedDB/Dexie calendar data and foreground Supabase reconciliation, with online startup/sign-in. Queued cached-calendar edits tolerate network interruptions; PWA offline startup/closed-app sync remain later work. One optional 3D prop may ship after performance/fallback checks. Add push, a full 3D world, gold, or multiplayer only when requested.
- If requirements conflict, follow explicit user decisions and update stale docs. Do not silently change behavior to fit an implementation shortcut.
- Consult [RESEARCH_REVIEW.md](RESEARCH_REVIEW.md) when changing motivation or growth features. Distinguish evidence, product hypotheses, and measured outcomes; never treat a commercial feature list as proof of user benefit.

## Working method

1. Inspect the existing entry points, related code, migrations, and scripts before editing. Search with `rg` when available.
2. Identify observable acceptance conditions and the smallest coherent change. Diagnose unclear failures before changing code.
3. Reuse established patterns. Fix behavior at the responsible layer; avoid unrelated cleanup or speculative abstractions.
4. Implement the complete authorized path, including errors and persistence where required.
5. Run focused relevant checks, inspect the diff, and report changes plus material limitations. Stop when acceptance passes.

Do not discard another contributor's edits, reset shared state, or modify unrelated files. Do not deploy or apply destructive operations to shared/production environments unless the task authorizes them. Ordinary local edits and checks do not need an extra approval flow. Use disposable local databases for destructive migration tests.

## Clean code

Use CUPID as the design/review baseline:

- **Composable:** explicit typed inputs/results, small useful feature entry points, minimal hidden dependencies.
- **Unix philosophy:** one clear, complete product purpose per operation; completion/reward/receipt writes remain one transaction.
- **Predictable:** explicit time/zone/revision/epoch inputs, bounded work, typed failures and stable retry behavior.
- **Idiomatic:** established TypeScript/React/Next.js/PostgreSQL/Dexie patterns for the installed versions; practical functions and adapters before generic frameworks.
- **Domain-based:** group and name code by planning, occurrences, progression, itineraries and accounts. Keep one shared schedule-rule implementation across calendar/travel views.

For data changes, identify the authoritative owner/writer, validation/invariants, access class, retention/export/deletion, consistency boundary and query/index need. Local intentions, confirmed snapshots, projections and server facts are distinct. Generate SQL-facing types, validate runtime boundaries, and prove cross-runtime rules with meaningful fixtures. Add abstractions and denormalizations only with a concrete use and maintenance/rebuild rule.

- Prefer simple functions and explicit data flow. Separate responsibilities when they change independently; avoid premature interfaces, factories, base classes, generic repositories, or global stores.
- Use names that describe domain meaning: quest definition, occurrence, completion reward, planning timezone. Avoid vague `data`, `manager`, or `helper` modules.
- Keep route files focused on composition. Keep database calls and scheduling/progression rules out of presentation components.
- Extract a component or function when it has a distinct responsibility, meaningful reuse, or is difficult to understand. Do not split solely to satisfy an arbitrary line limit.
- Avoid duplicated business rules. Database invariants are authoritative; frontend validation and presentation must agree with them through shared contracts/tests.
- Use early returns for clear error paths; avoid deep nesting, hidden mutation, and flag-heavy functions.
- Add comments for intent, invariants, or non-obvious tradeoffs. Remove stale comments, abandoned code, unused imports, and unrelated TODOs.
- Preserve behavior during refactors and verify the affected path. Do not combine a broad refactor with a small bug fix unless necessary.

## TypeScript and validation

- Target type safety across application code and data boundaries; do not claim that TypeScript proves runtime shapes, authorization, SQL invariants or all possible behavior. The scaffold establishes compiler/type-aware lint enforcement; feature-specific schemas and SQL/RLS proof arrive with their implementations.
- Enable `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitReturns`, `noFallthroughCasesInSwitch` and `useUnknownInCatchVariables`. Keep type checking without emit as a separate required check; preserve framework-required configuration. Do not enable build options that ignore type errors.
- Reject explicit/implicit `any`, unsafe assignments/calls/member access/arguments/returns, non-null assertions and double casts such as `as unknown as T`. Start untrusted values as `unknown` and narrow or parse them. Do not hide failures with suppression comments or broad ambient declarations. Any unavoidable library-interop assertion must be localized in an adapter, documented with its actual proof and covered by a focused check; never let an unchecked value escape as a domain type. `as const` and `satisfies` are useful static tools, not runtime validation.
- Use type-aware ESLint to enforce unsafe-value rules, `no-floating-promises`, `no-misused-promises` and exhaustive union switches. Await async work or deliberately handle its rejection; `void` alone is not error handling. Apply the rules to maintained application and test code, keeping generated/vendor files separate rather than disabling safety globally.
- Use Zod schemas for untrusted forms/URLs, environment configuration, request/response payloads, SQL JSON/JSONB envelopes, provider/model responses and rehydrated persisted records. Parse at ingress before a value becomes trusted application state. Handle invalid/version-unsupported data explicitly, preserving queued work and drafts; parsing must not rewrite a frozen attempted command.
- Derive validated DTO types from their owning schemas with `z.input`/`z.output` or `z.infer` as appropriate. Do not maintain a parallel handwritten interface for the same schema. Keep raw form inputs, wire DTOs, SQL rows, persisted records and domain models distinct where their representations differ; use explicit typed mappers.
- Generate database types from local migrations and type every Supabase client with them; do not hand-edit generated files or maintain a competing ORM schema. Generated `Json`/JSONB RPC types and SDK type overrides do not prove an envelope's fields: use command-specific request/response schemas and adapters. Follow [the technical boundary contract](TECHNICAL_DESIGN.md#end-to-end-type-safety).
- Before local SQL migrations exist, the scaffold exposes Auth-only facades and deliberately provides no table/RPC surface or fabricated database types. Replace that temporary boundary with actual generated types when implementing the database slice; do not widen it to `any`.
- Validate distinct domain IDs, local dates, wall times, IANA zones, UTC instants, revisions and sync epochs before creating their domain representations; use branded types where confusing concepts would cause a real bug. Keep revisions/counters as validated decimal strings on the wire and in persistence. Handle null, omitted fields and undefined deliberately; do not replace meaningful zero/false with truthy defaults.
- Use discriminated unions for command names/payloads, tagged records, UI/sync states and success/failure results. Keep command name and payload types correlated; do not use a generic string plus an unrelated payload union. Handle variants exhaustively and recoverable errors explicitly; never swallow failures or return fake success. Auth/RLS and database constraints remain independent required checks.
- Keep pure calendar/progression functions independent of React and Supabase. Pass time/timezone inputs explicitly so tests are deterministic.

## Next.js and React

- Use App Router conventions for the installed version. Server Components are the default; add `use client` only at required interactive/browser boundaries.
- Keep secret-dependent modules server-only. Pass only necessary serializable data across the server/client boundary.
- Verify authentication inside server operations; a protected layout or session-refresh proxy is not sufficient authorization.
- Never put per-user database results into shared/public caches. Define identity and invalidation before adding any private cache.
- Keep UI state local unless multiple real consumers require sharing. Put navigable dates in validated URL parameters.
- Use effects for external synchronization, not derived values or event-driven business logic. Clean up listeners and prevent stale async results from replacing newer state.
- Use stable record IDs as list keys. Keep forms responsive during pending requests; preserve drafts on failure.
- Choose one mutation path per operation. Do not duplicate ordinary Supabase reads behind a custom REST layer or add a separate backend by default.

## Supabase and database rules

- Supabase owns canonical accepted data/rewards; Dexie owns confirmed snapshots and durable pending commands. Render the calendar from their local projection; do not use localStorage for application records or keep another independent writable XP balance.
- Save ordinary private edits locally and enqueue atomically before reporting saved-on-device. One sync module handles dependency ordering, frozen retry payloads, acknowledgments, revisions, tombstones, conflicts, and tab coordination. Do not bypass it with ad hoc component cloud writes. Creator upload and deliberate publication commands have the separate online paths defined in the creator plan; never replay a scheduling intention automatically from the calendar outbox.
- Isolate local partitions by account, keep auth credentials out of Dexie, preserve pending work on expiry/conflict, and never replay it as another user. Follow sign-out/export/discard and deletion contracts.
- Keep pending work locked on deliberate sign-out until same-account recovery, sync, explicit discard or confirmed deletion. Evict only unpinned confirmed data; never reset a nonempty queue to fix quota/migration failures. Validate server-owned sync epochs; restore mismatches require review, not rewriting frozen requests.
- Every exposed user table requires RLS and least-privilege grants. Validate ownership in functions and enforce parent/child owner consistency in constraints.
- Use the chosen owner-SELECT/no-direct-browser-write model: public invoker wrappers delegate to unexposed restricted command implementations. Enable RLS on internal tables too; grant only required executor operations. The executor is not a table owner, bypass role, or browser role membership. Audit default table/function grants and keep helpers/private tables outside exposed schemas.
- Advance the separate account snapshot counter atomically with scoped changes, using consistent owner-first lock order. Validate deterministic pagination tokens before accepting complete scopes. Do not turn preference revisions into an account-wide CAS token or replace an outbox command's observed revision with a newer pull.
- Use verified session identity; never trust a client-supplied owner UUID or an unverified session object.
- Privileged keys stay on the server. Never expose them through `NEXT_PUBLIC_*`, client imports, commits, logs, fixtures, or API responses.
- Keep schema, grants, policies, functions, and indexes in versioned SQL migrations. Never alter a migration already applied to a shared environment; add a new migration.
- Re-generate database types after schema changes. Test migrations from a fresh disposable database and plan recovery for destructive changes.
- Completion, undo, and reward-changing deletion must be transactional and idempotent. Enforce unique occurrence/reward identities and revision checks in the database.
- Browser code cannot assign XP, write progression balances, or bypass controlled status transitions. Derive level and room milestones from accepted active rewards.
- Use operation UUID receipts for ambiguous retries. Reusing the same UUID with a different payload is an error; a delayed retry must not resurrect undone work.
- Validate mutation response bodies before dropping a pending projection; missing/malformed responses or aborted requests leave acceptance unknown. A missing receipt does not prove an in-flight command failed. Use the original receipt acknowledgment for dependent revisions, never silently substitute a newer canonical base. Broad changes need canonical roots plus durable invalidations/refetch.
- Keep materialization explicit and separate from read pagination. Wire bigint values remain validated decimal strings; snapshot tokens bind scope/counter/time anchor/expiry and do not authorize another account. Page completion and recurrence coverage are distinct. Itinerary structural membership guards advance the documented aggregate revisions.
- Prefer invoker-security functions. If definer security is necessary, restrict grants, explicitly check the caller, set a safe search path, qualify identifiers, and test direct malicious calls.
- Query bounded date ranges and necessary columns. Add indexes for observed query paths; avoid per-row network requests.

## Calendar and progression invariants

- Distinguish date-only values, local wall times, IANA zones, and UTC instants. Never advance daily recurrence by adding fixed milliseconds.
- Centralize timezone conversions using the chosen maintained library. Follow the technical design's explicit DST policy and test boundaries.
- Recurrence generation is idempotent and preserves history. Rescheduling keeps occurrence identity; deleted occurrences do not regenerate.
- Occurrence command references carry cached definition/date/source-version identifiers. A missing local recurring instance can be materialized only after canonical source/identity validation; initial revision `1` cannot justify silently completing a remotely changed schedule.
- Series changes preserve historical and completed/skipped outcomes. Follow the technical design's schedule-version and snapshot rules.
- Overdue is derived, not a separately drifting status. Completion timestamps determine the consistency date.
- Undo skip uses `unskip_occurrence`, skipped -> pending with zero XP and unchanged identity; complete/reschedule requires pending. All-day quests are one date, due at the first valid start of their exclusive next local date. Preserve explicit appointment DST choices and apply future routine timezone changes through reviewed per-series edits.
- A durable local completion can appear pending sync, but rejected cloud requests cannot grant confirmed XP. Undo reverses exactly one active reward. Repeated clicks, reloads, retries, and concurrent devices cannot multiply it; preserve observed action dates across delayed sync.
- Validate/store the completion's observed timezone and server-derived local date so later profile timezone changes preserve history. Enforce occurrence/reward agreement through atomic transitions and a deferred cross-table invariant; CHECK expressions alone cannot validate another table.
- Do not reward priority, financial outcomes, or other unplanned inputs. Changes to reward rules require product documentation and regression proof.
- Appointment attendance, elapsed time, reflection, and app visits award no XP. Entry-kind snapshots and database checks enforce this; appointments do not contribute to quest metrics.
- Time blocks are editable timed quests. Conflict warnings are advisory and Gamecal-only until integration exists; use half-open intervals and union-based planned-time totals without inventing productive hours.
- Weekly consistency is the default; consecutive streaks are optional. Never erase XP/room progression for missed days or penalize reflection opt-out. Undo/deletion still reverses the relevant reward.
- Itinerary membership references the shared calendar occurrence; never duplicate its schedule/status/rewards. Preserve calendar history on detach/archive/itinerary deletion and enforce owner equality and one active membership.
- One-off appointments may span days and endpoint zones. Validate UTC ordering, preserve labeled local endpoints, and query day intersections; a continuation is not a new occurrence. Ordinary quests/recurrence stay single-day initially.
- Respect `blocks_time`: lodging/reference spans default informational; transport/meetings default blocking. Clip and union blocking intervals for day totals. Travel logistics and trip archive do not automatically earn XP.

## UI and accessibility

- The latest home proposal is a voice-led Today canvas with readable outcome cards and direct Calendar/People/Memory controls. The old mandatory split and twin behavior are historical until the new layout is finalized. The fantasy room and companion animation remain optional presentation.
- If a focused/split panel layout is retained, derive visibility from one explicit model. Preserve ordinary controls, scrolling and drafts, exclude hidden content from focus, honor reduced motion and keep direct labeled navigation available. Mascots cannot be the only navigation or permission control.
- Use semantic controls, visible labels/focus, keyboard support, correct dialog focus management, readable contrast, and reduced-motion behavior.
- Use design tokens and established Tailwind patterns. Avoid scattered hardcoded styles and duplicated controls.
- Make empty, pending, disconnected, error, conflict, and success states understandable. Report saved-on-device only after the local transaction; report synced only after acknowledgment. Distinguish uncached ranges from empty schedules and pending completions from confirmed rewards.
- Keep Undo accessible after short notifications disappear. In-session unsaved drafts survive panel switches but do not inherit the durable queue's reload guarantee. Pending Undo does not subtract confirmed XP before acceptance, and complete/undo pairs suppress superseded unlock celebrations.
- Use Motion for coordinated UI transitions and CSS for simple independent effects. Share motion tokens; do not stack competing animation engines or animate the same transform from multiple systems.
- Preserve shared controls' keyboard/focus behavior when adding transitions. Apply reduced-motion equivalents and never delay a save/navigation for a reveal.
- Keep optional 3D behind a lazy-loaded client boundary with a static fallback. Use one canvas/renderer, on-demand idle rendering, and pause hidden scenes. Verify React/Fiber compatibility and asset/resource cleanup.
- 3D consumes accepted progression state; it cannot assign rewards or replace essential HTML controls. Avoid per-frame React state updates and aggressive effects that degrade calendar input.
- Preserve user control: celebrations and streaks can be disabled, recovery offers a next action, and private reflection is optional. Do not add guilt copy, forced coaching, paid streak repair, or fake growth claims.
- Keep travel details optional and contextual so ordinary quest entry stays quick. Validate external links, exclude booking references/trip notes from logs/analytics, and never imply live routing/flight data or offline reopening without the corresponding implementation and proof.
- Weather is nonblocking planning context: it cannot grant XP or move bookings automatically. Label selected location/local forecast dates, source/update time, unsupported coverage, and stale/unavailable states. Never substitute historical data for a future forecast.
- Photos are illustrative and optional. Preserve readable agenda surfaces, source/photographer credit, stable auto/manual/none modes, and placeholders for missing images. Never imply a stock photo verifies a booked venue or live weather.
- Keep hosted reading focused on art: scroll/paged modes, explicit RTL/LTR, zoom, accessible chapter/page navigation, reduced-motion preferences, and artist transcript alternatives. Never reward reading/views/publication or insert calendar celebrations into the reader. External chapters have an explicit external-site action, not a fabricated in-app reading experience.

## Dependencies, configuration, and security

- Use one package manager and its lockfile. Pin a supported runtime and commit dependency resolution; avoid unrelated upgrades.
- Add a dependency only for a current requirement and explain material cost or tradeoffs. Prefer existing utilities over another package.
- Track placeholder `.env.example` values and ignore real secrets. Validate environment variables without printing them.
- Never log passwords, session tokens, quest notes, or raw private payloads. Sanitize errors and analytics; collect no task content by default.
- Treat export and deletion as authenticated owner-scoped workflows. Confirm destructive account actions in the product UI and preserve privacy in outputs.
- Verify current official framework/library documentation for version-sensitive APIs. Do not copy deprecated snippets or infer an API from memory when uncertain.
- WeatherAPI requests run through authenticated server-only code with a fixed HTTPS host, validated queries, rate limits, and redacted key-bearing URLs. Never expose `WEATHERAPI_KEY` publicly or proxy arbitrary client-supplied URLs/options.
- Follow the weather contract for entitlements, attribution, and hard expiry. Initial forecasts are transient caches, not Supabase records, Dexie outbox data, exports, backups, or permanent itinerary snapshots. Sync user location/unit settings separately; preserve the original fetch time across cache hits.
- Pexels queries use confirmed public destination/category context only, never private titles, notes, addresses, bookings, or attendees. Keep `PEXELS_API_KEY` server-only; validate provider page/image hosts and bounded queries, cache/coalesce calls, and respect rate limits.
- Persist photo references/credit/preferences, not photo binaries. Automatic image callbacks must check current context/mode and use the existing local command path. Do not silently add upload storage, optimizer/proxy costs, AI image inference, or live search to mutation replay.
- Planning-model requests are explicit, authenticated, online, bounded, and server-only; no model calls on mascot/panel navigation and no queued prompts. Minimize selected account context, validate structured output, preserve source revisions, and route accepted proposals through the existing editor/save path. Models cannot execute changes, grant XP, or publish content; ignore stale/cross-account responses and keep the calendar usable when AI fails.

## Creator publishing invariants

- Private calendar/account data and public creator aliases/series are distinct. Allowlist public fields; owner previews, draft links, unpublished manifests, and preview media URLs cannot enter shared public caches or anonymous responses. Published reader manifests/short-lived URLs require current server eligibility checks and remain uncached initially.
- A recurring cadence supplies slots, not finished content. Freeze a ready canonical chapter version only after explicit online scheduling acknowledgment. Confirm local release time/IANA zone and preserve accepted UTC targets across profile/cadence changes.
- Use a bounded server due-release job with transactional locks, unique publication events, revisions, and receipts. Empty/incomplete slots never publish; retries cannot duplicate releases. Resolve cancel/publication races truthfully.
- Keep hosted draft/scheduled artwork in private Storage. Verify current series/chapter/version eligibility before signing bounded reader URLs. Never sign arbitrary object paths, expose privileged credentials, or overwrite scheduled/published objects. Withdrawal stops new access; do not promise instant recall of issued URLs or downloaded copies.
- Upload transfers are distinct from metadata sync; enforce owner/path/type/byte/dimension limits, finalization, immutable versions, and retryable orphan/account-deletion cleanup. Do not persist artwork bytes or upload/signed tokens in the ordinary Dexie queue.
- External chapter scheduling controls only Gamecal card visibility. Validate HTTPS URLs without fetching arbitrary hosts; do not imply publication control over other platforms.
- Production quests reference existing occurrences and obey existing XP rules. Publishing and reader behavior cannot alter progression or duplicate calendar entries.

## Verification and completion

- Inspect `package.json` first; use existing scripts. Planned scripts in the technical doc are contracts to establish at bootstrap, not commands that already exist.
- For code changes, run relevant lint/type checks and focused tests. For framework/configuration changes and release readiness, include a production build.
- CI must fail on maintained-code type/typed-lint errors, stale generated database types and failed boundary-contract checks. Add compile-time negative cases for meaningful command/ID mixups and runtime cases for malformed RPC/provider/persisted payloads, unexpected variants, null/omitted fields and bigint precision. Type-check test files too; fixtures must not bypass validation with unsafe casts. The narrow exception for `@ts-expect-error` is a documented dedicated negative type test that fails if the expected compiler error disappears. A passing compiler alone is not an end-to-end safety claim.
- Test domain rules with unit tests, persistence/auth invariants with database tests, and the critical cross-layer journey with browser tests.
- Cover meaningful risks: duplicate rewards, undo, concurrency, recurrence edits, DST, stale revisions, and cross-account requests. Do not write tests that only mirror implementation details.
- For publishing work, also verify browser-closed releases, early anonymous/direct access, storage ownership, cancellation races, immutable manifests, external-link behavior, reader accessibility, upload recovery/quotas, and media cleanup. Use the creator plan's separate pilot gates.
- For UI changes, verify responsive behavior and accessibility in a browser when available. State what was actually observed and what remains unverified.
- Docs-only work needs content/link checks; do not install an app or invent a passing test run to validate Markdown.
- If a check cannot run, state the missing dependency/configuration and preserve a runnable next step. Never disable checks merely to make the result green.
- Update affected docs when contracts or scope change. Report what changed, why, validation performed, and any material remaining issue; avoid claiming unperformed deployment or tests.
