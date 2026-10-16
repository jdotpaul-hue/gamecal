# Itinerary Management — Product and Design Plan

**Updated:** 14 October 2026

**Confirmed audience:** Both personal travel/day trips and business travel/event schedules, using the same basic itinerary.

**Status:** Proposed MVP extension; documentation only. Related: [product plan](PRODUCT_PLAN.md), [technical design](TECHNICAL_DESIGN.md), [local sync](LOCAL_SYNC_DESIGN.md), [agent guide](AGENTS.md).

**Weather enhancement:** [WEATHER_PLAN.md](WEATHER_PLAN.md) uses WeatherAPI.com for location/date-specific near-term forecasts. It is advisory context, separate from bookings, rewards, and itinerary cache readiness.

**Optional cover imagery:** [PHOTO_PLAN.md](PHOTO_PLAN.md) explores Pexels destination covers with stable auto/manual/none selection, visible credit, and no uploaded image-object storage. A photo is illustrative, not a booking/property preview.

## 1. Product idea

An itinerary organizes calendar entries around a trip or event. A vacation, work trip, conference, or local day outing uses the same model: dates, a daily timeline, locations, and useful logistics. This extends the calendar rather than creating a second scheduling system.

**Promise:** Plan the trip, know what happens next, and keep the details together.

Personal example: travel to a city, hotel check-in, museum visit, dinner, and return transport. Business example: outbound travel, hotel, conference sessions, client meeting, preparation quests, and return transport. These are examples, not prepopulated bookings.

## 2. Brainstorm and priorities

| Idea | User benefit | Recommendation |
| --- | --- | --- |
| Itinerary overview and day timeline | See the whole plan and the next commitment | MVP |
| Shared calendar/itinerary entries | Avoid editing the same event twice | MVP; one underlying occurrence |
| Places, addresses, map/booking links | Find the destination and relevant details quickly | MVP; manual text and external links |
| Transport, lodging, activity, meeting/session labels | Make logistics easy to scan | MVP; presentation metadata, not new reward types |
| Booking references and notes | Reduce switching between scattered confirmations | MVP; private manual fields |
| Overnight and cross-timezone entries | Represent actual travel correctly | MVP for appointments; explicit endpoint dates/zones |
| Manual transfer/buffer blocks | Avoid a plan that leaves no time to move between places | MVP; clearly user-estimated |
| Destination weather and hourly detail | Inspect outdoor plans and transfers with weather context | MVP using WeatherAPI, only for supported returned dates |
| Destination photo cover | Recognize a trip at a glance and personalize its overview | Optional experiment; public destination only, user can change/remove |
| Preparation quests | Organize packing, reading, or meeting preparation | MVP; link existing quest occurrences |
| Printable overview | Carry a simple plan outside the app | MVP using browser print styling |
| Complete-trip cache and read-only offline reopening | Keep essential details accessible during travel | First follow-up; prove offline reopening before claiming travel-ready access |
| Saved places/unscheduled ideas | Collect possibilities before assigning a day | Later; do not complicate the first scheduling model |
| Companion sharing | Coordinate with family or coworkers | Later; owner/viewer/editor permissions first |
| Maps, route estimates, optimized ordering | Reduce geographic backtracking | Later after demand; requires provider, cost, and freshness decisions |
| Email import, live flight updates, attachments | Reduce manual entry and track changes | Later; separate integrations, permissions, and reliability checks |
| Budgeting and expense splitting | Organize trip costs | Later; avoid turning this into a financial product |
| Travel-themed cosmetics | Connect meaningful preparation to the game | Optional later; logistics do not become forced quests |

## 3. MVP user flow

1. Create an itinerary with title, inclusive start/end dates, and a display timezone. Optional destination summary and notes.
2. Select a day and add an appointment or link an existing calendar occurrence. Choose a logistics label and enter optional location/booking details.
3. Add a preparation quest, such as "Pack charger" or "Prepare meeting notes," with its own scheduled date. Preparation may occur before the trip.
4. Review chronological entries, gaps, and conflicts. Add an explicit transfer/buffer appointment when needed; no automatic duration estimates.
5. During the trip, use Today or the itinerary timeline to open the next entry's details. Both views read the same record.
6. Print an overview or save a local recovery bundle. Archive the itinerary after use without removing calendar history or earning completion XP.

