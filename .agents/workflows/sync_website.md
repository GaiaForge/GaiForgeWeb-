---
description: how to sync and deploy the GaiaForge website to the VPS
---

// turbo-all

## Sync GaiaForge Website to VPS

Push local changes to GitHub. The VPS webhook auto-deploys the site.

### 1. Stage all changes
```bash
git -C /Users/gaiaforge/Projects/Gaiaforge/GaiaForgeWeb add -A
```

### 2. Commit
```bash
git -C /Users/gaiaforge/Projects/Gaiaforge/GaiaForgeWeb commit -m "Update website"
```

### 3. Push (triggers webhook on VPS)
```bash
git -C /Users/gaiaforge/Projects/Gaiaforge/GaiaForgeWeb push origin main
```

**Pipeline:** GitHub → `http://46.224.26.91:9000/hooks/deploy` → `/var/www/deploy.sh` (fresh clone → copy to `/var/www/html`)

**To check webhook logs on VPS:**
```bash
ssh root@46.224.26.91 'journalctl -u webhook -n 20'
```
