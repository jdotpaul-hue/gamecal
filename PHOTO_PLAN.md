# Pexels Photos — Exploration and Cover Selection

**Reviewed:** 14 October 2026

**Status:** Recommended optional itinerary-cover experiment; not an implemented integration or a required MVP gate. Related: [product plan](PRODUCT_PLAN.md), [itineraries](ITINERARY_PLAN.md), [technical design](TECHNICAL_DESIGN.md), [local sync](LOCAL_SYNC_DESIGN.md), [agent guide](AGENTS.md).

## 1. Recommendation

Use destination-based photos for itinerary covers and list cards. Keep the agenda on a plain readable surface and preserve the illustrated fantasy room as the progression identity. Later, offer category-based event-header suggestions when users want them; do not search using every private calendar title or place a photo behind every event.

Examples of query intent, not verified photo selections:

| Available public context | Query idea | Fallback |
| --- | --- | --- |
| Confirmed Tokyo, Japan destination | `Tokyo Japan skyline` | Reviewed city-scene pool or neutral gradient |
| Confirmed coastal destination | Destination name/country plus `coast` | Reviewed coast/nature pool |
| Conference trip with confirmed city | City/country plus `cityscape` | Neutral city cover, without business/client names |
| User requests a hiking-style header | `hiking trail landscape` | Reviewed nature image |
| No confirmed destination or image preference | No provider request | App-owned gradient/illustration |

A stock photo is illustrative. Search relevance does not prove the image depicts the booked hotel, exact venue, or live destination conditions. Label it as a cover/inspiration image, not a property preview or weather report.

## 2. Verified service fit and limits

