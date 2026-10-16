# Creator Publishing and Manga Reader Plan

**Updated:** 14 October 2026

**Status:** Proposed extension; documentation only. The user requested content creation, recurring Wednesday manga releases, and dedicated reader UX, and confirmed support for both uploaded chapters and externally hosted chapters.

**Related contracts:** [Product plan](PRODUCT_PLAN.md), [technical design](TECHNICAL_DESIGN.md), [local sync](LOCAL_SYNC_DESIGN.md), and [agent guide](AGENTS.md).

**Database/security detail:** [DATABASE_SCHEMA_PLAN.md](DATABASE_SCHEMA_PLAN.md) and [RLS_PLAN.md](RLS_PLAN.md) place creator base tables in an unexposed schema, make immutable chapter versions concrete, and define owner/public/system and Storage boundaries. This is a later migration set; the current database planning task connects/executes nothing.

## 1. Product purpose and release boundary

Help a creator plan production, prepare a series, schedule ready chapters, and give readers a comfortable place to find and read releases. Start with manga/comics as the concrete content type. Here, creation means organizing and publishing the artist's existing work; a drawing editor, AI art generation, prose/video publishing, paid subscriptions, comments, and a social network are later possibilities, not implied requirements.

Keep the private calendar and fantasy room as Gamecal's core. Add an opt-in Creator Studio and public series/reader routes. Use the same account and stack, with deliberately separate private and public data. Recommend an invited creator pilot after the calendar pilot gate; this is a meaningful product expansion rather than another calendar field.

## 2. Two publishing modes

Choose a mode per chapter so one series can support both approaches. A chapter may also offer an optional external mirror alongside its hosted pages.

| Mode | What creators provide | What readers get | What Gamecal schedules |
| --- | --- | --- | --- |
| Hosted chapter | Uploaded, ordered image pages and chapter metadata | Dedicated in-app reader | Public availability of the chapter and its pages |
| External chapter | HTTPS chapter URL, title, number, optional summary | Series/chapter release card and clearly labeled Read on external site action | Visibility of that card and link inside Gamecal |

An external link does not give Gamecal control over the source site's publication time, availability, access rules, or reader layout. Do not promise to publish to that site, scrape/rehost it, or embed it in an iframe by default. Creators manage the external site's release separately. A source page might already be public before its Gamecal card appears.

Hosted reading requires persistent remote files. Remembering a laptop/phone file path cannot deliver pages to readers on other devices. This is an explicit addition of Supabase Storage for creator artwork; the earlier metadata-only Pexels and itinerary policies remain unchanged. External chapters avoid Gamecal chapter-image storage, but still use database/hosting resources.

## 3. Creator workflow and Wednesday cadence

1. Create a series: public pen name, title, description, optional cover, and default reading format.
2. Set a cadence such as **every Wednesday**, a local release time, an IANA timezone, and a start date. Time and timezone need explicit confirmation; the requested weekday alone does not establish an exact release instant.
3. Create a chapter draft. For hosted mode, select images, inspect previews, order pages, and supply captions/transcript where available. For external mode, enter a valid HTTPS chapter link.
4. Optionally add production quests, such as sketch, ink, lettering, and proofread, through the ordinary calendar editor. Link existing occurrences rather than duplicating their schedule/status.
5. Preview the actual reader or external release card. Validate required content and resolve upload/processing failures.
6. Assign the ready chapter to a release slot and explicitly confirm Schedule online. Display the accepted date, time, zone, and canonical status only after server acknowledgment.
7. The server releases the frozen chapter version when due. The creator can inspect the resulting public chapter and release history.

The cadence creates a bounded list of planning slots, not automatic unfinished chapters. A slot without a ready assigned chapter stays unfilled; nothing is published and no HP/XP penalty occurs. A skipped Wednesday does not automatically shift or publish all subsequent drafts. Creators can skip a slot, select a later date, or release deliberately now.

Scheduling multiple chapters requires an explicit assignment preview and confirmation for each chapter/date pairing; a batch can be added later. Changing the cadence updates unassigned future slots only. Moving an already scheduled chapter is a separate revision-checked action with a clear before/after time.

Resolve each local slot into a UTC instant using its series timezone. Preserve the original local date/time/zone alongside that instant. For daylight-saving gaps or ambiguity, require an explicit valid time/offset choice before confirmation; later profile/device timezone changes do not move accepted releases.

## 4. Creator Studio UX

| Surface | Main interaction | Important states |
| --- | --- | --- |
| Studio overview | Select a series; see next release and drafts needing attention | No series, unfilled slot, upload failed, scheduled, released late |
| Series workspace | Ordered chapter list plus upcoming release slots | Draft, ready, scheduled, published, withdrawn; show hosting mode |
| Chapter editor | Title/number, page upload and ordering or external link | Per-file progress/retry, unsaved draft, saved locally, synced, validation errors |
| Release planner | Wednesday slots with assigned chapters; explicit time/zone | Unassigned, ready to schedule, confirming, confirmed, needs attention |
| Preview | Open the reader/card exactly as intended for release | Owner-only preview clearly labeled unpublished |

