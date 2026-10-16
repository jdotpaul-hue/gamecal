# Gamecal Data Architecture Principles

**Updated:** 16 October 2026

**Status:** Adopted planning baseline. This document defines data ownership and design principles; [DATABASE_SCHEMA_PLAN.md](DATABASE_SCHEMA_PLAN.md) owns exact SQL fields/relationships and [API_CONTRACTS.md](API_CONTRACTS.md) owns wire shapes. The planned thirteen-table pilot model is unchanged and no SQL schema exists. The webapp scaffold has account-partitioned IndexedDB metadata only; the authoritative application records/outbox remain unimplemented.

**Related:** [Software design](ARCHITECTURE_PRINCIPLES.md), [technical design](TECHNICAL_DESIGN.md), [RLS](RLS_PLAN.md), [local sync](LOCAL_SYNC_DESIGN.md), and [operations](OPERATIONS_PLAN.md).

## 1. One authority for each kind of fact

Supabase PostgreSQL is authoritative for accepted account data and rewards. IndexedDB is authoritative for whether an unsent local intention was durably recorded on that browser. Those are different facts: a local completion is not an accepted reward.

| Data class | Owner / authority | Copies and limits |
| --- | --- | --- |
| Identity/credentials | Supabase Auth | Application profile references the Auth UUID; no second credential table |
| Accepted schedules/outcomes | Planning's canonical PostgreSQL records | Versioned, account-scoped local snapshots plus pending overlays |
| Rewards | Canonical completion/reward transaction | Accepted totals/levels are derived; local summary is a labeled cache, never a writable XP balance |
| Trip organization | Canonical itinerary/membership/settings records | References shared occurrences; no second editable time/status/reward |
| Pending intentions | Account-partitioned Dexie outbox until reconciliation | Frozen payloads, dependencies and observed revisions; protected from automatic eviction |
| Provider forecasts/search batches | External provider, normalized transient cache | Bounded freshness/expiry; no forecast archive in SQL, outbox, exports or backup |
| Selected locations/photo references | User-controlled profile/itinerary settings | Small validated metadata follows the normal account command path; images remain remote |
| AI proposals | Untrusted, session-scoped proposed values | Review/editor/save produces the ordinary intention; a proposal has no mutation authority |
| Operating records | Restricted server workflows | Budgets/deletion jobs and private markers have explicit exceptions to domain retention/FKs |
| Uploaded art, later | Private Supabase Storage and canonical version manifests | File bytes live in object storage; SQL holds validated references/readiness; file-path strings are not portable attachments |

Read caches, projections and exports must identify scope, completeness, version and relevant time context. Never infer a global empty/deleted state from missing or partial cached rows.

## 2. Conceptual, logical and physical models

- **Conceptual:** a definition supplies a versioned schedule; an occurrence is one scheduled commitment; a quest can earn one active reward; an itinerary groups existing occurrences.
- **Logical:** stable IDs, ownership, kind/status vocabularies, version/parent relationships and permitted transitions express those concepts. Historical snapshots and accepted outcomes survive template changes under the documented rules.
- **Physical:** PostgreSQL constraints, indexes, role grants/RLS, functions and bounded query shapes implement the logical model. Dexie indexes/stores serve local projection/recovery, not a second independently editable canonical model.

The schema's nine user-readable plus four internal pilot tables remain authoritative. A feature boundary is not a promise that each table is a separate module/service. One transactional use case may coordinate several owned records.

## 3. Normalize mutable facts and justify snapshots

Store current business facts once and refer to stable parent identities. Use normal typed columns for ownership, schedules, revisions, status and queried fields. Use bounded validated JSONB only for the documented variable metadata/results.

Intentional duplication needs an explicit purpose:

- Owner IDs on child rows support indexed isolation and composite ownership constraints.
- Occurrence snapshots preserve the schedule/content applicable to that commitment, with deliberate occurrence edits allowed by the command contract.
- Reward amount/rule version preserves the accepted award through later policy changes.
- Read summaries/projections accelerate bounded screens and are rebuildable from canonical data and retained intentions.

For each denormalization, specify the source, writer, transaction/update rule and rebuild/invalidation path. Do not maintain a trip-specific event schedule, writable level balance, or competing per-component copy of task status.

## 4. Identity, time and valid relationships

Use stable UUIDs rather than labels/titles for joins. Preserve deterministic occurrence identity across rescheduling. Distinguish entity revision, account snapshot counter, operation ID and sync epoch; none substitutes for verified ownership.