[Pexels' official API guidance](https://help.pexels.com/hc/en-us/articles/4405588861721-Can-I-use-the-API-as-a-wallpaper-app) permits background/header selection inside an app with a different primary purpose, while prohibiting a competing wallpaper/gallery service. Gamecal's proposed usage enhances planning rather than becoming a photo-download product.

The [free-API FAQ](https://help.pexels.com/hc/en-us/articles/47677890260761-Is-the-Pexels-API-free-to-use) lists default limits of 200 requests/hour and 20,000/month. Do not assume automatic unlimited access: the [limit-increase FAQ](https://help.pexels.com/hc/en-us/articles/900005852323-How-do-I-get-unlimited-requests) currently says increases are paused. Recheck account limits before launch.

Use the [API documentation](https://www.pexels.com/api/documentation/) for photo search, landscape/size filters, photo IDs, resized source URLs, dimensions, average color, and attribution metadata. The provider's `/curated` endpoint is a general editorial feed, not a destination-relevance filter. Our destination matching uses search plus our own selection rules.

Follow [Pexels' license](https://www.pexels.com/license/) and [terms](https://www.pexels.com/terms-of-service/) rather than copying content in bulk or implying endorsement. Keep a prominent Pexels link and available photographer/photo credit in the selection flow; auto-selected covers also show credit within their display. Use attribution even where general downloaded-photo licensing would not require it.

## 3. Curation and automatic selection

### A. Reviewed pools

During implementation, review a small set of city, coast, nature, and neutral-travel photos. Record photo IDs, source/photographer links, available image variants, and category tags in a small catalog. Prefer readable wide crops, uncluttered scenes, and no distracting branding or misleading property identity. This review creates a quality baseline; no live photos/catalog have been selected during this planning task.

### B. Destination-specific search

1. Use a confirmed public destination label/country or an explicit user-selected visual theme. Never send private titles, notes, meeting attendees, client names, booking references, or exact private addresses to Pexels.
2. Build a bounded normalized query with a simple rule map. No LLM, embedding database, or paid vision service in the first experiment.
3. Request a small landscape candidate batch, proposed 12 photos. Reuse that batch for automatic choice and a three-option Change Cover picker.
4. Filter invalid URLs/metadata and unsuitable dimensions. Rank by destination/topic text relevance, usable landscape crop, and reviewed pool preference. Metadata matching is a heuristic, not verified geographic recognition or visual-content assurance.
5. If relevance is weak or ambiguous, offer candidates for review or use a neutral fallback. Do not silently choose another city with the same name.
6. Persist the accepted selection and its context/rules version. The cover stays stable across refreshes; searches do not rerun on every render or itinerary edit.

The only automatic update happens when there is no selected cover, automatic mode remains enabled, and the result still matches the current destination context. A changed destination can offer a new suggestion; it never silently replaces a user's manual choice.

### C. User control

Provide Auto, Change Cover, and Remove Cover. Removing sets explicit none mode so the next refresh does not restore an image. Changing offers bounded candidates with credit; custom upload and an unrestricted stock-photo browser are deferred.

If a search started before a manual choice/removal/destination change, discard its obsolete result. Applying a selection is a revision-checked local command through the existing outbox, not a provider callback writing directly to Supabase.

## 4. Integration and storage

- Call Pexels from an authenticated Next.js Route Handler using native fetch and a server-only `PEXELS_API_KEY` in the Authorization header. Restrict the upstream host and operations; validate bounded query/category/page inputs and never accept arbitrary upstream URLs or client credentials.
- The app endpoint returns normalized candidates with photo ID, allowed image URL variants, dimensions, average-color placeholder, photographer credit, source page, and accessibility text. Validate HTTPS Pexels page/image hosts before use; never render provider HTML.
- Cache search results by normalized public query/filter/rules version and coalesce requests. Proposed refresh window is 24 hours; this is our freshness choice, not an asserted Pexels retention requirement. [Pexels' cache FAQ](https://help.pexels.com/hc/en-us/articles/900005538826-Why-do-I-get-the-same-content-from-multiple-requests) says repeated provider requests still consume allowance, even for provider-cached results.
- Add per-user cooldowns and track global allowance/reset information; do not promise a strict shared cap using per-process counters alone. On exhausted quota, use an existing selection/reviewed pool/gradient and stop retry loops.
- Save selected photo metadata and URLs with the itinerary; do not upload photo bytes into Supabase Storage. Render an appropriately sized supplied CDN image variant directly, using a responsive image or unoptimized Next.js image path initially. Default image optimization/proxying can introduce hosting transformation/bandwidth costs, so use it only after measuring and deliberately selecting that path.
- Crop/overlay in the UI for legibility; never download the largest original just to show a small card. Load offscreen cards lazily, reserve dimensions, and keep cover loading separate from agenda interactivity.
- If a photo disappears, fails to load, or must be removed, fall back without changing the itinerary. Support catalog/selection invalidation and retain no misleading source credit for a replacement.

Metadata-only selection avoids our own image-object storage but does not make network transfers, hosting, or API usage unlimited. An image URL is also not an offline image: saved-itinerary access must work with a local placeholder when remote media is unavailable. No photo bytes are bundled into recovery exports or offline packs initially.

Shared cost control is defined in [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md#4-request-limits-and-provider-budgets): committed PostgreSQL reservations, 150 upstream searches/hour and 15,000/calendar month globally, plus account cooldown/limits. Actual provider resets/limits also apply; enable the optional experiment only after concurrency/quota/fallback proof.

## 5. Data contract and presentation

Proposed itinerary cover fields: mode (`auto`, `manual`, `none`), optional normalized selection, and context/rules version. A selection contains provider `pexels`, photo ID, source page, image variants, dimensions, photographer/name link, alt description, average color, and selected timestamp. Owner/revision checks apply; the client cannot forge arbitrary remote hosts into the image renderer.

Use the existing itinerary revision/queue for cover changes rather than another sync engine. Fetching candidates is a best-effort read and not a queued user mutation. The selected metadata syncs across devices; browsers fetch image content separately. Export metadata/attribution links only.

Keep text on a solid panel or controlled scrim with measured contrast. A decorative cover uses appropriate empty alt text; any photo shown as meaningful content uses an accurate description. Do not fabricate a landmark/property name from the query. A short transition can reveal the loaded image, with reduced-motion support; do not animate a continuous slideshow or alter RPG rewards based on imagery.

## 6. Scope and verification

First experiment: one itinerary cover, stable automatic destination suggestion, a three-choice picker, Remove Cover, visible attribution, metadata-only persistence, and neutral offline/error fallback. Event images, daily wallpapers, image uploads, video covers, and AI semantic inference are later options.

Before shipping, verify:

- Public-context queries exclude private event/trip content; ambiguous/missing destinations use the documented fallback.
- Selection persists through reload and cross-device sync; late search results cannot override manual/none mode or a changed destination.
- Crop, readability, mobile transfer size, layout stability, attribution, keyboard access, and reduced motion are checked with actual selected assets.
- Secrets remain server-only; arbitrary hosts/URLs, oversized queries, and invalid upstream results are rejected.
- Request coalescing/caching/cooldowns and rate-limit failure do not block saving, forecasting, or calendar sync.
- Deleted/unavailable images and offline access show a placeholder; metadata exports contain no binaries or private query text.

Observe whether users find a trip easier to recognize and enjoy the interface without slower planning. Do not make cover selection mandatory or claim that photos prove personal growth.

No API account/key has been provisioned, authenticated photo requests made, remote photo downloaded, or live asset catalog curated in this exploration.
