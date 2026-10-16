# First Session Screens and Acceptance Flow

**Updated:** 16 October 2026

**Status:** UX and acceptance plan. The [webapp foundation](webapp/README.md) exists, including local Auth configuration, but these screens/Auth journeys, provider connections, migrations and database execution remain unimplemented.

**Related:** [Product scope](PRODUCT_PLAN.md), [workspace/mascots](UI_UX_PLAN.md), [API contracts](API_CONTRACTS.md), [local sync](LOCAL_SYNC_DESIGN.md), [technical design](TECHNICAL_DESIGN.md), [database](DATABASE_SCHEMA_PLAN.md), [permissions](RLS_PLAN.md), and [agent guide](AGENTS.md).

## 1. Outcome and bounded first slice

A new user can create a private account, confirm their planning timezone, enter the Calendar/AI split workspace, schedule one real task, mark it complete, see accepted progress, and undo a mistaken completion. If connectivity interrupts this flow, local work remains recoverable and the UI explains what is saved versus synced.

The first implementation slice is **sign up/sign in -> ensure profile -> create a one-off quest -> read/reconcile -> complete -> undo**, including its core failures. It proves the foundation; it is not the whole launch checklist. Recurrence, itinerary/weather, full weekly review, working AI generation, creator publishing, radio, and optional 3D remain subsequent feature gates.

Do not prepopulate real records or simulate accepted rewards to make onboarding look successful. Offer a removable example prompt such as “Write one paragraph,” but the user decides whether to make it an actual quest and when it is done. Reading instructions, signing in, opening a panel, and chatting award no XP.

Start at Level 1 and 0 XP. One accepted quest gives 20 XP, leaving 80 XP to Level 2. The lamp appears at 100 XP/five valid completions; the first session does not require five tasks or grant an early unlock. Room visuals reflect current accepted rewards, including undo.

## 2. Screen sequence and primary actions

| Screen/state | What the user sees | Primary action | Data/transition boundary |
| --- | --- | --- | --- |
| Welcome | Short calendar/progress promise, Create account, Sign in | Choose account flow | No private data, tracking prompt, sample mutation or AI call |
| Create account | Email/password, visible requirements, show/hide password, Sign in link | Create account | Supabase Auth; no custom password database |
| Verify email | Check-your-email message, resend with actual cooldown, change email / back to sign in | Follow valid verification link, then sign in if needed | Success requires a verified usable session, not a local success flag |
| Sign in | Email/password, Forgot password, Create account link | Sign in | Failed sign-in preserves email and explains retry; credentials stay with Auth integration |
| Recovery | Email request; valid reset link opens new-password form | Request/reset password | Neutral request response; invalid/expired link offers a new request |
| Set up calendar | Suggested valid browser IANA zone; editable zone; optional display name | Continue | `ensure_profile` accepted online before initial private workspace |
| Workspace loading | Layout skeleton or labeled existing cache, visible loading/error state | Wait / retry | Verify account, open matching partition, load own profile/scope; no false empty day |
| First split workspace | Calendar-left 50%, Planner-right 50%, Calendar/Both/AI controls | Focus Calendar or Add Quest | No mascot in split; no model request on entry |
| Quest editor | Title and selected date, optional details, Save/Cancel | Save | Validate, create stable IDs, then atomic local command write |
| Pending quest | Agenda row with Saved on this device / syncing marker | Work on it or continue planning | Durable local save; accepted cloud data may still be pending |
| Completed locally | Checkmark plus completion waiting to sync; visible Undo | Undo or continue | Queue completion; confirmed XP waits for acknowledgment |
| Completed and synced | Completed row, accepted +20 XP, updated level/progress | Undo / next action | Current canonical reward/progression, no duplicate reveal |
| Undo locally / synced | Task restored to pending; undo waiting or completed | Continue planning | Queue undo; canonical reward reversed after acceptance |

