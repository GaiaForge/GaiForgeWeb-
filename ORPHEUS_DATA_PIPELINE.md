# Orpheus Data Pipeline — Architecture & Implementation

## Overview

The Orpheus data pipeline moves sensor and playback data from deployed field devices to the GaiaForge cloud portal for researcher analysis.

**Flow:** `Orpheus Device → Flutter App (BLE/WiFi) → Phone → GaiaForge API → PostgreSQL → Portal Analytics`

---

## Components

### 1. Device (Raspberry Pi + ESP32)

**Repo:** `/Users/gaiaforge/Projects/Gaiaforge/Orpheus_unified/Orpheus_unified-main/`

**Data sources on device:**
- `environmental_readings` table (SQLite) — temperature, humidity, pressure every ~10 min
- `battery_log` table (SQLite) — voltage, percentage, charging state, solar power/yield
- `system_logs` table (SQLite) — WAKE, SLEEP, SHUTDOWN events
- `playback_YYYY-MM.csv` files — track name, mode, duration, volume, GPS per playback event

**WebSocket commands (Orpheus_main.py):**
| Command | Response Event | Data |
|---------|---------------|------|
| `get_environmental_history` | `environmental_history_update` | `{data: [{timestamp, temperature, humidity, pressure, is_valid}], days}` |
| `get_battery_history` | `battery_history_update` | `{history: [{timestamp, voltage, percentage, charging_state, power_output, yield_day}], days}` |
| `get_playback_history` | `playback_history_update` | `{events: [{start_time, end_time, playback_mode, track_name, category, duration_seconds, volume_percent, lat, lng, location_name}], days}` |
| `get_system_logs` | `system_logs_update` | `{logs: [{timestamp, event_type, description}]}` |

**Firmware update:** `build_release.sh` packages `.py` + icons + firmware.bin into password-protected `orpheus_update/orpheus_update.zip`. USB update via Settings tab on device.

---

### 2. Flutter App

**Repo:** `/Users/gaiaforge/Projects/Gaiaforge/Orpheus_unified/Orpheus_app-main/`

**Key files:**
| File | Purpose |
|------|---------|
| `lib/services/cloud_api.dart` | HTTP client: login, register, sync to GaiaForge API |
| `lib/services/sync_service.dart` | Orchestrates data pull from device + push to cloud |
| `lib/providers/account_provider.dart` | Auth state, token persistence via SharedPreferences |
| `lib/widgets/account_sheet.dart` | Login/register bottom sheet UI |
| `lib/screens/connect_screen.dart` | Person icon in AppBar (green = logged in) |
| `lib/widgets/side_tray_drawer.dart` | "Cloud" section: Sign In + Sync to Cloud buttons |

**Auth flow:**
1. User taps person icon on ConnectScreen → opens account sheet
2. Login with email/password or Register with email/password/name/serial
3. Token saved to SharedPreferences, restored on app startup
4. `AccountProvider.init()` validates token on launch via `GET /api/auth/me`

**Sync flow:**
1. User opens side drawer → taps "Sync to Cloud"
2. `SyncService` sends 4 WebSocket commands to device (env, battery, playback, system)
3. Waits for responses (15s timeout per command)
4. Formats data and POSTs to `POST /api/orpheus/sync`
5. Shows snackbar with result count

**Build:** `flutter run --release` for device deployment

---

### 3. GaiaForge API (Backend)

**Repo:** `/Users/gaiaforge/Projects/Gaiaforge/Gaiaforge_api/`
**VPS:** `/opt/gaiaforge-api/` on 46.224.26.91
**Service:** `systemctl restart gaiaforge-api`

**Database tables (PostgreSQL):**
| Table | Purpose |
|-------|---------|
| `orpheus_devices` | Registered devices (auto-created on first sync) |
| `orpheus_environmental_readings` | Temperature, humidity, pressure |
| `orpheus_battery_logs` | Voltage, charge, solar power/yield |
| `orpheus_playback_events` | Track, mode, duration, volume, GPS |
| `orpheus_system_events` | Wake, sleep, shutdown events |

**Sync endpoint:** `POST /api/orpheus/sync`
- Auth: Bearer token (same as portal login)
- Auto-creates `OrpheusDevice` on first sync if serial is valid + claimed by user
- Deduplicates environmental readings and battery logs by `(device_id, timestamp)`
- Playback and system events inserted as-is

**Query endpoints (for portal):**
| Endpoint | Purpose |
|----------|---------|
| `GET /api/orpheus/devices` | List user's devices |
| `GET /api/orpheus/devices/{id}/overview` | Latest readings + 30d stats |
| `GET /api/orpheus/devices/{id}/readings?days=7` | Environmental time series |
| `GET /api/orpheus/devices/{id}/battery?days=7` | Battery/solar time series |
| `GET /api/orpheus/devices/{id}/playback?days=30` | Playback events |
| `GET /api/orpheus/devices/{id}/events?days=30` | System events |

**Config:** `.env` with `GF_` prefix (e.g. `GF_DATABASE_URL`, `GF_SECRET_KEY`)

**Deploy:**
```bash
# From Mac
rsync -avz --exclude='.venv' --exclude='__pycache__' --exclude='gaiaforge.db' \
  ~/Projects/Gaiaforge/Gaiaforge_api/ root@46.224.26.91:/opt/gaiaforge-api/
# On VPS
systemctl restart gaiaforge-api
```

---

### 4. Portal (Frontend)

**Repo:** `/Users/gaiaforge/Projects/Gaiaforge/GaiaForgeWeb/`
**VPS:** `/var/www/html/portal/`

**Orpheus analytics page:** `src/pages/OrpheusAnalytics.jsx`
- 5 tabs: Overview, Environment, Battery & Solar, Playback, System Log
- Recharts for charts (area, line, bar, composed)
- Date range selector (7/14/30/90/365 days)
- CSV export on data tabs
- Device selector if user has multiple Orpheus units

**Route:** `/portal/orpheus/analytics` (linked from Orpheus sidebar)

**Deploy:**
```bash
npm run build
git push origin main
# On VPS
cd /tmp && rm -rf GaiForgeWeb- && git clone https://github.com/GaiaForge/GaiForgeWeb-.git
cp -r GaiForgeWeb-/html/portal/* /var/www/html/portal/
```

---

## Serial Registration Flow

1. Admin adds serial via Admin panel → Device Serials tab → "Add Serial"
2. User registers on portal with serial number → serial gets claimed
3. User logs into Flutter app with same account
4. First sync auto-creates `OrpheusDevice` linked to user
5. Data appears on portal analytics page

**Serial format:** `ORPB-2026-XXX` (Basic) or `ORPP-2026-XXX` (Pro)

---

## Subscription Tiers (Planned)

- **Basic (free):** Environmental charts, battery monitoring, playback history, system log, CSV export
- **Pro:** Everything in Basic + BirdNET recording analysis, AI deployment reports, correlation views, PDF export

Same pricing as HiveGuard. Gated in `OrpheusAnalytics.jsx` via `user.subscription_tier`.

---

## Deployed Devices

9 Orpheus units registered (as of 2026-04-01):
- 7 Basic units (ORPB-2026-001 through 007) — 6 at Schlammwiss Luxembourg (Natur em Emwelt), 1 with Max Steinmetz
- 2 Pro units (ORPP-2026-001, 002) — Schlammwiss Luxembourg (Natur em Emwelt)
- All PCB revision 1.6, built February 2026
