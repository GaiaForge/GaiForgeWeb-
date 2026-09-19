# Orpheus portal plan — from battery charts to a field tool

Agreed with Travis 2026-09-19. This is the plan of record for the Orpheus side
of the customer portal. `ROADMAP.md` tracks what is done; this file says what
we are building next, in what order, and why. Repo-specific detail lives here;
the vault links to it.

## Who it is for

Bird ringers and ornithologists running one to a handful of Orpheus units at a
ringing station or study site. They visit the units with the phone app, which
syncs the unit's logs to the cloud on every connect. They keep their catch
records in their national ringing scheme's software, because they must.

The portal earns its place if it answers two questions they cannot answer
elsewhere:

1. **Is each unit alive, charged, and where I left it?** (health at a glance)
2. **Does the playback bring birds into the nets?** (effort versus catch)

## What exists today (verified 2026-09-19)

| Piece | State |
|---|---|
| Sync from unit → app → `/api/orpheus/sync` → PostgreSQL | Live. Battery, environment, playback events, system events, plus device lat/lng and name. Auto on device connect while signed in, manual button as fallback. |
| Per-device analytics (`/orpheus/analytics`) | Live. Temperature, humidity, pressure, battery, solar, playback hours and mode, correlation, system log, CSV export. (AI reports are a HiveGuard feature only; the Orpheus report button is a plain data summary, not part of this plan.) |
| `last_sync` per device | Stored and returned by `/api/orpheus/devices`; shown as a small header line only. |
| Device coordinates | Stored per device, returned by the device list. **Nothing draws them.** |
| Recordings and species tabs | Rendered, empty for every customer. No audio reaches the cloud: the phone relay was removed (23 MB/min is not viable) and a Pi-direct path was never built. BirdNET (`birdnetlib`) is wired into the API and waiting. |
| Journal (`/orpheus/journal`) | Live. Free-text dated entries per device. |

## The plan, in order

Each step is useful on its own and the next one builds on it.

### 1. Map page — `/orpheus/map`  ← built 2026-09-19, not yet deployed

Status: `src/pages/OrpheusMap.jsx` + `OrpheusMap.css`, route in `App.jsx`, Map
link in the three Orpheus sidebars. Verified locally against the production API
as the review account (one placed unit, green pin, popup, attribution). Same
change also fixes a pre-existing bug: on a cold page load the app didn't know
the visitor was signed in, so every deep link / bookmark to an inner page
bounced to the product dashboard; the saved session is now read synchronously
at startup and still validated against `/api/auth/me`.

- Leaflet + react-leaflet, **OpenTopoMap** tiles. Free with attribution
  (CC BY-SA; the credit line must stay visible). Volunteer-run tile server:
  fine at our traffic, and the tile URL is a one-line change if that ever
  changes. Max zoom 17, which is a feature for a wildlife product.
- One pin per unit from `/api/orpheus/devices`. Pin popup: name/serial,
  battery % and voltage (from the overview endpoint), last sync, link to that
  unit's analytics.
- **Last sync is loud.** Pin colour and a chip by age: green ≤ 7 days,
  amber ≤ 30, red beyond, grey never. Data only moves when someone visits
  with a phone, so freshness is the health signal, not the numbers.
- Units with no coordinates are listed beside the map, not silently dropped,
  with a note that location is set on the app's Settings screen.
- No aerial layer at first (licensing is murkier). Add a free-tier provider
  later if asked.
- **Privacy:** exact coordinates are shown only to the owning account. Unit
  positions can reveal nest sites or roosts. Nothing on a shared or public
  page, ever. A per-device "coarse location" flag (round to ~1 km) is a
  candidate follow-up.

### 2. Recording metadata sync

BirdNET itself is installed and verified on the VPS as of 2026-09-19 (model
load ~9 s, ~5× real time on CPU; see the API repo's `pyproject.toml`
`birdnet` extra). Still missing for real use: an upload page, a background
analysis job (analysis currently runs inside the web request), a storage
policy for the audio, and the non-commercial model-licence question.

A fifth dataset in the app's `sync_service.dart`: start time, duration,
format, trigger type (manual / scheduled / threshold), storage label. The unit
already keeps this list. Fills the recordings tab without moving audio. Audio
itself comes later through a USB-stick upload page on the portal feeding
BirdNET, which is the path researchers already walk (stick → home).

### 3. Catch data — import first, log second

Ringers already type every bird into scheme software. Do **not** make them do
it twice. Order of preference:

- **Import**: accept an EURING exchange file or a CSV with column mapping
  (species, date, time, count). EURING is the pan-European standard every
  scheme can export; national tools differ (Germany alone has three
  ringing centres). Verify the current EURING field spec against the
  published document before designing the mapper — do not design from
  memory.
- **Lightweight catch log** in the existing Journal as the fallback for
  stations without an export: session date, time window, species from a
  **fixed list with autocomplete** (not free text — keeps it chartable and
  the same list serves BirdNET detections later), count, net, notes. Must be
  enterable from a phone in under a minute. CSV export.
- Not a ringing database. No ring numbers, no biometrics, no submission
  formats. Ask two or three customers which software they use and for a
  sample export (ring numbers blanked) before building the importer.

### 4. Effort versus catch

Catches per session overlaid on that unit's playback windows. Detections
during playback versus outside it once audio flows. This is the chart that
answers question 2 above, and it is a view on data steps 1–3 already collect.

## Deploy reminder

Portal changes ship by `npm run build`, committing `html/portal/`, and pushing
— the committed build is the deployed artifact (see `CLAUDE.md`). New
dependencies (`leaflet`, `react-leaflet`) are in `package.json`; nothing
server-side changes for step 1.

## Not doing

- Live telemetry. Data arrives when a person visits with a phone; the portal
  is a field notebook. Say so on the page rather than letting a flat chart
  look like a dead unit.
- Paid tiers or upgrade prompts anywhere in the portal
  (`PAID_TIERS_ENABLED = false`; see the Orpheus app repo's
  `APP_STORE_REVIEW.md` for why).
