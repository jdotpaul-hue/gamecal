# Gamecal Software Design Principles

**Updated:** 16 October 2026

**Decision:** Adopt CUPID as the software design baseline, with explicit domain boundaries and the [data architecture](DATA_ARCHITECTURE.md). This refines the planned implementation; it adds no runtime, dependencies, tables, or deployed services.

**References:** [Technical design](TECHNICAL_DESIGN.md), [coding guide](AGENTS.md), [product plan](PRODUCT_PLAN.md), [API contracts](API_CONTRACTS.md), and [data architecture](DATA_ARCHITECTURE.md).

## 1. CUPID applied to Gamecal

CUPID's original properties are Composable, Unix philosophy, Predictable, Idiomatic and Domain-based. We use them as design and review questions. Domain-based language supports a practical domain-driven approach; it does not require a particular class hierarchy or deployment pattern. Reference: [Dan North's CUPID article](https://dannorth.net/blog/cupid-for-joyful-coding/).

| Property | Gamecal practice | Review question |
| --- | --- | --- |
| Composable | Functions accept explicit values and return typed results; feature operations reuse scheduling, validation and sync behavior through small documented entry points | Can another real caller use this without inheriting UI state or hidden side effects? |
| Unix philosophy | A module/operation has one clear product purpose, including the work needed to finish that purpose safely | Is its complete outcome easy to explain? |
| Predictable | Explicit clocks/zones/revisions, visible state transitions, bounded work and stable retry/error behavior | What happens on retry, concurrency, missing coverage, or failure? |
| Idiomatic | Use established TypeScript, React, Next.js, PostgreSQL and Dexie conventions for the installed versions | Would a developer familiar with this stack recognize the approach? |
| Domain-based | Name and group code around schedules, occurrences, rewards, itineraries and accounts | Can a product discussion locate the relevant code directly? |

Completing a quest and awarding its reward is **one logical outcome**. Its occurrence, reward and receipt writes stay in one database transaction. Composability cannot justify splitting an invariant across independently failing network requests.

## 2. Application shape and domain boundaries

Use one modular Next.js application backed by Supabase. Modules have clear ownership inside the application; their boundaries do not require separate servers. The existing `src/features` organization remains the starting point.

| Boundary | Owns | Collaboration |
| --- | --- | --- |
| Planning | Definitions, schedule versions, occurrences, date/time rules and quest/appointment transitions | Calendar UI and quest operations share this model; designate one owner for each scheduling rule |
| Progression | Reward eligibility/amount policy, accepted reward interpretation, levels/milestone presentation | Completion/undo composes with its canonical SQL logic in the same transaction |
| Itineraries | Trip envelope, membership, logistics and selected weather locations | References Planning occurrences; delegates schedule/status changes to their existing operations |
| Account | Profile preferences, verified identity integration, export and account lifecycle | Supabase owns credentials; deletion uses the operating workflow |
| Sync | Durable queue, projections, dependencies, transport, reconciliation and coverage | Dispatches named feature commands; canonical business decisions remain server-owned |
| Integrations | Weather/photo/model request validation, normalization and bounded provider access | Produces data or reviewed proposals for a feature; does not bypass its command boundary |
| Operations | Budgets, deletion jobs, recovery and operator controls | Separate restricted system permissions and retention from ordinary account data |
| Publishing, later | Creator drafts/versions, release state and public reader projections | Private production links reference Planning; public publication has its own access boundary |

Room/motion/mascot rendering consumes accepted state. It does not own reward calculation, persistence, or scheduling. Creator and radio gates remain unchanged.

The Planning boundary can span the existing `features/calendar` and `features/quests` folders. Calendar owns navigation/view composition; quest operations own definition/occurrence actions. Keep one shared implementation of pure schedule rules in the calendar feature rather than maintaining one per view. Folder names are implementation guidance, not extra runtime layers.

## 3. Dependencies and side effects

- **Domain rules:** pure TypeScript and explicit date/value inputs. Keep React, browser storage, network clients and environment secrets out. Supply time and zones explicitly rather than reading an ambient device timezone.
- **Application operations:** validate an intention, obtain IDs/action timestamps once, build the typed command, and persist it through the shared local transaction. Record dependencies/revisions explicitly.
- **Adapters:** own Dexie operations, Supabase RPC transport, server Auth and provider fetch/normalization. Map errors/DTOs at these boundaries; generated database types stay close to SQL-facing code.
- **Presentation:** components compose feature hooks/operations and render named states. Ordinary clicks save through the application operation; synchronization effects manage external lifecycles rather than inventing a second mutation path.
- **Canonical SQL:** final ownership, transitions, revisions, receipts and cross-table invariants follow the schema/RLS/API plans. Pure client previews do not supersede canonical validation.

Use direct functions and concrete adapters initially. Add a narrow interface when a real replacement or meaningful test seam needs it. Extract shared code when two real uses share the same semantics; proximity in field shape alone is insufficient.

## 4. Naming and module interfaces

Prefer operations such as `completeOccurrence`, `unskipOccurrence`, `attachItineraryEntry` and `resolveSchedule`, rather than a generic `updateData` command. Keep the existing RPC names and wire contracts; TypeScript naming does not rename tables or endpoints.

Use explicit concepts for local dates, wall times, IANA zones, UTC instants, revisions and sync epochs where mixing them could produce a bug. Validate values at entry boundaries. A TypeScript alias or cast alone does not establish that a string is a valid date/UUID/zone.

The stored `quest_*` tables represent both quests and appointments through `entry_kind`. UI/domain names must expose that distinction; explain legacy storage names at the adapter boundary. Do not infer reward eligibility from a table name or create a second appointment schedule.

Expose a feature's small operations/types rather than importing private implementation files across features. Keep related UI/rules/operations near their feature; genuinely shared controls stay in `components/ui`, and storage/transport mechanisms stay in `lib`. Avoid circular feature imports and an ever-growing shared business-logic utility file.

## 5. Predictability and proof

Return typed success/failure results with actionable recovery. Distinguish durable local save, unknown server acceptance, accepted canonical state and conflict; do not collapse them into one loading boolean.

Use a new operation ID for a new deliberate intention and preserve the frozen request for an ambiguous retry. Generation, projection and reconciliation must tolerate interruption. Make cost, page/window size, timeout and retention bounds visible in the relevant contract rather than implicit inside a component.

Verify pure rules with outcome-based fixtures, adapters with actual boundary behavior, canonical writes with local database/RLS tests, and the first user journey in a browser. Test shared TypeScript/SQL behavior for recurrence/time boundaries and rewards; do not claim that an isolated mock proves transactional correctness. The webapp scaffold contains initial helpers and boundary tests; database transactions and the product user journey remain unproven.

## 6. Change review checklist

For an affected feature, a reviewer should be able to identify:

1. Its product purpose, owning module and public operation.
2. Its inputs, output, validation and observable side effects.
3. Which data is authoritative, pending, cached, derived or external.
4. Which invariants require a transaction and which reads may be eventually consistent.
5. Retry/concurrency/error behavior and the user's recovery path.
6. Evidence appropriate to that behavior, including performance/access isolation when affected.

Record a material boundary/storage/security/consistency change in the owning design document with its reason, tradeoff and verification. Keep the first implementation focused on the existing profile -> one-off quest -> complete/undo -> reconcile slice. This design baseline does not expand release scope or authorize a database connection.
