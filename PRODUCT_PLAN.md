# Gamecal — Product Review, PRD, and Delivery Plan

**Updated:** 16 October 2026

**Status:** Product scope remains planned. A [webapp foundation](webapp/README.md) now exists with framework/tooling/helpers only; product UI/UX, Auth journeys, calendar commands and sync are not implemented.

**Working name:** Gamecal

**Positioning:** A calendar that makes everyday progress visible.

**Confirmed direction:** General productivity plus personal/business itinerary management; web app first; Supabase from the initial MVP; a clean calendar with a small evolving fantasy room.

This document replaces the earlier Android-first and trader-focused proposals. Scope, mechanics, and technical choices below are recommendations unless explicitly marked confirmed.

**Latest revision:** Use local-first calendar data with IndexedDB/Dexie and background Supabase synchronization from the initial MVP. Supabase holds accepted cross-device account data; local saves keep the UI responsive. Initial sign-in/app loading require internet; guaranteed offline reopening and PWA installation remain later work. This supersedes the earlier online-only write path.

**Implementation references:** [Technical design](TECHNICAL_DESIGN.md) defines architecture, data contracts, and verification. [Agent coding guide](AGENTS.md) defines repository coding rules. Keep this product plan focused on user outcomes and release scope.

**Design principles:** Adopt [CUPID](ARCHITECTURE_PRINCIPLES.md) and the [data architecture principles](DATA_ARCHITECTURE.md): domain-oriented feature modules, clear fact ownership, predictable operations and canonical consistency. The current stack, release gates and planned schema remain unchanged.

**Database/RLS planning:** [Database structure](DATABASE_SCHEMA_PLAN.md) and [permissions plan](RLS_PLAN.md) make the PostgreSQL/Supabase design reviewable before connection or execution: nine owner-readable application tables, two private sync tables plus two private operating tables before pilot readiness, controlled writes, relationship/reward constraints, and separate later public-content policies. No tables, rules, buckets, or remote connection exist yet.

**API planning:** [API_CONTRACTS.md](API_CONTRACTS.md) defines calendar/sync RPCs, reviewed itinerary commands, provider/AI routes, request/response/error contracts, and the first delivery slice. It adds no application implementation or database connection.

**First-session planning:** [FIRST_SESSION_PLAN.md](FIRST_SESSION_PLAN.md) defines account/setup, the first split workspace, quest editor, completion/undo, exact saved-versus-synced copy, and recovery/acceptance journeys. One accepted quest earns 20 XP; the first room upgrade remains at 100 XP. It is documentation only.

**Persistence contract:** [Local sync design](LOCAL_SYNC_DESIGN.md) defines atomic local saves, queued commands, acknowledgments, conflicts, account isolation, and browser-storage limits.

**Gap resolutions:** [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md) defines retained sign-out work, cache cleanup, deletion recovery, request/provider budgets and backup/restore. Undo skip and precise all-day/DST/timezone contracts are in the API/technical plans. These are resolved planning decisions, not implemented guarantees; [the review register](DOCS_REVIEW.md) distinguishes design closure from deployment proof.

**Itinerary extension:** [Itinerary plan](ITINERARY_PLAN.md) covers personal outings/travel and business trips/events using shared calendar entries, daily logistics, and explicit endpoint timezones. Manual itineraries are proposed for the MVP; advanced travel integrations remain later work.

**Weather integration:** [Weather plan](WEATHER_PLAN.md) adds WeatherAPI.com destination forecasts, server-side credentials, near-term capability handling, freshness/retention, and quota control. Weather enriches planning without blocking local saves or changing rewards/bookings.

**Photo exploration:** [Photo plan](PHOTO_PLAN.md) recommends an optional Pexels itinerary-cover experiment: public destination queries, reviewed fallbacks, stable selections, visible credit, and metadata-only storage. Event images remain later; this experiment is not a mandatory MVP gate.

**Creator extension:** [Creator publishing and reader plan](CREATOR_PLAN.md) adds series/chapter preparation, recurring release slots such as Wednesdays, hosted manga reading, and external chapter links. Both hosting modes are confirmed by the user. Recommend a separate invited creator pilot after the calendar MVP; public publishing and artwork storage are a substantial additional scope.

**Parked radio idea:** [Radio plan](RADIO_PLAN.md) saves the user's API article and a bounded optional station/player concept. Radio is explicitly later work; the candidate provider's current free quota and terms remain unverified.

**Main workspace UX:** [UI/UX plan](UI_UX_PLAN.md) defines the requested initial 50/50 Calendar-left/AI-right layout, outward panel exits, twin mascots visible only for hidden panels, and conversational reopening. AI first proposes quests, time blocks, and itinerary changes for user review. This replaces the previous desktop calendar/room split recommendation.

**Research update:** [Research review](RESEARCH_REVIEW.md) records sources, evidence limits, and proposed user-benefit changes: distinguish appointments from quests, support editable time blocks and conflict warnings, emphasize weekly consistency, and connect reflection to a next action. Scheduling remains foundational; game rewards support it.

## 1. Product review

### What is compelling

The strongest idea is connecting real commitments to visible progress. A calendar gives tasks a place in the day; a persistent room gives completed work a lasting reward. The experience should feel useful even before the user cares about the game.

The central hypothesis is: **people will return to their calendar and follow through more consistently when completed commitments visibly improve a personal fantasy room.** This is a hypothesis to test, not an established benefit.

Real-world growth means users make better planning decisions or follow through on personally meaningful commitments. XP represents reported quest completion, not a verified increase in intelligence, fitness, or discipline. Preserve user choice and measure usefulness separately from engagement with the game.

### What needs changing from the original proposal

| Original direction | Recommended change | Reason |
| --- | --- | --- |
| Trading sessions and financial metadata | General categories: Work, Learning, Health, Personal, Admin | The confirmed audience is general productivity users. |
| 3D scene occupies half the mobile screen | Compact room summary above the agenda; larger room in its own view | Planning and today's commitments need immediate visibility. |
| Avatar, six stats, XP, gold, HP, and loot | XP, levels, and room milestones for the pilot | One understandable loop is easier to build and evaluate. |
| Losing HP or gold for missed quests | Missed-task review, rescheduling, and a fresh start | Proposed recovery design; test whether it encourages return after a difficult day. |
| Random reward chests | Predictable room upgrades with short reveal animations | Make progress understandable before introducing a second reward system. |
| Cloud sync constantly in the background | Local saves with a durable queue; Supabase reconciliation while the app is open | Distinguish saved-on-device from synced, preserve edits, and handle conflicts explicitly. |
| Multiplayer becomes easy with WebSockets | Preserve stable identities and separate rules; design multiplayer later | Realtime transport does not supply fairness, permissions, or authoritative rewards. |