Represent local dates, wall times, IANA zones and UTC instants separately. Preserve endpoint meaning and the action's observed completion zone; database acceptance time is separate. Use the existing all-day, DST, date-line and future-routine rules. Persist resolved/validated instants rather than trusting a browser's interpretation.

Enforce row bounds with NOT NULL/CHECK, identity/cardinality with keys/unique constraints, ownership/parents with composite foreign keys, and nonoverlapping schedule versions with the chosen exclusion constraint. Use transactional transitions and deferred checks for cross-table reward consistency. PostgreSQL's [constraint documentation](https://www.postgresql.org/docs/current/ddl-constraints.html) distinguishes these mechanisms; cross-table business invariants are not ordinary row CHECKs.

Frontend validation helps the user correct input; transport validation rejects malformed DTOs; SQL protects durable invariants against every caller. Keep overlapping rules consistent through shared contracts/fixtures, including TypeScript/SQL date and recurrence parity. Generated types alone do not validate runtime input.

Follow [the end-to-end type-safety boundary contract](TECHNICAL_DESIGN.md#end-to-end-type-safety): schema-inferred wire DTOs, generated SQL-facing types, explicit domain/persistence mappings and versioned decoding of rehydrated browser records. A typed database client or Dexie table does not validate arbitrary runtime JSON. Keep unsupported/malformed pending records recoverable instead of coercing or deleting them.

## 5. Explicit consistency and transactions

| Boundary | Required consistency |
| --- | --- |
| Local command/projection metadata | Atomic IndexedDB save before saved-on-device feedback |
| Completion, reward, revisions, receipt and account counter | One canonical database transaction |
| Itinerary attachment and newly created appointment | One command transaction using shared occurrence identity |
| Multiple snapshot pages | Same validated epoch/counter/scope/as-of, or restart; generation completeness separately reported |
| Browser versus cloud during an interruption | Eventually consistent, visible pending state and retained intention |
| Forecasts/photos/AI generation | Independently available enrichment; no part of the calendar mutation transaction |
| Auth deletion and object cleanup | Retryable operating workflow across service boundaries, with truthful intermediate states |

Use the defined owner-first domain lock order and revision guards. Request-budget locks precede domain locks as documented. A sequence of HTTP requests is not a transaction. A stale revision requires review, and a replayed receipt reports its historical acceptance separately from current canonical state.

Keep one durable outbox and bounded snapshot pulls. This is enough for the planned MVP; a domain event bus, full event-sourcing ledger, generic CQRS framework or extra analytical store needs a concrete requirement before introduction. Mutation receipts provide retry evidence rather than a complete edit-history event stream.

## 6. Access, privacy and lifecycle

Grants control available operations, RLS controls row visibility, constraints protect relationships, and command validation protects transitions. Follow the restricted roles/read RPCs in [RLS_PLAN.md](RLS_PLAN.md); a UI route guard is insufficient. See [Supabase RLS guidance](https://supabase.com/docs/guides/database/postgres/row-level-security).

Treat account content, operational metadata, public publication projections and external provider data as distinct access classes. Public reader DTOs are allowlisted. Provider keys and privileged credentials stay server-only; notes/prompts/bookings are excluded from ordinary logs and analytics.

Retention follows the owning contract: pending work survives keep-work sign-out, caches can be safely evicted, forecasts expire, tombstones/receipts remain for the MVP lifetime, and operating jobs/markers follow their limited retention. Auth deletion deliberately removes canonical account data while independent recovery records survive as specified. Database backups and uploaded object bytes require their separate recovery mechanisms. A user export is not the operator backup.

## 7. Evolution, performance and evidence

Version SQL migrations, local schemas, command envelopes, DTOs and export formats. Preserve compatibility with retained frozen requests or pause them for explicit recovery; never silently reinterpret them. After database restore, use the existing deletion-marker reconciliation and new sync epochs before access.

Index measured owner/date/join paths; paginate and bound windows. Inspect representative query plans and RLS cost before adding indexes or changing limits. Keep exact limits in the API/operations plans so they can be tuned in one place. Collect safe counts/latency/error codes rather than private payloads.

Before a new persisted field or store is accepted, record its domain owner, meaning, source/writer, validation/invariants, access class, retention/deletion/export behavior, consistency requirement and query/index need. Extend the existing model when it already expresses the same fact.

Prove meaningful outcomes: cross-owner access denied, one reward per occurrence, retries after undo, partial scopes not accepted as complete, timezone parity, preserved queues on quota/migration failure, and safe restore/deletion recovery. Current document/link checks are not evidence that those runtime properties pass. Build the authorized local vertical slice before expanding the model.
