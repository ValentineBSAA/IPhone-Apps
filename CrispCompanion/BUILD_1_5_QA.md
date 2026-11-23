# Crisp Companion v0.1.5 — Quick Local Probe QA

## Automated
- [ ] Complete CI iOS Simulator build, XCTest, device Release, app identity guard and unsigned IPA artifact.
- [ ] Swift tests for byte-position analysis: stable candidate, counter changes, incomplete/mismatched frames and no false mapping.
- [ ] BLE static source guard confirms no characteristic readValue / writeValue / discoverDescriptors calls in Quick Local Probe or earlier diagnostics.
- [ ] Only FFF1/F000FFE2 notification channel subscriptions permitted; exclude all TI OAD characteristics.
- [ ] App bundle ID `com.valentinebsaa.crispcompanion`, iOS 16+, version 0.1.5; recipes/timer unchanged.

## Physical iPhone, idle/non-heating
- [ ] Install in place using existing AltStore; verify saved recipes persisted.
- [ ] Settings shows Quick Local Probe as a prominent card; older diagnostics folded into "Advanced Bluetooth diagnostics".
- [ ] Checkbox required before Start, session remains foreground; no automatic heater/control commands.
- [ ] Exact name CAF-P583S-KUS detected, then BLE notification subscription to approved characteristics only.
- [ ] Untouched baseline lasts 12 seconds AFTER successful subscription. Confirm no button presses.
- [ ] Automatically prompt **Air Fry** for 8 seconds: tap that physical preset once, do not press Start.
- [ ] Automatically prompt **Reheat** for 8 seconds: tap once.
- [ ] Automatically prompt **Air Fry** for 8 seconds: tap once.
- [ ] Automatically prompt **Reheat** for 8 seconds: tap once.
- [ ] Each phase advances without pressing Arm/Next on the iPhone; vibration prompt (if permitted) and large text visible.
- [ ] End displays number of usable FFF1 message captures, candidate positions, same-preset changed positions or honest incomplete result.
- [ ] Copy safe report contains only byte POSITION NUMBERS, message lengths, event counts; no payload values, MACs, SSIDs, account tokens or stable hashes.
- [ ] Stop, leave screen and background abort, disconnect, discard transient payloads.
- [ ] If no events appear or another channel interrupts, show incomplete rather than claim successful decoder.
- [ ] No heating, no commands, no network onboarding or VeSync Cloud.

## Limitations
The first observed FFF1 frame per 8-second phase may be periodic rather than preset-derived. Even consistent positions are ONLY research candidates, not validated status or control commands. BLE notification subscription changes CCCD (configuration descriptor); no characteristic value writes are issued.
