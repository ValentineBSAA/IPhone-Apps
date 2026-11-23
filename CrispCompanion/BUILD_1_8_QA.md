# Crisp Companion v0.1.8 — Packet Families QA

## CI acceptance (confirm actual green run before distributing)
- [ ] GitHub Actions iOS Simulator compiles successfully.
- [ ] All synthetic XCTest pass, including anonymous category consistency, return-to-A type, short/mixed frame handling, packet cap and clearing.
- [ ] iOS Release physical-device build succeeds with `com.valentinebsaa.crispcompanion`, version 0.1.8 and minimum iOS 16.
- [ ] Unsigned IPA artifact ZIP integrity, Info.plist identity, executable, size and SHA256 independently verified.
- [ ] Static no-command guard includes all BLE diagnostic sources including `BLEPacketFamilies.swift`; no GATT `writeValue()` / `readValue()` / `discoverDescriptors()` calls in the observer.
- [ ] Existing app data schema, recipes and manual timers preserved; no unrelated code changed.

## Physical iPhone test: one Start, three physical taps; NO heating
- [ ] Install signed version with current AltStore workflow over 0.1.7 and verify recipe data.
- [ ] Physically preselect **Reheat** and leave the fryer idle, NOT heating, before opening test.
- [ ] In Settings select featured **Packet Families**; previous tools are grouped in Advanced Bluetooth diagnostics.
- [ ] Check explicit idle confirmation; tap Start once. Exact CAF-P583S-KUS BLE name match, FFF0/FFF1 service/notify only.
- [ ] Wait **10 seconds without touching fryer** during the baseline, starting only after FFF1 is successfully subscribed.
- [ ] Follow three automatically advanced 9-second prompts: **Air Fry**, **Reheat**, **Air Fry**. Do not press the physical Start/heating button.
- [ ] One incoming FFF1 notification per prompt is sufficient to calculate type A/B/C labels and adjacent pair counters. More than one is counted safely and in acquisition order.
- [ ] Result includes anonymous category distribution by stage, A5 and declared-length consistency, type12/22 match rate, equal-length adjacent sequence +1 and b2+b5 sum invariance.
- [ ] Copy safe report: only counts, packet lengths and arbitrary A/B/C labels; no actual byte1 type value or raw packet, identifying data, hashes or secrets.
- [ ] Successful completion disconnects automatically and erases temporary type/sequence bytes; Stop, exit and background also disconnect/erase.
- [ ] If events are missing or format mismatches, report them honestly. Do not interpret an anonymous category as cooking mode.
- [ ] No FFF2 characteristic writes, TI OAD/firmware, VeSync cloud, Wi-Fi provisioning or remote heater start.

## Interpretation
The independent Cosori Kettle project shares the FFF0/FFF1/FFF2 GATT naming and six-byte A5/type/seq/length/check header, but its outgoing ten-byte poll and incoming 18/35-byte status differ from this fryer's observed incoming ten-byte frame. Matching an anonymous type category across Air Fry/Reheat/Air Fry suggests the notification is not identifying those presets via byte 1 in this sample. Still cannot infer full message meaning, authenticated local control or safety of operating commands.

## Verification addendum: real physical report, 2026-11-23

- [x] GitHub Actions [run 45129017719](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/45129017719) terminal status **success**; simulator build, synthetic XCTest, unsigned physical device build, application identity packaging step, bridge tests and static no-characteristic-command guard all finished successfully.
- [x] CI uploaded artifact named `CrispCompanion-v0.1.8-iOS16-unsigned` (artifact ID 14797940074, currently reported not expired).
- [ ] Independently download/unzip/test binary, verify digest/Info.plist, and ensure saved recipes survived real in-place install (not established by the above CI success).
- [x] Owner confirmed the air fryer **was idle, initial Reheat, never pressed physical Start**, with automatic physical prompt order Air Fry → Reheat → Air Fry.
- [x] Report: untouched baseline 0 FFF1; prompts 1/1/1; three 10-byte frames; A5 3/3 and declared-length match 3/3, known kettle types 0/3, full kettle headers 0/3.
- [x] Only one **anonymous** type category A across all prompts; 2/2 equal-length adjacent pairs same category, +1 byte 2 transitions 2/2 and byte2+byte5 constant 2/2.
- [x] Report contains aggregate anonymous labels/counts only; no raw payload or secret values were shared.
- [x] Owner newly observed factory-selected panel times: **Air Fry 10 minutes; Reheat 5 minutes**. These are not verified readings in the BLE frames.
- [ ] Explicit manual verification of Stop, navigation, app-background disconnect and ephemeral bytes deletion; owner report does not address them.
- [ ] Do not mark local device status, actual preset value, temperature, duration telemetry, Wi-Fi provisioning or any cooking command as decoded or supported.

**Protocol verdict:** current incoming FFF1 notification looks like a shared frame family with sequence/checksum-like changes, not a visible Air Fry/Reheat status mapping. See [field verdict](../RESEARCH/CRISP_COMPANION_FFF1_FIELD_VERDICT_2026-11-23.md). No repeated v0.1.9 version solely for the same structural checks.
