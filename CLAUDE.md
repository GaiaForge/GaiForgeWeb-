# GaiaForgeWeb

Static marketing site + React customer portal for GaiaForge (gaiaforge.tech) —
IoT devices for wildlife monitoring and agriculture: Orpheus (bird audio),
HiveGuard (beehives), SprigRig (growing). Founder/solo dev: Travis.

## Repo layout

- `html/` — the static site as deployed (plain HTML/CSS/JS)
- `src/` — React portal source (Vite, base path `/portal/`)
- `html/portal/` — portal build output (`npm run build`). **The committed build
  is the deployed artifact** — after building, commit `html/portal/` and push,
  or the next push will revert the live portal to the stale committed build.
- Sibling repo `../Gaiaforge_api/` — FastAPI backend (auth, serials, product
  data). Schema is managed there via Alembic; never ALTER tables by hand.

## Production (VPS 46.224.26.91, gaiaforge.tech)

- nginx serves `/var/www/html/` and proxies `/api/*` → GaiaForge API (port 8000),
  `/api/orpheus/{firmware,app,docs}/*` plus `/api/hiveguard/docs` and
  `/api/sprigrig/docs` → firmware/app/docs upload API (8001, systemd
  unit `orpheus-firmware.service`), `/send-contact` → mailer (5001). Everything
  else under `/api/orpheus/*` (devices, journal, recordings, sync, reports) is
  handled by the main API on 8000 — only firmware/app/docs uploads live on 8001.
  nginx routing lives in `/etc/nginx/snippets/gaiaforge-api.conf` on the VPS —
  **not tracked in this repo.**
- **Routes to 8001 are enumerated one prefix at a time.** There is no wildcard —
  each path is its own `location` block. A new route added to
  `server/orpheus_firmware_api.py` under a path nginx doesn't already list falls
  through to the generic `location /api/` and hits the main API on 8000, which
  404s. Adding a fourth product (or any new 8001 route) means editing the nginx
  snippet too, not just deploying the Python file. Confirmed 2026-08-14: the
  per-product doc library shipped with `/api/{hiveguard,sprigrig}/docs`
  unrouted; Orpheus worked, the other two 404'd until the blocks were added.
- PostgreSQL database `gaiaforge` (see `/db` skill before touching it)
- Nightly DB/config backup 03:30 → `/var/backups/gaiaforge/`, 7-day retention,
  on-VPS only

## Deploys (consolidated 2026-07-16)

**Every push to main auto-deploys BOTH the static site and the portal.**
GitHub webhook → `/gh-deploy` (HMAC-verified) → adnanh `webhook` service →
`/var/www/deploy.sh`: clones main, rsyncs `html/` including the committed
`html/portal/` build, backs up the portal first, prunes to 3 backups.

- Site change: commit, push — live in seconds.
- Portal change: `npm run build`, commit `html/portal/`, push. An rsync-only
  portal deploy is reverted by the next push — always commit the build.
- Manual fallback: `ssh root@46.224.26.91 "bash /var/www/deploy.sh"`.
- The old `gaiaforge-deploy` service (`/deploy-hook`, unauthenticated, created
  by a past Claude session) was retired 2026-07-16 — service, nginx route, and
  script all removed.

**`server/orpheus_firmware_api.py` is NOT covered by the above pipeline.** It's
the source for the firmware/app/docs upload service (port 8001, systemd unit
`orpheus-firmware.service`), but `deploy.sh` only ever rsyncs `html/` — pushing
to main does nothing to this file. To ship a change to it: `scp` it to
`/opt/orpheus_firmware_api.py` on the VPS (back up the existing file first),
then `systemctl restart orpheus-firmware`. Confirmed 2026-08-13: this file had
drifted — `app/upload` and `docs/upload` routes existed in the repo but were
never deployed, so the admin app-upload feature 404'd in production despite
looking correct in the codebase. Check `diff <(ssh root@46.224.26.91 cat
/opt/orpheus_firmware_api.py) server/orpheus_firmware_api.py` if this service
misbehaves — the deployed copy may be stale.

## Per-product document library

Each product has a manifest at
`/var/www/html/downloads/<product>/docs/manifest.json` (`documents[]` list).
The portal **reads it as a static file** via nginx — reads never touch the API.
The 8001 service only handles writes (admin add/delete) and seeds a missing
manifest on startup.

- **The manifests are runtime state, not repo state.** They live under
  `/var/www/html/downloads/` and are deliberately gitignored. They survive
  deploys only because `deploy.sh` rsyncs the site **without** `--delete`
  (the `--delete` there applies to `html/portal/` only). If anyone ever adds
  `--delete` to the site rsync, or commits a `manifest.json`, every
  admin-uploaded document is wiped on the next push.
- Startup seeding only writes a manifest that is **missing**, so it never
  clobbers admin edits — but it also never repairs a corrupt one.
- **Latent collision:** the legacy slot-based `POST /api/orpheus/docs/upload`
  writes a *different* format (`{slot: {...}}`) to the *same* orpheus manifest
  path. Nothing in the frontend calls it as of 2026-08-14, but if it is ever
  used it will overwrite the `documents[]` list, and the Orpheus doc cards will
  silently fall back to built-in defaults. Remove that endpoint when convenient.

## Conventions & standing decisions

- Portal login flow: product selector after login routes to Orpheus / HiveGuard /
  SprigRig dashboards.
- No Cloudflare/CDN (deliberate): Hetzner DDoS protection + nginx rate limits.
- API config env vars use the `GF_` prefix.
- Travis is not a professional developer — explain non-obvious commands and SQL
  in plain language, and prefer showing what a change will do before doing it.
- "Request a Quote" is intentionally hidden site-wide for now.