MVP items must be scheduled; an undated ideas board is deferred. Itinerary membership is one occurrence at a time, not an automatic link of an entire recurring series.

## 4. Fields and interaction

### Itinerary

- Title, date range, display IANA timezone, optional destination summary, private notes, and archive state.
- Optional selected base weather city/location; a dated override supports multiple destinations. A free-text destination summary or venue address is not automatically a resolved forecast location.
- Optional cover mode/selection. Use confirmed city/country or a chosen travel theme for suggestions; do not send private itinerary notes/title details to a photo provider. A manually selected or removed cover stays that way across refreshes.
- Upcoming/current/past labels are derived from the date range; archive state is an explicit user choice.
- Changing itinerary dates adjusts its envelope only. Flag entries outside the range; never silently move booked appointments. Show preparation entries in a separate section.

### Entry

- The existing quest/appointment owns title, schedule, status, and reward eligibility.
- Itinerary metadata supplies a type label: transport, lodging, activity, meeting/session, preparation, or other.
- Optional fields: location name, address, external map link, provider/booking reference, booking link, and logistical notes. Transport can show departure/arrival place text.
- Start/end dates and IANA zones are explicit when times cross days or regions. Unknown times remain unknown; do not invent flight durations or hotel check-in times.
- Default travel/events to Appointment. Preparation can be a user-chosen Quest. Travel time, attending a meeting, checking into lodging, or archiving a trip grants no automatic XP.
- Preserve title-only quest entry for ordinary use. Show travel-specific fields only in the itinerary editor or when requested.

Moving an entry between itinerary days changes its date through the standard reschedule command. Ordering does not secretly move fixed times. Provide accessible move/date controls before considering drag-and-drop; if dragging ships, keep a keyboard equivalent.

## 5. Time and conflict semantics

- Timed appointments may span midnight, multiple days, and different start/end zones. Ordinary quests stay single-day for the initial MVP.
- Resolve endpoints independently into UTC. Validate `endInstant > startInstant`, rather than comparing local clock readings. Preserve both original local dates/times/zones for display.
- Daily itinerary grouping uses its selected display timezone. Always label a transport entry's departure and arrival local zones/dates; changing the display zone does not rewrite its instants.
- The main calendar uses the profile planning zone. An itinerary entry can therefore appear on a different local day in that view; make this explicit.
- Multi-day appointments appear on each intersected day as continuations of one occurrence. They must not duplicate status or rewards.
- All-day appointment ranges use an exclusive end date. Lodging uses clearly labeled check-in/check-out boundaries; do not equate nights with fixed 24-hour periods.
- Lodging/reference spans default to not blocking time. Transport, meetings, and timed activities default to blocking time. The user may change this planning flag; it never changes XP.
- Only blocking intervals contribute to conflict warnings and planned-time totals. Both calendar and itinerary views use the same interval rules.
- Manual transfer blocks are estimates, not provider-calculated routes. Warn about overlap; do not promise route feasibility, seat availability, or real-time flight status.

**Fictional example:** Departure 14 October 2026 at 23:30 in `Asia/Singapore`; arrival 15 October at 07:30 in `Asia/Tokyo`. Store both labeled endpoints and the resolved seven-hour UTC interval. Never reject it solely because the local date changes.

## 6. Shared data model

Keep existing quest definitions, schedule versions, and occurrences as scheduling truth. Add:

| Entity | Ownership and role |
| --- | --- |
| `itineraries` | UUID, owner, title, local envelope dates, display zone, destination/notes, archive state, revision, timestamps/tombstone |
| `itinerary_entries` | UUID, owner, itinerary UUID, unique occurrence UUID, type label and optional place/booking metadata, revision, timestamps/tombstone |

One occurrence belongs to at most one itinerary in the MVP. Owner equality must be enforced across itinerary, membership, and occurrence. The metadata row does not contain a second editable event schedule or independent completion status.

