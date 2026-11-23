# Crisp Companion D2: CAF-P583S-KUS native provisioning research
Updated: 2026-11-22. This is a **research handoff**, NOT a verified Wi-Fi pairing implementation.
Working scope: use existing iPhone, Windows and optional Synology NAS. **Do not suggest Android, another Apple Account, App Store downloads, or untrusted IPA sites.**

## Evidence already confirmed on real owner hardware
1. Crisp Companion v0.1.0 performed user-initiated iPhone BLE scan; named advertisement `CAF-P583S-KUS`, -57 dBm, among 20 nearby devices. Strong model-name evidence, not authenticated identity.
2. Crisp Companion v0.1.1 made a temporary GATT connection and discovered **three services / six characteristics** without characteristic reads/writes:
   - `FFF0`: `FFF1` Notify, `FFF2` Write/Write without response
   - `F000FFC0-0451-4000-B000-000000000000`: `F000FFC1`, `F000FFC2` Write/Write without response/Notify
   - `F000FFE0-0451-4000-B000-000000000000`: `F000FFE2` Notify, `F000FFE1` Write/Write without response
3. Device has **never been registered/paird in VeSync**. The NAS pyvesync read-only cloud bridge is therefore blocked until legitimate provisioning and VeSync account association are solved.

## Independently verified sources and implications