### Principal product risks

- **Novelty wears off:** Test repeat use over two weeks, rather than measuring excitement on the first day.
- **Task entry becomes a chore:** Keep the required form to a title and date; time, category, priority, and repetition are optional.
- **The game competes with the calendar:** Put the agenda first and keep progression feedback brief.
- **Missed days cause abandonment:** Preserve earned progress and make returning easy.
- **Users create trivial quests for XP:** Accept self-reported progress in solo mode. Competitive scoring would need a separate design.
- **Calendar data is lost:** Use account-backed storage from the start, verify saves, and include data export. Define operational backup and recovery before inviting users; account persistence alone is not a backup policy.

## 2. Audience and product promise

**Primary audience:** People who plan work, study, exercise, chores, and personal routines on their phones and enjoy light game progression.

The same calendar also serves people organizing personal trips/day outings and business travel/event schedules. An itinerary groups appointments and chosen preparation quests, rather than imposing game mechanics on every travel activity.

**Job to be done:** "Help me decide what to do today, keep my commitments visible, and make completing them feel rewarding."

**Promise:** Plan your day, finish meaningful quests, and grow your own small fantasy room.

**Itinerary promise:** Keep the trip or event schedule, locations, and logistical details together, with the next commitment easy to find.

The app supports personal planning and self-reported completion. Trading can be entered as an ordinary Work quest; dedicated financial fields are outside the current product scope.

## 3. Identity and visual direction

Gamecal is a working name, not a final branding decision. Check availability before public launch.

- **Theme:** Clean productivity UI surrounding a cozy fantasy study.
- **World:** Start with a modest room; unlock a lamp, plants, shelves, and a window scene as levels increase.
- **Palette direction:** Warm neutral surfaces, ink-colored text, muted green actions, and restrained gold progression accents. Validate contrast before selecting final color values.
- **Typography:** Readable interface text; decorative fantasy styling limited to room details.
- **Language:** "Quest" means a scheduled task, "Daily" means a repeating quest, and "Level" means accumulated progress. Keep ordinary calendar labels for dates and times.
- **Feedback:** A small completion animation and XP update; a more prominent reveal only at a room milestone.
- **Accessibility:** Keyboard operation, visible focus, labeled controls, screen-reader completion feedback, reduced motion, and status indicated with more than color.

The room should feel personal and calm. Interactive animations and transitions are part of the requested experience. Use an illustrated room as the baseline and explore one small 3D prop, such as a lamp, plant, or milestone ornament. A complete 3D room remains later work; the first prop can ship with the MVP if it meets mobile performance and fallback requirements.

The main workspace starts with Calendar on the left and AI Planner on the right at 50/50. Focusing Calendar hides the planner through the right edge; focusing AI hides Calendar through the left edge. Only the hidden panel's mascot appears at its corresponding edge. Mascot conversation offers an explicit reopen action; Open restores split. Keep the room as a separate destination/compact progression detail and keep public reading separate. Names/art for the matching calendar and planner twins remain open.

## 4. Core loop

1. Open the split workspace and see scheduled commitments; focus Calendar when needed.
2. Add a one-off quest or a repeating daily.
3. Complete a quest, receive immediate saved-on-device checkmark feedback, then confirmed XP after server acceptance.
4. Reach a level milestone and reveal a room improvement.
5. Review unfinished commitments and plan the next day.

**First-session outcome:** Create and complete a quest, understand the reward, and see what the next room milestone requires.

The concrete journey is verify/sign in -> confirm timezone -> split workspace -> create one real quest -> accepted 20 XP -> reversible Undo. The user need not complete five tasks or finish an obligatory tutorial. Room milestone proof uses a separate reward fixture, not seeded production progress. Follow the first-session plan's state/acceptance contract.

## 5. Release scope

### Phase 1A — Supabase-backed web MVP

| Area | Included |
| --- | --- |
| Planning | Today agenda, week navigation, month date picker, appointments, timed/untimed quests, editable time blocks, conflict warnings |
| Itineraries | Personal/business trip envelope, daily timeline, shared calendar entries, manual location/booking notes, preparation quests, transfer blocks, print overview |
| Travel time | One-off appointments spanning days/zones, labeled endpoint dates, lodging/reference spans that do not block time by default |
| Weather | WeatherAPI location selection, daily forecast and optional hourly details, unit preference, source/update labels, supported-date and unavailable states |
| Quest management | Create, edit, delete, complete, undo completion, skip, undo skip, and reschedule |
| Recurrence | Daily or selected weekdays, optional end date; edit this occurrence or this and future occurrences |
| Organization | Five built-in categories; Main or Side priority |
| Progression | XP, levels, room milestones, completion history |
| Interactive UI | Animated quest completion, editor transitions, XP feedback, reduced-motion support; optional single 3D prop after performance checks |
| Main workspace | Initial 50/50 Calendar/AI layout, Calendar/AI focus modes, directional exits, twin hidden-panel mascots and deterministic reopen/help popovers |
| Optional live AI planning integration | Requested planning proposals for quests/time blocks/itinerary changes; independent integration gate, not a calendar pilot launch dependency; truthful guidance when disabled |
| Optional itinerary cover experiment | Pexels destination suggestions, Change/Remove Cover, credit, stable metadata-only selection, neutral loading/offline fallback |
| Reflection | Daily summary, weekly consistency/completion view, optional private takeaway and next action |
| Persistence | IndexedDB/Dexie snapshots and durable queue; Supabase canonical data and rewards; versioned local/SQL schemas; account export and local recovery bundle |
| Platform | Responsive browser app; mobile/desktop; online startup/sign-in; cached-calendar edits survive connection interruptions |
| Account | Supabase Auth with one sign-in method, private profile and per-user data access |
| Launch | Public landing page, hosted app, basic activation feedback, account deletion |

Required Phase 1A gates are calendar/recurrence/progression/review, manual itineraries and WeatherAPI, the split workspace/deterministic mascots, account/sync/recovery/operations, accessibility and deployment. Live AI, Pexels covers and 3D are separately enabled additions; their absence does not fail the calendar pilot gate. Creator/radio, PWA offline reopening, push and external calendar integration retain their later gates.

### Phase 1B — convenience and resilience

- Prioritize optional server-scheduled web push reminders when pilot feedback identifies missed commitments; verify permissions and real-device delivery before shipping.
- Prioritize read-only saved-itinerary offline reopening before calling the app travel-ready without connectivity. Cache complete trip details and verify the app shell/account lifecycle on actual devices.
- PWA manifest, installation guidance, and offline app shell for guaranteed offline reopening after setup.
- Extend cached coverage and optional browser-supported closed-app sync only after lifecycle/device validation.
- Live multi-device updates if pilot feedback shows that refresh-on-open is insufficient.
- Validated data restore/import; existing account data must survive invalid imports.

