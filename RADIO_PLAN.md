# Radio — Parked Feature

**Updated:** 14 October 2026

**Status:** Requested by the user and explicitly parked for later. No implementation, API subscription, credentials, or streaming tests. Not a calendar MVP or creator-pilot dependency.

**Related documents:** [Product plan](PRODUCT_PLAN.md), [technical design](TECHNICAL_DESIGN.md), and [agent guide](AGENTS.md).

## 1. Idea and first slice

Offer optional live radio while a user plans, works, or reads. Start with a small station picker, search/filter by country or genre, favorites, and a compact player with play/pause, mute/volume where supported, station/source label, and clear connecting/unavailable states. Listening earns no XP and never starts automatically from a quest, schedule, room unlock, or manga page.

Keep playback controls accessible without covering calendar actions or comic art. A small radio object in the fantasy room could open the picker later, but an ordinary HTML control must work without 3D. Default off; the reader remains quiet unless the user intentionally enables audio. No broadcasting, recording/downloads, track library, visualizer, or shared listening room in this first slice.

## 2. Saved API lead and research limits

The supplied [Heri Hermawan article](https://medium.com/@herihermawan/free-api-to-access-90-000-radio-stations-worldwide-33768facc0de), dated 2 January 2026, describes the **50K Radio Stations API** on RapidAPI, advertises over 90,000 stations, and outlines station search, country/genre/language filters, metadata, and stream URLs. These are the author's claims, not a verified live catalog or compatibility guarantee.

Candidate references: [RapidAPI listing](https://rapidapi.com/herihermwn/api/50k-radio-stations) and [provider documentation](https://radio.herani.id/docs). Proposed directory host from the article: `50k-radio-stations.p.rapidapi.com`. The article's introduction says 300 free requests/month, while its pricing section says 500. Provider/listing pages yielded insufficient readable content during this review, so current prices, quota, billing requirements, terms, availability, and API schema remain unverified. Treat “free” as a possible limited tier, not a commitment to free production service.

Before implementation, verify the actual plan, overage behavior, caching/attribution requirements, and permitted stream use from the provider and relevant station terms. A directory entry alone does not establish permission to rehost or redistribute a broadcast. Retain this candidate without buying a plan or choosing another provider now.

## 3. Proposed technical path

- Reuse Next.js/React. Directory queries go through bounded server-only provider requests with a server-held RapidAPI key, fixed host, pagination, debounce, caching/coalescing, and quota/error handling. Never forward private calendar, itinerary, or creator text as search input. Do not add an API key or required configuration to the MVP.
- Play a validated station stream directly from the browser using one native `<audio>` element. Gamecal does not store, record, or relay the stream through Next.js/Supabase; this avoids making our servers the audio bandwidth path. Listeners still use internet/data, and the broadcaster receives the direct connection.
- Start with tested HTTPS streams in formats the target browsers can play. Insecure streams/redirects, unsupported codecs, dead links, or geographic restrictions can fail even when a directory lists a station. Do not add an arbitrary-URL proxy to work around failure. Use a bounded same-station fallback where available, then offer retry/another station.
- Mount the single player above relevant client navigation boundaries so supported in-app navigation does not create overlapping audio. Stop/release it on explicit stop, sign-out, and account switch. Do not restore playback automatically after reload. Ignore stale events/results when switching stations rapidly.
- Treat `play()` as asynchronous and handle rejection; show Playing only after successful playback, and handle later buffering/error/pause events. Browsers apply autoplay restrictions, as documented in [MDN's autoplay guide](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Autoplay) and [play() reference](https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/play).
- Media Session can add supported system metadata/controls later. It does not establish guaranteed lock-screen, background, or closed-browser playback; validate actual phone/browser behavior. See [MDN Media Session](https://developer.mozilla.org/en-US/docs/Web/API/Media_Session_API) and [mixed-content rules](https://developer.mozilla.org/en-US/docs/Web/Security/Defenses/Mixed_content).

Audio playback, buffering, and provider responses are runtime state, not durable calendar commands. If favorites/settings are persisted, store provider/station IDs and small validated metadata in the existing account-isolated Dexie/Supabase path; re-resolve streams when needed. Never enqueue Play or persist audio bytes, credential-bearing URLs, or an entire station catalog. Offline favorites do not mean offline listening. No radio-specific database schema or package is needed while this feature is parked.

## 4. Revisit and acceptance

Revisit when users express a need for optional listening during planning/work/reading and core delivery is stable. Confirm the provider's actual plan first, then test a small representative station set rather than assuming the advertised catalog is playable.

Before a radio slice ships, prove explicit-start behavior, one-player navigation, accessible controls, rapid station switching, invalid/failed streams, quota/provider failures, disconnect/reconnect without surprise playback, account isolation, and real-device interruptions. Confirm that calendar saving and reader navigation work independently of radio, that credentials stay server-side, and that no stream is stored/proxied. Measure provider calls and listener transfer/battery behavior; do not claim radio improves focus without user-specific evidence.

**Next action:** None while parked. Recheck this candidate and decide the bounded player scope when the radio feature is activated.