Use a compact list and step-by-step editor on mobile; desktop can show a page thumbnail rail and preview beside the editor. Page ordering needs keyboard Move up/down controls as well as optional drag interaction. Preserve text during errors. Never show a local scheduling intention as an accepted release.

Use existing Motion/CSS tokens for sheet transitions, page reordering, and status feedback. Publication succeeds independently of animation. Do not bring 3D, room celebrations, or quest navigation into reading surfaces. Release actions explain public visibility in the product UI and require an intentional confirmation.

## 5. Reader UX

Readers can browse published public series and chapters without an account. Start from direct series links and a small curated list; broad discovery/search is a later experiment. A pen name and selected series metadata are public; calendar entries, legal/account identifiers, email, travel, and private production notes remain private.

| Surface | Reader experience |
| --- | --- |
| Series page | Cover/title/pen name, description, ordered published chapters, Read first/latest, and stated cadence |
| Chapter card | Chapter number/title, release date, hosted/external label, and spoiler-safe summary |
| Hosted reader | Continuous vertical scrolling or paged reading; creator-selected default; user may switch |
| Paged controls | Explicit right-to-left or left-to-right direction, large touch targets, keyboard navigation, page indicator |
| Reading controls | Fit width/zoom, background preference, chapter selector, previous/next published chapter, visible exit |
| Resume | Device-local last-read chapter/page anchor; explain that it does not yet sync across devices |
| External chapter | Gamecal release metadata and an explicit external-site action; external site owns reading controls/progress |

Support both conventional manga pages and vertically arranged webtoon-style pages. Do not assume every comic reads right-to-left. Keep readable art central, restrict line/column width on desktop, and avoid cropping panels. Touch zoom must coexist with normal browser accessibility. Controls can collapse, but remain available on focus/tap; no timed auto-advance, forced auto-scroll, or completion confetti.

Reserve page aspect ratios and lazy-load a bounded lookahead rather than fetching the whole series. Offer retry for an unavailable page without losing the reading position. On chapter exit, show the next *published* chapter or a quiet end-of-available-content state; no fabricated next release. Cadence is an intention unless a release is confirmed. Show precise upcoming timestamps only when the creator deliberately exposes that slot's public announcement; never leak its draft title/pages/link.

Provide descriptive page labels and an artist-supplied transcript/description view so image text can have a readable alternative. Test keyboard operation, focus, zoom, contrast, and reduced motion. Page-number alt labels alone do not make the story accessible. The recommendation against distracting automatic movement follows [W3C guidance](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html).

Reading or viewing releases earns no calendar XP. A reader can explicitly add a release reminder as an appointment through the existing editor; do not auto-populate their calendar. Follow lists, cloud reading progress, push/email release alerts, comments, ratings, and monetization are follow-ups with their own privacy/delivery contracts.

## 6. Technical architecture and data model

Keep Next.js App Router, React, TypeScript, Tailwind, Motion, Supabase Auth/PostgreSQL, and Dexie for relevant private metadata. Add Supabase Storage only for hosted artwork. Use semantic HTML/images for the reader; a game engine or 3D canvas adds no value to comic pages.

Proposed routes: authenticated `/studio`, `/studio/series/[id]`, `/studio/chapters/[id]`; public `/read/[seriesSlug]` and `/read/[seriesSlug]/[chapterSlug]`. Owner preview uses an authenticated route and private cache behavior. Public pages never receive the full owner profile, draft payloads, or signed preview URLs.

| Proposed entity | Core fields and constraints |
| --- | --- |
| `creator_profiles` | Owner UUID, unique public slug, pen name, intentionally public bio; separate from private account profile |
| `content_series` | UUID, owner, slug/title/description, public visibility, reading format/direction, cadence weekday/time/IANA zone, revision/tombstone |
| `content_chapters` | UUID, owner/series, unique chapter ordering key and slug within series, state, current/published version references, revision/tombstone |
| `chapter_versions` | UUID, owner/series/chapter, unique chapter/version number, `hosted`/`external` mode, frozen title/summary/private external URL, readiness; immutable once scheduled/published |
| `chapter_pages` | UUID, owner/chapter/version UUID, unique page position, immutable object references, verified MIME/size/dimensions, ready state, description/transcript |
| `release_slots` | UUID, owner/series, local date/time/zone plus resolved UTC target, optional assigned chapter/frozen content version, announcement preference, state/revision; one active assignment per chapter and one chapter per slot |
| `publication_events` | UUID, chapter/slot/version, operation identity, requested target and actual publication timestamp, publish/withdraw audit outcome; unique release event for an assignment |
| `creator_quest_links` | Owner-matched series/chapter and existing calendar occurrence UUID; private reference only, no duplicated status or reward |

