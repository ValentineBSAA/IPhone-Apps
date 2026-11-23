# Crisp Companion — D3 first-time provisioning protocol research

Research checkpoint: 2026-11-22. **Exact CAF-P583S-KUS onboarding packet format NOT FOUND.**
Status: evidence study COMPLETE; first-time pairing implementation NOT READY.
Dedicated issue: [#102](https://github.com/ValentineBSAA/IPhone-Apps/issues/102).

## User constraints (non-negotiable)
- Existing physical iPhone with AltStore, Windows 11 PC, and Synology DS418 NAS are the target equipment.
- No App Store downloads, no other Apple Account, no Android phone/tablet, no third-party IPA hunting.
- User owns the air fryer, has never onboarded it into VeSync.
- No remote start or heater control during protocol exploration. No firmware-update operations.

## Ground truth from owner hardware

- D0: iOS BLE scan sees `CAF-P583S-KUS` at -57 dBm before configuration mode.
- D1: iPhone genuinely connects and discovers these service/characteristic UUIDs, **no data reads/writes**:
  - `FFF0`, `FFF1` notify, `FFF2` write.
  - `F000FFC0-0451-4000-B000-000000000000`, `F000FFC1` and `F000FFC2` write/notify. This is Texas Instruments' firmware update OAD service; categorically excluded from experiments.
  - `F000FFE0-0451-4000-B000-000000000000`, `F000FFE2` notify, `F000FFE1` write.
- D2: Five-second *physical* On/Off press makes Wi-Fi icon blink. No obvious COSORI-branded SSID in one ordinary iPhone Settings Wi-Fi listing. BLE still advertises `CAF-P583S-KUS`, -50 dBm. GATT service/characteristic table **unchanged** in blinking/configuration state.
- Exact physical *sticker* and firmware revision still unverified; advertising model name is strong evidence but not equivalent to device ID/authentication.

## Research conclusions: what the public sources actually support

### A. Exact CAF-P583S-KUS cloud controls are documented, setup is NOT
[webdjoe/pyvesync issue #477](https://github.com/webdjoe/pyvesync/issues/477) includes post-setup device descriptors `configModule=WFON_AFR_CAF-P583S-KUS_US`, `connectionType=WiFi+BTOnboarding+BTNotify`, and bypass cloud commands. It includes **no complete first-use BLE pairing packet trace**. [RedsGT/hass-vesync-enhanced](https://github.com/RedsGT/hass-vesync-enhanced) supports an already-paired US device, not onboarding. [pyvesync](https://webdjoe.github.io/pyvesync/latest/) explicitly connects over VeSync cloud after devices are configured.

**Interpretation:** our optional NAS bridge cannot discover a device not bound to a VeSync account, regardless of how polished the iPhone frontend is.

### B. VeSync has used an encrypted Bluetooth onboarding protocol in another product
[Independent 2023 analysis of a VeSync power socket](https://itooktheredpill.irgendwo.org/2023/vesync-powersocket-analysis/) documents an encrypted, framed BLE exchange involving a session-key handshake, Wi-Fi list discovery, network credentials, and cloud-config data such as an account ID, a config key, and MQTT server. The analysis also shows cloud certificate restrictions.

This is **useful architectural evidence**, *not* proof the CAF-P583S uses the same service, messages, key exchange, keys, firmware, or cloud registration. **No socket packets, opcodes, keys, or credentials should ever be replayed to the fryer.** To apply it would require verified CAF-P583S hardware/firmware or a model-specific trace and legitimate cloud-claim flow.

### C. Older COSORI air fryer used a DIFFERENT setup mechanism
[Cisco Talos TALOS-2020-1216](https://talos.talosintelligence.com/vulnerability_reports/TALOS-2020-1216) describes an **older** COSORI smart fryer using a Wi-Fi SoftAP and an encrypted TCP configuration service. This is not evidence that the Dual Blaze uses the same port/protocol or the same security weaknesses. The owner's Wi-Fi listing did not show an obvious brand-named hotspot; that observation does not conclusively exclude an ephemeral or differently named SoftAP.

### D. Another VeSync product confirms Bluetooth-assisted device family, but NOT compatibility
[Levoit Core 300S protocol study](https://github.com/nico202/levoit-core300s-ota-wifi-flash/blob/main/docs/protocol.md) gives `WiFi+BTOnboarding+BTNotify` for an ESP32-based purifier. It documents its cloud/OTA behavior, **not a reusable pairing implementation** for COSORI CAF-P583S. The shared connection-type string merely supports the broader architecture possibility.

### E. GATT UUIDs suggest functions; they do not define messages
- [Texas Instruments OAD docs](https://www.ti.com/lit/an/swra619b/swra619b.pdf) and [TI Bluetooth OAD code](https://git.ti.com/cgit/ble-oad-android-source-code/ble-oad-android-source-code/commit/app) identify the `F000FFC0` family as firmware updates. **Never read/write/subscribe/flash OAD in future pairing experiments.**
- [TI BLE base UUID](https://software-dl.ti.com/lprf/sdg-latest/doxygen/ble/html/bcomdef_8h.html) is `F000XXXX-0451-4000-B000-000000000000`; it does not identify the `F000FFE0` firmware-specific payloads.
- [Feasycom documentation](https://document.feasycom.com/docs/fsc-faq/EN/latest/faqs.html) uses `FFF0`/notify `FFF1`/write `FFF2` in a serial BLE module, and an [unrelated COSORI kettle project](https://github.com/barrymichels/CosoriKettleBLE) uses this trio for a different device. Those are **layout similarities**, not an air fryer handshake specification.
- [FCC ID 2ARBY-CAF-P583S](https://fccid.io/2ARBY-CAF-P583S) has public wireless approval for the Dual Blaze, with original 2021 filing and 2023 modification. Internal photos were listed but **not directly inspected in this research**, so chipset/board revision identification remains uncertain.

### F. VeSync cloud registration is an independent hard gate
[Official CAF-P583S-KUS manual](https://device.report/m/f43caea918e51f0deb4ecd8f2645272b993bf091f3c24d823ac70f288a22a771) specifies VeSync app/account for adding the fryer, with no alternate setup API documentation. [pyvesync errors](https://webdjoe.github.io/pyvesync/3.0.0b1/development/utils/errors/) include cloud errors for `CONFIGKEY_NOT_EXIST`, `CONFIGKEY_EXPIRED`, and `DEVICE_BOUND`; those support a distinct authorization/claim step but **do not tell us how to produce valid credentials**.

An official [VeSync Account portal](https://account.vesync.com/) exists, but the publicly retrieved page did not expose whether new VeSync accounts can be created there or whether it can register a device. **Do not assert that it solves account onboarding**. This is NOT suggesting a new Apple Account.

## Explicit negative results
- No exact-model, publicly available, tested end-to-end BLE first-time pairing code found in searched public repositories.
- No verified pairing payload for `FFF2` or `F000FFE1`.
- No verified first-use device registration / cloud `configKey` acquisition protocol for CAF-P583S-KUS.
- No confirmed standalone/local-only control path for this unit.
- More repeated iPhone scan/GATT-UUID inspections will not reveal encrypted payload framing.

## Feasibility assessment
- **Physical iPhone Bluetooth discovery:** DONE and owner-observed.
- **Bluetooth GATT service inspection:** DONE and owner-observed.
- **Documented Wi-Fi setup-mode transition:** DONE, blinking indicator owner-observed.
- **Wi-Fi provisioning via custom iPhone app:** PLAUSIBLE in principle, NOT proven for this model. Current blocker is proprietary BLE framing/authentication and possibly cloud-generated configuration.
- **App replaces VeSync for real remote controls:** BLOCKED until successful provisioning and documented legitimate cloud/local interface; no basis for a success guarantee.

## Prioritized next action, no new IPA yet

1. **Ask exact-model community contributors for an anonymized first-onboarding trace or specification**, particularly participants in [pyvesync issue #477](https://github.com/webdjoe/pyvesync/issues/477) and [RedsGT's integration](https://github.com/RedsGT/hass-vesync-enhanced). Their existing post-pair API captures aren't enough. Specific request: BLE GATT UUIDs (no MAC/serial), sanitized handshake shape/packet lengths, whether the cloud first provides a device claim/config key, and any permission/license for using protocol details. Captures must redact usernames, tokens, passwords, MACs, device IDs and SSIDs.
2. **Ask VeSync support** if they offer an authorized iOS/onboarding SDK, pairing instructions, or a direct account-based onboarding API for `CAF-P583S-KUS`. Explain that their owner has an iPhone but cannot install the App Store app. Official app page lists `support@vesync.com`. Avoid sharing personal credentials in the request.
3. **Identify exact board/firmware where feasible via non-invasive manufacturer documentation**, especially if the FCC filing revision corresponds to hardware sticker. No disassembly or firmware flashing.
4. **Only when exact protocol evidence arrives**, build an *offline parsing and simulation harness* against anonymized recorded frames, verify length, integrity, replay protections and authentication; keep writable commands DISABLED on physical hardware.
5. **Then** implement an explicit, user-consented BLE onboarding UI and controlled Wi-Fi delivery, plus legitimate VeSync cloud claiming. No remote heater start. Only deliver a new IPA when there is a model-specific testable hypothesis, not as a speculative iteration.

### Suggested narrowly scoped question for contributors/support

> Do you have a protocol specification or privacy-redacted **first-time BLE provisioning** trace for COSORI CAF-P583S-KUS (`WFON_AFR_CAF-P583S-KUS_US`)? The owner's iPhone discovers `FFF0/FFF1/FFF2` and the `F000FFE0` family, while the `F000FFC0` service is reserved for firmware updates. We specifically need to know how Wi-Fi configuration and legitimate VeSync account/device registration occur. We are not looking for cooking or firmware-flashing commands. Please omit credentials, tokens, MACs and unique device identifiers.

## Go / no-go rules
**NO-GO** for speculative `FFF2` writes, `F000FFE1` writes, any OAD activity, firmware extraction/flashing, hardware changes, remote heater start, or authentication bypass. **GO** for public documentation, non-invasive identification, privacy-safe community protocol evidence, offline parser/fixture tests, and manufacturer-authorized onboarding integration.

This file is the D3 handoff. Current iPhone IPA `0.1.1` remains the most recently owner-tested diagnostic build. The source branches and draft PR stack must not be merged or labelled functioning VeSync replacements until real pairing succeeds.
