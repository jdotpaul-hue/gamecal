# Local Data and Supabase Sync

**Updated:** 14 October 2026

**Decision:** Local-first application data with authenticated Supabase synchronization in the initial MVP. This supersedes the earlier online-only mutation design. See [product plan](PRODUCT_PLAN.md), [technical design](TECHNICAL_DESIGN.md), and [agent guide](AGENTS.md).

**Implementation status:** The [webapp foundation](webapp/README.md) initializes and validates account-specific `sync_meta` only. Confirmed records, outbox commands, projections, sender/reconciliation, verified account locking and lifecycle recovery below are not implemented yet.

**Knowledge proposal:** [SECOND_BRAIN_PLAN.md](SECOND_BRAIN_PLAN.md) would reuse account-scoped durable local intentions and confirmed snapshots for supported note/source/link metadata after their contracts exist. A source note is durable user content; a transcription/generation/embedding request is separate online work and never automatically replayed as a calendar command. Raw audio and filesystem handles do not enter the ordinary outbox. Keep unsynced notes through the same recovery protections, validate source revisions for derived results, and distinguish text saved from organization/indexing complete. Markdown export is not an account/queue restore mechanism. Direct folder writers need a separate conflict design.

Automatic organization can start on eligible saved captures without a separate per-note approval. Its generated output needs validated source/target revisions, deduplicated processing identity and correction overrides. Interrupted processing leaves the source saved and organization pending/failed; resume only under valid account/configuration scope. This does not put provider prompts into the calendar outbox or promise closed-browser execution.

**Database/security plan:** [DATABASE_SCHEMA_PLAN.md](DATABASE_SCHEMA_PLAN.md) and [RLS_PLAN.md](RLS_PLAN.md) define canonical tables, private receipts/materialization, controlled writes, and snapshot tokens. Local migrations implement a calendar foundation subset; full pilot sync and remote deployment remain unproven. New knowledge contracts are planning only.

**Wire contract:** [API_CONTRACTS.md](API_CONTRACTS.md) defines the versioned request envelope, named commands, safe decimal-string revisions, acknowledgments/current canonical records, scope invalidations, and error recovery. Validate transport responses before acknowledging queued work.

**First-session UI:** [FIRST_SESSION_PLAN.md](FIRST_SESSION_PLAN.md) maps these states to the editor/agenda/Undo, compact sync indicators, incomplete coverage, conflict panels, expired-session and sign-out choices. Unsaved form drafts have only an in-session lifetime; they cannot claim the queue's durability.

**Resolved recovery/operations contract:** [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md) specifies keep-work sign-out, cache eviction, retryable deletion, shared budgets, and restore epochs. These are design decisions, not implemented or passing checks.

**Itinerary extension:** [ITINERARY_PLAN.md](ITINERARY_PLAN.md) uses this same queue/cache for trip records and shared calendar occurrences. A second travel backend or sync system is not needed.

**Weather boundary:** [WEATHER_PLAN.md](WEATHER_PLAN.md) persists/syncs selected location/unit settings through this queue. Forecast reads and transient snapshots have a separate expiry lifecycle and never become durable user mutations.

**Optional cover boundary:** [PHOTO_PLAN.md](PHOTO_PLAN.md) syncs a stable selected Pexels photo reference, credit, and auto/manual/none preference with the itinerary. Search responses and image bytes are not queued; remote media loading has an independent failure lifecycle.

**Creator extension boundary:** [CREATOR_PLAN.md](CREATOR_PLAN.md) proposes local-first private creator metadata, separate online artwork transfers, and explicit online publication commands. Browser-closed chapter release is a server job, not execution of this browser queue.

**Planning assistant boundary:** [UI_UX_PLAN.md](UI_UX_PLAN.md) keeps navigation/mascot help local, model requests online and explicit, and proposals review-only. Do not enqueue prompts or model calls. Accepted proposals prefill the existing editor; only its validated save enters this queue. Preserve source revision/context and flag stale plans rather than silently rebasing. Initial scheduling advice uses acknowledged context; relevant pending edits must sync first. Hiding a workspace panel never removes a draft or pending command.

## 1. User experience and boundaries

The calendar reads from a browser database and persists ordinary edits there immediately. A durable queue sends those changes to Supabase while the app is open. Normal use should not wait for each network round trip.