These are migration proposals, not implemented tables. Use composite ownership constraints, RLS, controlled publication RPCs, existing operation receipts for browser command retries, and explicit states. Chapter states are `draft`, `ready`, `scheduled`, `published`, and `withdrawn`; uploading/processing is a separate asset readiness state. A scheduled content version cannot be edited in place; unschedule it first. Initially published content is immutable; corrections require withdraw, revise, and deliberate republish with a new version and audit record.

Store these base records in `app_private`; owner and public readers use explicit allowlisted read RPCs. The public-reader role sees only eligible published fields, while the command role remains owner-scoped and the publication worker has separate restricted system privileges. Keep account IDs/private drafts out of public projections. Version IDs replace an informal version counter as the release's immutable manifest reference.

Expose public series/chapter fields through an explicit projection with allowlisted columns and publication predicates. A hidden series suppresses all its public chapters. Never expose raw draft tables/URLs through a public view or broad SELECT policy. Owner preview cannot warm a shared public cache. Public manifests/media responses must be revalidated against current publication eligibility; start with no shared caching for them so withdrawal is effective for new access, then introduce bounded caching only with measured invalidation behavior.

## 7. Server release and access contracts

Scheduling is an online, deliberate server operation: verify identity/ownership, expected revision, future target, series visibility rules, complete content readiness, and unique slot assignment. Commit the frozen version, state, slot, and retry receipt atomically. Validate external URLs syntactically; never fetch arbitrary URLs as a readiness check. Artist preview remains the check that the external destination is useful.