Create an appointment and its membership atomically; reuse that occurrence in both views. Attach/detach changes metadata, not the occurrence's schedule or reward. Detaching preserves the calendar entry; deleting the underlying entry removes it from both views. Archive preserves all entries. Deleting an itinerary unlinks memberships while retaining calendar history, unless the user explicitly requests separate entry deletion.

Extend the shared schedule/occurrence contract with start/end date-zone snapshots, all-day end boundary, and `blocks_time`. Synchronize itinerary records through the existing local queue with creation dependencies, revision checks, and tombstones. No separate trip backend or sync engine.

## 7. Cached access and privacy

The current MVP still requires online startup/sign-in. After opening an itinerary, cache its complete date range and details across bounded fetches; mark it fully cached only after the full owner-scoped snapshot is validated. Keep pending local edits visible over the snapshot. Do not confuse a partially cached day with an empty day.

The first follow-up is an explicit saved-itinerary mode with read-only offline reopening. This needs a service-worker app shell, cache readiness checks, account/device privacy policy, and real-device airplane-mode tests. It does not imply offline maps, live booking links, reminders, or continued cloud sync. Update the account/session lifecycle contract before enabling that mode.

Weather availability is separate: transient forecasts expire and are not part of the durable trip snapshot/print export. Show location, destination-local forecast dates, source/update time, and unsupported-date states; changing weather location must not change an event's schedule. A forecast failure must not make trip details unavailable.

Cover metadata may sync with the itinerary, but remote image bytes are not part of the cached trip pack or recovery bundle. Use a local gradient/illustration when the CDN image is unavailable. Exclude the decorative cover from the initial print overview so it doesn't obscure details or imply offline media availability.

Booking references, addresses, and trip notes stay private, outside analytics/log payloads. Validate new booking/map links as HTTPS, label them as external, and require a user click; no auto-fetching arbitrary booking pages or emails. The initial model stores no passport scans, payment credentials, or attachments.

Print a clean day-by-day itinerary with optional inclusion of booking references, defaulting them off. Printing a locally pending plan must label its sync state. Sharing with companions is deferred rather than exposing private account data through guessed public URLs.

## 8. Acceptance and delivery

- One leisure outing and one business/conference schedule can use the same itinerary form and timeline.
- An itinerary edit appears in Calendar/Today; a calendar reschedule appears in the itinerary with no duplicate entry.
- A preparation quest earns the ordinary quest reward once; lodging, transport, sessions, and trip archive earn zero automatic XP.
- Cross-midnight, DST, and date-line travel validate using UTC instants and display explicit local endpoint dates/zones.
- A two-night lodging span does not warn that all sightseeing sessions overlap it by default; overlapping blocking transport/session entries do warn.
- Archive/detach/delete behavior preserves the documented calendar history and handles queued edits without resurrection.
- Complete-trip cache readiness, print output, and private export/delete behavior are verified. Do not claim offline reopening until the follow-up gate passes.
- Forecasts match selected weather locations and returned dates; multiple-zone travel labels are explicit, unsupported dates are honest, and weather outages never block itinerary edits or automatically move bookings.

Build after the local one-off quest/sync vertical slice. Deliver manual itineraries and endpoint time semantics before adding map providers, collaboration, or optional 3D expansion. This increases MVP scope; validate travel planning alongside the existing productivity pilot rather than assuming one audience's success transfers to the other.

## 9. Reference check

[TripIt's sample itinerary](https://help.tripit.com/en/support/solutions/articles/103000063427/) demonstrates consolidating travel plans and printing a trip. [Wanderlog's product overview](https://wanderlog.com/) highlights daily itinerary/map views and reservation organization. These support feature discovery, not proof of Gamecal's demand.

[TripIt's mobile offline guidance](https://help.tripit.com/en/support/solutions/articles/103000063436-using-mobile-apps-without-connectivity) describes cached access while signed in. That mobile capability does not automatically apply to a Next.js browser app. It informs the saved-itinerary follow-up, which needs its own implementation and tests.