### Later, only after validation

- Creator Studio and dedicated reader experience as a separately gated extension: series, ready chapters, weekly release slots, hosted pages and external links. Deliver external scheduled cards first, then the hosted reader; both paths share the same series model. See [CREATOR_PLAN.md](CREATOR_PLAN.md).
- Optional radio: station discovery/favorites and a compact, user-started player. Explicitly parked by the user; no MVP work or API subscription. Save the RapidAPI candidate and browser constraints in [RADIO_PLAN.md](RADIO_PLAN.md).
- Gold and a small cosmetic shop with a defined earning, spending, and undo policy.
- More room customization and a lightweight 3D version of the established room.
- A few category-based attributes if users want deeper progression.
- External calendar integration, with separate read/write permissions and conflict rules.
- Guilds, cooperative quests, and optional leaderboards.
- Itinerary sharing, saved-place ideas, embedded maps/routes, email reservation import, live transport updates, file attachments, budgets, and expense splitting after travel-use validation.

Prioritize a read-only integration with one demanded calendar provider before two-way sync or shared calendars. Supabase account persistence is not external Google/Outlook synchronization. Connected external commitments should provide availability context and never grant XP automatically. Shared calendars and focus timers remain later work.

### Non-goals for the initial release

Native Android/iOS apps, guaranteed offline startup, closed-app background sync, push reminders, live collaboration, trading analytics, broker integrations, financial rewards, HP penalties, random loot, purchasable currency, multiplayer, chat, item trading, and a full RPG combat system.

Live radio is also outside the initial release and creator-pilot gates. Listening adds no XP; it remains a separately enabled convenience when revisited.

The itinerary MVP uses manual information and external map/booking links. Live flight data, automated routes, reservation importing, and companion sharing are not implied by itinerary support.

WeatherAPI forecasting is the selected initial weather integration. Long-range predictions, weather notifications, AQI/pollen, automatic weather-based rescheduling, and provider alternatives are deferred.

Pexels covers are an optional experiment; full-screen daily wallpapers, arbitrary event-title analysis, stock-photo browsing as a product, video covers, and itinerary photo uploads remain outside the initial scope. Creator artwork uploads belong to the separate publishing extension, not this cover experiment.

## 6. Functional requirements and acceptance

### A. Calendar and quest entry

- Offer two entry kinds: Quest (an actionable commitment) and Appointment (a scheduled event). Default to Quest; appointments have no XP reward or quest-completion requirement.
- A quest requires a title and date; the date defaults to the selected day.
- Optional fields: start time, end time, category, priority, notes, and recurrence.
- Default category is Personal; default priority is Side.
- Main quests receive visual emphasis but the same XP as Side quests in the pilot.
- Today's agenda lists timed quests chronologically and untimed quests in a separate section.
- Week navigation shows daily counts; the month picker selects a day. A full desktop time-grid is deferred.
- A time block is a quest with both start and end times, not a separate task entity. Offer optional duration shortcuts; changing a block preserves quest identity and does not affect XP.
- Before saving, warn about overlapping timed entries marked as blocking time and offer edit times or keep overlap. Overlap is allowed; invalid time ranges are rejected. Adjacent blocks do not conflict. Label coverage as "Gamecal schedule" until external calendars are connected. Lodging/reference spans default to informational rather than blocking the entire stay.
- Show the union of known timed blocking intervals as planned time, plus the untimed quest count. This is neither actual focused time nor a complete assessment of free time; start-only/all-day entries have no assumed duration.
- First-quest guidance suggests a specific finishable action, such as "Read 10 pages," and an optional note about why it matters. Do not require a goal, duration, or perfect-day commitment.
- Ordinary quests remain single-day. One-off appointments support overnight/multi-day and cross-timezone endpoints; validate the resolved UTC order rather than comparing local clock readings.

**Acceptance:** A user can create a quest using only a title, find it on the selected day, edit it, and retain it after reload. A 10:00–11:00 block warns about a 10:30–11:30 entry, but not an 11:00–12:00 entry; keeping an intentional overlap succeeds. Saving errors preserve entered text and never report a successful save falsely.

### B. Recurring occurrences

- Store the repeating definition separately from individual occurrence outcomes.
- One occurrence has a stable identity for its definition and scheduled local date.
- Completing, skipping, or moving one occurrence does not change other occurrences.
- "This and future" edits preserve past outcomes; stopping a series preserves history.
- Generation must be idempotent: reopening the app never creates duplicates.

**Acceptance:** A weekday quest appears on the correct dates, can be completed independently each day, and preserves its history after the series is changed.

### C. Status and recovery

- Stored outcomes: pending, completed, or skipped. Overdue is derived from time and pending status.
- Timed quests become overdue after their end time, or start time if no end is supplied; untimed quests become overdue at local day end.
- All-day quests cover one local date and become due at the first valid start of their exclusive next local date in the quest zone; use calendar-date/DST rules rather than a fixed 24-hour duration.
- Late completion is allowed and receives the same XP; history distinguishes scheduled and completed times.
- Skipping grants no XP. Rescheduling moves the commitment and preserves its identity.
- Undo skip returns skipped to pending without XP or identity changes and remains accessible on the row/details. Complete/reschedule a skipped entry only after unskipping it; stale transitions require review.
- Undo returns the quest to pending and removes its completion reward.
- Deleting a completed occurrence removes its reward after explicit confirmation; deleting a recurring definition preserves historical occurrences.
- No automatic XP loss for lateness, missed days, or inactivity.
- Appointments may be marked attended using the same internal completed state but receive no XP. Past unacknowledged appointments use neutral event language rather than becoming failed quests. Undo attendance does not change progression.
- Recovery offers complete, reschedule, or skip without pressure. A missed consistency day does not erase earned XP or upgrades; deliberate undo/deletion still reverses the associated completion reward.

**Acceptance:** Completing, undoing, and completing again produces one active reward. A missed day never erases previously earned progress.

### D. Progression rules

Pilot values are deliberately simple and subject to playtesting:

| Rule | Proposed value |
| --- | --- |
| Valid quest completion | 20 XP |
| Appointment attendance, elapsed time, reflection, or opening the app | 0 XP |
| Starting state | Level 1, 0 XP |
| Level formula | `1 + floor(totalXP / 100)` |
| Room milestones | Level 2: lamp; level 3: plant; level 5: bookshelf; level 8: window scene |
| Priority/category multiplier | None |
| Late-completion penalty | None |

