"""Read-only checks; never print secrets, API messages, or personal account data."""
import json, os, urllib.request, urllib.error
key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
if not key:
    raise SystemExit("Secret missing or empty")
known = {"invalid_api_key", "missing_api_key", "missing_permissions", "authentication_error", "authorization_error", "quota_exceeded", "insufficient_credits", "model_access_denied", "feature_not_available", "unusual_activity", "detected_unusual_activity", "unauthorized", "forbidden", "ip_not_allowed", "api_key_expired", "invalid_request", "invalid_token", "expired_api_key", "permission_denied", "rate_limit_exceeded"}
for endpoint in ("models", "user"):
    try:
        req = urllib.request.Request("https://api.elevenlabs.io/v1/" + endpoint, headers={"xi-api-key":key,"Accept":"application/json"}, method="GET")
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.load(response)
        print(endpoint + ": HTTP 200")
        if endpoint == "models" and isinstance(data, list):
            print("Eleven v4 TTS advertised: " + str(any(m.get("model_id") == "eleven_v4" and m.get("can_do_text_to_speech") for m in data if isinstance(m,dict))))
    except urllib.error.HTTPError as e:
        status = "unrecognized_error"
        try:
            d = json.loads(e.read(65536))
            detail = d.get("detail", {})
            if isinstance(detail, dict):
                for candidate in (detail.get("status"), detail.get("code"), detail.get("type")):
                    if isinstance(candidate,str) and candidate in known:
                        status = candidate
                        break
        except (ValueError, TypeError, AttributeError):
            pass
        print(f"{endpoint}: HTTP {e.code}; reason={status}")
    except (urllib.error.URLError, TimeoutError):
        print(endpoint + ": network error")
print("Read-only diagnostics finished. No TTS POST requests made.")
