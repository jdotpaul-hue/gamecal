# Gamecal Account Recovery and Pilot Operations

**Updated:** 14 October 2026

**Status:** Planning contract. The decisions below close the operating-design gaps in [DOCS_REVIEW.md](DOCS_REVIEW.md); implementation, credentials, paid-plan selection, restore rehearsals, and measured results remain outstanding. No service has been configured or database operation performed.

**Related:** [Product](PRODUCT_PLAN.md), [technical design](TECHNICAL_DESIGN.md), [API contracts](API_CONTRACTS.md), [schema](DATABASE_SCHEMA_PLAN.md), [RLS](RLS_PLAN.md), [sync](LOCAL_SYNC_DESIGN.md), and [first-session UX](FIRST_SESSION_PLAN.md).

**Assistant expansion:** [PERSONALIZATION_PLAN.md](PERSONALIZATION_PLAN.md) proposes explicit memory/teaching and later templates/standing assignments. Before those ship, extend deletion/export and budgets to their actual persisted data; forgotten content must not survive in audit text, retrieval caches or reusable live context. A private template export is not public publication. Browser-closed work is a separate backend lifecycle with expiry, revocation, retry receipts and spend controls, not an implied extension of foreground calendar sync. No automation is created by this plan.

**Knowledge expansion:** [SECOND_BRAIN_PLAN.md](SECOND_BRAIN_PLAN.md) adds proposed source/summary retention, derived link/chunk/vector invalidation, bounded transcription/indexing spend and private Markdown portability. Edits/forgetting/deletion fence late jobs by source revision/hash; background workers and closed-app briefings remain separately gated. Do not retain raw audio by default or expose sensitive recap text through logs/lock-screen notifications. A local attachment path does not provide cloud indexing access, and notes export does not restore unsynced operations or replace tested backups.

## 1. Sign-out and local recovery

The MVP does not import recovery bundles. **Exporting a copy never authorizes deleting the retained queue.** Pending work remains in its existing account partition until acknowledged, deliberately discarded, or removed following confirmed account deletion.

| Choice with pending work | Result |
| --- | --- |
| Sync first | Reconcile the queue while authenticated; sign out and clear the partition only when no unresolved work remains |
| Keep work and sign out | Stop/coordinate senders, sign out, and retain a locked partition containing the queue and its required confirmed records/coverage; resume only after verified same-account sign-in |
| Export a copy | Download a clearly labeled partial recovery file; retain local work and the current sign-in state; explain that in-app import is unavailable |
| Discard and sign out | Confirm the affected pending intentions/dependents, coordinate senders and reconcile uncertain responses where possible, then clear the partition deliberately |
| Stay signed in | Keep the current state |

Normal sign-out with no pending/ambiguous work clears the partition. Expiry locks it without clearing. Signed-out or different-account UI, readers, queries, and senders cannot access/replay a retained partition. On same-account return, first verify identity and reconcile attempted commands before projecting/resending dependencies. Preserve frozen IDs/payloads/revisions. An application lock is access gating, not encryption against someone with access to the browser profile.

Pending partitions have no automatic age expiry. Retain only the data needed for pending projection/review; evict unrelated confirmed caches under section 2. A full recovery import remains a separately validated future feature. Local discard does not cancel an accepted or in-flight server operation.

## 2. Cache cleanup and storage recovery

Use one measured cache policy shared across tabs. Initial **confirmed-cache target: 20 MiB per browser origin**, excluding queued intentions and their pinned dependencies. Estimate serialized record/metadata size conservatively and use `navigator.storage.estimate()` where available; neither figure is an exact IndexedDB file-size guarantee. Browser quotas can be smaller.

- Pin pending/attempted commands, dependency records and receipts needed for reconciliation, the active editor's source, and the current visible scope. No automatic cleanup may remove them.
- Evict least-recently-used, unpinned confirmed scopes when over target, aiming for 15 MiB. Remove scope membership/coverage atomically with unused records; shared/pinned records remain. A subsequent visit shows loading/incomplete coverage rather than an empty day.
- After quota failure, attempt one safe eviction and retry the same unsent local transaction once. If still unsuccessful, preserve the draft and offer Retry, Clear downloaded cache, Export a copy of pending work, or explicit discard in the account flow. Never claim a save or switch silently to a cloud-only path.
- Clear downloaded cache removes only unpinned confirmed data. If pending work itself consumes the available storage, explain that syncing or explicit discard is needed; export alone frees nothing.
- Show a nonblocking pending-work notice at 100 commands or approximately 5 MiB. These are warning thresholds, not permission to purge the queue. Browser storage denial/private mode may prevent local saving entirely; retain/copy the draft and report that limitation.
- Schema upgrades preserve outbox bytes and frozen payloads. An unsuccessful migration stops writes, keeps the old database recoverable, and offers export/operator recovery; it never resets the database automatically.