- Total XP is derived from active completion rewards; record the awarded amount so later balance changes do not rewrite history.
- Local completion receives immediate checkmark feedback and a pending-sync marker. Confirmed XP/room milestones update after server acceptance; connection loss does not discard the queued completion or invent a confirmed reward.
- Completion state and reward state commit atomically in a PostgreSQL transaction through an authenticated database operation. Validate ownership, assign the reward amount on the server, and prevent arbitrary client writes to reward records.
- Each occurrence can have only one active reward; duplicate clicks, reloads, and retries cannot multiply XP.
- Room appearance is derived from the current level. Undo can return the room to an earlier milestone; restoring completion restores the milestone.
- Labels explain XP earned and XP remaining to the next level.
- Separate XP progress, quest completion, and planned time visually. Do not fill a productive-hours bar merely because a clock elapsed, reward longer blocks, or replay confetti on refresh. Sound is deferred and must be opt-in if introduced.

**Acceptance:** Five valid completions yield 100 XP and level 2. Repeating the same completion request leaves the total unchanged. Undoing one yields 80 XP and level 1.

### E. Reflection and consistency

- Daily summary shows completed, skipped, and overdue quests without judgmental language.
- Weekly completion rate = completed quests / eligible scheduled quest occurrences for the selected week, using their effective scheduled dates; appointments are excluded and skipped quests remain in the denominator. Display raw counts alongside the rate.
- Future occurrences are excluded until their due time; completed occurrences are included immediately. A zero denominator displays "No scheduled quests yet."
- Deleted commitments are excluded from this personal metric; the UI does not present it as a competitive discipline score.
- Default consistency feedback shows quest-active dates over the recent seven local days, with a count such as "Active on 4 of the last 7 days." No perfect-week requirement; do not frame rest days as failures.
- Consecutive streaks are optional and hidden by default. When enabled, count consecutive local dates with at least one completed quest. Late completions count on the actual completion date and do not backfill missed days.
- A day without completion ends only the optional current run. While today is still open, yesterday's run remains visible as "Continue today." Best run is derived from current valid history; undo can change it. Inactivity never resets earned progression.
- Offer an optional weekly reflection: one takeaway and one next action. Store it privately; skipping it has no penalty. Let users explicitly turn the next action into a new quest, without automatic scheduling or bonus XP.
- Let users reduce celebratory feedback independently of system reduced motion. The agenda remains fully usable with celebrations/streaks disabled.

**Acceptance:** Empty schedules never produce division errors; appointments do not inflate quest metrics; an unfinished current day does not prematurely report a lost run. Weekly consistency stays visible with streaks off. Users can save/edit a private reflection or skip it without changing XP.

### F. Accounts, persistence, and connectivity

- Use Supabase Auth; proposed first method is email/password with verification and password recovery. Defer additional providers.
- Each account owns its profile, quest definitions, occurrences, and rewards. Enforce ownership in the database, not just the UI.
- Read the calendar from account-scoped IndexedDB/Dexie data. Save a validated command and its recoverable local state atomically before showing "Saved on this device."
- Queue ordinary edits/completions during interruptions. Distinguish saved locally, syncing, synced, needs sign-in, and needs attention; keep normal sync quiet.
- Sync on authenticated startup, reconnect, navigation, focus, and conservatively while the app is visible. Live subscriptions and closed-app execution are not required for the MVP.
- Reject stale server revisions without losing local text. Show the remote/local choices and reapply an explicitly chosen edit through a new operation. Never silently overwrite another device or revive deleted work.
- Cache active/recent calendar data; fetch older history on demand. Distinguish an uncached range from an empty one. Browser data may be cleared, so Supabase persistence and recovery remain necessary.
- Online export produces a complete versioned account snapshot. A local recovery bundle preserves cached data plus unsynced commands and states its incomplete coverage. Restore/import is deferred.
- Keep local partitions isolated by account. Sign-out with pending work offers sync, keep work and sign out, export a copy, explicit discard, or stay signed in. Retained work is locked until verified same-account return. Exporting never clears the queue while import is unavailable.
- Provide online account deletion through freshly reauthenticated prepare/confirm/status, a private retryable job, and verified server removal; clear local work only after confirmed removal.
- Apply the operations plan's safe cache eviction, shared budgets, operator ownership and tested backup/restore requirements. Restored accounts use new server epochs so old queued commands cannot silently replay missing receipts.

**Acceptance:** A locally saved edit survives an interruption and reload, then syncs once; accepted quests/XP appear on a second device. Failed local writes preserve editor input, and rejected cloud commands preserve a recovery choice. Accounts cannot access/replay each other's data. Online export is complete; local recovery clearly identifies pending work and cached coverage.

### G. Itinerary management

- Use the same basic itinerary for leisure, business trips, conferences, and day outings. Create a title, date envelope, and display zone, then organize daily entries.
- Link the existing appointment/quest occurrence; never copy its schedule or completion state into a second system. Editing either view updates the same entry.
- Add optional place/address, external map link, booking reference/link, and notes. Use transport/lodging/activity/meeting/preparation labels for scanning, not as reward types.
- Display transport start/end local dates and IANA zones, including overnight/date-line changes. Daily grouping uses the itinerary display zone; the main calendar uses the profile planning zone, with differences labeled.
- Support explicit preparation quests before the itinerary's date range and manual transfer/buffer appointments. Ordinary travel logistics, attendance, lodging, and trip archive award no XP.
- Archiving preserves calendar history. Detaching removes itinerary membership while preserving the calendar entry; deleting the itinerary unlinks entries without silently deleting them.
- Cache a complete itinerary after opening it through bounded reads, show readiness/last-sync status, and offer a clean printable overview. Guaranteed offline reopening is a first-follow-up gate, not an MVP claim.

**Acceptance:** A leisure and a conference itinerary use the same model. A calendar reschedule appears in the trip without duplication; overnight cross-zone appointments are valid; lodging does not block every session by default; preparation receives only the existing quest reward. See [ITINERARY_PLAN.md](ITINERARY_PLAN.md) for detailed contracts and scope.

### H. Weather-aware planning

- Use WeatherAPI.com through authenticated Next.js server routes. Select a city-level weather location; an itinerary has a base location and may override it by day for multi-destination travel. Today can use an optional home/weather location.
- Display condition, high/low, rain probability, wind, and returned hourly details in a compact expandable card. Include location-local date, source, and fetched time. Temperature-unit changes reuse the same data.
- Launch against the configured free-tier near-term horizon unless a different plan is selected. Show "Forecast not available for this date yet" outside returned coverage, not a fabricated forecast for future trips.
- Use short-lived server/browser caches under [WEATHER_PLAN.md](WEATHER_PLAN.md). Persist/sync user weather settings, not forecast payloads; initial browser forecasts are in memory rather than the durable outbox or exports.
- Handle quota, provider, network, and location errors independently of calendar saving. Weather never automatically reschedules appointments or modifies XP.

