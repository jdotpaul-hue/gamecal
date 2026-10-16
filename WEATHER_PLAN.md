# WeatherAPI Forecast Integration

**Updated:** 14 October 2026

**Decision:** Use WeatherAPI.com for weather forecasts. This is an MVP itinerary enhancement, not an implemented integration. Related: [product](PRODUCT_PLAN.md), [technical design](TECHNICAL_DESIGN.md), [itineraries](ITINERARY_PLAN.md), [local sync](LOCAL_SYNC_DESIGN.md), [agent guide](AGENTS.md).

## 1. User value and scope

Help people plan an outing, meeting, transfer, or trip with location-specific weather context. Show a compact forecast on an itinerary day and optionally Today after a user selects a home/weather location. Calendar entry, local saving, and synchronization must work when weather is missing or unavailable.

MVP display: location, destination-local forecast date, condition icon/text, high/low temperature, chance of rain, and maximum wind. Offer hourly temperature/rain/wind detail for the selected day where returned. Default temperature to Celsius; let users choose Fahrenheit without another API request.

Weather is advisory planning context. Do not automatically move bookings, mark a quest failed, grant XP, or claim an activity is safe. Proactive weather notifications, official alerts, AQI/pollen, long-range predictions, maps, and automated weather-based scheduling are deferred.

## 2. Verified launch capabilities