Use one bounded due-release scanner, proposed every minute, via [Supabase Cron](https://supabase.com/docs/guides/cron). It runs a restricted database function selecting accepted scheduled assignments with `scheduled_at <= server_now`; no per-creator cron jobs and no browser timer. Treat minute-level release timing as a proposed service target, not an exact-second guarantee.

Lock eligible chapter/slot rows in short batches with skip-locked behavior. Verify the frozen ready manifest and assignment remain valid; update published state/actual timestamp and insert its unique publication event in one transaction. Duplicate/overlapping job runs cannot release a chapter twice. Catch up due valid releases after an outage; show scheduled target and actual release time separately. Record actionable job errors/backlog; a failed release remains non-public and visible as needing attention to its owner.

The detailed database plan establishes owner-profile lock first, then slot/chapter locks, with the snapshot counter updated atomically. The worker identifies candidates before taking that lock order; it must not lock a slot first and then wait on a profile while owner commands do the reverse.

Skip publication for a deletion-requested account. Extend the [existing account-deletion workflow](OPERATIONS_PLAN.md#3-retryable-account-deletion) with object manifests/cleanup before Auth removal; no independent calendar-outbox deletion or second account lifecycle is needed. Hosted-art object backup/restore has its separate pilot gate.

Cancel/unschedule/withdraw uses the same row locks and expected revisions. If publication wins the race, return the actual published status and offer withdrawal, rather than claiming cancellation succeeded. Readers use server publication state/time, never their device clock. There is no need for WebSockets in the pilot; refresh/navigation fetches newly available chapters.

Hosted draft and scheduled page objects stay in a **private** bucket. Supabase documents that public buckets expose their files; private files require authorized access or signed URLs. Use owner-only storage policies, and a server-only media service that verifies a currently published chapter/version before signing a short-lived page URL. Never sign a user-supplied object path. Bound/rate-limit anonymous media requests and never expose the privileged key. See [bucket access models](https://supabase.com/docs/guides/storage/buckets/fundamentals) and [Storage access control](https://supabase.com/docs/guides/storage/security/access-control).

Proposed reader URL lifetime: five minutes, renewed for nearby pages as needed. Withdrawal blocks new manifests/URLs, but already issued URLs can remain valid until expiry and readers may retain copies. Do not promise instant recall. This follows [Supabase signed-URL behavior](https://supabase.com/docs/guides/storage/serving/downloads). Do not persist signed URLs in Dexie, logs, exports, or shared public page caches.

## 8. Local-first boundary, uploads, and cost

Private creator text/ordering/cadence edits can use the existing account-scoped metadata queue once this module is implemented. Sync pending changes before online publication actions; scheduling checks canonical metadata and verified asset readiness. Schedule, publish-now, cancel, and withdraw are explicit online RPCs, never automatically replayed calendar-outbox intentions. Ambiguous responses retry the *same* operation UUID/payload and reconcile its receipt before allowing a contradictory action.

Binary upload is a separate authenticated transfer lifecycle. Use unique versioned object paths, restricted creator ownership, size/type/dimension limits, verified decoding, per-file progress/retry, and server finalization before a page is ready. Accept JPEG/PNG/WebP initially; no ZIP/PDF/SVG import in the pilot. Strip unnecessary metadata and preview any optimized variant so lettering remains legible. Do not silently overwrite scheduled/published objects or treat a selected filename as an uploaded file.

Use Supabase's [resumable uploads](https://supabase.com/docs/guides/storage/uploads/resumable-uploads) for unreliable mobile connections/progress, adding only a narrow TUS client when implementing this slice. Upload resume after reload may require reselecting the original file; the pilot does not persist artwork blobs in IndexedDB. Closing the browser stops an unfinished transfer, but cannot stop a fully confirmed server release.

Proposed pilot limits: 50 pages/chapter, 10 MB/source page, 100 MB total source files/chapter, with byte limits also enforced server-side and bounded decoded dimensions. Tune after testing real art, then publish the actual limits in the upload UI. Keep originals private only under an explicit quota/retention choice; generated reader variants must be artist-previewed. Track incomplete upload objects and retryable orphan cleanup without deleting any scheduled/published references. Account deletion removes objects as well as rows through a retryable workflow; database cascades alone do not remove Storage files.

Measure retained originals/variants, reader transfer bytes, processing, and hosting costs using the actual provisioned [Supabase plan](https://supabase.com/pricing). Do not promise unlimited free hosting. Illustrative arithmetic: 20 delivered pages averaging 400 KB is about 8 MB per complete chapter read; 1,000 uncached complete reads is about 8 GB of delivery, before thumbnails/overhead. The artwork quality and cache behavior determine real cost. External-only chapters can validate cadence and discovery with lower media costs; the hosted reader follows as a bounded pilot using the same series model.

Published pages are fetched online in the pilot. Device-local reading position is not an offline chapter download or cross-device sync. Keep guest reading progress separate from private account partitions and clear it through a visible control; do not leak one user's reading history to the next signed-in user.

## 9. Delivery slices and acceptance

| Slice | Deliverable | Exit condition |
| --- | --- | --- |
| C1. Creator planning | Invited creator profiles, series/drafts, Wednesday slots, optional quest links | Creator plans a chapter without duplicating calendar entries or exposing private data |
| C2. External publishing | Link chapters, preview, explicit scheduling, server release, public series/cards | Link appears once when due while browser is closed; early access and cancel/release races pass |
| C3. Hosted reader | Private upload/finalization, ordered manifests, reader modes, local resume | Correct page ordering/direction, readable art, retry/zoom/keyboard and cost limits pass |
| C4. Creator pilot readiness | Hosted scheduled releases, withdrawal, reporting path and operational controls | All boundary and release checks below pass with invited artists and real reader devices |

Before opening creator signups broadly, establish content ownership/publishing terms, a reader report path, and operator withdrawal tools. For the pilot, creators explicitly confirm they can publish the work, and public surfaces offer Report content. Avoid adding comments/chat until there is a concrete moderation plan.

Required proof:

- Hosted and external chapters can coexist in one series; external links are labeled, validated, and never fetched through an arbitrary server proxy.
- Wednesday releases match the creator's confirmed local time/zone across DST; empty slots never publish, and cadence changes preserve accepted targets.
- Browser closed, scanner retry/overlap, missed job, incomplete upload, revision conflict, unschedule race, and withdraw/republish all have truthful states.
- Anonymous and cross-owner direct requests cannot retrieve draft metadata, chapter URLs, page objects, or private production/calendar/account data. Owner preview stays private; hidden/withdrawn chapters cannot obtain new media access.
- Both scroll and paged reading work on phone/desktop, with RTL/LTR, focus, zoom, transcripts, image failures, position recovery, reduced motion, and bounded loading.
- Metadata conflicts preserve drafts; incomplete upload bytes are not falsely reported as durable/synced; sign-out/account changes isolate creator data and reading history.
- Upload limits/finalization, immutable paths, orphan cleanup, storage deletion, signed-URL expiry, cache behavior, and measured delivery budget pass.
- Neither scheduled publishing nor reading grants XP; explicit production quests follow the existing completion/undo rules.

Evaluate creators' time to prepare/confirm a release, confusion about cadence versus readiness, release reliability, and readers' ability to find/resume the right chapter. Treat these as feature hypotheses, not proof that publication frequency or reading time measures personal growth.

**Next design step:** Sketch the series workspace, Wednesday assignment/confirmation flow, public series page, and mobile reader as one coherent example using a hosted chapter and an external chapter. Exact release time/zone, art assets, hosting budget, and pilot quotas are implementation setup choices; no external content has been uploaded or published.