**Acceptance:** The correct selected location/date is labeled; unsupported dates and stale/unavailable forecasts are explicit; daily/hourly values match fixtures; the provider key never reaches the browser; unit switching is request-free; weather failures do not break local itinerary/quest operations.

### I. Optional destination covers

- Recommend an itinerary cover from a confirmed public destination/country or explicit visual theme. Do not send private event titles, notes, client names, attendee details, or booking information to Pexels.
- Use a small candidate batch plus reviewed fallbacks. Keep the selected cover stable; offer Change Cover and Remove Cover, with source/photographer credit. A removed/manual image is not overwritten by an automatic refresh.
- Treat stock imagery as illustrative, not evidence of the booked property or current conditions. Keep agenda text on a readable surface and leave RPG room art independent.
- Store photo IDs, approved image URLs, and attribution metadata, not uploaded photo files. Remote-image failures use a gradient/illustration without blocking saves or trip access.

**Acceptance if shipped:** Selection survives reload/sync, manual/none mode is respected, private data is absent from provider queries, credit and mobile readability pass, and provider/remote-image failure leaves planning functional. Follow [PHOTO_PLAN.md](PHOTO_PLAN.md); event-header suggestions are deferred.

### J. Creator publishing and readers — separate pilot

- Creators organize manga/comic series and chapter drafts, set a weekday/time/IANA-zone cadence, and assign ready chapters to explicit release slots. Wednesday is the requested example; no exact time is established yet.
- Support uploaded image chapters in Gamecal and chapter links hosted elsewhere, including an optional external mirror for a hosted chapter. An external card's scheduled reveal does not publish or embargo the source site.
- Offer Creator Studio, upload/order or link entry, owner-only reader preview, and deliberate online scheduling confirmation. Production quests may reference existing calendar occurrences without duplicating status or XP.
- Server-side releases operate after the creator closes their browser. Empty slots and incomplete uploads never publish. Draft content stays private until its accepted release becomes due.
- Readers get public series/chapter pages and a dedicated hosted reader with continuous scroll or paged RTL/LTR reading, zoom, chapter navigation, accessible controls, and device-local resume. External chapters have a clearly labeled external-site action.
- Reading and publication earn no XP automatically. Hosted art requires storage/delivery budgeting; public aliases and release metadata stay separate from private calendar/account information.

**Acceptance for the creator pilot:** Both chapter modes work in one series, a confirmed Wednesday release appears once with the browser closed, early/private access fails, cancellation/withdrawal races report the truth, and reader readability/accessibility/cost checks pass. Follow [CREATOR_PLAN.md](CREATOR_PLAN.md) for contracts and launch gates. This is requested feature scope, not an implemented module or a new calendar MVP prerequisite.

### K. Main workspace and AI planning

- Use `split`, `calendar_focus`, and `assistant_focus` as the three layout states. Calendar is always the left-owned panel; AI is right-owned. Neither mascot appears in split.
- Give each half a clear focus area. Calendar dates/actions/forms, chat controls, scrolling, and dragging retain their normal behavior rather than accidentally changing layout.
- Narrow phones initially show two compact side-by-side previews; focused mode provides full-width calendar/editor or planner. Do not shrink working forms/month grids into half a phone.
- A hidden panel's mascot opens a small conversation-style popover. Open Calendar/Open AI restores split; the planner mascot can also offer Ask planner to open the AI composer. A Calendar/Both/AI control provides direct accessible navigation.
- Keep panel drafts, selected dates, and local pending work across transitions; hidden content leaves keyboard/accessibility navigation. Honor reduced motion and reserve safe space for mascots.
- AI suggests bounded, timezone-labeled proposals. Accept opens the existing editor; saving uses existing validation/revisions/local queue. The assistant cannot auto-complete quests, assign XP, publish chapters, or make bookings.

**Acceptance:** All layout/touch/mascot/state checks in [UI_UX_PLAN.md](UI_UX_PLAN.md) pass. Working AI additionally requires verified account/context isolation, structured response validation, cost limits, errors, and stale-proposal checks. The split shell can be tested with clearly labeled deterministic guidance while that integration is unavailable.

## 7. Screen plan

| Screen | Primary purpose | Essential content |
| --- | --- | --- |
| Planning workspace | Choose calendar or assisted planning | Initial 50/50 layout, Focus Calendar/AI, Calendar/Both/AI control, hidden-panel mascots, preserved drafts |
| Today | Decide what to do next | Date, compact room/XP summary, agenda, Add Quest |
| AI Planner | Review planning ideas | Explicit requests, bounded calendar/itinerary context, proposed changes, edit/review before saving, unavailable/pending states |
| Calendar | Plan across days | Week strip, month picker, selected-day agenda |
| Itineraries | Organize leisure/business trips | Upcoming/past list, itinerary overview, day selector/timeline, preparation, details and print |
| Quest editor | Capture or revise a commitment | Title first; optional details progressively disclosed |
| Room | Enjoy progress | Room illustration, level, next milestone, unlocked details |
| Review | Reflect and recover | Daily outcomes, weekly quest counts/rate, recent-week consistency, optional reflection, reschedule actions |
| Settings | Manage preferences and data | Planning timezone, optional streaks, celebration preferences, reduced motion, account, export, deletion; reminders and restore later |
| Sign-in/onboarding | Start a private calendar | One auth method, recovery, timezone confirmation, first quest guidance |
| Creator Studio — extension | Prepare and release a series | Chapter drafts, uploads/order or links, release slots, preview and scheduling confirmation |
| Public series — extension | Find available chapters | Public pen name, series metadata, ordered released chapters, hosted/external labels |
| Reader — extension | Read hosted comics comfortably | Scroll/paged modes, RTL/LTR, fit/zoom, chapter navigation, local resume; quiet reading surface |

**Mobile:** Portrait workspace begins with 50/50 Calendar/AI previews, then expands the selected area to full width. Calendar focus keeps familiar date navigation, thumb-accessible Add Quest, and a keyboard-safe editor sheet. App navigation remains available without mascots obscuring it; Review, Room, and Settings are secondary destinations. Avoid competing bottom bars for workspace modes and calendar actions.

Expose Itineraries from Calendar and a clear app-navigation destination. Keep the itinerary timeline readable on a phone; desktop may add a details panel. Travel fields should not lengthen ordinary title-only quest entry.

**Desktop:** Calendar/agenda occupy the left half and AI Planner the right half initially. Focus mode expands either workspace panel; the other exits toward its own outer edge. Room/progress remains a secondary destination or compact calendar detail, not the right-hand workspace panel. Desktop may show more content without changing the state contract.

Creator Studio is an opt-in destination; public reading uses its own layout. Keep calendar/quest controls and room celebrations out of the reader. Desktop studio can add a thumbnail rail and preview; phone reading prioritizes full-width art and accessible controls.