Verify eviction races, shared-scope references, two tabs, a nonempty queue, auth expiry, reload and simulated quota errors. Browser clearing/eviction can still remove local data; cloud-confirmed records are recoverable independently. See [MDN storage guidance](https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria).

## 3. Retryable account deletion

Deletion is an online, explicit two-step account workflow, separate from the calendar outbox. Use a narrow durable `app_private.account_deletion_jobs` record that has **no FK cascading from Auth/profile**. It survives identity removal until status/recovery is complete. The verified UUID is the deletion target; user input never selects another owner.

1. Pause/coordinate local senders. Show the private-data and pending-work consequences, offer account export first, and require an explicit decision about unsynced intentions. Another browser can retain locked local data until explicitly cleared or deletion is independently confirmed there; a failed sign-in alone is not deletion proof and cannot purge its queue. Immediate remote browser erasure is not promised.
2. Prepare through `POST /api/account/deletion/prepare`. Verify the session and same-origin boundary, then check the current account's password using an isolated, nonpersisting Auth client. The returned identity must match the verified account. Never persist/log the password or resulting temporary session. Fresh reauthentication is valid for **five minutes**, bound to this job and account.
3. Before prepare, the browser generates a job UUID and cryptographically random 256-bit status secret, retained in sessionStorage for this workflow, outside Dexie/outbox/exports. Prepare stores only its digest. The same job ID/secret can reconcile a lost prepare response; an existing job cannot be rebound to another account/secret. The server returns only job ID, expiry and safe state.
4. The user explicitly confirms through `POST /api/account/deletion/confirm`, authenticated as the same account, within that reauthentication window. It atomically changes prepared to requested. Expired preparation requires reauthentication; a stale prepared record cannot initiate deletion by itself. Replay returns the job's existing status and cannot delete twice.
5. The server attempts requested work immediately. A protected Node.js runner, `GET /api/internal/account-deletion/run`, is the planned Vercel Pro Cron retry path every five minutes; verify `CRON_SECRET` before any job access. Run at most five jobs per invocation with short per-call timeouts, a 120-second lease, and a bounded invocation deadline. This is not a generic job framework or a public worker API. Creator publication remains its separately planned Supabase Cron job.
6. Mark a live profile as deletion-requested through the trusted workflow before external cleanup. Ordinary commands fail with `account_deleting`; replays of already accepted receipts can report their old outcome without new effects. This prevents continued mutations while Auth administration is in progress.
7. Before calling Auth administration, write an immutable requested-deletion marker to a private, operator-only Supabase Storage bucket `operations-recovery`; include only job/owner UUIDs and server timestamps, with no status secret or content. If this fails, retain/retry the job without deleting Auth. Delete through the server-only Supabase Auth Admin API. After an ambiguous result, inspect the exact same UUID through trusted administration: retry while it is present, and treat transport/grant/provider errors as unknown. A provider-confirmed missing Auth user plus an absent profile confirms the locally tested cascade graph. A generic HTTP 404 or expired session is insufficient evidence. Write a completion marker after verification; marker failures remain retryable.
8. Mark completed only after confirmed removal; then clear the browser partition and show completion. `POST /api/account/deletion/status` accepts job ID/status secret in a body, not a URL, and returns only prepared/pending/completed/needs_help/expired without identity/content. Expired unconfirmed jobs require a new deliberate preparation. Use constant-time digest comparison, no-store responses and bounded polling. The capability can report status only; it cannot confirm deletion or execute another action.

Jobs use server-only state transitions, lease recovery and exponential retry delays capped at one hour. After ten failures, set needs-help and alert the operator; manual retry resumes the same job. A lost status secret after tab closure uses operator recovery rather than an anonymous account lookup. Prepared jobs expire after 24 hours without executing; completed/expired records and status digests are removed after 30 days. Requested/error jobs are retained until handled. No account emails, passwords, notes, raw tokens or full recovery files live in these rows.

The operations bucket has no browser policies/grants; service-only objects are not owned by the deleted Auth user. Terminal markers expire after 30 days, beyond the selected seven-day database restore window; unresolved requested markers remain. During a restore, reconcile these markers before public access so restored backups cannot reactivate deletion-requested accounts. These small operator records are an exception to the calendar's no-user-upload-bucket scope, not a file attachment feature. Whole-project loss needs an independent backup source; managed in-project backups/journals alone cannot recover a deleted Supabase project.