As checked on 14 October 2026, the [WeatherAPI pricing table](https://www.weatherapi.com/pricing.aspx) lists a free tier with 100,000 monthly calls and a three-day forecast; Starter lists seven days. The [Forecast API](https://www.weatherapi.com/docs/forecast-api/) supports daily/hourly data with access depending on subscription. Launch against the free-tier capability unless a different account plan is deliberately selected; recheck entitlements before implementation/deployment.

Do not promise a forecast for an arbitrary future trip. Show only returned supported dates; otherwise display "Forecast not available for this date yet." Historical observations and the separate Future API are not substitutes for the selected near-term forecast.

Past itinerary dates have no current forecast card in this MVP. Do not relabel an older forecast as observed weather; historical-weather views are deferred.

The [provider terms](https://www.weatherapi.com/terms.aspx) require free-tier source attribution, allow forecast caching for at most 24 hours, limit current-condition caching to 60 minutes, and prohibit storing provider data beyond the subscription term. Keep WeatherAPI attribution on weather views. This MVP uses forecast data only and drops the current-condition block from normalized responses. Follow the stricter terms where the attribution guide's wording differs, and verify terms again at launch.

## 3. Choosing locations and dates

- Ask the user to select a city/town from WeatherAPI search results. Include region/country so ambiguous names are distinguishable. No automatic IP lookup or GPS request.
- Store the selected label and coordinates as weather-location settings. An itinerary has an optional base weather location; a dated override supplies a different location for a multi-destination day. Today may use an optional profile location.
- A venue address, map URL, or free-text destination summary is not automatically a resolved weather location. This is city-level weather selection, not an address/geocoding/map integration.
- Use `/v1/search.json` through our server for search and `/v1/forecast.json` with selected latitude/longitude for forecast retrieval. Forecast requests use the configured supported horizon and omit paid-only extras.
- Search responses do not include the timezone field; the forecast response's matched location supplies `tz_id`. See the [location-object documentation](https://www.weatherapi.com/docs/location-object/) and [search documentation](https://www.weatherapi.com/docs/search-api/). Never invent a timezone from a city name.
- Weather dates belong to the weather location's zone. Hourly records use `time_epoch` when aligning with itinerary intervals. If itinerary and weather zones differ, label dates/zones explicitly; never match using the phone's date or a UTC date substring.
- A selected itinerary-day interval may intersect two weather-local dates; show the relevant labeled daily sections/hourly coverage rather than inventing one mixed daily high/low. Only display hours/dates actually returned.
- Choosing/changing a weather location does not alter booked event times or the itinerary display zone.

## 4. Request architecture

```text
Weather card -> local forecast snapshot (if usable)
                    |
                    v
Authenticated Next.js weather route
  validation + rate limit + cache/coalescing
                    |
                    v
WeatherAPI over HTTPS with server-only key
```

Use Next.js Route Handlers and native `fetch`; no separate backend, provider SDK, or alternate weather provider is needed. Add `src/features/weather` for normalized types/rendering and a server-only provider module. The API key is `WEATHERAPI_KEY`, never a public environment variable or a value sent to the browser.

Proposed application routes:

| Route | Contract |
| --- | --- |
| `GET /api/weather/search` | Verified session; bounded city query; return only selected location candidates |
| `GET /api/weather/forecast` | Verified session; validated numeric coordinates; server clamps forecast days/options; normalized response without provider credentials |

Restrict outbound requests to the fixed WeatherAPI HTTPS host/endpoints. Do not accept an upstream URL, raw API options, or a client-supplied provider key. Send only weather query data, not itinerary IDs, notes, booking references, or user credentials. Redact upstream query strings because they contain the key; avoid logging precise location/search content.

Validate upstream JSON and map it to a stable response containing location/zone, returned forecast dates, daily values, requested hourly values, source, `fetched_at`, `refresh_after`, and `expires_at`. Map condition codes to our existing icon system or validate official icon-host URLs; do not load arbitrary image hosts from responses. Preserve meaningful unavailable states rather than converting missing readings to zero.

## 5. Caching and cost control

Proposed freshness policy: forecast snapshots refresh after 60 minutes and are removed at the hard expiry defined by the provider contract, measured from the original upstream fetch. Cache hits must carry that original timestamp; neither downloading nor reading the snapshot extends its age. A stale-but-unexpired snapshot may be displayed with its timestamp during a refresh failure. An expired snapshot is removed, not presented as current or kept as a trip archive.

- Cache by normalized selected location, supported horizon, language if used, and response-schema version. Temperature-unit toggles reuse the same normalized data.
- Use a bounded, expiring server cache with in-flight coalescing; a per-process cache is acceptable initially and may duplicate misses across instances. Use an existing hosting cache only if its retention behavior fits the contract; don't add Redis solely for this feature.
- Use an account-partitioned in-memory browser cache for forecasts in the MVP, with expiry checks and active cleanup. Do not persist forecast payloads in Dexie initially: deletion cannot run while the browser is closed, and persistent forecast retention needs a confirmed provider-compatible policy. Location/unit settings still persist locally and sync normally.
- Keep weather responses out of Supabase trip rows, mutation receipts, complete account exports, recovery bundles, permanent backups, and the initial print overview. Sync only user weather-location/unit settings.
- Debounce location search (proposed 400 ms, minimum three characters), cancel stale UI results, and deduplicate active location requests. A weather card refreshes on visible use/focus when stale, not on every render, calendar edit, or background queue drain.
- Apply server-side per-user request limits, search cooldowns, and a provider-usage budget. Track upstream call counts/errors without content; a shared budget mechanism is required before promising a strict global cap across server instances.

The mechanism/initial limits are now defined in [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md#4-request-limits-and-provider-budgets): atomic PostgreSQL reservations committed before requests, 2,000 upstream calls/day and 80,000/calendar month globally, plus account search/forecast limits. Obey provider windows/reset/quota independently; counters are not a promise of provider billing or successful deployment. No Redis is required.
- Handle provider quota exhaustion with cached usable data or an unavailable state; stop repeated upstream calls until the configured billing-window reset or operator intervention. Do not auto-upgrade or purchase a plan.

WeatherAPI [error documentation](https://www.weatherapi.com/docs/error-codes/) distinguishes unknown location, invalid key, exhausted quota, disabled key, and unavailable plan access. Map these to application states and safe operator logs rather than exposing raw upstream errors or retrying them forever. Use a short timeout and bounded backoff only for transient errors.

## 6. UI and local-first behavior

| State | Display |
| --- | --- |
| No location | "Choose a weather location"; ordinary planning stays usable |
| Loading with no cache | Compact placeholder; do not block the timeline |
| Fresh forecast | Labeled location/date, values, update time, WeatherAPI attribution |
| Older but usable snapshot | Visible cached/update-time label; refresh quietly when online |
| Beyond returned horizon | "Forecast not available for this date yet" |
| No network/cache expired | "Weather unavailable—connect to refresh" |
| Ambiguous/unknown location | Ask for a specific search selection; do not choose silently |
| Quota/provider/config error | Weather unavailable with a retry policy; save/sync continue independently |

Normal local location-setting edits use the existing outbox; forecast retrieval itself is a best-effort read and never queues a weather "mutation." A selected location can be used immediately for a forecast read before its settings sync completes. Cached weather follows its own expiry independently of complete-trip cache readiness.

An already-open app can show a still-valid in-memory snapshot during a connection interruption. After closing/reopening offline, itinerary access does not imply weather access. Add persisted weather only if the provider-compatible retention lifecycle is confirmed; weather expiry must never remove the itinerary. On provider disconnection/subscription termination, clear provider-derived caches/metadata as required while preserving user-entered trip content.

## 7. Data and implementation order

Store optional profile temperature-unit/home-location settings, an optional itinerary base weather location, and `itinerary_weather_locations` for dated overrides: UUID, owner, itinerary UUID, itinerary-local date, selected location fields, revision, timestamps/tombstone, unique active itinerary/date. Enforce owner equality and the normal queue/deletion rules. Provider timezone metadata is enrichment, not authority to reschedule a user's entry.

Build after the manual itinerary and local-sync slices:

1. Set server configuration and verified entitlement limits; add provider response fixtures and normalization.
2. Implement authenticated/rate-limited search and forecast routes plus secret-redaction checks.
3. Add city selection, daily/hourly cards, freshness states, transient browser snapshots, and unit switching.
4. Verify expiry/usage/error behavior and location-date matching before enabling weather in the pilot.

## 8. Acceptance checks

- Daily values and selected hourly records match a validated provider fixture; missing data never appears as zero probability or temperature.
- A trip outside the returned forecast dates shows unavailable, not fabricated long-range weather.
- Ambiguous cities require selection; search does not assume `tz_id`; phone, itinerary, and weather-zone differences are handled correctly.
- Concurrent cards coalesce requests; rapid typing, navigation, and unit toggles do not create avoidable upstream calls or stale UI overwrites.
- Fresh/older/expired caches retain the original upstream time; hard expiry removes forecast data from server/browser reads and later cache hits cannot extend it.
- Provider errors, quotas, and network interruption do not break local quest/itinerary saves, rewards, or Supabase sync.
- The key is absent from browser bundles, responses, exports, and logs. Unauthenticated/oversized/arbitrary-URL requests are rejected.
- Weather location overrides are owner-isolated, sync safely, and disappear after itinerary deletion; forecasts themselves never enter the durable outbox.
- Attribution, location/date labels, keyboard access, reduced motion, and Celsius/Fahrenheit behavior are verified.

No WeatherAPI account has been created, plan purchased, key configured, or provider call made with credentials as part of this planning work.