Required states: signed out, verifying email, expired session, empty day, saving, failed save, disconnected, stale edit, overdue, completion, level-up, empty review, and unavailable optional visuals. Invalid import is required when restore ships.

## 8. Recommended architecture

### Stack proposal

| Layer | Recommendation | Rationale |
| --- | --- | --- |
| Frontend | Next.js App Router + React + TypeScript | One project for landing page, authenticated routes, and server operations; use the [Supabase Next.js starter](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs). |
| Styling | Tailwind CSS with shared design tokens | Keep spacing, colors, and responsive behavior consistent. |
| UI controls | Selected shadcn/ui components using one consistent Radix primitive family | Start with editable controls for dialogs, menus, and forms; verify accessibility after customization. |
| UI animation | Motion for React plus CSS transitions | Motion for coordinated layout/entry/exit feedback; CSS for simple hover/focus/color transitions. |
| Planning assistant | Server-side model request with bounded authenticated context; provider not selected yet | Validated proposals reviewed through the existing editor; shell/navigation require no model call. |
| Database and auth | Supabase PostgreSQL + Auth from day one | Account-backed data with per-user Row Level Security policies. |
| Local data and sync | IndexedDB through Dexie + durable operation queue | Responsive local reads/writes with idempotent authenticated Supabase reconciliation; not localStorage for app records. |
| Auth integration | Supabase client libraries and `@supabase/ssr` | Use the starter's cookie-based browser/server session integration. |
| Weather | WeatherAPI.com via Next.js Route Handlers and native fetch | Server-only key, normalized responses, bounded caching/usage, and independently available UI. |
| Optional cover imagery | Pexels API via authenticated server search; direct responsive CDN variants | Small reusable candidate batches, attribution, stable selection, and no Supabase image-object storage. |
| Game rules | Pure TypeScript functions | Calendar UI and room rendering consume the same rules. |
| Reward persistence | Authenticated PostgreSQL operation | Atomic completion/undo and database constraints prevent duplicate rewards. |
| Initial room | Illustrated/SVG scene with Motion reveals; optional compact 3D prop | Give progression interactive feedback while preserving a fast visual fallback. |
| Hosting | Managed Next.js hosting; Vercel is the proposed default | Reduce deployment setup; verify current plan limits before launch. |
| PWA/offline startup | Deferred to Phase 1B | Cached data/queue are in the MVP; service-worker offline reopening and closed-app sync are separate features. |
| Optional 3D | Three.js + React Three Fiber + selected Drei helpers | Recommended code-controlled rendering for progression-linked objects; lazy-load only when the feature ships. |

### Why Next.js for this version

React/Vite is a reasonable simpler option for a client-only app; Supabase also documents a [React/Vite quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/reactjs). Next.js is recommended here because the initial release now includes accounts, public acquisition pages, and authenticated server operations. Its Supabase starter includes cookie-based auth, TypeScript, and Tailwind. These documented starting points support the recommendation; neither framework guarantees a shorter delivery time.

Keep interactive calendar and room controls in client components. Use server code for session-aware bootstrap and privileged operations; use the local read model for normal calendar rendering. Keep user data out of shared/public caches. The sync module uses authenticated Supabase reads/RPCs protected by RLS; do not duplicate every table behind a custom API or introduce a separate backend service. Use controlled database transactions for progression invariants.

Local-first persistence adds work to the MVP; prove one-off quest saving/retry/reconciliation before recurrence. Keep the scope narrow by deferring a service worker, realtime subscriptions, and a complete 3D room. Implement UI motion as part of the core experience and keep optional 3D to one measured prop.

### Ownership boundaries

```text
Next.js routes + interactive React calendar/room views
          |
Quest application operations
          |
Calendar/time rules + progression rules
          |
Dexie: confirmed snapshots + durable outbox -> local calendar projection
          |
Foreground sync -> authenticated Supabase operations
          |
PostgreSQL: ownership policies + atomic rewards

Phase 1B additions:
Service worker for offline startup; optional supported closed-app sync
Reminder scheduler -> browser push service -> notification handler
```

Keep calendar rules, progression calculations, persistence, and visual rendering separate. Preserve stable UUIDs and versioned database migrations from day one. Avoid speculative WebSocket or guild scaffolding.

### Minimum data model

| Entity | Key data |
| --- | --- |
| Profile | UUID linked to Supabase Auth user, display name, planning timezone, created timestamp |
| Quest definition/schedule version | Stable definition UUID, profile UUID, versioned entry kind/title/category/priority/notes/date-time fields/recurrence, timestamps |
| Quest occurrence | UUID, definition UUID, original scheduled date, effective date/time, entry-kind/content snapshots, status, completion timestamp |
| Completion reward | UUID, occurrence UUID, awarded XP, rules version, active/reversed state |
| Preferences | Fields on the private profile: streak/celebration/motion and weather unit/location; no independent preferences table or stored export timestamp initially |
| Weekly reflection | UUID, profile UUID, local week-start date, private takeaway/next action, revision, timestamps |
| Itinerary | UUID, owner, title, inclusive local envelope dates, display zone, notes/destination, archive state, revision/tombstone |
| Itinerary entry | UUID, owner, itinerary UUID, unique occurrence UUID, optional type/place/booking metadata, revision/tombstone; shared occurrence owns schedule/status |
| Weather settings | Optional profile home/unit settings, itinerary base location, and owner-scoped dated itinerary location overrides; provider forecasts remain transient |
| Optional itinerary cover | Auto/manual/none mode, provider/photo ID, validated URL variants, credit/alt/crop metadata, context/rules version; no photo bytes |

Include owner UUIDs where needed for RLS, revision numbers for mutable records, and uniqueness constraints for recurrence occurrences and reward identity. Define these in checked-in SQL migrations.

Persist timestamps as UTC instants. Preserve all-day dates as date-only values and recurrence times with an IANA planning timezone. Generate repeating occurrences by local calendar date rather than adding 24 hours. The profile timezone defaults to the browser's timezone; travel does not silently change it. Offer an explicit timezone change affecting future scheduling while preserving history. Test daylight-saving gaps and overlaps before release.

Changing the profile zone changes display/new-entry defaults only. Review future routines separately previews selected active quest series, preserves wall clocks/weekday rules and sends one existing series-edit command per confirmed series from a date still in the future in both old/new zones. Show partial success per series; do not rewrite fixed bookings or historical outcomes. Booked ambiguous endpoints require explicit earlier/later selection with displayed offset; nonexistent booked times require correction. Exact fields and all-day due rules are in the API/technical contracts.

Itinerary appointments additionally preserve independent local start/end dates and zones; all-day appointment ranges have exclusive end boundaries. Fixed travel instants never change just because the profile or itinerary display zone changes.

