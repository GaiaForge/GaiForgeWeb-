"""
Orpheus Firmware Upload API

A lightweight FastAPI service that handles firmware upload/delete for the
Orpheus portal. Saves files to the static downloads directory and maintains
a manifest.json that the frontend reads.

Setup on VPS:
    pip install fastapi uvicorn python-multipart
    python3 orpheus_firmware_api.py

Or run with uvicorn directly:
    uvicorn orpheus_firmware_api:app --host 127.0.0.1 --port 8001

Then add to your nginx config (inside the server block):
    location /api/orpheus {
        proxy_pass http://127.0.0.1:8001;
        client_max_body_size 200M;
    }
"""

import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import JSONResponse

app = FastAPI()

# --- Configuration ---
# Adjust this path to match your VPS web root
DOWNLOADS_DIR = Path(os.environ.get("ORPHEUS_DOWNLOADS_DIR", "/var/www/html/downloads/orpheus"))
MANIFEST_PATH = DOWNLOADS_DIR / "manifest.json"

APP_DIR = DOWNLOADS_DIR / "app"
APP_MANIFEST_PATH = APP_DIR / "manifest.json"

DOCS_DIR = DOWNLOADS_DIR / "docs"
DOCS_MANIFEST_PATH = DOCS_DIR / "manifest.json"
DOC_SLOTS = {"manual", "quickstart", "solar_guide"}

# Your existing auth API base URL (to validate tokens)
AUTH_API_BASE = os.environ.get("AUTH_API_BASE", "http://127.0.0.1:8000")


async def verify_admin(request: Request):
    """Validate the Bearer token against the existing auth API and check admin status."""
    import httpx

    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid token")

    try:
        async with httpx.AsyncClient() as client:
            res = await client.get(
                f"{AUTH_API_BASE}/api/auth/me",
                headers={"Authorization": auth_header},
            )
            if res.status_code != 200:
                raise HTTPException(status_code=401, detail="Invalid token")
            profile = res.json()
            if not profile.get("is_admin"):
                raise HTTPException(status_code=403, detail="Admin access required")
    except httpx.RequestError:
        raise HTTPException(status_code=502, detail="Could not reach auth service")


def load_manifest():
    """Load the firmware manifest, or return empty structure."""
    if MANIFEST_PATH.exists():
        try:
            return json.loads(MANIFEST_PATH.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {"releases": []}


def save_manifest(data):
    """Write the manifest atomically."""
    tmp = MANIFEST_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2))
    tmp.replace(MANIFEST_PATH)


@app.post("/api/orpheus/firmware/upload")
async def upload_firmware(
    request: Request,
    file: UploadFile = File(...),
    version: str = Form(...),
    notes: str = Form(""),
):
    await verify_admin(request)

    if not file.filename.endswith(".zip"):
        raise HTTPException(status_code=400, detail="Only .zip files are accepted")

    # The device expects the file at: orpheus_update/orpheus_update.zip
    update_dir = DOWNLOADS_DIR / "orpheus_update"
    update_dir.mkdir(parents=True, exist_ok=True)
    dest = update_dir / "orpheus_update.zip"

    # Archive the previous version if it exists
    if dest.exists():
        manifest = load_manifest()
        old_releases = manifest.get("releases", [])
        if old_releases:
            old_version = old_releases[0].get("version", "unknown")
            archive_name = f"orpheus_update_v{old_version}.zip"
            archive_dir = DOWNLOADS_DIR / "archive"
            archive_dir.mkdir(parents=True, exist_ok=True)
            dest.rename(archive_dir / archive_name)

    # Save the new file
    content = await file.read()
    dest.write_bytes(content)

    # Update manifest — only keep the current release
    manifest = load_manifest()
    manifest["releases"] = [{
        "version": version,
        "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "filename": "orpheus_update/orpheus_update.zip",
        "size": f"{len(content) / 1048576:.1f} MB",
        "notes": notes,
    }]

    save_manifest(manifest)

    return {"status": "ok", "filename": "orpheus_update.zip", "version": version}