This is a flow of screen states, not a mandatory slideshow. Returning users with an existing profile skip setup; a verified existing session skips account forms. A user can leave onboarding without creating a quest. No completion or tutorial popup blocks access to the calendar.

## 3. Authentication and setup details

Keep **email/password with verification and password recovery** as the existing proposed first method; it is not newly confirmed branding or an added provider. Implement against the actual supported [Supabase password flow](https://supabase.com/docs/guides/auth/passwords) and the project's SSR/cookie integration. Hosted/local verification defaults may differ, so explicitly configure and test the intended local verification behavior later rather than bypassing it to make a test pass.

Use proper field labels, password-manager/autocomplete support, show/hide password, and an explicit submit action. No password copy in Dexie, logs, analytics, screenshots/fixtures, or a custom endpoint. Do not ask for password confirmation unless real usability evidence justifies the extra entry. Requirements match the configured provider policy, not a second contradictory client policy.

Verification/recovery handling includes sending, resend cooldown/rate-limited, malformed link, expired link, and callback/session failure. Configure only intended callback origins/local return routes. Following a link can happen in another browser/device; handle that supported session path or direct the user back to sign in, without leaking or transferring the first browser's private drafts. Recovery completion never silently authenticates a different account partition.

Email delivery is an implementation prerequisite before an invited pilot. Verify the actual SMTP provider/allowances, templates, deployment redirects and delivery; do not assume Supabase's trial delivery is suitable for arbitrary pilot addresses. Local Auth email capture can verify development flows without sending real emails. See [Supabase SMTP guidance](https://supabase.com/docs/guides/auth/auth-smtp). No provider account or email has been configured/sent in this planning task.

Setup suggests the browser timezone, shows its IANA name and example local date/time, and allows correction. Do not infer a timezone from an itinerary destination, request GPS, or force Asia/Singapore for all users. Optional display name can remain blank. Streaks default off; celebrations default on while system reduced motion still applies. Further settings remain accessible later without adding first-session questions.

Continue uses a stable bootstrap operation ID/request and remains pending until accepted. A failed or ambiguous profile response offers retry/reconciliation without creating another profile or overwriting existing preferences. Reloading checks the canonical profile before asking the user to start over. A changed device timezone suggests a setting review, not an automatic rewrite of appointments/history.

## 4. Workspace, editor, and mascot behavior

Reuse [the three-state workspace contract](UI_UX_PLAN.md#2-three-layout-states): split initially; Calendar focus hides Planner right; AI focus hides Calendar left. Only the hidden panel's twin appears at that edge. Open Calendar/Open AI from its deterministic conversation restores split; Ask planner opens the right composer. A labeled mode control always provides another way back.

First use shows concise Focus Calendar/Focus AI labels. Calendar dates, quest checkboxes, forms and scrolling keep their normal behavior. On narrow phones the split is a compact overview; Add Quest can deliberately enter Calendar focus and open the full-width keyboard-safe sheet in one action. On desktop it opens a dialog from the current Calendar surface. Do not switch views accidentally because the user tapped a calendar date or edited text.

The right panel can ship a clearly labeled deterministic guidance/unavailable state while real AI planning is not enabled. It can explain the workflow or open the normal editor; it cannot show canned text as a live personalized model result. Opening the panel/mascot never spends an AI request. Working proposals follow the separate reviewed editor journey in the API/UX plans.

Quest editor fields:

- Title required and focused; date required but prefilled from the selected calendar day in the planning zone.
- Quest kind default; category Personal and priority Side. Appointment choice makes its zero-XP behavior clear without introducing a separate editor/backend.
- Time, notes, category/priority and other optional details stay progressively disclosed. No recurrence controls until that slice is implemented; do not show nonfunctional controls.
- Save is blocked for invalid input, with inline messages. Save disables duplicate submission only during the local transaction, not for an entire network sync delay.
- A successful local transaction closes the editor and shows the projected row. A failed write leaves the form and all text visible; Cancel/Close with dirty text offers Keep editing or explicit Discard draft.

Unsaved form/assistant drafts survive panel switches within the session. They are **not** promised to survive a tab reload/browser closure until an explicit draft-persistence feature exists. “Saved on this device” appears only after the Dexie transaction succeeds; it cannot describe an unsaved form. Confirmed cached coverage, pending commands, and accepted rewards have the durable contracts in the sync plan.

Editor dismissal returns focus to its initiating control; hidden panels leave keyboard navigation. When Add Quest expanded a phone preview, closing the sheet returns to the selected-day calendar without losing the row/date. Use accessible dialog focus/dismiss behavior from [W3C's modal dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/). Mascot popovers remain lightweight navigation helpers and cannot cover Save, bottom navigation, or the keyboard composer.

## 5. Completion, undo, and feedback states

Use a named task checkbox or Complete action, with an accessible label tied to the title. A click first attempts an atomic local command write. Only after success can the row display its locally completed checkmark and pending-sync state. Record the observed time/confirmed planning zone at the action; server acceptance supplies canonical reward/date semantics.

After a synced completion, show restrained +20 XP feedback and current accepted progress. No required sound, blocking reveal, or repeated celebration on refresh/retry. Preserve a visible Undo completion action on the row/details after any short success toast disappears; accidental completion must remain reversible. Completing an appointment shows attendance and zero XP.

Undo is a new command with a dependency on the completion when needed, not cancellation of an uncertain transmitted request. The task can appear pending locally with Undo waiting to sync. If its completion reward is already accepted, confirmed XP may still include it until reversal acceptance; label that pending adjustment rather than subtracting speculative XP or hiding the server value.

If complete and undo are queued before reconnection, retain their order and frozen payloads. Suppress XP/unlock celebrations for an intermediate acceptance already superseded by the queued undo. Final accepted XP is unchanged from before that pair. A duplicate click/retry/second tab cannot multiply one occurrence's reward. If Undo fails validation/conflict, keep the pending intention recoverable; do not claim the reversal is synced.

| Example from a fresh account | Local task | Confirmed XP | Feedback |
| --- | --- | --- | --- |
| New task saved locally, unsynced | Pending | 0 | Saved on this device |
| Completion queued | Completed, waiting | 0 | Completion waiting to sync |
| Completion accepted | Completed | 20 | +20 XP; 80 XP to Level 2 |
| Undo queued after acceptance | Pending, waiting | 20 | Undo waiting to sync; progress update pending |
| Undo accepted | Pending | 0 | Completion undone; accepted progress updated |
| Complete then undo both queued | Pending, waiting | 0 | Changes waiting to sync; no intermediate reward celebration |

The first-session acceptance ends at this reversible loop. A separate fixture with four prior accepted rewards proves a fifth completion unlocks Level 2/lamp, and undo returns to 80 XP/Level 1. It is test setup in a disposable environment, not a seeded production reward or a requirement to rush five tasks.

## 6. Loading, sync, and recovery copy

Display a compact global sync indicator with a details panel and relevant row markers. Keep network/coverage, account/session, write durability, and confirmed rewards distinct; “Synced” does not mean an uncached day is empty or AI is available.

| State | Suggested product copy | Available recovery / limit |
| --- | --- | --- |
| Initial uncached load | Loading your calendar… | Retry on failure; no empty-state call to action until coverage is known |
| Confirmed empty day | No plans for this day yet. | Add Quest; only after a complete scope/generation result |
| Durable pending changes | Saved on this device · changes waiting to sync | Continue cached planning; inspect pending items |
| Active sender | Syncing changes… | Do not block independent local work |
| Accepted writes, refreshing scope | Changes synced · updating calendar… | Keep incomplete/invalidated coverage explicit |
| Drained and refreshed scope | Synced | Quiet indicator; accepted row/progression state |
| Interrupted connection | Connection interrupted. Saved changes will sync when you reconnect. | Cached-calendar edits only; uncached scope remains unavailable |
| Local storage write failed | Couldn't save on this device. Your draft is still open. | Retry after storage issue resolved or keep/copy draft; no cloud-only fallback |
| Expired session | Sign in again to sync your saved changes. | Pause/lock that account; preserve pending work for same-account recovery |
| Stale edit | This quest changed elsewhere. Review both versions. | Keep current version or review/reapply retained intention |
| Deleted remote task | This quest was deleted elsewhere. Your pending change is still available. | Keep deletion or explicitly create a new quest identity |
| Ambiguous save response | Saved on this device · checking sync status | Reconcile/retry same operation; no duplicate creation or false failure |
| Invalid observed clock | Check this device's date and time before retrying completion. | Preserve pending command; deliberate corrected action gets a new operation identity |

These are initial copy proposals, not extra persistent status columns. Row outcomes remain pending/completed/skipped; sync state belongs to the queue/projection. Say changes are saved only if the local transaction actually succeeded. Announce save/error/state changes appropriately without stealing focus or repeatedly announcing normal polling; see [W3C status-message guidance](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html).

Initial sign-in/fresh app loading and uncached scopes require internet. An already-open app with a still-usable account session can queue valid cached edits during an interruption. Expired sessions pause/lock access under the current account policy. After an online reload/authenticated startup, the durable queue resumes; the MVP does not guarantee airplane-mode cold start or browser-closed calendar sync.

Conflict panel: show owner-only current server values and the user's retained intention with clear labels. Keep current version explicitly discards the affected local intention after the user reviews it; explain any dependent commands that also cannot apply. Review my change opens the normal editor against the refreshed version and creates a new deliberate operation only on Save. It never rewrites a frozen attempted payload. A remotely deleted record cannot be silently restored through an edit.

Signing out with pending work offers Sync first, Keep work and sign out, Export a copy, Discard and sign out, or Stay signed in. Keep work stops senders and retains a locked account partition until verified same-account return. Export contains private partial cache/queue data and has no MVP import path; exporting or acknowledging the file never clears the queue. Only drained work, explicit discard, or confirmed account deletion permits clearing. A different signed-in account never sees or sends this queue. Follow [the operations contract](OPERATIONS_PLAN.md#1-sign-out-and-local-recovery).

Discard concerns the local pending copy; it cannot undo a command already accepted by the server or guarantee cancellation of an in-flight request. Pause/coordinate senders and reconcile ambiguous work before clearing where possible. Explain this distinction if the user chooses local discard while acceptance remains unknown; no false “cloud changes cancelled” message. Reopening later reconciles canonical account state normally.

## 7. Acceptance journeys and observable proof

Tests below are planned, not executed. Use real local database/RLS/receipt contracts with fixture users and a controlled clock; mock-only UI success is insufficient. Retain the actual script/browser/device observations when implementation exists.

| ID | Journey | Required observation |
| --- | --- | --- |
| FS-01 | Fresh signup -> verify -> sign in -> confirm timezone | No private workspace before verified session; one own profile; returning user skips setup without overwriting preferences |
| FS-02 | Sign-in/recovery/verification failure and retry | Rate limits/expired links show safe states, no account enumeration/password logging, correct account/callback; input preserved appropriately |
| FS-03 | First workspace -> focus Calendar -> open editor | 50/50 split first; AI exits right; planner twin appears only when hidden; editor usable full-width on phone |
| FS-04 | Enter title/date -> Save -> refresh online | Local row only after durable write; one canonical definition/version/occurrence; IDs survive retries/reload |
| FS-05 | Complete synced quest -> wait acceptance -> Undo; verify appointment-kind alternative if enabled | Checkmark pending first; +20 XP accepted once; Undo available; final pending task and 0 XP; appointment attendance/Undo yields zero XP |
| FS-06 | Disconnect open cached app -> create/complete/undo -> reconnect | Local commands survive, dependent order intact, final no active reward, no stale milestone celebration |
| FS-07 | Lose response after server commit -> retry same request | One outcome/reward; old receipt acknowledgment distinct from current canonical row |
| FS-08 | Fail local write or schema/quota operation | Editor remains with text; no saved/checkmark claim, duplicate command, or cloud-only fallback |
| FS-09 | Edit on second device while local edit pending | Conflict retains both own values; review/reapply uses new operation and current observed revision; no silent overwrite |
| FS-10 | Remote deletion / out-of-range move / incomplete page set | Deleted work cannot revive; moved scope corrected; incomplete cache never appears as complete empty day |
| FS-11 | Session expiry, same-account reauth, account switch | Queue paused/locked but retained; only correct account can recover it; no wrong-account replay/history leak |
| FS-12 | Sign-out with pending commands | Explicit sync/keep-work/export/discard/stay choices; same-account resume works; export never purges pending work |
| FS-13 | Split/focus/mascot rapid navigation with editor draft | Correct edge/twin, no orphan popover; selected date/draft and pending saves survive; ordinary controls/scrolling do not collapse views |
| FS-14 | Keyboard, reduced motion, phone keyboard, zoom/large text | Focus exclusion/return, labels, readable states, nonoverlapping targets and usable forms; animation cannot delay save |
| FS-15 | Optional room asset/AI unavailable | Calendar still works; guidance truthful; no automatic model call, fake reward, or rendering dependency |
| FS-16 | Milestone fixture at 80 XP -> complete -> undo | Accepted 100 XP/Level 2/lamp, then 80 XP/Level 1; no duplicate reveal after refresh |

FS-01 through FS-15 define the foundation journey; FS-16 is the next reward/room milestone gate. Full pilot readiness still needs recurrence/date/appointment tests, itinerary/weather, export/deletion, operational recovery, and any separately enabled AI/visual features in the product/technical plans.

FS-12 additionally proves Keep work and sign out -> same-account return -> reconciliation, no access from another account, and export without deletion. Subsequent status controls include Undo skip on row/details: skipped -> pending with no XP, followed by normal complete/reschedule. The [operations plan](OPERATIONS_PLAN.md) adds cache cleanup, deletion prepare/confirm/status, throttling and restored-account review states to pilot proof. Live AI is optional for the calendar pilot and cannot block its release.

Proposed usability checks: users distinguish saved locally versus synced, create a title-only quest in the existing under-20-second target, find Undo without assistance, and identify where the hidden panel went. Treat these as targets/interview observations, not measured results or evidence of growth. Do not send quest titles, emails, prompts or booking details to analytics; anonymous/consented event counts can be considered during the pilot.

## 8. Delivery order and stop condition

1. Sketch the account/setup screens and split workspace/editor/recovery states using this document. Existing workspace interaction preview remains a concept preview, not proof of auth/sync behavior.
2. After implementation is authorized, scaffold the chosen stack, scripts/local Auth configuration and the minimum schema/grants/commands. Test the first one-off path in a disposable local Supabase environment; no remote project is implied.
3. Implement the shell plus truthful pending/completion/undo/conflict states and preserve input/account isolation. Run FS-01–FS-15 and relevant database/date/retry checks, production build, accessibility/device review.
4. Then add recurrence and the milestone gate, followed by the specified itinerary/weather and full pilot lifecycle requirements. Add real AI only under its provider/context/budget gate.

**Planning stop condition:** Screen actions, copy, durability boundaries and acceptance journeys are reviewable and linked to the existing contracts. No build or authentication/database test is reported as passing before it exists.

**Next step:** Use the [development setup and local delivery checklist](DEVELOPMENT_SETUP.md) for runtime/package candidates, scripts, local Auth/email, environment handling and shared fixtures. Once implementation is requested, resolve machine prerequisites and build the first slice above; remote connection/table execution remains outside this planning task.
