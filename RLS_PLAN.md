# Supabase RLS, Grants, and Command Security Plan

**Updated:** 14 October 2026

**Status:** Security design baseline. Local calendar foundation migrations/tests now exist as recorded in [the webapp status](webapp/README.md); illustrative SQL below is not proof of the entire pilot implementation. Assistant/knowledge policies remain to be designed. This brainstorming pass makes no database/security changes or remote connection.

**Companion:** [Database structure](DATABASE_SCHEMA_PLAN.md). Also read [sync](LOCAL_SYNC_DESIGN.md), [technical design](TECHNICAL_DESIGN.md), [creator publishing](CREATOR_PLAN.md), and [agent guide](AGENTS.md).

**API detail:** [API_CONTRACTS.md](API_CONTRACTS.md) specifies typed command envelopes, wire revisions, scope reads, related guards, safe transport errors and the first implementation slice. Function names/signatures remain proposed until locally tested migrations exist.

**Operating detail:** [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md) defines retained queues, private budget/deletion records, service-only deletion markers, shared limits and restore handling. The foundation has eleven tables; the complete calendar pilot has thirteen. These remain documentation-only requirements.

**Personalization extension:** [PERSONALIZATION_PLAN.md](PERSONALIZATION_PLAN.md#8-data-architecture-and-contracts-to-design) proposes private configuration/rules/memory and later narrow action grants/templates. Exact schema and policies are not designed or executed by this extension. Owner RLS remains necessary, while assistant-specific permission checks must also run at trusted tool execution. Persona text, model output and templates cannot create grants. Public sharing requires a separate allowlisted projection; never expose private assistant rows through it.

**Knowledge extension:** [SECOND_BRAIN_PLAN.md](SECOND_BRAIN_PLAN.md) proposes private notes, sources, links and optional derived chunks/vectors. Every read/search/link traversal must enforce authenticated ownership and current parent/source eligibility before model context is assembled. A broad privileged vector search followed by client filtering is not acceptable isolation. Prevent cross-owner source/person/link references; deletion invalidates derived access. New precise schemas, grants, functions and adversarial fixtures are still to be designed. A friend's agent has no default access to any of these records.

Automatic organization may persist reversible generated summaries/topic/mention links through narrowly scoped validated operations without per-item human approval. Processing configuration, authenticated owner, source/target eligibility, revisions and correction overrides remain enforced outside the model. This grants no authority to alter People facts, rules, calendar state or permissions; those retain distinct command/approval contracts. The model never receives an unrestricted writer.

## 1. Access model

**Private data by default; authenticated users read their own rows; controlled commands perform all application writes.** RLS decides which rows are accessible. Grants decide which operations a role can attempt. Constraints/revision checks enforce relationships and valid state. An owner policy alone cannot protect XP or make offline retries transactional. These are complementary controls, as described in [Supabase Data API security](https://supabase.com/docs/guides/api/securing-your-api).

No organization, sharing, guild, or team-role system is required initially. Ownership is the Auth UUID. Do not use editable user metadata as an administrator/creator-publishing grant. Anonymous Auth accounts are separate from signed-out `anon` requests; anonymous sign-in is not part of the chosen initial Auth flow.

| Actor | Initial private reads | Initial application writes | Boundary |
| --- | --- | --- | --- |
| Signed-out `anon` | None | None | Landing page requires no private database data |
| `authenticated` user A | Only A's rows through allowlisted read RPCs; table SELECT supports invoker execution | Execute allowlisted command wrappers; no direct INSERT/UPDATE/DELETE | RLS plus verified identity; Data API hook denies direct table endpoints |
| `authenticated` user B | Only B's rows | Same rules for B | Cannot reference A's parent records, receipts, or rewards |
| `gamecal_command_executor` | Required owner-scoped application/internal rows | Required INSERT/UPDATE inside private command implementations | Proposed non-login, non-owner, non-bypass role; not granted to clients |
| `gamecal_invariant_reader` | Minimal occurrence/reward columns needed to check the real pair | None | Unexposed constraint-trigger execution only; no caller-identity dependency or client membership |
| `gamecal_ops_executor` | Only budget/deletion fields and minimal profile existence/lifecycle fields | Private budget reservations, deletion job transitions, profile deletion marker | Non-login/non-owner/non-bypass role; exact implementations executable only by trusted server workflows |
| `service_role` / secret-key workflows | No general application-table grants | Exact service-only operating wrappers, Auth administration, private operations marker Storage | Can bypass RLS when granted access; never ordinary sync/browser credentials |
| Migration/operator role | Trusted schema administration | Tables/functions/policies/migrations | Never a browser credential or ordinary application runtime |

No role receives TRUNCATE, table ownership, schema CREATE, role membership, or arbitrary function execution from browser-facing application grants. The `PUBLIC` pseudo-role means every PostgreSQL role; it is different from the schema named `public`.

## 2. Table permission matrix

`Owner SELECT` includes the user's own tombstones/history where required for sync. Active filtering belongs to the read contract; authorization must not accidentally hide deletions or archived history.

The matrix describes SQL object grants, not permission to use arbitrary HTTP table endpoints. A fail-closed Data API pre-request allowlist admits named POST RPCs and denies direct table endpoints. Table SELECT remains needed for invoker read RPCs; test this additional boundary independently.

| Table | `anon` | `authenticated` direct SELECT | `authenticated` direct I/U/D | Accepted writes |
| --- | --- | --- | --- | --- |
| `public.profiles` | None | `id = auth.uid()` | None | Ensure own profile; validated preferences/timezone/weather settings |
| `public.quest_definitions` | None | `owner_id = auth.uid()` | None | Create/edit/archive/delete through commands |
| `public.quest_schedule_versions` | None | Owner SELECT | None | Controlled schedule-version creation/interval reconciliation |
| `public.quest_occurrences` | None | Owner SELECT | None | Materialize/edit/complete/undo/skip/reschedule/tombstone |
| `public.completion_rewards` | None | Owner SELECT | None | Completion/undo/delete transaction only; never independent reward API |
| `public.weekly_reflections` | None | Owner SELECT | None | Save/delete/explicit restore with expected revision |
| `public.itineraries` | None | Owner SELECT | None | Validated itinerary and optional cover/settings commands |
| `public.itinerary_entries` | None | Owner SELECT | None | Atomic add/attach/edit/detach/parent cleanup commands |
| `public.itinerary_weather_locations` | None | Owner SELECT | None | Owner-matched base/dated location commands and cleanup |
| `app_private.mutation_receipts` | None | No table grant; own result RPC only | None | Internal claim/result in the same accepted transaction |
| `app_private.schedule_materialization` | None | No table grant; coverage summary RPC only | None | Internal bounded catch-up operation |
| `app_private.request_budgets` | None | No table grant | None | Fixed own request buckets through hook; provider/job reservations through service-only operating functions |
| `app_private.account_deletion_jobs` | None | No table grant; narrow server status only | None | Verified prepare/confirm, trusted worker/cleanup; no Auth/profile cascade |

Enable RLS on **all thirteen** pilot application/internal tables, with the eleven foundation tables created first. Grant the command executor only implemented domain/sync operations and fixed own budget columns. It has no deletion-job/global-budget access or physical DELETE. The ops executor has narrowly granted operating-record maintenance and profile lifecycle fields, never ordinary content/reward writes; physical cleanup is limited to its two operating tables. No client table grant exposes them.

Inspect and revoke automatic client/PUBLIC application-object grants before adding explicit ones. Also remove default `service_role` grants on Gamecal tables where they are not required; leave Supabase-managed Auth/Storage permissions alone. Apply table creation, grants, RLS, policies, and functions within a migration transaction so no exposed gap exists. Default privilege changes apply to the actual migration object-creator role and future application objects; audit existing grants separately. Do not blindly revoke every managed function in the project.

Illustrative owner-read pattern, **not executed**:

```sql
ALTER TABLE public.quest_occurrences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.quest_occurrences
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON TABLE public.quest_occurrences TO authenticated;

CREATE POLICY occurrences_owner_read
ON public.quest_occurrences FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = owner_id);
```

Profiles substitute `id` for `owner_id`. No authenticated write policy or table write grant is added by this example. A missing/null `auth.uid()` cannot satisfy equality. Explicit role targets and indexed ownership columns keep policy intent clear. See [Supabase RLS guidance](https://supabase.com/docs/guides/database/postgres/row-level-security).

## 3. Controlled command boundary

Expose small typed RPC wrappers in `public`, using **SECURITY INVOKER**. Each delegates to its matching implementation in unexposed `app_private`. The private implementation uses **SECURITY DEFINER** under `gamecal_command_executor` because caller table writes are deliberately unavailable. Keep helper elevation out of the exposed schema, restrict execution, and pin `search_path = ''` with fully qualified identifiers.

Proposed executor attributes: NOLOGIN, NOINHERIT, NOBYPASSRLS; it owns command implementations, **not tables**, and has no membership in privileged Supabase roles. Migration/operator ownership remains separate. RLS still applies to the executor. Confirm supported role ownership/grants in the disposable environment before promoting migrations; do not silently replace the executor with a broad postgres-owned definer.

To execute the invoker wrapper, `authenticated` needs schema usage and EXECUTE on that exact private implementation, but still has **no private table grants** and `app_private` is not API-exposed. Check authorization in the implementation itself so an alternative authorized call path cannot bypass the wrapper. Revoke default EXECUTE from PUBLIC/anon and grant only named wrappers/implementations; avoid a generic arbitrary-table/SQL mutation endpoint. Never expose an internal helper just to fix an API error.

For each executor-accessed table, define a role-specific SELECT policy and INSERT/UPDATE policies:

| Executor policy | Predicate |
| --- | --- |
| SELECT USING | `owner_id = (SELECT auth.uid())` |
| INSERT WITH CHECK | Same owner predicate |
| UPDATE USING and WITH CHECK | Same owner predicate for old and new rows |
| DELETE | None |

Profiles use `id`. Receipts/materialization use their owner column. These policies are scoped to the executor; they do not grant browser write access. Empty identity fails closed. Explicit owner validation, immutable ID/owner checks, parent FKs, revision/state guards, and field allowlists remain inside commands; a role's RLS permission is not business-rule permission.

The deferred reward constraint trigger is a distinct trusted read boundary. Its unexposed SECURITY DEFINER implementation is owned by `gamecal_invariant_reader`, also non-login/non-owner/non-bypass. Give that role SELECT only on the minimal occurrence/reward identity, kind, status, deletion, active-reward, amount, and rule columns, with role-specific read policies independent of `auth.uid()`. It needs cross-owner visibility to validate actual event-supplied pairs during Auth deletion, but no notes/preferences, writes, or callable client result. Revoke client EXECUTE and role membership; it is a trigger function, not an RPC. Test that authorized cascades succeed without JWT context and that the trigger rejects invalid pairs instead of being fooled by owner-filtered visibility.

Operating functions use the separate non-login/non-owner/non-bypass `gamecal_ops_executor`. Explicit ops-only policies allow its minimal budget/job access and profile ID/lifecycle checks without an end-user JWT. Public service-only invoker wrappers delegate to exact private implementations, with EXECUTE revoked from PUBLIC/anon/authenticated and granted only to the trusted server role; implementations also verify the verified service-call context. Never infer the original caller from a definer's `current_user`. The operations marker bucket allows service-only writes/reads and has no user/anonymous object grant. Normal command policies must not gain global budget/job visibility.

Invoker/definer privileges and ownership require independent review; an ordinary postgres-owned definer can bypass table RLS. PostgreSQL documents owner/bypass behavior in [row-security rules](https://www.postgresql.org/docs/current/ddl-rowsecurity.html), and safe definer setup in [CREATE FUNCTION](https://www.postgresql.org/docs/current/sql-createfunction.html). Prefer invoker functions for reads that need no elevation; [Supabase function security](https://supabase.com/docs/guides/database/functions) explains execution grants and search-path protection.

### Command acceptance protocol

1. Derive `actor_id` from verified `auth.uid()`; reject absent identity and require a live own profile, except for its narrow bootstrap command. Do not accept a caller-selected owner or trust `current_user` as the person's UUID.
2. Validate bounded typed fields/command version; form the canonical payload hash, including expected revisions and observed action inputs. Do not include server acceptance time in that retry hash.
3. Lock the owner's profile first. Check the operation receipt: identical accepted retry returns its old outcome; another payload under that UUID fails. Claim a new receipt within this same transaction.
   Request-budget locks in the pre-request hook precede this domain lock order. After receipt lookup, reject new work for deletion-requested profiles or mismatched sync epochs; bootstrap is the documented narrow exception. Accepted receipt replay has no new domain effect. Counter changes from a raised failing request roll back and are not persistent failed-attempt accounting.
4. Lock affected definition/occurrence/itinerary parents in one documented order; validate owner relationships, tombstones, active-parent requirements for new children, expected revisions, and permitted transitions. History operations may still access an archived definition's live historical occurrences.
5. Apply the field-limited mutation, reward/relationship changes, entity revisions, and owner snapshot-counter increment atomically. Run deferred cross-table invariants at commit. Roll back everything on failure.
6. Finalize compact successful receipt/result; return its accepted IDs/revisions, with current canonical owner rows/progression separately where needed for local acknowledgment. Read those under the owner lock, and distinguish them from a replay's historical acknowledgment. A receipt replay cannot modify newer state or rerun a celebration; no full historical private snapshot needs to live in the receipt.

Input must never directly assign owner, server timestamps, revisions, account counter, XP, reward rule, computed level, or an unrestricted status transition. Proposed completion wrapper is `complete_occurrence(request jsonb)` with validated version/operation/expected revision envelope, occurrence source reference, and observed time/zone data, as defined in the API contract. Validate owner, definition/date/version and deterministic identity before materializing a missing recurring occurrence; reject changed sources rather than substituting a different task. Award value/kind eligibility comes from locked canonical records and the database rule, not the model/browser.

Errors distinguish validation, unauthenticated, stale conflict, snapshot changed, scope too large, unavailable, and unexpected. Treat missing/inaccessible entity lookups equivalently; avoid returning another user's constraint detail, row contents, or IDs. Preserve pending work rather than retrying denied/invalid commands forever.

Any failure after receipt claim must roll back its writes/claim, using a raised error or a correctly scoped subtransaction; returning an error-shaped JSON value alone does not roll back SQL. Normalize database exceptions at the command boundary without committing partial work. Validate deferred application constraints before successful return where needed to surface a controlled error, and still enforce them at commit. Test both function-time and commit-time failure paths.

## 4. Read RPCs, snapshots, and views

Owner SELECT supports bounded invoker RPCs; direct Data API table endpoints are denied by the pre-request allowlist. A multi-table or paginated complete scope uses the database snapshot contract, not unrelated HTTP reads. Proposed narrow RPCs: `get_calendar_scope`, `get_itinerary_scope`, `get_progression`, `get_own_operation_result`, and owner export. Private read helpers use the same verified owner boundary where internal bookkeeping is needed; ordinary aggregation over owner-readable rows can be invoker security.

Return validated requested scope, deterministic page cursor, `account_data_revision` token, bounded rows, tombstones, and coverage. Each page checks the token and reads its rows in one SQL statement/snapshot. Any accepted scoped change invalidates it. Restart a changed confirmed pull without discarding pending overlays. Clamp date windows/page sizes; reject oversized/unrecognized scopes rather than returning false completeness. Export uses the same consistent owner snapshot approach and omits credentials/internal raw bookkeeping.

Explicit materialization commands precede scope reads; reads do not mutate. Wire counters/revisions are decimal strings; tokens also bind scope and first-page time context/expiry. Snapshot paging completeness and recurrence-generation completeness are separate response fields. Parse token/cursor data as untrusted; it cannot choose an owner or bypass grants. Follow the API plan's acknowledgment/canonical/invalidation contract when reconciling broad changes.

A view is not automatically safe because its underlying table has RLS. Avoid exposing private views initially. If one is needed later, verify the server version supports `security_invoker = true`, use explicit columns, and test its grants/RLS as a separate object. No `SELECT *` public projection or privileged view silently bypassing ownership. Do not grant schema CREATE to clients or permit client-selected search paths.

RLS does not replace rate limiting, request-size limits, or service isolation. Implement those at the actual API/command boundary. Do not assume a Data API pre-request hook also protects Storage, Auth, or future other products.

Apply the operations plan's fixed request buckets at the Data API boundary and separately committed provider reservations from Next.js; browser users cannot reset/increase budgets or invoke service-only helpers. Deny direct table endpoints and oversized/unrecognized RPCs. Verify Supabase ingress separately because transactional hook counters cannot persist a failed call. Snapshot tokens/ordinary commands bind server-owned `sync_epoch`; restoration remints it, with missing old-epoch receipts requiring review. Do not grant user updates to epoch/deletion fields.

Budget-accounted wrappers use POST/VOLATILE so accounting is permitted by PostgREST transaction mode; domain reads still select consistently. In Gamecal-only environments disable unused pg_graphql after dependency inspection, verify browser GraphQL access is closed, and leave private application tables out of Realtime publications. Owner SELECT grants must not create an alternative to the bounded read RPCs; shared-project exceptions need their own reviewed restriction.

## 5. Creator/public reader policy — later

Future creator base tables stay unexposed in `app_private`. Owner read/metadata RPCs enforce `auth.uid()` and composite ownership. Creator profiles are provisioned for the invited pilot through a trusted workflow; editable profile/user metadata cannot enroll someone as a privileged publisher/operator. No client can change publication/audit/readiness fields directly.

| Actor | Future access |
| --- | --- |
| Creator owner | Own drafts/pages/slots and owner preview via authenticated allowlisted RPCs; metadata commands; explicit online schedule/cancel/withdraw |
| Other authenticated user | Same public released content as a guest; no other creator's draft or private quest links |
| Guest reader | Allowlisted public series/chapter/announcement RPC results only; no base-table grants, account IDs, or unpublished external links |
| `gamecal_public_reader` | Proposed restricted non-login/non-owner/non-bypass role; SELECT of eligible published rows/columns only inside private public-read implementation |
| `gamecal_publisher` | Proposed restricted system role for the unexposed due-release function; minimum required schedule/chapter/version/event/counter operations, no browser role membership |

Public invoker wrappers may receive EXECUTE for anon/authenticated **only when this module ships**; they delegate to exact unexposed read implementations. The public-reader role has narrow SELECT policies/grants requiring live public series, live published chapter/version, and database publication time. It receives no private calendar, receipt, booking, or production-link access. Carefully order parent eligibility helpers/policies to avoid recursive RLS queries.

Allowlist DTO fields: public creator slug/pen name/chosen bio, series slug/title/description/reading settings, released chapter metadata, and published page descriptions/dimensions. Resolve media object references internally. Never return owner UUID/email, drafts, booking details, private links, storage reservation tokens, or unpublished page paths. Upcoming slot timestamps need the creator's explicit announcement preference; assignment metadata stays private.

Publication is a separate restricted backend function, not an owner-read definer with all-user access. Cron invokes it through the trusted scheduler role; neither anon nor authenticated may EXECUTE it. Per-owner work locks the profile first, then due slot/chapter rows, so it shares the normal lock order. Duplicate jobs, cancel races, missing readiness, and withdrawn/hidden series must fail safely. All-user system access is confined to this reviewed worker; never add `USING (true)` to a browser policy for it.

## 6. Creator Storage RLS — later

Private bucket example: `creator-artwork`. Proposed immutable object naming: `<owner_uuid>/<chapter_uuid>/<version_uuid>/<page_uuid>/<variant>`. A folder prefix is not authorization by itself; resolve it against an existing owner-matched reservation/manifest and actual publication state.

| Storage operation | Signed-out visitor | Creator owner | Trusted transfer/media/cleanup workflow |
| --- | --- | --- | --- |
| INSERT | Denied | Only a reserved own draft/version path, with bucket restrictions | Narrow signed upload/reservation if deliberately used |
| SELECT/list/download | No direct object grant, including published originals | Own authorized draft/preview objects only | Sign verified currently published reader variants |
| UPDATE/upsert | Denied | Denied; use a new immutable object path | No in-place scheduled/published overwrite |
| DELETE | Denied | No raw client DELETE | Retryable cleanup of unreferenced drafts or account deletion |

Enforce allowed MIME/file limits at the bucket and verify decoded content/dimensions/ownership before finalizing a page as ready. No client-asserted `ready=true`. Storage policies need their own tests; application-table RLS does not secure object downloads. See [Supabase Storage access control](https://supabase.com/docs/guides/storage/security/access-control).

The public media service checks a current published manifest/version before signing a short-lived reader URL; never sign an arbitrary supplied path. Keep signing credentials server-only, limit requests, and exclude URLs/tokens from shared caches and logs. Withdrawal denies new access; existing issued URLs can survive until expiry, as described in [signed URL behavior](https://supabase.com/docs/guides/storage/serving/downloads). No promise to recall downloaded copies.

Storage cleanup is independent of row cascades. When implementing hosted content, add a backend-only retryable cleanup-job record that can survive Auth-row deletion, captures only required object references, and has no browser table grant. Delete objects through the Storage API, not manual DELETEs on `storage.objects`. The exact job schema/retention belongs to that later migration set.

## 7. Other feature boundaries

- AI has no direct elevated database capability. Calendar actions use reviewed proposals and the normal validated save path. Knowledge organization has the narrow derived-output exception described above, validated independently of model text; it cannot mutate calendar facts or permissions. Persistent chat is not implied by note capture.
- Weather/Pexels reads keep provider secrets server-side. Durable location/photo preferences remain owner-controlled rows; provider response/audio/image binaries are excluded from the calendar schema/outbox.
- Twin-mascot/workspace state is presentation state. Radio is parked. These features do not justify new permissive policies, public account profiles, or XP grants.
- Future sharing requires explicit membership/owner/viewer/editor semantics and a new policy/test design. UUIDs alone do not grant permission or establish multiplayer readiness.

## 8. Verification matrix

These are **planned tests**, not passing results. Use a disposable local Supabase database and realistic Auth JWT contexts/roles; do not run only as postgres/service_role and call that an RLS test. Create user A, user B, their records, and signed-out requests. Verify actual allowed row contents/counts, not just that a query did not throw.

| Case | Required result |
| --- | --- |
| A reads A's entities/rewards/history/tombstones | Exact intended rows through RPCs and SQL policy fixtures; direct HTTP table endpoints denied |
| A reads B's IDs, joins, counts, nested parents, or RPCs | No private rows/metadata disclosed; inaccessible lookup has generic outcome |
| Anonymous private read or private command | No rows or denied operation; null identity cannot claim an owner |
| A directly inserts/updates/deletes own rows | Denied even though A owns them; only command path is permitted |
| A tries changing owner/ID/revision/time/counter/XP/status by command | Protected field rejected; server values authoritative |
| A links B's definition/version/occurrence/itinerary | Denied by command and composite FK; no partial writes |
| Same-owner occurrence references version from another definition | Denied |
| Repeated receipt, changed-payload reuse, delayed completion after undo | One accepted effect; conflicting payload rejected; no XP resurrection |
| Stale revision or concurrent completion/undo/series edit | Conflict or correct serialization; at most one active reward |
| Owner reads aggregate/view/snapshot/export | Owner-only, consistent with accepted rewards; no privileged-view leak |
| Change between snapshot pages / materialization during pull | Token invalidation/restart; no partial scope accepted as complete |
| Parent tombstone plus stale queued child operation | Cannot restore deleted metadata; calendar history/valid reward behavior preserved |
| New table/function privilege defaults and executor role attributes | No inherited write/EXECUTE gap; executor not owner/bypass/client member |
| Deferred reward checker with/without JWT and account cascade | Actual pair checked through restricted trigger role; no hidden-row false result or cleanup permission failure |
| Account deletion | Complete graph removed; no unrelated account changes; future Storage job survives until cleanup |
| Ops role/direct table/forged status secret | No user access to budget/jobs/markers; limited status DTO only with valid capability; server functions cannot be called by a browser |
| Concurrent budget reservation / failed command / 429 | Shared caps hold for their documented committed/reserved units; failed-call accounting limits remain truthful; outbox request identity retained |
| Operational restore / old pending command | Epoch changes invalidate scopes; accepted receipt reconciles without effect, missing old receipt requires review; deletion markers prevent account reactivation |
| Future public chapter before target/withdrawal/hidden series | No new public metadata/media access |
| Future owner draft preview and forged Storage path/upsert | Own preview only; unauthorized or immutable path writes denied |
| Future Cron worker via browser versus scheduler, duplicate run/cancel race | Browser cannot execute worker; scheduler publishes once with truthful status |

Also test ordinary recurrence/timezone/date-line rules, same-day quest versus multi-day appointment validation, restored reflections, coordinate/text bounds, RLS policy performance, page-size limits, and deleted/archived history operations. Inspect grants/policies/role memberships and exposed schemas as part of migration verification. Table/constraint tests and function EXECUTE tests must accompany feature acceptance.

## 9. Review decisions and implementation boundary

Recommended defaults: one owner per private domain record; owner SELECT for allowlisted invoker RPCs, direct table endpoints denied; controlled ordinary writes; eleven foundation/thirteen pilot tables with private operating exceptions; snapshot counter/restore epoch; no public content until publishing ships; service-only operations markers before pilot and private creator buckets later.

Before implementation, verify the actual local PostgreSQL/Supabase versions, UUID/exclusion-extension support, custom role ownership, Auth flow, and planned migration/tooling. Before remote application, establish the intended project/environment and authorization, inspect existing objects/defaults, and present tested migrations. **The current task ends with reviewed planning documents; it does not connect or apply any of this.**
