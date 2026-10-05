# GaiaForge Portal Roadmap

## Completed

### Multi-Product Portal Architecture
- [x] Product selector after login — Orpheus, HiveGuard, SprigRig tiles
- [x] Serial-gated registration — users must enter a valid device serial to create an account
- [x] Device type linked to account — portal only shows products user has registered
- [x] Admin sees all products
- [x] Auto-redirect if user owns one device (skip selector)

### Orpheus Portal
- [x] Firmware downloads page — loads from manifest.json
- [x] Admin firmware upload with drag-and-drop
- [x] File naming matches device updater expectations (`orpheus_update/orpheus_update.zip`)
- [x] Previous versions archived on upload
- [x] Admin can delete firmware releases
- [x] Documentation tab (user manual, quick start guide, solar panel guide)
- [x] Mobile app tab (Android APK download, iOS placeholder)
- [x] Firmware upload API service on VPS (port 8001, systemd managed)

### HiveGuard Portal (pre-existing)
- [x] Dashboard with hive health scores, behavioral analysis
- [x] Analytics with charts, AI reports, spectral analysis
- [x] CSV upload and app sync for sensor data
- [x] Device management
- [x] Alerts with email notifications
- [x] Researcher journal
- [x] Beekeeper vs Researcher mode
- [x] Admin panel with user management, audit log, GDPR tools

### SprigRig Portal
- [x] Placeholder page (coming soon)

### Backend (Hiveguard API)
- [x] DeviceSerial model — pre-registered serials with product type
- [x] Serial validation on registration
- [x] Admin serial management endpoints (list, add, bulk add, delete)
- [x] Login and session return products list
- [x] Alembic migration for device_serials table

---

## In Progress

- [ ] Catch-data import (EURING / CSV) and the effort-vs-catch view — see `ORPHEUS_PORTAL_PLAN.md`
- [ ] Recording metadata sync from the app (fifth dataset)

---

## Recently Completed

(Updated 2026-10-05. `ORPHEUS_PORTAL_PLAN.md` is the plan of record for what
comes next on the Orpheus side; this list records what shipped.)

### Orpheus Data Pipeline (Done, 2026-07)
- [x] Orpheus data schema (environmental readings, battery, playback events, system events)
- [x] API models and `/api/orpheus/sync`
- [x] Sync from the app: automatic on device connect while signed in, manual fallback
- [x] Device registration via the app (serial claimed on first sync)

### Orpheus Analytics Dashboard (Done, 2026-08)
- [x] Device overview with last sync time
- [x] Environmental charts (temperature, humidity, pressure, battery, solar)
- [x] Playback timeline and mode breakdown
- [x] Correlation view
- [x] Date range filtering and CSV export

### Orpheus Researcher Journal (Done, 2026-08)
- [x] Timestamped entries per device
- [ ] Photo attachment, environmental snapshot, export — not built

### Orpheus Map (Done, 2026-09-19)
- [x] `/orpheus/map`: OpenTopoMap, one pin per unit, colour by sync age, popup with battery and last sync
- [x] Units without a location listed beside the map

### Orpheus Recordings and Species (Done, 2026-09-19/20)
- [x] Upload WAV from the unit's USB stick; recording time and location read from the file's GUANO metadata
- [x] Species identification with Perch 2.0 (Apache 2.0 licence); BirdNET kept as a comparison engine only
- [x] Location filter from GBIF sightings near the unit in season
- [x] Delete a recording and its analysis; re-analyse replaces results
- [x] Detection timeline on a real time axis
- [ ] Background analysis job and chunked reading for files over ~20 minutes
- [ ] Folder upload for a whole stick

### Orpheus Reports
- [ ] Not started. AI-generated reports are a HiveGuard feature; the Orpheus button is a plain data summary.

---

## Future

### SprigRig Portal
- [ ] Define SprigRig data model (grow environment sensors, automation events)
- [ ] Dashboard for monitoring grow environments
- [ ] Sensor data visualization
- [ ] Automation control and scheduling
- [ ] Fertigation and irrigation logging

### Platform-Wide
- [ ] Automated deployment pipeline (webhook triggers git pull on VPS)
- [ ] Add serial via Profile page (let users register additional devices)
- [ ] Multi-device management per product (user owns multiple Orpheus units)
- [ ] Mobile-responsive portal improvements
- [ ] Notification system (in-app + email) across all products

---

## Architecture Reference

### VPS: 46.224.26.91 (gaiaforge.tech)

| Service              | Port | Purpose                              |
|----------------------|------|--------------------------------------|
| nginx                | 443  | Static site + portal, API proxy      |
| HiveGuard API        | 8000 | Auth, serials, hive data, analytics  |
| Orpheus Firmware API | 8001 | Firmware upload/delete                |
| Contact form         | 5001 | /send-contact                        |

### Repos
- **GaiaForgeWeb** — Frontend (public site + React portal) → GitHub
- **Hiveguard_api** — Backend API (auth, data, analytics) → local

### Deploy
- Portal: push → clone on VPS → copy html/* to /var/www/html/
- Firmware API: copy to /opt/ → systemctl restart orpheus-firmware
- Backend API: manual deploy + migration