### COSORI's *exact model* user manual (strong, direct)
[CAF-P583S-KUS manual, original PDF](https://device.report/m/f43caea918e51f0deb4ecd8f2645272b993bf091f3c24d823ac70f288a22a771.pdf), **print page 10 / PDF zero-index page 9**:
- The **On/Off power button** at the far **left** of the control panel is the control pictured with the instruction: **press and hold for 5 seconds to configure the air fryer**.
- The **Wi-Fi indicator** is the Wi-Fi symbol beside the central cooking status/time display, not the power button.
- The same model's setup instructions (print page 8 / PDF page 7) require VeSync's app and VeSync account; no standalone protocol / app-independent pairing steps are supplied.
- **Press-and-hold for 15 seconds resets/disconnects Wi-Fi**, distinct from five-second setup. Do NOT hold for 15 seconds during our test.

### BLE service ownership (reliable but NOT device protocol)
Texas Instruments' [OAD source code](https://git.ti.com/cgit/ble-oad-android-source-code/ble-oad-android-source-code/commit/app) explicitly identifies `F000FFC0` as firmware **Over-the-Air Download** service, `FFC1` image notify, `FFC2` image block. Firmware controls are excluded from *all* experiments. A common `FFF0/FFF1/FFF2` UART-style layout also appears in an [unrelated COSORI kettle reverse-engineering project](https://github.com/barrymichels/CosoriKettleBLE), but that kettle is a DIFFERENT appliance and its handshake/payloads **must never be reused on this air fryer** without hardware-specific proof. `F000FFE0` and `FFF0` may use device-specific framing; UUIDs alone cannot tell us the authentication, Wi-Fi setup, or VeSync registration commands.

### VeSync cloud status != onboarding
The model's [pyvesync #477](https://github.com/webdjoe/pyvesync/issues/477) reports `connectionType: WiFi+BTOnboarding+BTNotify` for an already-provisioned CAF-P583S-KUS, and later captures `getAirfryerStatus` and other post-pairing cloud calls. That is evidence for BLE involvement in setup, **not a documented BLE credential exchange or cloud claim workflow**.
[pyvesync documentation](https://webdjoe.github.io/pyvesync/latest/) explicitly says it controls VeSync devices **after they are set up** and has no local connection.

### iOS capabilities and constraints
[Apple TN3111](https://developer.apple.com/documentation/technotes/tn3111-ios-wifi-api-overview.md): iOS does not permit a general-purpose third-party app to scan all nearby Wi-Fi SSIDs. We can compare manually using **Settings > Wi-Fi**. Once a legitimate, identifiable device hotspot and its provisioning protocol are known, a user-consented `NEHotspotConfigurationManager` flow may be possible, but it is not implemented now. BLE/CoreBluetooth alone cannot magically register a VeSync cloud device.

## D2 next safe physical experiment (NO new IPA required)

**Purpose:** determine what enabling the manufacturer's *documented* five-second configuration mode changes. No secret exchange or heater actuation.

1. With fryer plugged in and **not cooking**, stand near it with iPhone. Open iPhone **Settings > Wi-Fi**, note only whether a network with an obvious **COSORI / VeSync / Smart*** device prefix is visible. Do NOT join unknown networks. The actual home SSID/password must not be shared.
2. Open installed **Crisp Companion > Settings > Find my fryer**. Note if `CAF-P583S-KUS` still appears in scan. This is a baseline, not a pairing check.
3. At the **physical air fryer**, press and hold the **leftmost On/Off power icon** for **5 seconds, then release**. **Do not hold 15 seconds**, do not cook during test. Observe the little Wi-Fi indicator (on/off/blinking, approximate blink style). If the appliance behaves unexpectedly, stop.
4. Return to iPhone **Settings > Wi-Fi**. Look for a *new* device-looking Wi-Fi network compared with baseline. Record only its **generic prefix**, not your home network name. Do not join or enter any password.
5. In Crisp Companion, tap **Scan again**. Note if the `CAF-P583S-KUS` advertisement is still visible, whether name/signal changed, and whether the scan can still find it. **Do not inspect/write firmware characteristics**.
6. Report three non-sensitive observations: (a) Wi-Fi indicator after the five-second press, (b) whether a new network appeared (prefix only), (c) whether the BLE name was still visible. If a new hotspot appears, the next step is researching its actual provisioning endpoint before connecting; if none appears, BLE-only onboarding remains a hypothesis. **Neither result establishes VeSync registration.**

## Research matrix / gatekeeping

| Hypothesis | Evidence | What would confirm | Present status |
| --- | --- | --- | --- |
| The fryer uses Bluetooth for onboarding | VeSync model metadata `WiFi+BTOnboarding+BTNotify`, actual live BLE service discovery | Passive difference on entering setup and documented handshake | **Supported, protocol unverified** |
| It exposes its own Wi-Fi AP in pairing mode | Only generic VeSync appliance manuals, NOT direct model protocol | New SSID appears after five-second power press | **Unverified** |
| `FFF0` is provisioning transport | Has notify + write layout; unrelated COSORI kettle uses same UUIDs | Credible exact-model packet specification or trace | **Unverified; no writes** |
| `F000FFE0` is provisioning transport | Has notify/write properties, TI family UUID | Exact-model protocol/firmware documentation | **Unverified; no writes** |
| `F000FFC0` is the pairing service | Matches TI OAD/firmware-update UUID | None, ruled out for routine onboarding | **Do not use** |
| Already-paired cloud APIs complete initial setup | pyvesync post-setup functionality | Confirmed compatible cloud device-claim mechanism | **No, not sufficient** |

## What to build only after test evidence
- If SoftAP is actually observed: investigate on-device connection approach with user consent, and the requirement for VeSync account registration. No automated hotspot join without an identified network and protocol.
- If BLE-only mode: study exact-model protocol references/traces or vendor documentation. Potential future *explicit opt-in* notification-only diagnostic would require CCCD subscription, which **technically writes descriptor configuration**, and must be documented accurately; don't call it zero-write. Do not issue command characteristic writes.
- Show clear live/preview state, preserve existing app bundle identifier and user data, and require physical device tests before progressing to control.

## Safety and release stop conditions
Never auto-start cooking, alter firmware, supply speculative FFF0/FFE0 payloads, fake pairing success, leak SSIDs/passwords/tokens, or share device UUIDs/MACs publicly. **No new IPA for this D2 experiment**: iPhone Settings and installed v0.1.1 provide everything needed. The actual native first-time pairing protocol and cloud claim remain major unsolved blockers.

## D2 test outcome and D3 follow-up (2026-11-22)
User subsequently completed all observational comparison steps: blinking Wi-Fi indicator after 5-second hold, no clearly branded new SSID visible in an iPhone Wi-Fi scan, same BLE name (RSSI varied -57 to -50 dBm), same three GATT services/six characteristic metadata in configuration mode. D2 physical comparison **PASS** but pairing **NOT SOLVED**. The earlier step list above is historical, not a task to repeat. Continue with [D3 protocol research](../CrispCompanion/PROVISIONING_PROTOCOL_RESEARCH.md).