Initial sign-in, fresh app loading, account recovery/deletion, and loading uncached history require internet. An already-open app can edit its cached calendar during connection interruptions; the queue survives reload and drains after authenticated startup. A service worker and guaranteed offline reopening are not part of this MVP. Installing a PWA or syncing with the browser closed is separate work.

Display a compact account sync indicator: **Saved on this device**, **Syncing**, **Synced**, **Needs sign-in**, or **Needs attention**. Ordinary successful sync stays quiet. Explain prolonged pending changes or conflicts without blocking unrelated local work.

## 2. Storage roles

| Layer | Role |
| --- | --- |
| IndexedDB through Dexie | Last confirmed account snapshots, durable pending commands, sync metadata, cached coverage |
| Reactive local read model | Confirmed snapshots with pending commands applied in order; the calendar's normal rendering source |
| Supabase PostgreSQL | Accepted cross-device account data, canonical revisions, completion rewards, mutation receipts |
| React component state | Unsaved form drafts and temporary interaction state |

Use `dexie` and `dexie-react-hooks`; [Dexie's React guide](https://dexie.org/docs/Tutorial/React) describes IndexedDB-backed reactive queries. This does not provide Supabase sync automatically. Implement one narrow sync module rather than introducing a second cloud database/provider.

Cache profile/preferences, definitions, schedule versions, viewed occurrences, rewards needed for those occurrences, and reflections. Start with the selected calendar window and recent review history; fetch older windows on demand. Cache the server-derived progression summary so level display does not require the entire historical reward ledger locally. Never silently present an uncached range as an empty schedule.

Opening an itinerary loads all its memberships and linked occurrences/metadata, including preparation outside the date envelope and overnight continuations. Fetch the entire scope in bounded consistent pages and mark complete-trip coverage only after validation. Do not treat an incomplete trip day as empty. This caches data but does not guarantee offline app startup.

Do not copy privileged credentials, password data, or auth tokens into these stores. Session storage remains the responsibility of Supabase's documented authentication integration. Binary room assets are a separate asset-loading concern, not database rows.

Do not add forecast payloads to confirmed records, outbox payloads, recovery bundles, or account exports. Initial WeatherAPI responses use bounded transient server/browser memory caches; keep source/fetch/expiry metadata and enforce the weather contract. An unavailable/expired forecast does not invalidate cached itinerary details or prevent queued edits from syncing.

Optional cover metadata can be a durable itinerary field and appear in metadata exports, but no photo bytes enter Dexie/queue/recovery bundles in the first experiment. Persist none/manual mode explicitly, preserve attribution, and use a local placeholder when a remote image is unavailable. A photo reference is not proof the image itself is cached offline.

### Creator publishing extension

When the creator module ships, ordinary private series/chapter metadata edits can use this queue under the same account/revision rules. Add its scopes and local schema deliberately; do not place public reader data into an owner's private projection by default. Artwork bytes, upload tokens, and signed media URLs are excluded from Dexie/outbox/recovery exports. Resuming an incomplete transfer after reload may require reselecting its source file.

Schedule, publish-now, cancel, and withdraw use dedicated online, authenticated, revision-checked server commands with operation UUID receipts. They are intentional exceptions to queued ordinary editing. First synchronize relevant metadata and finalize uploads; then freeze the canonical content version. An offline form may preserve a scheduling intention, but cannot claim an accepted release or replay publication automatically later. Resolve ambiguous publication responses through their original receipts before new contradictory actions.

After confirmation, the backend owns due release execution even when the browser closes. This does not add closed-app calendar sync or reminders. Reader manifests/pages require online access in the creator pilot; local reading position does not imply offline downloads or cloud resume. Isolate guest/account reading history, and keep media access independent from the private calendar outbox.

## 3. Local stores and atomic save

Use account-scoped stores or keys containing the authenticated account UUID:

- `confirmed_records`: normalized server snapshots, revision, and deletion markers.
- `outbox`: operation UUID, account, command/schema version, entity IDs, validated payload, base revision captured at editing time, predecessor dependencies, observed action timestamp and completion timezone where relevant, creation order, attempt status, retry metadata, and any frozen transmitted request.
- `sync_meta`: local schema version, cached date coverage, acknowledged progression summary, last successful refresh, and sender lease metadata.

Store the verified profile's server-owned `sync_epoch` with account sync metadata. Include it in every ordinary frozen mutation except profile bootstrap. Snapshot tokens bind it too. A changed epoch after operational restore locks retained work for review; do not substitute the new epoch/revisions into an attempted request. An accepted receipt can still reconcile its original effect; a missing old-epoch receipt cannot justify replay. Reviewed recovery creates a new action/ID.

In one IndexedDB transaction, append the validated command and the metadata needed to recover its local projection. Derive the visible projection from confirmed records plus the ordered queue; do not maintain another independent writable copy of XP or task status. A failed local transaction is a failed save: retain the form, show the error, and do not report success or silently use an alternate cloud-only path.

Create record UUIDs before enqueueing and preserve them on the server. For occurrences, use a deterministic UUID derived from the stable definition UUID and original ISO local date, following [the fixed UUIDv5 namespace/encoding and vectors](DEVELOPMENT_SETUP.md#5-shared-occurrence-identity) in TypeScript and SQL. Verify the chosen library/database extension at implementation; test parity and retain the existing uniqueness constraint. Rescheduling does not change this identity.

## 4. Sender protocol

1. After verified startup, open the matching account partition, hydrate the cached view, and request a refresh for the current scope. Authenticate before sending anything.
2. Drain commands in dependency order: creation precedes edits/completion; commands touching the same entity or series remain sequential. The MVP uses one sender per account, coordinated across tabs with a recoverable lease; server receipts still protect against duplicate senders.
3. Before a command's first transmission, use the base revision captured when the user edited, or the accepted revision of its successful predecessor, and freeze the exact request with its operation UUID. Never substitute a newer remotely pulled revision without user review: that would silently overwrite another device's edit. Once attempted, never change that UUID's payload or expected revision; ambiguous retries send the same request.
4. Call the existing authenticated PostgreSQL operation. Ownership, revision, state, reward, and receipt checks remain authoritative on the server.
5. On success, atomically record the acknowledgment in IndexedDB, update confirmed snapshots, and remove/acknowledge the queued operation. Reapply remaining queued commands so an acknowledgment never overwrites a newer local edit.
6. After draining, refresh the active bounded account scope and progression summary. Poll conservatively while visible and also refresh on focus, navigation, reconnect, and manual retry. Coalesce overlapping refreshes.

Network/timeouts use bounded exponential backoff with jitter. An expired session pauses the queue and requests sign-in; validation/conflict errors stop only the affected command and its dependents. Retain their payloads for resolution. Never retry an invalid command indefinitely or drop it silently.

For itinerary commands, creation of the itinerary and occurrence precedes attachment; an add-appointment command may create both occurrence and metadata atomically on the server. Shared occurrence edits appear in both local views. Itinerary deletion tombstones memberships but preserves calendar entries; explicit event deletion is a separate dependency-safe operation. Locking and receipts must prevent a delayed attach/edit from restoring a deleted itinerary or duplicate membership.

Itinerary weather-location overrides depend on the itinerary's creation and are tombstoned on deletion. Location edits do not rewrite dates or trigger forecast requests during every queue drain. Weather retrieval is an independent visible-use read; it is not retried as part of the calendar mutation protocol.

Optional cover mutations also depend on itinerary creation and use revision/conflict rules. Provider search does not run inside mutation replay. Before applying an automatic search result, compare the current local cover mode/context so a stale response cannot replace a manual choice, removed cover, or changed destination. Itinerary deletion invalidates pending enrichment; image failure cannot block independent saves.

Receipts must survive long enough to cover any retained queue: retain them for the MVP lifetime. A crash after server commit but before local acknowledgment replays the same command and consumes its receipt. Replayed responses must not regress the UI or repeat celebrations.

Freeze the command's normalized wire envelope and decimal-string revisions before first transmission. Original acknowledgment revisions remain the base for already queued dependent intentions; newer canonical data does not silently rebase them. Invalid/missing success bodies and client aborts leave acceptance unknown. A `not_seen` receipt lookup alone cannot rule out a concurrent command still executing; resend the identical request rather than inventing a new operation ID.

For broad changes, atomically persist canonical root replacements plus explicit scope invalidations before removing the acknowledged projection. Mark invalidated coverage incomplete, preserve unsent intentions, and pull missing revisions before dependent transmission. An itinerary membership change advances its aggregate itinerary revision and, for structural attach/detach, its occurrence revision; later commands follow their declared dependencies and related guards.

## 5. Pulls, deletions, and conflicts

Use bounded full snapshots for active scopes in the MVP; do not implement a bespoke incremental change-feed protocol yet. A snapshot must state its complete scope and include the revisions/deletion information needed to reconcile it. Replace confirmed membership only after the whole scoped response is validated. Never interpret a partial/failed page as deletion. Reapply pending commands after replacement.

Use a consistent owner-scoped database snapshot or explicit versioned pagination for multi-table scope reads. Server-derived totals and accepted rewards must agree. An entry moved outside a fetched date range is removed from that range's confirmed membership, while unsent local edits remain preserved.

The chosen version token is `profiles.account_data_revision`, advanced transactionally with every accepted change affecting an account snapshot. It is independent of preference/entity CAS revisions. Deterministic pages verify the same token and read their scope in one SQL snapshot; a changed token restarts the confirmed pull while preserving pending overlays. Future-window generation cannot advance the internal contiguous historical materialization cursor. Do not cache a partial scope as complete.

Materialization is a separate explicit command before scope reads; no page can mutate during a pull. Tokens bind scope and first-page `as_of`/expiry as well as the counter. Keep `page_set_complete` distinct from generation/historical coverage and preserve the time anchor for paginated review totals. Full owner export finishes only after all entity pages match, without pretending a partial download is a complete backup.

Retain server tombstones for all deletable cached entities, including occurrences and reflections, for the MVP lifetime. Parent archive/deletion behavior must not allow queued children to resurrect deleted work. Never prune tombstones without a stale-device recovery design.

If another device changed a record, reject the stale expected revision. Show the remote value and the retained local intention; let the user keep the remote version or review/reapply their change using a new operation UUID and current revision. Do not automatically overwrite notes, revive deleted records, or merge competing completion/undo transitions. A deleted remote quest can be explicitly recreated with a new identity, not revived accidentally.

Block commands that depend on unresolved series/parent changes; continue independent work. Identity, grants, and canonical revisions never come from a client-chosen replacement account.

## 6. Completion, XP, and time

Completing a quest marks it completed in the local projection with **pending sync**. Immediate checkmark feedback acknowledges the local save. Confirmed XP and room unlocks update only after the server accepts a reward-changing operation; show pending completion count when useful, rather than granting speculative authoritative XP.

If a queued completion is followed by undo, preserve that order through sync. Suppress milestone celebrations for intermediate acknowledgments superseded by newer local actions. A duplicate receipt cannot grant a second reward; a late retry cannot resurrect work that was subsequently undone. Appointment attendance still grants no XP.

Skip/unskip is also an ordered pair: `skip_occurrence` moves pending to skipped; `unskip_occurrence` returns skipped to pending without XP or identity changes. Undo skip remains visible on the row/details. A skipped entry must be unskipped before completing/rescheduling it. Never delete an uncertain transmitted Skip as if that cancelled its server effect.

Record `observed_at` at the user's action and `accepted_at` on the server separately. A validated observed timestamp supplies the canonical completion time, so syncing tomorrow does not move today's action into tomorrow's consistency count. Reject invalid or implausibly future timestamps and preserve the command for correction; do not treat device clocks as proof for competitive scoring.

Also capture the user's confirmed planning timezone for the action; the server validates it and derives/stores the completion-local date. Later profile-zone edits cannot silently reclassify that accepted historical date. The schema plan proposes a five-minute future-clock tolerance, to test during implementation; correction creates a new explicit operation rather than changing an ambiguous retry's frozen payload.

Generate local recurring instances using the same pure scheduling rules and deterministic IDs as the server. The server validates/materializes their canonical schedule version before dependent transitions. Cached-only calendar/review totals may be incomplete: show coverage/sync state rather than presenting them as fresh cross-device statistics.

Occurrence command references include the definition ID, original local date, and observed schedule-version ID as well as the derived occurrence ID. This lets the server materialize a missing instance safely and reject a remotely changed/removed source. Initial local revision `1` alone cannot distinguish a newly materialized different schedule version; never complete/reward that substitute silently. See the API contract's `occurrence_ref` guard.

## 7. Account lifecycle, exports, and storage limits

Never merge partitions or replay one account's commands under another account. Reauthenticate the same account to resume a paused queue. Local data is a convenience and pending-work store, not independent authorization to access cloud records.

Normal sign-out clears the account cache only when no pending/ambiguous work remains. With pending work offer Sync first, Keep work and sign out, Export a copy, Discard and sign out, or Stay signed in. Keep-work sign-out stops senders and retains the locked account queue and required dependency records; only verified same-account sign-in resumes it. Session expiry also locks without erasing. Account deletion follows the online reauthentication/job contract and clears that partition only after confirmed removal.

Exporting never clears pending work, even after saved-file acknowledgment: the MVP has no import path. Only a drained queue, explicit discard, or confirmed account deletion permits clearing. Local discard cannot undo an accepted/in-flight cloud command. Pause/coordinate senders and reconcile ambiguous work before clearing where possible; explain any still-unknown acceptance truthfully.

Provide two clearly identified exports: a complete online account snapshot, and a local recovery bundle containing cached coverage plus pending commands. The recovery bundle is not a complete account backup, includes private content, and is not replayed/imported automatically. Validated restore/import remains later work.

Use the operations plan's 20 MiB confirmed-cache target/LRU cleanup, pin pending dependencies and active sources, and invalidate evicted coverage atomically. Quota recovery retries one unsent local transaction after safe cleanup, then preserves the draft with practical recovery actions; it never prunes pending work or resets a failed migration. Browser storage can be smaller than the target.

Request persistent storage where supported, but handle denial, quota errors, browser data clearing, and private browsing. [MDN storage guidance](https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria) explains quotas and eviction. Unsynced data can be lost if browser storage is cleared; synced account data can be rehydrated from Supabase.

Foreground sync is the guaranteed lifecycle. [Background Sync](https://developer.mozilla.org/en-US/docs/Web/API/Background_Synchronization_API) has limited browser availability and needs a service worker; do not depend on it for this MVP or promise work continues after the app closes.

### Saved-itinerary follow-up

Travel creates a specific need to reopen essential details without connectivity. Prioritize an opt-in read-only saved itinerary before claiming offline travel access. It needs a cached service-worker shell, complete trip snapshot/version/readiness checks, and airplane-mode restart tests. Define how previously authenticated local read access and session expiry interact before enabling it; current MVP auth/sign-out rules remain in force until deliberately revised. Maps, external booking pages, live updates, and cloud sync remain online capabilities.

Saved itinerary access does not imply a current weather forecast. A still-valid in-memory forecast may survive a connection interruption in an open app, but forecast persistence across browser closure is deferred pending a provider-compatible retention lifecycle. Never preserve weather indefinitely inside the saved trip pack.

## 8. Required proof before the pilot

- Create/edit/complete an entry during a simulated network interruption, reload online, and confirm one accepted server outcome.
- Complete then undo before reconnection; final XP is unchanged and no stale unlock reveal occurs.
- Lose the acknowledgment after server commit, retry, and confirm exactly one reward.
- Reconcile two-device edits, remote deletion, moved entries, and a blocked series dependency without losing local text.
- Reopen multiple tabs and verify sender recovery, no duplicate rewards, and consistent projections.
- Expire the session or switch accounts; no data leakage or cross-account queue replay.
- Test local quota/write failure, local schema upgrades with a nonempty queue, and explicitly incomplete cached ranges.
- Preserve the actual completion date across a delayed sync and test invalid clocks.
- Verify keep-work sign-out/same-account resume, export without purge, explicit discard and server-confirmed deletion with a lost response.
- Verify skip/unskip order and stale-revision recovery without XP; restore epoch changes lock old pending commands rather than silently rebasing them.
- Sync trip/occurrence creation, cross-view rescheduling, conflicting metadata, complete-trip cache, and detach/archive/delete while commands are queued. Booking details must remain owner-scoped and absent from logs.
- Persist/reconcile owner-scoped weather preferences/overrides without putting forecasts in the queue; prove weather timeouts/expiry/quota failures leave calendar saves and sync intact.

This adds real engineering work to the MVP. Implement a one-off quest vertical slice and the retry protocol before adding recurrence or optional 3D. Do not describe local-first reliability as complete until these checks pass.