When creator artwork ships, the same job gains a bounded/retryable object manifest captured before identity removal. Delete owned objects through the Storage API before removing Auth (including objects that prevent Auth deletion), then verify both file and row cleanup. The calendar MVP has no user-upload bucket. Database cascades are not file deletion. See [Supabase Admin deletion](https://supabase.com/docs/reference/javascript/auth-admin-deleteuser).

## 4. Request limits and provider budgets

These are **initial application limits to implement and measure**, not provider entitlements or guaranteed billing caps. Store shared counters in `app_private.request_budgets` in the existing PostgreSQL database; no Redis or second data provider is needed for this pilot.

Budget keys are allowlisted and window boundaries come from server UTC time. Fixed-window counters are updated atomically under row locks/upserts; reserve all applicable account/global units together before an upstream request. Concurrent instances cannot independently spend the same remaining allowance. Weather/Pexels attempts consume one unit, even if the result is lost/failed. No cache hit consumes an upstream unit. AI reserves the configured maximum request cost before generation and does not refund ambiguous charges. Do not use unbounded provider SDK retries.

| Boundary | Initial limit | On exhaustion |
| --- | --- | --- |
| Calendar mutations, including bootstrap | 120 committed calls/account/minute | 429 with safe retry delay; retained commands reuse their exact IDs/payloads |
| Materialization, additional cap | 10 committed calls/account/minute | Bounded retry, retaining explicit incomplete generation coverage |
| Owner scope/read/export RPCs | 60 committed calls/account/minute | Pause/coalesce refresh and retry; partial snapshots remain incomplete |
| Deletion prepare | 3 attempts/account/hour | Preserve UI state; require cooldown before password recheck |
| Deletion status | 12 calls/job/minute, route ingress limits for invalid requests | Back off; no anonymous account-discovery response |
| Weather search | 30 calls/account/minute and 100/day | Keep the selected city and usable cached results |
| Weather forecast | 10 calls/account/minute and 100/day | Show usable cache or unavailable state; saves continue |
| Weather upstream, search plus forecast | 2,000/day and 80,000/calendar month globally | Disable new upstream calls for the exhausted window; no paid upgrade |
| Pexels candidate searches | 10 calls/account/minute and 50/day | Existing selection/pool/neutral cover |
| Pexels upstream | 150/hour and 15,000/calendar month globally | Stop new searches; retain existing covers |
| Live AI, only after its gate | 10 generations/account/day; one concurrent generation/account; maximum 4,000 input and 1,500 output tokens | Ask to try later; manual editor remains available |
| Live AI estimated upstream spend | US$5/day and US$25/calendar month globally | Disable generation until reset/operator review |

Actual provider windows may differ from our UTC windows. Obey provider-reported quota/reset headers and stop when either limit is reached. Weather/Pexels caps deliberately leave headroom under the currently documented free allowances. Before AI is enabled, select the provider/model, verify prices and data handling, fit prompts within the token caps without silently dropping schedule context, and calculate a conservative maximum cost. AI stays disabled until that calculation and reservation path pass tests. These caps do not authorize buying a subscription.

Enforce Data API counters/allowlisting in its pre-request boundary and reject direct table endpoints for application traffic; owner SELECT grants remain for invoker RPCs. Owner reads use POST read RPCs. Budget locks precede domain locks; no command later acquires a budget lock after its profile/parent locks. This removes a browser-facing table-read alternative while preserving owner RLS. Trusted ops RPCs are explicitly service-only. Budget-write wrappers cannot be called by ordinary users to reset counters. Schema-cache/grant errors fail closed and are surfaced as deployment errors, not fake missing records. The [Supabase security guide](https://supabase.com/docs/guides/api/securing-your-api) distinguishes request controls from RLS and explains the Data API pre-request scope.

Data API accounting shares the request transaction: a raised domain error rolls back its counter update too. Thus the RPC numbers above limit committed calls and cannot be advertised as persistent counts of all failed attempts. Test the provisioned Supabase ingress/platform protections separately; do not claim a PostgreSQL hook protects every unauthenticated/failing request. Provider reservations use a separate committed server RPC before the network call, so downstream errors cannot refund that allowance accidentally.

Expose budget-accounted RPC wrappers as POST-only `VOLATILE` functions so their request transactions permit the internal accounting write, even when domain data is read-only. Each snapshot still checks its token and selects rows in one SQL snapshot. PostgREST treats POST calls to STABLE/IMMUTABLE functions as read-only transactions; verify the installed version rather than discovering this through production failures. See [transaction access modes](https://docs.postgrest.org/en/stable/references/transactions.html).

Gamecal-only environments disable the unused `pg_graphql` extension after dependency inspection and prove that its query endpoint is unavailable to browser roles. GraphQL otherwise uses the same table grants/RLS and is outside the PostgREST hook; retaining owner SELECT for invoker RPCs must not leave an unbudgeted alternative. Shared-project dependencies require a separately reviewed access restriction instead of silently disabling someone else's feature. Do not add application tables to Realtime publications while that feature is deferred. See [Supabase GraphQL permissions](https://supabase.com/docs/guides/graphql/security).

Next.js routes separately enforce verified identity, same-origin POSTs, bounded bodies, 10-second provider timeouts (30 seconds for enabled AI), cancellation/stale-result guards and shared budget reservations. Use Vercel ingress protection for unauthenticated/invalid-request bursts; configure and test that control before exposing routes rather than relying on a process-local counter. General operating counters are not calendar snapshots or recovery exports and do not advance account data revisions.

Keep at most current-window rows for the fixed allowlisted account/global keys; reset expired windows atomically. Expired account counters may be removed through trusted maintenance. Reserve counters contain no prompt/search/note content. Log upstream units, safe error codes, latency and estimated cost only. Alert the operator at 80% of application/provider budgets, on blocked budgets, repeated job failures or a missing backup. A reviewed server feature flag disables an integration immediately; outages never disable the ordinary calendar save path.

## 5. Hosting, backups and operator responsibilities

Proposed pilot hosting is **Vercel Pro for Next.js and Supabase Pro for Auth/PostgreSQL**. Supabase Storage joins only with uploaded content. These are operating recommendations, not provisioned or purchased plans. Vercel Pro is needed for the proposed frequent deletion retry job/commercial hosting; [Cron capabilities](https://vercel.com/docs/cron-jobs/usage-and-pricing) must be verified in the chosen deployment. A disposable local environment and Free Supabase prototype are acceptable before the invited hosted pilot.

The repository/project owner is the initial responsible operator; record the actual operator and support contact in the private deployment runbook before inviting users. Record project IDs/regions, hosting origins, secret owners, SMTP configuration/delivery checks, budget reset rules, monitoring access, and incident actions there; never commit secrets. Choose hosting compute near the Supabase region and measure latency with the reference device.

Backup baseline: managed **daily PostgreSQL backups with seven-day retention** on Supabase Pro. Verify backup freshness daily and alert if the latest successful backup is older than 26 hours. Proposed recovery targets: at most 24 hours of cloud-confirmed changes lost and service recovery within four hours; these are targets requiring a restore rehearsal, not a measured promise. Browser recovery exports are not the operational backup.

Before the pilot, restore into an isolated environment with provider calls/Cron/email disabled, reapply audited roles/grants as needed, verify schema/owner isolation/rewards/receipts/account cleanup, and record duration and data recovered. Reconcile requested-deletion markers before access. Operator restoration must preserve pending devices' retry safety: restore retained receipts/counters with data, then mint a new server-owned **`profiles.sync_epoch`** for each surviving account before access. Snapshot tokens and frozen ordinary commands carry that epoch. An existing receipt may report its old acceptance without new effects; a missing receipt with an old epoch returns `restore_requires_review`. Lock the affected queue for explicit reviewed recovery, preserving original frozen requests. A new reviewed action gets a new operation ID/current epoch. Add this tested restore mode before advertising the target.

Supabase documents daily paid-plan backups and seven-day Pro retention; its database backups contain Storage metadata, **not uploaded file bytes**. See [backup documentation](https://supabase.com/docs/guides/platform/backups). Repo-managed public artwork is recoverable from the release source/artifacts once versioned. The creator pilot needs a separately selected object-backup/retention/deletion plan and a file restore rehearsal before hosted art is advertised as recoverable.

Pilot device baseline: current/previous major iOS Safari, Android Chrome, and desktop Chrome/Safari/Firefox. Name the actual reference phone and controlled network profile in the delivery checklist; measure cold agenda usability against the proposed three-second target. No device measurements are claimed yet.

## 6. Pilot proof and remaining deployment gates

- Same-account recovery after keep-work sign-out, export without purge, different-account isolation and sender shutdown pass.
- Skip/unskip/complete/undo, all-day due times, DST choices and per-series timezone changes pass their domain/queue tests.
- Full-cache eviction preserves queued work and correct coverage across tabs/reload; migrations do not reset pending partitions.
- Prepared deletion cannot execute without confirmation; expired reauthentication fails; lost confirm/Admin responses, runner lease recovery and post-deletion status converge truthfully.
- Rate/cost reservations hold under concurrent instances; direct table reads cannot bypass the read boundary; 429/unknown outcomes preserve retry identity.
- Production Auth email delivery, chosen paid plans/secrets/ingress controls and monitoring are configured in the intended environment.
- Backup freshness and an isolated restore, including stale-device/receipt handling, are demonstrated; objects have their separate gate when they exist.

The design decisions are settled here. Pilot readiness remains blocked until implementation and these observations exist. Exact versions/runtime/local development scripts still belong to the next development-setup checklist.