## 9. Initial local/cloud sync and later reminders

### Cloud persistence is an MVP requirement

- Create the Supabase schema and migrations before building persistent quest flows.
- Enforce per-user database access with Row Level Security. Keep privileged keys on the server. See [Supabase data security](https://supabase.com/docs/guides/database/secure-data).
- Validate the authenticated user for server operations; UI route protection alone is insufficient.
- Make completion and undo idempotent and atomic in the database. Use the accepted database result for XP and room updates.
- Treat personal notes as private; do not include them in analytics or notification previews by default.
- Detect stale revisions for edits and protect user text when requesting a reload.

**Acceptance:** A second authenticated device loads the same saved data. Duplicate requests never duplicate XP. One account cannot read or modify another account's records through direct requests.

### Local reconciliation is an MVP requirement

Supabase Realtime delivers changes; the application still needs an offline reconciliation protocol. This is an architectural inference from its documented role as a change transport, not an automatic sync guarantee. See [Supabase Realtime](https://supabase.com/docs/reference/self-hosting-realtime).

- Include a durable account-scoped outbox, operation UUIDs, server revisions, dependency ordering, and deletion tombstones from the first persistence slice.
- Retry operations idempotently; sync after authenticated startup, reconnect, focus/navigation, and while the app is visible. Browser closure pauses guaranteed sync until the next launch.
- Resolve conflicting quest edits visibly rather than silently discarding text.
- Deduplicate rewards by occurrence and derive totals from accepted reward records.
- Show queued, syncing, synced, and failed states.
- Make dataset import retry-safe when restore is added; preserve completion/reward invariants.

**Acceptance:** Two devices converge after an offline edit/reconnect; duplicate requests never duplicate XP; one account cannot read or modify another account's records.

Follow [LOCAL_SYNC_DESIGN.md](LOCAL_SYNC_DESIGN.md) for the precise queue, acknowledgment, and conflict contracts. Local storage is not a cloud backup or proof of authorization.

### Reminder expectations

The initial web MVP has in-app due indicators only. It does not promise alerts while the app is closed.

For Phase 1B, schedule reminders on the server and deliver optional web push. Browsers may stop service workers, so persistent timers are not a dependable reminder scheduler. See [MDN offline and background operation](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Offline_and_background_operation).

On supported iOS versions, web push requires a Home Screen web app and a permission request triggered by user interaction. Push involves server delivery and browser notification handling. See [Apple web push guidance](https://developer.apple.com/documentation/usernotifications/sending-web-push-notifications-in-web-apps-and-browsers).

- Explain platform support before requesting permission; handle denied and unavailable states.
- Cancel or update pending reminders after task edits, completion, deletion, and timezone changes reach the server.
- Offline changes affect server reminders only after sync; communicate pending changes.
- Use generic notification text by default and let users explicitly enable quest titles.
- Support disabling reminders and removing expired subscriptions.
- Treat delivery as best effort; device settings, connectivity, and browser policies affect arrival.

**Acceptance:** Supported devices receive a test reminder with the app closed; unavailable or denied notifications never block calendar use. Test iPhone Home Screen installation, Android Chrome, and desktop browsers separately.

## 10. Delivery plan and exit gates

No calendar estimates are assigned yet; milestones are ordered by dependency.

| Milestone | Deliverable | Exit gate |
| --- | --- | --- |
| 0. Product and UX | This PRD, split/focus/mascot workspace prototype, Today/editor/Room sketches | Panel directions, reopening, mobile touch behavior, and core loop are understandable; scope/rules reviewed. |
| 0a. First-session flow | Account/setup, editor, pending/synced/undo, coverage/conflict/auth recovery states and FS acceptance journeys | Clear user actions/copy map to existing persistence/API contracts; no fake reward, AI or offline guarantee. |
| 1. Account and local data foundation | Runnable Next.js app, disposable local Supabase, migrations, verified Auth/email capture, RLS, landing page | Sign-in/recovery and isolation pass locally before any remote project selection/linking/application. |
| 2. Calendar and sync foundation | Dexie schema, local read model, durable queue, one-off quest CRUD, authenticated Supabase reconciliation | Local save/reload and network interruption recovery pass; ambiguous retries are idempotent; conflicts preserve input; second device sees accepted data. |
| 3. Repeatable scheduling | Recurrence, occurrence statuses, timezone rules, undo/reschedule | No duplicate occurrences; past outcomes survive series edits; date boundary checks pass. |
| 4. Reward loop | XP rules, level display, room milestones, daily/weekly review | Database completion is atomic and idempotent; undo reverses rewards; milestones reflect the correct level. |
| 4a. Itinerary slice | Shared-entry leisure/business timelines, metadata, endpoint zones, cross-day rendering, complete trip cache, print | Both example flows pass; edits stay unified; lodging overlap, ownership, sync/deletion, and zero-XP logistics checks pass. |
| 4b. Weather slice | WeatherAPI server routes, location settings, forecast cards, cache/error/capability states | Key isolation, fixtures/date-zone matching, quota/cache expiry, and independent local-save behavior pass. |
| A. Optional independent AI gate | Real request -> structured proposal -> reviewed existing editor -> normal local save | Provider/context/budget established and AI checks pass before enabling/advertising it; does not block calendar pilot. |
| 5. Pilot readiness | Export, retained-queue sign-out, deletion jobs, cache/budgets/backups, accessibility, device QA, then separately authorized remote/hosting setup | Required Phase 1A passes, including queue/tab/auth/isolation/upgrade and operating proof; optional AI/Pexels/3D excluded unless enabled. |
| 6. Pilot learning | Two-week trial with a small invited group | Evaluate repeat use and usefulness before expanding scope. |
| 7. Convenience and resilience | PWA offline startup, optional supported closed-app sync, optional server push | Add only features justified by feedback; lifecycle/device checks pass for each feature shipped. |
| C. Separate creator pilot | Creator Studio, Wednesday slots, external releases, then private artwork upload and hosted reader | Both hosting modes pass the publishing/reader acceptance and operating gates in the creator plan; calendar MVP remains usable independently. |

**Implementation stop condition for Phase 1A:** All pilot acceptance conditions pass and users can plan, complete, see progress, recover from a missed task, and export their data. Include the specified UI motion. An optional single 3D prop must pass the visual/performance checks; do not expand to gold, a full 3D world, or multiplayer while finishing this gate.

### Focused verification

- Unit tests for recurrence, timezone boundaries, XP thresholds, completion deduplication, and undo.
- Database checks for atomic task/reward writes, retries, uniqueness constraints, account isolation, stale edits, and deletion.
- Browser end-to-end flow: sign in -> create -> complete -> level up -> undo -> reload -> export.
- Actual browser/device checks for connection loss, mobile keyboard layout, focus handling, and reduced motion.
- Sync checks for queued create/complete/undo, lost acknowledgments, remote deletion, two-device conflicts, multiple tabs, auth expiry/account switch, and IndexedDB quota/schema migration failures.
- Itinerary checks for shared identity, endpoint zones/date lines, cross-day agenda membership, nonblocking lodging, metadata privacy, complete trip cache, archive/detach/delete, and print layout.
- Weather checks for supported dates, location/day-zone matching, cache age/expiry, units, provider errors/quotas, attribution, secret isolation, and unaffected calendar sync.
- If photo covers ship: public-context queries, stable selection/race handling, URL/key validation, quota/fallback behavior, attribution, readability, transfer size, and metadata-only sync/export.
- Verify migrations on a fresh database and rehearse the chosen operational recovery procedure.
- Before Phase 1B features ship: offline reopening/closed-app sync, install behavior, validated restore, and reminder cancellation tests as applicable.
- Before 3D: define a named reference phone and network profile; compare against the illustrated room. Proposed target: agenda usable within three seconds on a cold load, with no continuous rendering when the room is hidden.

## 11. Pilot success measures

Use these as learning targets, not claims about proven demand. For a proposed pilot of 5–10 people over 14 days, record aggregate counts with consent or collect feedback manually; never collect quest titles or notes for product analytics.

| Measure | Definition / provisional target |
| --- | --- |
| Activation | At least 80% create and complete a quest in their first session. |
| Entry friction | Median observed title-only quest creation takes under 20 seconds. |
| Repeat use | At least half use the app on five distinct days during their first week. |
| Calendar usefulness | At least half report that it helped them plan or follow through, with a concrete example. |
| Progression usefulness | Returning users can explain what room progression adds; investigate indifference or distraction. |
| Reliability | No observed data loss or duplicate rewards in the pilot; all scripted reliability cases pass. |
| Planning clarity | Users distinguish an appointment, a quest, and planned time; observe successful blocking/rescheduling and conflict handling. |
| Recovery | Record whether users return and complete a quest after an unfinished scheduled day; report the small sample descriptively. |
| User control | Ask whether streaks/celebrations help or create pressure; turning them off preserves core functionality. |
| Growth usefulness | Users can name one useful planning adjustment or meaningful follow-through; XP and session counts alone do not satisfy this measure. |
| Itinerary usefulness | Test one personal outing and one business/event schedule; users can find the next commitment, location, and booking detail without duplicate calendar edits. |

A small pilot provides directional evidence. If scheduling is useful but the room is ignored, adjust the reward presentation. If the room is enjoyed but scheduling is avoided, simplify planning. Expand the world only after repeated use is demonstrated.

## 12. Decision log and remaining choices

| Decision | Status |
| --- | --- |
| General gamified calendar rather than trader-first product | Confirmed by user |
| Itinerary management for both personal and business/event use | Confirmed by user; shared basic model |
| Manual itinerary MVP; travel integrations and offline reopening follow later | Proposed delivery scope; detailed itinerary plan defines gates |
| WeatherAPI.com forecasts | Requested by user; near-term weather card planned for the MVP |
| Pexels automatic imagery | Exploration requested; destination-cover experiment recommended, event imagery deferred |
| Creator publishing with scheduled weekly manga releases and reader UX | Requested by user; proposed separate pilot after the calendar MVP |
| Hosted chapters and external chapter links | Both confirmed by user; per-chapter choice, optional external mirror |
| Wednesday cadence with an explicitly chosen time/zone | User supplied weekday; exact time/zone remain configurable choices |
| Supabase Storage and Cron for creator publishing | Proposed reuse of existing backend; adds art storage/delivery cost and server release jobs |
| Radio capability | Requested and explicitly parked for later; article/API lead saved, provider selection and current quota unconfirmed |
| Clean calendar with a small evolving fantasy room | Confirmed by user |
| Interactive UI with animations and transitions | Requested by user |
| Initial 50/50 Calendar-left / AI-right workspace | Requested by user; replaces calendar/room desktop split |
| Outward exits and twin mascots only for hidden panels | Requested by user; deterministic conversation/reopen first |
| AI suggests quests, time blocks and itinerary changes for review | Confirmed by user; provider/cost/data contract remains to establish |
| Focus activation and narrow-phone overview | Recommended refinement: deliberate focus area, normal controls unaffected, full-width working view |
| 3D objects | Desired direction; first prop proposed subject to performance checks |
| Web app first | Confirmed by user |
| Gamecal name | Working title; final branding remains open |
| Room rather than a central character | Recommended interpretation of confirmed theme |
| Supabase database in the initial MVP | Confirmed by user; supersedes local-only pilot |
| XP and room milestones before gold, attributes, and chests | Proposed MVP simplification |
| Supportive recovery rather than HP/gold penalties | Proposed behavior to validate |
| Time blocking/conflict clarity and separate appointments | Research-informed MVP recommendation |
| Weekly consistency, optional streaks, and private reflection | Research-informed MVP recommendation |
| Next.js App Router + TypeScript + Tailwind + Supabase Auth/PostgreSQL | Recommended for the account-backed web MVP |
| CUPID and explicit data architecture | Requested by user; adopted planning baseline for domain modules, predictable composition, fact ownership and consistency |
| Motion + shadcn/ui; optional React Three Fiber/Drei | Recommended UI/visual stack |
| IndexedDB/Dexie local saves with Supabase reconciliation | Adopted after user delegated the local/cloud architecture choice |
| PostgreSQL schema/RLS before connection or table/rule execution | Requested by user; documentation-only plan now, local migrations/tests after authorization |
| Owner reads, controlled command writes, private reliability tables | Recommended database/security baseline; detailed plans define role/grant and snapshot contracts |
| Recovery gap resolutions | Planning baseline: keep-work sign-out, export without purge, Undo skip, explicit time rules, optional AI gate and local-first migration delivery |
| Pilot operations | Defined in operations plan: private budgets/deletion jobs, cache cleanup, backup/restore epochs and operator gates; implementation/provisioning/test proof still required |
| Online startup/sign-in; PWA offline startup and push later | MVP lifecycle boundary; queued edits tolerate connection interruptions |
| Exact room art, XP tuning, milestone content | Initial proposals; refine during UX/playtesting |
| Monetization and multiplayer scope | Deferred; no paid features or competitive guarantees in pilot |

**Next concrete step:** Follow the [development setup/local delivery checklist](DEVELOPMENT_SETUP.md), resolve machine prerequisites during authorized bootstrap, and use the first-session/API slice as the first implementation gate. Dependency compatibility and runtime proof remain pending; establish AI provider/context/budget separately. No remote connection or table/policy execution is implied by planning approval.