@app.delete("/api/orpheus/firmware/{filename}")
async def delete_firmware(request: Request, filename: str):
    await verify_admin(request)

    # Only the current update file can be deleted
    update_file = DOWNLOADS_DIR / "orpheus_update" / "orpheus_update.zip"
    if update_file.exists():
        update_file.unlink()

    # Clear manifest
    save_manifest({"releases": []})

    return {"status": "ok", "deleted": "orpheus_update.zip"}


def load_app_manifest():
    """Load the mobile app manifest, or return empty structure."""
    if APP_MANIFEST_PATH.exists():
        try:
            return json.loads(APP_MANIFEST_PATH.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {"releases": []}


def save_app_manifest(data):
    tmp = APP_MANIFEST_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2))
    tmp.replace(APP_MANIFEST_PATH)


@app.post("/api/orpheus/app/upload")
async def upload_app(
    request: Request,
    file: UploadFile = File(...),
    version: str = Form(...),
    notes: str = Form(""),
):
    await verify_admin(request)

    if not file.filename.endswith(".apk"):
        raise HTTPException(status_code=400, detail="Only .apk files are accepted")

    APP_DIR.mkdir(parents=True, exist_ok=True)
    dest = APP_DIR / "orpheus.apk"

    # Archive the previous version if it exists
    if dest.exists():
        manifest = load_app_manifest()
        old_releases = manifest.get("releases", [])
        if old_releases:
            old_version = old_releases[0].get("version", "unknown")
            archive_dir = APP_DIR / "archive"
            archive_dir.mkdir(parents=True, exist_ok=True)
            dest.rename(archive_dir / f"orpheus_v{old_version}.apk")

    content = await file.read()
    dest.write_bytes(content)

    manifest = load_app_manifest()
    manifest["releases"] = [{
        "version": version,
        "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "filename": "app/orpheus.apk",
        "size": f"{len(content) / 1048576:.1f} MB",
        "notes": notes,
    }]

    save_app_manifest(manifest)

    return {"status": "ok", "filename": "orpheus.apk", "version": version}


@app.delete("/api/orpheus/app/{filename}")
async def delete_app(request: Request, filename: str):
    await verify_admin(request)

    update_file = APP_DIR / "orpheus.apk"
    if update_file.exists():
        update_file.unlink()

    save_app_manifest({"releases": []})

    return {"status": "ok", "deleted": "orpheus.apk"}


def load_docs_manifest():
    """Load the documentation manifest, or return empty structure."""
    if DOCS_MANIFEST_PATH.exists():
        try:
            return json.loads(DOCS_MANIFEST_PATH.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def save_docs_manifest(data):
    tmp = DOCS_MANIFEST_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2))
    tmp.replace(DOCS_MANIFEST_PATH)


@app.post("/api/orpheus/docs/upload")
async def upload_doc(
    request: Request,
    file: UploadFile = File(...),
    slot: str = Form(...),
):
    await verify_admin(request)

    if slot not in DOC_SLOTS:
        raise HTTPException(status_code=400, detail="Unknown document slot")

    ext = Path(file.filename).suffix.lower()
    if ext not in (".pdf", ".html"):
        raise HTTPException(status_code=400, detail="Only .pdf or .html files are accepted")

    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    dest = DOCS_DIR / f"{slot}{ext}"

    content = await file.read()
    dest.write_bytes(content)

    manifest = load_docs_manifest()
    manifest[slot] = {
        "filename": f"docs/{slot}{ext}",
        "original_name": file.filename,
        "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "size": f"{len(content) / 1048576:.1f} MB",
    }
    save_docs_manifest(manifest)

    return {"status": "ok", "slot": slot, "filename": manifest[slot]["filename"]}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8001)
