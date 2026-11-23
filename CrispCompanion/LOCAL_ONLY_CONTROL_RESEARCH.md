# Crisp Companion — D4 local-only control feasibility and research plan

Date: 2026-11-22. Scope: **COSORI Dual Blaze CAF-P583S-KUS**. Owner wants a native iPhone companion with REAL controls and cooking status but **no VeSync cloud dependency**.

**Important state:** User successfully installed iOS app v0.1.1. BLE advertisement detection, CoreBluetooth GATT connection and UUID discovery, and 5-second Wi-Fi setup-mode comparison are **owner-observed passes**. No Bluetooth payload has been decoded, no device control/status has been received, no Wi-Fi onboarding has succeeded, and no VeSync cloud registration exists. The current UI 'recipe planner' only edits local notes. Never describe it as a functioning remote controller.

## 1. High-value finding: original FCC board has ESP32 Wi-Fi + Bluetooth module

The US model's [FCC filing 2ARBY-CAF-P583S](https://fccid.io/2ARBY-CAF-P583S) has:
- an original equipment grant dated **2021-11-15**;
- a Class II permissive change filing **2023-08-23**;
- original [2021 internal photo PDF](https://fccid.io/2ARBY-CAF-P583S/Internal-Photos/Internal-Photos-5537891.pdf), **PDF pages 7 and 8 zero-index**. Actual photos show the wireless PCB module labeled **ESP32-WROOM-32U**, with an external antenna connection and a printed module underside. This is *independently physically visible*, not a conjecture.
- User's exact board revision / module *still unknown*. The 2023 changed board photographs were indexed but NOT visually confirmed in this study. We cannot assert owner's unit uses the exact 2021 board.

**Implication:** ESP32 silicon is technically capable of local Bluetooth or Wi-Fi communication. But factory firmware decides which commands it supports. An ESP32 board does NOT imply a TCP/UDP local API, unrestricted BLE control, use of Espressif BluFi, or support for custom firmware without disassembly. No reason to open the appliance.

## 2. Actual GATT observations vs standard protocols

Owner's real iPhone observed, both before and during Wi-Fi indicator flashing:
- `FFF0`: `FFF1` notify, `FFF2` write / write-no-response
- `F000FFC0-0451-4000-B000-000000000000`: `F000FFC1`, `F000FFC2` write/notify (**Texas Instruments OAD firmware update; no touch**).
- `F000FFE0-0451-4000-B000-000000000000`: `F000FFE2` notify, `F000FFE1` write.

These UUIDs persisted unchanged in the blink/configuration state. Hardware accepted a temporary connection and metadata discovery only. **No GATT notifications from real cooking have been observed.**

[Espressif's own BluFi Wi-Fi provisioning documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/ble/blufi.html) specifies service `FFFF` and characteristics `FF01` and `FF02`. **Those standard BluFi identifiers are absent from this fryer's enumerated GATT table**, so an off-the-shelf BluFi iPhone library is not supported by current evidence. It could use a different vendor-specific BLE protocol instead.

The `FFF0` notify/write and `F000FFE0` notify/write structures *suggest serial-style message channels*. Neither set of UUIDs tells us whether it accepts operational cooking commands, only onboarding traffic, or both. Evidence from unrelated kettle and BLE UART devices must **not** be used to select commands.

## 3. Existing local-control evidence from other sources

- [Official pyvesync documentation](https://webdjoe.github.io/pyvesync/): explicitly cloud API, requires internet for library and fryer, and says **no current local-control method**.
- [Home Assistant COSORI](https://www.home-assistant.io/integrations/cosori) and [VeSync](https://www.home-assistant.io/integrations/vesync): cloud polling and **requires device first registered in VeSync app**.
- [webdjoe/pyvesync issue #477](https://github.com/webdjoe/pyvesync/issues/477) and [RedsGT's CAF-P583S integration](https://github.com/RedsGT/hass-vesync-enhanced): exact model post-pair API and presets, not local Bluetooth/control protocol. Community reports remote-start cloud behavior changes by region; NOT a reason to bypass appliance safeguards.
- [AV-TEST's 2021 CS158-AF security analysis](https://www.iot-tests.org/2021/10/its-getting-hot-in-here-cosori-air-fryer-cs158-af-in-the-security-test/): an **older DIFFERENT Cosori** used an ESP8285 with TLS MQTT to AWS and could not be locally operated using the official app. This is an architectural caution, **NOT proof** CAF-P583S is the same.
- [2023 VeSync power-socket analysis](https://itooktheredpill.irgendwo.org/2023/vesync-powersocket-analysis/): an **unrelated** VeSync ESP32 product sends Wi-Fi config + cloud keys over encrypted BLE then connects to VeSync MQTT. Investigator tried repointing MQTT server but device rejected self-signed TLS certificate. Supports possibility that cloud dependence is enforced in firmware rather than UI. **Do not reuse its AES keys/opcodes on the fryer.**
- [COSORI kettle local BLE project](https://github.com/barrymichels/CosoriKettleBLE) proves another manufacturer's product can be controlled locally via Bluetooth, but model/protocol not interchangeable.
- [FCC original module photos](https://fccid.io/2ARBY-CAF-P583S/Internal-Photos/Internal-Photos-5537891.pdf) show original ESP32-WROOM-32U board, but not the exact owner's board version or firmware.
- [Official COSORI CAF-P583S-KUS manual](https://device.report/m/b7de2b864169da5eb67a1f582f5a68af0d08f150590129b120d0ce79ed069a91): VeSync app restricts **remote initiation of cooking** in order to comply with UL safety requirements. Preserve that safeguard even if an undocumented command exists.

## 4. Realistic paths (ordered by value and safety)

| Strategy | Cloud needed | Hardware modifications | Evidence level | Verdict |
| --- | --- | --- | --- | --- |
| A. Native iPhone BLE status/limited local control | No, if firmware supports it | None | iPhone already connects; no event payloads or action support yet | **Most promising first research path, unproven** |
| B. Native iPhone local Wi-Fi TCP/UDP | No, if local endpoint exists | None | No Wi-Fi provisioning or discovered local service | **Blocked twice; not priority** |
| C. NAS BLE-to-iPhone bridge | No, if BLE local protocol exists | NAS needs compatible nearby BLE radio; DS418 native Bluetooth not verified | Merely relays A; solves zero protocol unknowns | **Not worth building yet** |
| D. Private NAS MQTT server impersonating VeSync | No external cloud if supported | No fryer hardware change, but firmware must accept a legitimate local broker | Different VeSync socket rejected untrusted certificate | **Unverified, high complexity, no proof** |
| E. Replace/modify fryer's ESP32 firmware or internal electronics | Potentially no | **Yes** | FCC shows ESP32 in original board only; no safe model-specific firmware or documented heater MCU links | **Reject for this household appliance** |
| F. Offline companion (recipes/manual timer) | No | None | Already implemented as planning UI | **Works as companion, NOT real control** |

The **critical distinction**: Even if we decode Wi-Fi provisioning, *local cooking status/control may still be absent*. And a BLE GATT connection does not mean the device has an operational BLE API. Full no-cloud parity may be impossible without a different hardware/firmware implementation.

## 5. D4 next experiment: controlled PASSIVE BLE event observatory

This is the smallest new experiment likely to distinguish an onboarding-only BLE service from one carrying live status. It is a **proposal**, not implemented or tested yet.

Prerequisites:
- Owner's consent to adding a diagnostic page and running it on **their own air fryer**, physically present.
- No new hardware, second phone, app store, account or NAS.
- Use already verified named peripheral `CAF-P583S-KUS`, and explicit user action; reject unknown candidate devices.
- The app connects in foreground, only subscribes to **FFF1** and **F000FFE2** (NOT OAD `FFC1/FFC2`), records timestamp, characteristic UUID, packet **length** and whether an event correlated with manual panel action; no automatic connection or background testing.
- CoreBluetooth `setNotifyValue(true, for:)` configures the BLE **Client Characteristic Configuration Descriptor**, which is a *protocol write*, though not a cooking command. Never mislabel it "no writes." No `writeValue()` to operational or OAD characteristics.
- First test is **while fryer idle, NOT heating**. User physically selects Air Fry/other preset or changes displayed time/temp without pressing Start. Check whether unsolicited notifications appear or change.
- Stop and disconnect after 30–60 seconds; all captured data local/in-memory; optionally user-controlled redacted summary export. **No passwords, SSIDs, MACs, device UUIDs, crypto keys or full message hex** in public GitHub. Require opt-in if future byte-level samples needed, with a privacy filter.
- Exclude other BLE devices; immediate Stop/Disconnect; show connection and known-not-connected state clearly.
- Avoid scanning endlessly, handling firmware GATT OAD, guessing commands, holding reset, or physically starting cooking as part of first probe.

Hypothesis:
- **If notifications vary with manual appliance setting changes**: we have a potential local status channel, but must determine message meanings, authentication and whether it works without VeSync registration. Only then design a separate *read-only* status experience.
- **If none appear**: it does *not conclusively prove* absence of BLE control. It suggests notifications may require an authenticated handshake, only work during provisioning, or not report local settings. No speculative writes to force traffic.
- **If signing or state unexpectedly changes**: immediately stop; audit before more experiments.

Implementation checklist:
- [ ] D4 `BLE Event Observatory` view in a separate test branch; original app bundle ID and offline recipes retained.
- [ ] Explicit consent text: notifications subscribe CCCD; no cooking/firmware controls.
- [ ] Product whitelist exact `CAF-P583S-KUS`, name match NOT cryptographic identity.
- [ ] Deny GATT mutation outside client notification descriptor; hard-coded no-OAD allowlist.
- [ ] Timeout, reconnect policy OFF, stop on view exit, permission errors, stale state and user-stop.
- [ ] Unit tests for discovery allowlist, handling packet metadata, no sensitive payload export and timeouts.
- [ ] CI simulator + iOS device build green, then owner physical trial. CI cannot replace physical hardware evidence.

## 6. Improve existing offline UI accurately (regardless of transport)

The current v0.1.1 planner offers **11 suggested presets** and values which DO NOT match the manufacturer's real defaults. The exact model's 2022 manual (page labelled 12, `Functions` table) lists **12** including Keep Warm. Verified manual default pairs:

| Preset | °F | min |
| --- | ---: | ---: |
| Chicken | 390 | 20 |
| Steak | 400 | 8 |
| Seafood | 375 | 8 |
| Veggies | 385 | 6 |
| Fries | 385 | 20 |
| Frozen | 395 | 12 |
| Air Fry | 360 | 10 |
| Reheat | 350 | 5 |
| Roast | 400 | 10 |
| Keep Warm | 175 | 30 |
| Bake | 320 | 20 |
| Broil | 400 | 10 |

From [exact-model owner's manual](https://device.report/m/b7de2b864169da5eb67a1f582f5a68af0d08f150590129b120d0ce79ed069a91), `Functions`, manual p.12. Note: published manual revision and owner's installed firmware may differ; present values as documented defaults, not hardware-confirmed favorites. The current app’s `Air Fry` planning default of 390°F/18min does not match the manual 360°F/10min, so **fix this before claiming app parity**.

Offline app can already offer 12 correct factory-planning templates, multiple saved recipes, background manual timer, clear non-live labels. These are meaningful without cloud and are independent of risky device control.

## 7. Expectations and release criteria

### What can be truthfully promised now
- No additional phone, Apple Account, App Store download or VeSync cloud for the existing SwiftUI offline planner.
- Native iPhone BLE discovery and GATT metadata inspection already work on owner's fryer.
- A plausible, bounded next scientific diagnostic exists (non-OAD notification observation).

### What remains speculative
- Any useful BLE status messages in normal cooking operation.
- BLE commands to set modes, temperature or time.
- BLE accountless session/authentication.
- Wi-Fi provisioning independent of cloud config key.
- LAN/MQTT local service, private broker compatibility.
- Full live-UI parity with VeSync while offline.

### GO / NO-GO
**GO:** original hardware documentation, locally authorized GATT reads or CCCD notification observation with express consent and guarded flow, offline test fixtures, native iPhone UI matching documented device preset values.
**NO-GO:** guessed `FFF2` / `F000FFE1` commands; any `F000FFC0` firmware-update channel activity; heater auto-start/remote start; flashing ESP32 in a live appliance; physical mains disassembly; dumping user secrets; claiming cloud code is local.

**Final technical verdict:** The ESP32 discovery makes the project a credible *research target*, not a working controller. Native local status is the first condition to prove. If no status or controls are exposed without onboarding/VeSync auth, a true no-cloud VeSync replacement may not be achievable without firmware modification that we should not do on a household heater.
