# Crisp Companion 🍳

A **native iPhone 16-compatible SwiftUI companion** for the COSORI Dual Blaze air fryer. This project is **independent and unofficial**, not affiliated with COSORI or VeSync.

**Project state:** Build 1 development branch. Source and roadmap are present; physical fryer pairing, CI build outcome, and real-device status have **not yet been verified**. The app must clearly say PREVIEW until a real secure bridge actually returns device state. No fake cooking data, no paid features, no App Store dependency for local sideloading.

## Where it lives

- Folder: `CrispCompanion/` in `ValentineBSAA/IPhone-Apps`. Other iPhone projects remain untouched.
- Target iPhone: iOS 16+; SwiftUI; working identifier `com.valentinebsaa.crispcompanion` (do not change once installed without migration).
- Build system: XcodeGen, GitHub Actions on macOS, **unsigned IPA** artifact to sign through owner's existing AltStore setup if and only if CI succeeds.
- Device candidate: **CAF-P583S-KUS**, COSORI Dual Blaze 6.8 qt. The exact sticker/model and firmware **must be confirmed** on real hardware before live-control testing.
- VeSync Account: initially unavailable until official app pairing can be achieved. This is a genuine blocker, not a cosmetic detail.

## Build 1 screens

| Screen | Actually implemented in source | Notes |
| --- | --- | --- |
| Kitchen | Premium dark enamel UI, clear connection banner, status ring, manual planning sliders/presets | No false live readings; hardware actions never sent |
| Recipes | Custom recipe entry, on-device save/delete, favorites from Kitchen | Local data is unencrypted UserDefaults; don't store sensitive notes |
| Timer | Independent countdown with optional local notification | **Not tied to cooking status** |
| Settings | Preview toggle, HTTPS-only private NAS endpoint, Keychain bridge token, manual refresh | Requires a paired VeSync account, configured NAS service and TLS |
| Bridge | Bearer-token read-only `GET /v1/status` using pyvesync's COSORI support | Experimental, no pairing, no device mutation |

The first screen uses labeled cards, vibrant amber/peach highlights, large controls, subtle glass layers, two-column recipe layout where helpful, dark-mode legibility, navigation tabs, and SF Symbols. UI is functional without external services.

### Explicit exclusions

- **No remote cooking start**, no bypass of a manufacturer's heater-start restriction, no unsafe auto-start or activation while unattended.
- No claim that the official VeSync onboarding or catalog is implemented.
- No counterfeit COSORI logos, bundled Apple IPAs, extracted copyrighted recipe library, or third-party credentials.
- No background polling or invented heat-sensor/cooldown readings. Refreshed manually in Build 1.
- Do not ship a live-build designation before both real pairing and CI/device verification.

## Get a development build

GitHub Actions: `.github/workflows/crisp-companion-build.yml`. Workflow builds simulator and physical iOS binaries, runs the model tests, packages a standard `Payload/CrispCompanion.app` unsigned IPA and uploads it as an artifact if everything succeeds. An unsigned IPA still needs compatible signing before installation.

## Optional read-only private bridge

The app can talk to a small Python service on a machine **you control**, such as a supported Python environment on your Synology NAS or another trusted host.

```bash
cd CrispCompanion/bridge
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
export VESYNC_USERNAME="your-own-vesync-account"
export VESYNC_PASSWORD="your-own-password"
export CRISP_BRIDGE_TOKEN="at-least-24-random-characters"
export CRISP_DEVICE_FILTER="CAF-P583S"
uvicorn server:app --host 127.0.0.1 --port 8765
```

**Important:** Do not put these credentials in GitHub, chat logs or app source. Use environment variables protected by the host. The app accepts **HTTPS only**, so put the bridge behind a *private authenticated TLS reverse proxy* or correctly configured HTTPS Tailscale service and restrict access. Never expose the Python service directly to the public Internet. On the DS418, Python availability and reverse proxy permissions must be checked before deployment. This setup **does not pair the fryer** and is useless for real status until the device has been provisioned in VeSync.

Install dependency source is pinned to community-supported revision `RedsGT/pyvesync@77db69d...`. Reevaluate for a stable upstream release, test actual device field units and account auth, and verify library license notices before distributing.

### JSON read-only contract

```json
{
  "connected": false,
  "cooking": false,
  "temperature_f": null,
  "minutes_remaining": null,
  "preset": null,
  "message": "No paired matching fryer on VeSync account",
  "updated_at": "2026-11-22T00:00:00Z"
}
```

Fields with uncertain sensor values **must remain null**. This service is intentionally read-only even if the upstream library supports commands. No local heater-start capability.

## Source references

- [webdjoe/pyvesync](https://github.com/webdjoe/pyvesync) and [supported device list](https://webdjoe.github.io/pyvesync/latest/supported_devices/)
- [RedsGT/hass-vesync-enhanced](https://github.com/RedsGT/hass-vesync-enhanced): community CAF-P583S-KUS test and model support
- [RedsGT/pyvesync wfon-caf-p583s](https://github.com/RedsGT/pyvesync/tree/wfon-caf-p583s)
- [COSORI CAF-P583S manual](https://www.manualslib.com/manual/2918829/Cosori-Dual-Blaze-Caf-P583s.html)

The manufacturer manual states cooking cannot be started remotely; third-party code demonstrations are **not permission** to add that feature here.

Continue from [ROADMAP.md](ROADMAP.md), [BUILD_1_QA.md](BUILD_1_QA.md), and [the active handoff](../PROJECT_HANDOFFS/CRISP_COMPANION_ACTIVE.md).

## iPhone-only pairing research
The owner cannot use Android, the App Store or a second Apple Account. [PAIRING_RESEARCH.md](PAIRING_RESEARCH.md) tracks a carefully scoped discovery-first native pairing investigation. The next diagnostic build adds **Settings → Find my fryer**, a permission-gated BLE scan only. This does not pair the device, send Wi-Fi passwords or access VeSync's cloud.

## Build 1.2: Local Bluetooth Event Observatory
Optional idle-only, explicitly started and automatically time-limited diagnostic in **Settings > BLE Event Observatory**. Designed to help determine whether the real fryer emits metadata when you change physical presets. The app does not record payload bytes, send heater commands, provision Wi-Fi or register a VeSync account. Bluetooth notification subscriptions alter the CCCD descriptor; this is explained in-app. The local recipe planner now uses **12 documented factory presets** (not measured real-device settings). See [BUILD_1_2_QA.md](BUILD_1_2_QA.md).

## Build 1.3: packet-comparison experiment
Settings > Packet Comparison now contrasts an untouched 45-second idle baseline against a separate 45-second physical-adjustment run. HMAC-SHA256 fingerprints are keyed with a new random secret for the in-memory experiment and are cleared on leaving the screen; no raw BLE messages are saved or exported. The result is statistical only: a changed message does **not** mean we've decoded a preset, temperature, or controller protocol. No cooking commands, firmware activity, or cloud required. See [BUILD_1_3_QA.md](BUILD_1_3_QA.md).

## Build 1.4: Guided preset mapping
Settings > Preset Mapping provides two physical rounds of all twelve fryer presets while idle. Each button press is prompted by a five-second listening window, with ten seconds of untouched initial baseline. Session-only keyed HMAC signatures allow comparing repeated patterns without saving BLE payloads or IDs. No commands, OAD or cloud required; CCCD notification subscription is a Bluetooth descriptor configuration write. No cooking status or control has been decoded. See [BUILD_1_4_QA.md](BUILD_1_4_QA.md).
