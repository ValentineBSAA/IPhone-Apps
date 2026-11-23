# Crisp Companion 0.1.2: BLE Event Observatory real iPhone QA

Source exists on the Build 1.2 feature branch; mark tests [x] only after CI / owner results.

## Automated gates
- [ ] Native iOS simulator build and XCTest green.
- [ ] iOS 16+ Release iPhone build, bundle ID unchanged, 0.1.2 IPA generated.
- [ ] Bridge Python tests and no-write-route guard green.
- [ ] BLE policy tests: only exact `CAF-P583S-KUS` name, `FFF1` and `F000FFE2` notifications, no OAD or command UUIDs.
- [ ] Static scan enforces no `writeValue()` or `readValue()` methods in the observatory source.

## Physical iPhone tests (do not fake)
- [ ] Install new IPA over existing app, retain saved recipes/timer settings.
- [ ] Factory planner shows **12** documented presets including Keep Warm 175°F/30min; Air Fry 360°F/10min. Planner changes only local notes.
- [ ] Settings > BLE Event Observatory opens, visually legible.
- [ ] Start disabled until owner confirms fryer is **idle / not heating**.
- [ ] Start with Bluetooth on; permission prompt or supported OS state appears; exact model detection.
- [ ] Unknown BLE devices never connect; while real cooker off or busy don't use observer.
- [ ] Observer stops automatically at 45 seconds; Stop button cancels earlier; leaving screen or backgrounding stops/disconnects.
- [ ] After physically changing presets/time/temp **without Start**, record channel counts, notification **byte lengths/timestamps**, or zero events honestly.
- [ ] Unknown payloads are NOT decoded as temperatures or presets, and no cloud/network access required.
- [ ] No text or report contains Wi-Fi credentials, Bluetooth peripheral IDs, device MACs, full payload contents.
- [ ] Fryer remains at normal operating state after observation; any unexpected heat is a hard stop.

## Interpretation
- Receiving notifications *correlated with manual changes* is an interesting lead, not proven live status or command parity.
- No notifications does not disprove local control; may require authentication/handshake.
- Bluetooth `setNotifyValue(true)` configures a **CCCD descriptor**. It is a configuration write, not a cooking command. We do not claim zero writes at protocol level.
- NEVER write to `F000FFC0` / `F000FFC1` / `F000FFC2` (firmware update), or to `FFF2` / `F000FFE1`.
- Manufacturer's remote heater-start restriction remains in force.

See `LOCAL_ONLY_CONTROL_RESEARCH.md` and `ROADMAP.md`.
