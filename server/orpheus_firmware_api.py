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
    location /api/orpheus/firmware {
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

    # Sanitize filename
    safe_filename = f"Orpheus-USB-Update-v{version}.zip"
    dest = DOWNLOADS_DIR / safe_filename

    # Ensure downloads directory exists
    DOWNLOADS_DIR.mkdir(parents=True, exist_ok=True)

    # Save the file
    content = await file.read()
    dest.write_bytes(content)

    # Update manifest
    manifest = load_manifest()

    # Remove existing entry for this version if re-uploading
    manifest["releases"] = [r for r in manifest["releases"] if r["version"] != version]

    # Add new entry at the top
    manifest["releases"].insert(0, {
        "version": version,
        "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "filename": safe_filename,
        "size": f"{len(content) / 1048576:.1f} MB",
        "notes": notes,
    })

    # Sort by version descending
    manifest["releases"].sort(key=lambda r: [int(x) for x in r["version"].split(".")], reverse=True)

    save_manifest(manifest)

    return {"status": "ok", "filename": safe_filename, "version": version}


@app.delete("/api/orpheus/firmware/{filename}")
async def delete_firmware(request: Request, filename: str):
    await verify_admin(request)

    # Sanitize — only allow expected filenames
    if not filename.startswith("Orpheus-") or not filename.endswith(".zip"):
        raise HTTPException(status_code=400, detail="Invalid filename")

    filepath = DOWNLOADS_DIR / filename
    if filepath.exists():
        filepath.unlink()

    # Remove from manifest
    manifest = load_manifest()
    manifest["releases"] = [r for r in manifest["releases"] if r["filename"] != filename]
    save_manifest(manifest)

    return {"status": "ok", "deleted": filename}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8001)
