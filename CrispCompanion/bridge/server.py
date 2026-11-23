"""Opt-in read-only VeSync bridge. No pairing, start, or heating command routes."""
import os
import secrets
from datetime import datetime, timezone
from fastapi import FastAPI, Header, HTTPException
from pyvesync import VeSync

app = FastAPI(title="Crisp Companion read-only bridge", docs_url=None, redoc_url=None, openapi_url=None)

def normalize_status(device):
    state = device.state
    # pyvesync's FryerState times are seconds, not minutes.
    remaining = getattr(state, "cook_last_time", None)
    if remaining is not None:
        remaining = max(0, (int(remaining) + 59) // 60)
    cook_status = getattr(state, "cook_status", None)
    online = str(getattr(state, "connection_status", "")).lower()
    # Unknown connection states must NOT be called online.
    connected = "online" in online or "connected" in online
    running = bool(getattr(state, "is_cooking", False)) and connected
    return {
        "connected": connected,
        "cooking": running,
        "temperature_f": getattr(state, "cook_set_temp", None) if running else None,
        "minutes_remaining": remaining if running else None,
        "preset": str(getattr(state, "cook_mode", "")) or None if running else None,
        "message": str(getattr(cook_status, "value", cook_status)) if connected else "Fryer not connected",
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }

@app.get("/v1/status")
async def read_status(authorization: str | None = Header(default=None)):
    expected = os.getenv("CRISP_BRIDGE_TOKEN", "")
    if len(expected) < 24:
        raise HTTPException(status_code=503, detail="Bridge access token not configured")
    provided = (authorization or "").removeprefix("Bearer ")
    if not secrets.compare_digest(provided, expected):
        raise HTTPException(status_code=401, detail="Unauthorized")
    username = os.getenv("VESYNC_USERNAME", "")
    password = os.getenv("VESYNC_PASSWORD", "")
    if not username or not password:
        return {
            "connected": False, "cooking": False, "temperature_f": None,
            "minutes_remaining": None, "preset": None,
            "message": "VeSync account not configured on the NAS", "updated_at": datetime.now(timezone.utc).isoformat()
        }
    try:
        async with VeSync(username, password, country_code="US", redact=True) as manager:
            await manager.login()
            await manager.get_devices()
            await manager.update()
            fryers = list(manager.devices.air_fryers)
            desired = os.getenv("CRISP_DEVICE_FILTER", "CAF-P583S").upper()
            match = next((item for item in fryers if desired in
                          (str(getattr(item, "config_module", "")) + " " +
                           str(getattr(item, "device_type", ""))).upper()), None)
            if match is None:
                return {
                    "connected": False, "cooking": False, "temperature_f": None,
                    "minutes_remaining": None, "preset": None,
                    "message": "No paired matching fryer on VeSync account",
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
            return normalize_status(match)
    except Exception:
        # Do not send credentials, device IDs, internal URLs, or exception details to clients.
        raise HTTPException(status_code=503, detail="VeSync device service unavailable")
