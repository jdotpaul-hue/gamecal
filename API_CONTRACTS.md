# Gamecal API Contracts

**Updated:** 14 October 2026

**Status:** Calendar/provider endpoint and SQL planning baseline. The [webapp foundation](webapp/README.md) now has generated-type clients, local calendar foundation RPCs and initial runtime schemas; complete Auth/sync and broader assistant/provider routes remain unimplemented. Current read/validation bugs are in [the review register](DOCS_REVIEW.md#7-review-of-commits-35b6a5b-and-6a160ed). This brainstorming pass adds no code, migrations, provider connection or deployment.

**Related:** [Product scope](PRODUCT_PLAN.md), [database structure](DATABASE_SCHEMA_PLAN.md), [RLS/grants](RLS_PLAN.md), [local sync](LOCAL_SYNC_DESIGN.md), [technical design](TECHNICAL_DESIGN.md), [itineraries](ITINERARY_PLAN.md), [weather](WEATHER_PLAN.md), [photos](PHOTO_PLAN.md), [planning assistant](UI_UX_PLAN.md), and [creator publishing](CREATOR_PLAN.md).

**Screen/acceptance mapping:** [FIRST_SESSION_PLAN.md](FIRST_SESSION_PLAN.md) turns the first API slice into account/setup, quest editor, completion/undo, pending-sync and recovery states. An accepted first completion is 20 XP; no early room unlock or model action is implied.

**Operating contract:** [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md) specifies retained sign-out queues, cache cleanup, deletion jobs/status, shared request budgets and operational restore. Ordinary browser reads use allowlisted POST RPCs; owner SELECT grants support those invoker functions, while the Data API hook denies direct table endpoints.

**Assistant personalization extension:** [PERSONALIZATION_PLAN.md](PERSONALIZATION_PLAN.md) defines the proposed charter/rule/memory/permission/teaching behavior. Exact request/response schemas are a subsequent design task, not implemented endpoints. Changes need owner identity, correlated typed inputs, expected revisions, durable operation IDs and explicit local-versus-accepted results. A proposal references the relevant settings/source revisions; trusted execution rechecks current permissions and constraints. Imported templates never grant authority, and settings edits do not implicitly execute a calendar action.

**Knowledge extension:** [SECOND_BRAIN_PLAN.md](SECOND_BRAIN_PLAN.md) proposes explicit capture/save, automatic organization/linking, source-linked retrieval and Markdown export/import. Exact RPCs/routes are not specified or implemented yet. The organizer applies reversible generated summaries/topic/mention links without per-item approval, using authenticated scope, source/target validation, revision fencing and idempotent processing identities. Corrections/unlinks constrain reprocessing; consequential ambiguity is selectively clarified. Distinguish note save from model processing, derived indexing, approved memory promotion and each calendar action; return independent results for multiple intentions. Search needs authenticated bounded scope, source revisions/eligibility and citations. Frontmatter, imported IDs and note text cannot execute commands or establish ownership. Notes export is not restoration of pending calendar operations.

## 1. API ownership and first delivery

| Boundary | Owns | Does not own |
| --- | --- | --- |
| Supabase Auth | Sign-in, verification, recovery, session refresh | A second custom password/session API |
| Supabase Data API + named PostgreSQL RPCs | Owner reads, canonical commands, receipts, progression, consistent scope reads | Public table writes or generic arbitrary-SQL commands |
| Next.js Route Handlers | Authenticated WeatherAPI/Pexels requests, AI planning generation, deliberately privileged account workflow | A duplicate REST CRUD layer around the same calendar tables |
| Browser application operations | Runtime validation, atomic Dexie enqueue, pending projection, retry/reconciliation, proposal review | Authoritative rewards, ownership, or publication time |

Use Supabase's documented [RPC client](https://supabase.com/docs/reference/javascript/rpc) to call the public invoker wrappers in the RLS plan. Each wrapper delegates to its exact unexposed implementation. Next.js provider routes use the installed version's [Route Handler conventions](https://nextjs.org/docs/app/getting-started/route-handlers). The interfaces below are our proposed contracts, not a promise that every listed feature exists.

First implement **ensure profile -> create one-off quest -> read scope -> complete -> undo -> reconcile after an interrupted connection**. Recurrence, itineraries, weather, and AI extend that proven path. Creator/public reader APIs are a separate later gate; radio has no endpoint while parked. No WebSocket, generic gateway, batch mutation engine, or new backend service is required.

## 2. Wire conventions and validation

All named RPC wrappers have one explicitly named `request jsonb` parameter and return one JSON object. The application calls `rpc(name, { request })`; the serialized HTTP body therefore contains that outer `request` field. A JSON parameter enables a versioned envelope but does **not** allow arbitrary fields/tables/actions. Each function validates a narrow schema independently. Use no ambiguous overloaded signatures or unnamed JSON fallback. See [PostgREST function inputs](https://docs.postgrest.org/en/stable/references/api/functions.html).

Budget-accounted exposed wrappers are POST-only and `VOLATILE` to permit the pre-request counter write; do not mark them STABLE merely because their domain result is a read. Snapshot selection/token verification remains one SQL snapshot. The operations plan also closes unused GraphQL/Realtime alternatives before pilot access.

| Value | Wire rule |
| --- | --- |
| Contract/schema version | Integer `contract_version: 1`; persisted commands also record this version |
| UUID | Canonical UUID string; generate entity IDs before enqueueing; derive occurrence UUID by the fixed shared namespace/date rule |
| Entity revision / account snapshot counter | Canonical decimal **string**, e.g. `"4"`; never convert bigint counters to a JavaScript Number |
| Sync epoch | Server-owned UUID from the accepted profile; ordinary commands and snapshot tokens carry it; bootstrap uses null |
| Date | Strict valid `YYYY-MM-DD`, with documented inclusive/exclusive boundaries |
| Wall time | Strict `HH:mm:ss`; optional seconds normalize to `:00` before freezing a command |
| Zone / instant | Valid IANA name; RFC 3339 UTC instant ending in `Z` for observed/audit times |
| Missing / null | Omitted patch field means unchanged; explicit null clears a nullable field; creation requires explicit normalized defaults |
| Numbers | Finite bounded values only; no NaN/Infinity; preserve nullable provider readings rather than inventing zero |
| Text / URL | Bounded domain fields; trim title edges, preserve meaningful note newlines; HTTPS links only where the feature contract requires them |

Reject unknown/protected request fields, unsupported versions, malformed dates/zones, duplicate array identities, and oversized inputs. Parse decimal revisions strictly, with signed-bigint bounds, and compare without precision loss. RPC DTOs explicitly cast counters/revisions to text; generated database types alone do not prove wire correctness. Owner SELECT grants support invoker RPCs; the Data API hook denies direct table endpoints, and application DTOs preserve bigint-sensitive values.

**Typed implementation contract:** Each command owns a versioned runtime request schema and expected success-response schema, with TypeScript DTOs inferred from those schemas and a correlated command-name/payload union. Validate tagged canonical records individually. Type the Supabase client from the generated local database definitions, but treat JSON/JSONB envelopes as `unknown` until decoded; a cast or SDK return-type override is not evidence of validity. Normalize SDK/PostgREST failures through the existing error adapter. An unrecognized/malformed response preserves the frozen pending command and confirmed state for reconciliation; it must not be acknowledged as a successful local sync or rewritten into a new attempted payload. See [the technical boundary contract](TECHNICAL_DESIGN.md#end-to-end-type-safety).

No request can set `owner_id`, another account, XP, level, reward amount/rule, server acceptance timestamps, account counters, raw row revisions, privileged credentials, or arbitrary SQL/objects. Supplying the observed sync epoch is a guard, not permission to update the profile's epoch. Schema versions stay compatible with retained frozen outbox commands; incompatible requests return a recoverable `unsupported_contract`, never silent reinterpretation.

Proposed initial bounds: 64 KiB mutation body, 200 records maximum per snapshot page, 42 local dates per calendar materialization/read window, 5,000 note characters, 200 title characters. Reject excessive values rather than silently truncating a requested complete scope. Body byte limits and type validation apply at the real database/provider boundary, not only in forms. Tune performance limits with tests before pilot release.

## 3. Mutation envelope, receipts, and response

Every durable domain command uses `contract_version`, `operation_id`, `sync_epoch`, `expected_revision`, and command-specific `data`. Profile bootstrap alone uses `sync_epoch: null`; other commands require the UUID captured from the verified profile. Creation uses `expected_revision: null`; updates require the revision observed by the editor or acknowledged predecessor. Commands that depend on additional aggregates also require a named `expected_related_revisions` object. It is not a caller-selected list of arbitrary database rows.

Example **inner request** to `create_quest` (sample date/content/IDs):

```json
{
  "contract_version": 1,
  "operation_id": "761e5305-4569-4ba4-82fb-d2088143fe4c",
  "sync_epoch": "e6cb04be-6d6c-4b23-9f10-c16e4ef52e8d",
  "expected_revision": null,
  "data": {
    "definition_id": "fda923dc-3ebd-489e-a655-37e04fef3163",
    "schedule_version_id": "84915f93-ef45-4617-a753-0b072ab89ccd",
    "entry_kind": "quest",
    "title": "Practice sketching",
    "notes": null,
    "category": "learning",
    "priority": "side",
    "blocks_time": true,
    "schedule": {
      "anchor_date": "2026-10-14",
      "planning_timezone": "Asia/Singapore",
      "timing": {
        "kind": "timed",
        "start_local_time": "10:00:00",
        "end_local_time": "10:30:00",
        "start_ambiguity_choice": null,
        "end_ambiguity_choice": null
      },
      "recurrence": { "kind": "none" }
    }
  }
}
```

The server derives/materializes the same deterministic occurrence ID as the client and returns it. Creation is one transaction, not independent definition/version/occurrence inserts. Completion sends its new operation ID, occurrence source reference, expected revision, `observed_at`, and `observed_timezone`; it sends no XP or resulting status field.

Successful response envelope:

| Field | Contract |
| --- | --- |
| `ok`, `contract_version` | `true`, `1` |
| `acknowledgment` | Operation ID, fixed command name, `replayed` boolean, original server `accepted_at`, original affected entity IDs/accepted revisions, original accepted outcome |
| `canonical` | Current `sync_epoch`, account counter as a string, bounded tagged owner records needed for this action, and current accepted progression when relevant |
| `invalidations` | Explicit affected calendar/date/definition/itinerary scopes requiring a fresh complete pull; never an unrestricted entity selector |

The historical acknowledgment and **current** canonical data are distinct. A lost completion response retried after a later undo returns the original acknowledgment and the current pending/reversed canonical state. It cannot reactivate XP. Original accepted revisions remain the base for already queued dependent intentions; a newer canonical revision cannot silently replace their base and authorize an overwrite.

Tag each canonical record as `{ "entity": "quest_occurrence", "record": { ... } }`, with an allowlisted entity-specific DTO matching the schema plan. Minimum occurrence fields: ID/owner/definition/version IDs, original/effective date, content/kind/timing snapshots, UTC anchors, status/completion fields, decimal revision, timestamps/tombstone. Reward DTOs carry their original amount/rule/reversal; profile/itinerary/etc. DTOs use their own documented fields. No unrestricted database row dump or provider payload.

Bound command reconciliation: complete/undo returns its occurrence, relevant reward, profile counters and progression; create returns its root definition/version/occurrence. A series or itinerary cleanup may affect too many rows for one command response: acknowledge its canonical roots and invalidate dependent scopes. The sender removes a pending projection only once the canonical replacement/invalidation is durably recorded. Mark invalidated cached scopes as refreshing/incomplete and fetch missing dependent revisions before transmitting further dependent commands; never show stale rows as a complete accepted result.

The sender freezes the normalized request **before first transmission**. Ambiguous retry uses the same operation ID and exact normalized payload/revisions. Server receipt hash covers the command name/version and canonical validated request, excluding transport request IDs/server timestamps. Changed data under the same operation ID returns `operation_payload_mismatch`. No per-request mutation timestamp generated during retries.

## 4. Calendar and profile RPC catalog

Names below are stable proposed public wrappers; typed feature helpers hide transport details from components. All mutations follow the envelope/receipt rules; each target is authorized from `auth.uid()`, not the client account partition.

For occurrence commands, the table's “occurrence ID” is shorthand for a required `occurrence_ref`: `{ id, definition_id, original_scheduled_date, expected_schedule_version_id }`. These are the cached canonical source identifiers, not content supplied to replace the record. Validate the deterministic ID and owner/version/definition relationship before accessing the occurrence. If a locally generated recurring occurrence is not yet materialized, validate its date and source against the canonical series, then materialize it inside the command transaction before its transition. Its creation revision is `"1"`; never assume that an existing remotely edited row still has that revision. If the series now assigns a different version or excludes that date, return a source-schedule conflict requiring review, rather than completing a different canonical task that happens to share the date/ID.

| RPC | Command-specific data and precondition | Accepted behavior |
| --- | --- | --- |
| `ensure_profile` | Display name, confirmed planning zone and normalized initial preferences; expected null | Create own profile if absent; existing profile returned without overwriting preferences; bootstrap receipt handled atomically |
| `update_profile` | Allowlisted preference/home-weather patch; expected profile revision | Update only deliberate fields; profile-zone change does not implicitly rewrite schedules/history |
| `create_quest` | Definition/version UUIDs, content and schedule; expected null | Create either quest or appointment using its kind; materialize its one-off or anchor occurrence and return identities |
| `edit_occurrence` | Occurrence ID, allowlisted content/timing patch; expected occurrence revision | Edit the shared snapshot, retaining original identity; completed-kind change requires undo |
| `edit_series` | Definition ID, new version UUID, effective date and complete future template; expected definition revision | Close/split/reconcile versions; preserve historical/completed/skipped outcomes; future scope invalidated |
| `complete_occurrence` | Occurrence ID, observed UTC time and confirmed observed zone; expected occurrence revision | Pending -> completed; valid quest activates its one server reward; appointment -> attended with zero XP |
| `undo_occurrence` | Occurrence ID; expected occurrence revision | Completed -> pending; reverse its active reward and clear active completion fields |
| `skip_occurrence` | Occurrence ID; expected occurrence revision | Pending -> skipped; zero reward |
| `unskip_occurrence` | Occurrence ID; expected occurrence revision | Skipped -> pending; zero reward, unchanged identity/source and no completion fields; stale state conflicts |
| `reschedule_occurrence` | Occurrence ID and complete valid replacement timing/date; expected occurrence revision | Move a pending occurrence, never recreate the original date or change ID |
| `delete_occurrence` | Occurrence ID; expected occurrence revision | Tombstone and reverse reward; tombstone active itinerary memberships; confirmation belongs in editor UI |
| `archive_series` | Definition ID, explicit effective local date; expected definition revision | Stop future scheduling, tombstone affected pending future instances, preserve past outcomes/rewards |
| `materialize_calendar` | Date window plus optional bounded historical catch-up request; no entity CAS | Validate/generate canonical eligible instances idempotently and return coverage; no reward; receipt/counter when changed |
| `save_reflection` | Reflection UUID, Monday week date, zone, bounded takeaway/next-action; expected null on initial create or current revision on edit | Save one owner/week record, with no XP |
| `delete_reflection` | Reflection ID; expected reflection revision | Tombstone own reflection |
| `restore_reflection` | Existing tombstoned reflection ID and reviewed replacement text; expected current revision | Explicit same-week restore; stale save cannot revive it |

Already-completed with a different new operation ID is `invalid_transition`, not an additional reward; an identical receipt retry succeeds. Another active record with a supplied creation ID returns a generic identity/conflict outcome, not an overwrite. Materialization and bootstrap are the only listed commands without a normal existing-entity CAS; their own uniqueness and transactional locks still apply.

Every schedule uses a discriminated timing object: `untimed` has no clocks; `timed` has a starting wall time and optional end; `all_day` has an exclusive end date. One-off appointments can supply a distinct local end date/zone and explicit ambiguity choice. Single-day recurring entries reuse the day's local date. Recurrence is `none`, `daily` with optional inclusive `until`, or `weekly` with sorted unique ISO weekdays 1–7 and optional inclusive `until`. Reject incompatible endpoint/recurrence combinations; compute/verify UTC on the server under the existing DST policy.

Timed objects normalize `start_ambiguity_choice` and `end_ambiguity_choice` to null or `earlier`/`later`. One-off appointments require a choice for each ambiguous endpoint, show the resulting UTC offset, and reject nonexistent booked wall times until corrected; unambiguous/missing endpoints use null. Store those choices in versions/occurrence snapshots. Routine quests/recurring entries use null plus the shared policy: shift a gap by its actual offset change and choose the earlier fold instant. A timed interval invalid after resolution requires correction. All-day quests have exclusive end = effective date + one calendar day and `due_at` at that end date's first valid local instant; no invented 24-hour duration. All-day appointments can span dates and do not participate in quest overdue metrics.

Changing `planning_timezone` through `update_profile` changes display/new-entry defaults only. The separate Review future routines action previews selected active quest series and sends one `edit_series` per confirmed series, preserving local clock/weekday rules. Its initial effective boundary is the later of tomorrow's local date in the old series zone and tomorrow's local date in the selected new zone, so the preview does not move an elapsed commitment into a past instant. It does not offer a bulk atomic rewrite or a preserve-instant recurring mode; fixed appointment instants/history remain unchanged. Partial acceptance is shown per series, and stale queued boundaries require review.

Use whole-field replacement for a complex schedule/location object rather than an ambiguous nested patch. Flat content patches may omit unchanged fields. Historical series selection applies a future template from today as the documented UI proposes; a stale offline series boundary is a conflict requiring review, not silently moved to acceptance day. Simple occurrence editing remains distinct.

## 5. Scope reads, progression, and pagination

All owner RPC reads take `contract_version: 1` and fixed-function `data`; no operation receipt is needed. Use POST RPC calls for consistent JSON inputs. **Read functions perform no domain materialization/mutations**: the sync controller calls the explicit bounded materialization command first where needed. Internal request-budget accounting is the only read-request write and does not change account snapshots.

| RPC | Scope/input | Result |
| --- | --- | --- |
| `get_profile` | No account ID | Own profile DTO / bootstrap-needed state |
| `get_calendar_scope` | Inclusive `from_date`, exclusive `until_date`, display IANA zone, page size, cursor/snapshot token | Bounded calendar snapshot, intersecting appointment spans, relevant schedule versions/definitions/rewards, coverage and progression |
| `get_review_scope` | Explicit Monday week date/zone, bounded cursor/token | Eligible quest outcomes, related rewards/reflection, raw completion/consistency counts, explicit coverage; appointments excluded |
| `get_itinerary_list` | Active/archive filter and bounded cursor/token | Owner itineraries and pagination; no full-trip completeness claim |
| `get_itinerary_scope` | Itinerary UUID and bounded cursor/token | Complete trip metadata, memberships, all referenced occurrences/parents/rewards, including preparation outside envelope and continuations |
| `get_progression` | No owner/XP input | Decimal total XP/level, progress-to-next-level, derived milestone IDs, account token/as-of |
| `get_own_operation_result` | Operation UUID | Own accepted acknowledgment or `not_seen`; no private receipt table grant |
| `export_account_page` | Cursor/token and fixed export format version | Owner-only paginated full account snapshot; valid download only after all pages match |

Example **inner first-page request** to `get_calendar_scope`:

```json
{
  "contract_version": 1,
  "data": {
    "from_date": "2026-10-12",
    "until_date": "2026-10-19",
    "display_timezone": "Asia/Singapore",
    "page_size": 100,
    "snapshot_token": null,
    "cursor": null
  }
}
```

Response `ok: true`, version, and `data` contains:

- `scope`: exact normalized function-specific scope; do not substitute an account-wide scope or a smaller truncated window.
- `snapshot_token`: account UUID partition, server-owned `sync_epoch`, decimal `account_data_revision`, scope fingerprint and first-page `as_of` instant. The account part is server-derived; the token is a consistency marker, not authentication or a lock. Old restore epochs require review/restart, not substitution into queued requests.
- `records`: up to the requested bounded count of tagged DTOs. Use fixed entity-order plus ID keyset pagination; parents may be on other pages and membership is complete only after the final page.
- `next_cursor`: validated opaque cursor or null; cursor binds the same scope/token/order. Decode as untrusted input; never let a token choose another account, arbitrary table, SQL, or unbounded limit.
- `page_set_complete`: true only on the final page; `coverage` independently reports requested generation and historical catch-up completeness. A completed set of cached rows is not proof all obligations were generated.
- `summary`: first-page profile/progression or review aggregates from that same snapshot where relevant, labeled with `as_of`; no per-page moving denominator based on a later clock.

Each page verifies the token and selects its records in **one SQL snapshot**. An accepted mutation or materialization changes `account_data_revision`, so a subsequent page returns `snapshot_changed`; restart that confirmed pull and retain local pending work. Freeze time-derived review eligibility to first-page `as_of` during pagination. Proposed token expiry: five minutes; expired scope resumes from a new first page rather than interpreting old rows as current. No long-lived database transaction spans browser HTTP requests.

Do not materialize again between pages or retry bootstrap/preference updates on every page. A `not_seen` receipt lookup is not proof a concurrently executing command failed: resend the identical command and let the receipt/locks serialize it. A transport timeout/abort cannot certify rollback.

For full trips/exports larger than one window, paginate entities under the same snapshot token without narrowing membership to displayed days. Export JSON contains `export_format_version`, account, `snapshot_as_of`, complete records/history and accepted progression, excluding secrets, transient forecasts, internal raw receipts, and binary media. Interrupted/token-changed export does not offer a falsely complete file; the local recovery bundle remains a separate browser-only workflow.

## 6. Itinerary mutation contracts

These functions reuse the same command envelope and scheduler; they do not create an independent travel backend. Adding/linking preparation never automatically completes it. All ordinary itinerary changes queue locally and use the normal retry protocol.

| RPC | Inputs / revision guard | Behavior |
| --- | --- | --- |
| `create_itinerary` | Itinerary UUID, title, inclusive envelope, display zone, optional notes/destination/base weather; expected null | Create private trip; no copied events or rewards |
| `edit_itinerary` | Itinerary UUID and allowlisted fields; expected itinerary revision | Change envelope/settings without moving bookings |
| `archive_itinerary` | Itinerary UUID; expected itinerary revision | Hide from active list while preserving memberships/history |
| `delete_itinerary` | Itinerary UUID; expected itinerary revision | Tombstone trip, memberships and weather overrides; preserve calendar occurrences/rewards |
| `add_itinerary_appointment` | Itinerary UUID, new definition/version/membership UUIDs, standard appointment template and logistics; expected itinerary revision | Create the shared calendar appointment and membership atomically |
| `attach_itinerary_entry` | Itinerary/occurrence/new membership UUIDs, logistics; expected occurrence revision plus related itinerary revision | Attach existing occurrence; reject another active membership; no copied status/time |
| `edit_itinerary_entry` | Membership UUID, allowlisted logistics patch; expected membership revision plus related itinerary revision | Edit private notes/place/links, leaving schedule to occurrence commands |
| `detach_itinerary_entry` | Membership UUID; expected membership revision plus related itinerary and occurrence revisions | Tombstone membership; retain original occurrence |
| `set_itinerary_weather_location` | Itinerary UUID, target base or dated override, selected city/coords or explicit clear; expected itinerary revision and dated row revision/absence where applicable | Settings only; no forecast payload/API call during replay |
| `set_itinerary_cover` — optional | Itinerary UUID, mode, validated selection/context revision; expected itinerary revision | Store reference/credit or clear; stale auto/manual/none conflicts preserved |

Define itinerary revision as its metadata **and membership/weather-setting aggregate** version; structural membership changes also bump the linked occurrence revision. This guards delayed attach after detach/delete without adding a separate membership-generation table. Commands return the affected aggregate revisions, and update local known values atomically. Ordinary occurrence edits/completion do not bump unrelated itinerary metadata; their own shared occurrence revision is sufficient. Dependent queued requests use original accepted predecessor revisions, not whichever remote revision is newest.

Base location clear affects only the base; dated clear tombstones only that override. A new dated row uses its pre-generated UUID and expected absence; another active row is a conflict, not an upsert. HTTPS links are validated without server-fetching arbitrary hosts. Transport/lodging stay appointment-kind with zero XP; a real preparation task uses the normal quest path. No manual reorder command can silently alter chronological appointment times.

## 7. Errors, retries, and transport

Use one validated client result union across boundaries: `{ ok: true, ... }` or `{ ok: false, contract_version: 1, error: { code, message, recovery, field_errors? }, request_id? }`. Safe messages are UI copy, not raw SQL/provider details. `field_errors` gives bounded field paths/codes, never another user's record or a dumped input.

| Error code | HTTP target / recovery | Sender/UI behavior |
| --- | --- | --- |
| `validation`, `unsupported_contract` | 422 / review or upgrade | Preserve draft/queue; correct deliberately with a new operation ID |
| `unauthenticated` | 401 / same-account sign-in | Pause queue; never replay as a different account |
| `account_deleting` | 409 / inspect deletion status | Freeze account mutations; accepted receipts may reconcile without new effects |
| `restore_requires_review` | 409 / account recovery review | Lock old-epoch pending work; retain original requests; deliberate recovery uses new IDs/current epoch |
| `not_found` | 404 / refresh/review | Missing and inaccessible are equivalent; no private entity details |
| `revision_conflict`, `invalid_transition`, `identity_conflict` | 409 / refresh and review | Preserve intention, fetch own canonical row; new deliberate action/ID |
| `source_schedule_conflict` | 409 / refresh and review | Cached occurrence source changed or is no longer eligible; never materialize/complete different work silently |
| `operation_payload_mismatch` | 409 / investigate command integrity | Never replace payload under its attempted ID |
| `snapshot_changed`, `snapshot_expired` | 409 / restart scope | Discard incomplete confirmed page set, preserve pending overlays |
| `scope_too_large`, `request_too_large` | 413 / narrow request | No truncated scope or partial acceptance |
| `rate_limited` | 429 / bounded delay | Respect provided retry delay; domain commands reuse their exact request |
| `context_not_ready` | 409 / sync or choose smaller context | AI cannot treat incomplete/pending schedule as fresh availability |
| `feature_unavailable`, `provider_unavailable` | 503 / later explicit use | Disable enrichment/AI affordance safely; calendar continues |
| `unexpected` | 500 / retained request, investigate | Sanitized correlation only; ambiguous mutation remains recoverable |

RPC failure is a raised SQL exception so the command/receipt writes roll back, **not** an `ok:false` JSON return that accidentally commits partial changes. Proposed controlled SQLSTATE codes use PostgREST's `PTxxx` HTTP mapping; `message` carries a known machine code and `details` carries only bounded validated field/recovery metadata. The client adapter maps recognized SDK/PostgREST errors into the union; unknown database error messages/details are never shown or logged raw. Verify this behavior with the actual deployed version, including commit-time constraints; see [PostgREST errors](https://docs.postgrest.org/en/stable/references/errors.html).

Next.js routes emit their own normalized JSON union and HTTP status; Supabase SDK transport errors are not already that envelope. JWT/grant failures may occur before a wrapper and need separate safe mapping. Do not equate every 404 with an absent entity: a missing RPC/schema-cache error is a deployment `unexpected`/unavailable condition, not permission to recreate records.

Network interruption, timeout, client abort, or invalid/missing success body leaves a mutation's acceptance **unknown**. Keep the frozen request; reconcile/retry it with bounded exponential backoff/jitter and existing receipts. Definitive validation/conflict/auth failures pause only the affected command/dependents, with independent work continuing. Reads retry independently; provider/model requests are never replayed from the durable calendar outbox.

Transport request IDs help sanitized diagnostics and may change on retry; operation IDs identify durable work and never change on an ambiguous retry. Do not log tokens, query text, notes, booking references, prompts, or key-bearing upstream URLs. Realtime subscriptions and blind auto-retry middleware are not part of the first contract.

## 8. Next.js weather and photo routes

All routes verify the session server-side, validate bounded inputs, use fixed provider hosts/native fetch, redact secrets, and return normalized responses. User-specific HTTP responses use `Cache-Control: private, no-store`; provider caches are explicitly separate transient/bounded caches under their feature contracts, not public caching of private requests.

| Route | Input | Output / bounds |
| --- | --- | --- |
| `GET /api/weather/search` | `q`: 3–100 characters | At most 10 normalized candidates: label/city/region/country, finite coords, optional provider ID; no invented search timezone |
| `GET /api/weather/forecast` | Selected `latitude`, `longitude`; optional destination-local `date` | Matched city/zone, source, original `fetched_at`/`refresh_after`/`expires_at`, available forecast dates, daily/hourly values, selected-date coverage |
| `GET /api/imagery/candidates` — optional | Confirmed public destination/country **or** allowlisted theme; bounded context version | Up to 12 validated candidates with photo ID/variant URLs/dimensions/alt/credit; context echoed to reject obsolete results |

Forecast coverage is a successful domain result such as `available`, `not_yet_available`, or `past_date_unsupported`, not an invented long-range prediction or a save failure. Server configuration owns forecast horizon/plan extras; callers cannot request arbitrary paid options/provider keys/upstream URLs. Nullable readings remain null; normalized hourly instants use returned epoch/timezone. Celsius/Fahrenheit toggles reuse data. Never merge highs/lows across different weather-local days to imply one forecast.

Forecast caches preserve original upstream fetch time and hard expiry from the weather plan; no durable forecast SQL/Dexie/export. Search/date/coords are excluded from access logs where possible. Pexels uses public context only and saves metadata separately through `set_itinerary_cover`; retrieval never writes itinerary rows or changes rewards. A provider/CDN/quota error falls back without blocking calendar edits. No photo bytes or credential-bearing URLs appear in these contracts.

## 9. Planning assistant request and proposal contract

Proposed `POST /api/planning/proposals` is enabled only after the provider/data-handling/budget decision. It is authenticated, same-origin, explicit user action, and online. Panel/mascot opening uses deterministic navigation/help without this request. Use a bounded JSON response first; streaming is not needed to prove reviewed planning.

Input: `contract_version`, UI `request_id`, prompt (proposed ≤2,000 characters), optional session turns (≤6, bounded total), and one context selector: selected calendar date window (≤7 dates), selected itinerary ID, or `general` with no schedule context. Schedule-specific input carries its acknowledged account snapshot token. Client knows its pending-scope edits and must block that request until sync; server also verifies the token/current owner scope. Client-provided rows/revisions/owner fields are not trusted context.

The server reads only selected **acknowledged** owner records, validates coverage/token, and minimizes content: titles/times/kinds only by default, no private notes/booking refs or unrelated publication/reading data. If a trip/context exceeds the proposed 100-occurrence limit or is incomplete, return `context_not_ready` and ask for a smaller scope; never silently truncate and call the remainder free time. General prompts can return general guidance without availability claims. Bound response proposals to five; account-level cost/request controls are shared across instances before promising a hard budget.

Response: `ok`, version, server request ID, context token/coverage, safe assistant text, and validated `proposals`. A proposal contains:

| Field | Contract |
| --- | --- |
| `proposal_id`, `kind` | Response-scoped ID; allowlisted `create_quest`, `create_time_block`, or `edit_itinerary_occurrence` |
| `summary`, `reason` | Bounded readable guidance, not an execution instruction |
| `context` | Server-derived account token, display zone, selected date/itinerary scope and relevant source revisions |
| `target` / `before` | Owner-verified existing occurrence/itinerary reference and current values for edits; null for a new quest |
| `draft` / `after` | Allowlisted title/kind/date/time/zone/duration/notes fields under the normal editor schema |

A response-scoped proposal ID is not a database identity, receipt, or authority. New entity IDs and a new mutation operation ID are generated only when the user saves a reviewed editor draft. Match model target IDs/fields against the actual allowed context; the model cannot choose another account, complete/delete entries, award XP, publish chapters, book travel, or call arbitrary tools. Validate timing/DST/content before displaying it and again on save.

Before opening/applying an existing-entry draft, verify its source token/revisions and any pending edits; changed data needs refresh/re-review. Accept opens the existing editor, and **Save** follows the normal local operation/receipt path. There is no `accept_proposal` endpoint that executes a model payload directly. Abort on account/session changes, discard stale request responses, preserve session drafts across panel switches, and clear them on sign-out; no persistent chat/proposal table or queued offline model request now.

Cookie-authenticated POST routes also validate the intended same-origin request/CSRF boundary; do not assume hiding a route behind the app layout provides authorization. No permissive cross-origin credential access. Cancelling a model request prevents obsolete UI application but does not promise the upstream provider incurred zero usage.

## 10. Account and later creator interfaces

Account authentication/recovery uses Supabase Auth. Privileged deletion uses the online prepare/confirm/status Route Handlers in [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md#3-retryable-account-deletion), never a table DELETE or queued browser command. Prepare accepts job UUID/status secret/current password with a verified same-account session; confirm accepts job UUID/status secret after deliberate UI confirmation within five minutes of reauthentication. Status accepts only job UUID/secret and returns a narrow safe state even after Auth removal. A private job and operator-only deletion marker survive profile deletion; ambiguous Admin results require exact-target verification. The local partition clears only after confirmed removal. The internal Cron runner is secret-protected and service-only.

Owner export uses `export_account_page`; local pending-work recovery is browser-only and clearly identifies cache coverage. Restore/import remains a later contract, never automatic replay of a downloaded bundle.

Export never clears a pending queue. Keep-work sign-out retains a locked partition for same-account recovery. Current `sync_epoch` is server-owned and guarded in ordinary commands: look up an existing receipt first; otherwise reject a mismatched epoch or deletion-requested account before domain changes. Operational restore recovery is separate from importing a recovery file.

For creator publishing, reserve named owner commands such as `schedule_chapter`, `cancel_chapter_release`, and `withdraw_chapter`, and public read functions such as `get_public_series`/`get_public_chapter`. These are **future**, not granted initial RPCs. Schedule/cancel/withdraw requires an online canonical revision, finalized frozen chapter version, confirmed local time/zone, and its own retry receipt; no automatic outbox publishing intention. The due-release worker is not a public endpoint.

Uploads use the private Storage/reservation/finalization boundary from the creator plan; media URLs come from a narrowly scoped server route resolving a currently published chapter/version, never an arbitrary object path. Public DTOs omit account IDs/drafts/private URLs; external mode schedules only Gamecal card visibility. Exact creator/upload/public-media request shapes are deliberately deferred to that pilot so the calendar API does not pretend to cover unimplemented public storage infrastructure. Radio, push, multiplayer and external calendar APIs remain parked/deferred.

## 11. Contract verification and implementation stop condition

These are planned checks; no app/test runner exists yet.

| Scenario | Expected proof |
| --- | --- |
| First profile/create/scope/complete/undo | Correct owner entities, decimal revisions, deterministic IDs, one active reward then reversal |
| Lost response and identical retry | One effect; historical acknowledgment distinct from current canonical state |
| Changed payload under attempted operation ID | Rejected, original work/receipt intact |
| Stale editor or receipt replay after remote edit/undo | No silent rebase, overwrite, duplicate reward, or resurrection |
| Invalid fields/JSON/date/zone/large body/precision | Rejected without partial domain/receipt writes; large counters round-trip exactly |
| A/B/anonymous/direct table access | RLS/grants/private-wrapper behavior matches the permissions matrix |
| Snapshot pages changed/expired, unknown duration, incomplete catch-up | Explicit restart/coverage; no false empty/complete schedule, duplicated span, or inconsistent progression |
| Series/itinerary multi-row change | Bounded response/invalidation, pending intent preserved; parent revision and dependent-command rules pass |
| Local-only recurring occurrence after remote series edit/archive | Source-version/date validation rejects changed/removed work; no wrong-task completion or reward |
| Forecast/search/photo quotas/expiry/private context | Correct normalized states, secret isolation, independent local saving |
| AI malformed response/stale context/failure/cancellation | No execution; reviewed valid draft only; manual calendar remains usable |

Validate request/response schemas against real RPC/HTTP fixtures, meaningful database tests, and one browser journey; do not test only a mock that repeats these JSON examples. Version compatibility, receipt hashing, exact transport/error mapping, commit-time constraint rollback, cursor completeness, and account switches need integration proof. Unknown success bodies remain ambiguous until reconciled, not silently accepted.

**Next implementation slice:** once implementation is authorized, scaffold the stack/local tests and deliver the first profile + one-off calendar/reward/sync path against a disposable local Supabase environment, using the first-session screen/acceptance contract. Expand only after its acceptance checks pass. Plan exact versions/local setup/Auth email tests next; no remote database connection or execution is authorized by this document.
