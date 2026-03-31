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

### Deploy Serial Registration
- [ ] Run device_serials migration on production database
- [ ] Deploy updated API to VPS
- [ ] Deploy updated portal to VPS
- [ ] Pre-register Orpheus device serials (7 units) via admin API
- [ ] Test full registration flow end-to-end

---

## Next Up

### Orpheus Data Pipeline
- [ ] Define Orpheus data schema (environmental readings, playback events)
- [ ] API models for Orpheus readings (temperature, humidity, battery, solar, GPS)
- [ ] API models for playback logs (track played, start/stop time, volume, schedule name)
- [ ] Sync endpoint — Flutter app pushes data over hotspot to phone, phone uploads to API when online
- [ ] Device registration via app (auto-register serial on first sync)

### Orpheus Analytics Dashboard
- [ ] Device overview — status of all registered Orpheus units, last sync time
- [ ] Environmental charts — temperature, humidity, battery voltage, solar input over time
- [ ] Playback timeline — visual timeline of what was played and when
- [ ] Correlation views — overlay environmental data with playback events
- [ ] Date range filtering and data export (CSV)

### Orpheus Researcher Journal
- [ ] Timestamped field notes tied to deployment site / device
- [ ] Categories: observation, maintenance, deployment, collection, incident
- [ ] Photo attachment support
- [ ] Environmental snapshot at time of entry (auto-fill from latest reading)
- [ ] Export journal entries

### Orpheus Reports
- [ ] Summary reports per deployment period
- [ ] AI-generated insights (like HiveGuard's AI reports)
- [ ] Exportable PDF reports for research publications

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
