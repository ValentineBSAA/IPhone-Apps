# Crisp Companion 0.1.6, Signal Structure QA

## Automated release checks
- [ ] iOS simulator compile and XCTest pass, unsigned physical-device Release build pass.
- [ ] Artifact identity: `com.valentinebsaa.crispcompanion`, version 0.1.6, minimum iOS 16, successful ZIP/IPA verification.
- [ ] Existing recipes and timer use the same saved schema and original bundle ID; no account and no Apple App Store dependency.
- [ ] Static safeguard scans all diagnostic source files, including BLEStructureProbe.swift, for no `readValue()`, `writeValue()`, or `discoverDescriptors()` calls.
- [ ] Tests cover synthetic volatile counters, candidate positions, same-session +/XOR heuristics, missing packets, mismatched lengths, read-only allowlist, and privacy-safe export.

## Real owner hardware testing, idle only
- [ ] v0.1.6 installs over v0.1.5 using the same AltStore setup.
- [ ] Saved recipes and prior UI features remain.
- [ ] Settings highlights "Signal Structure".
- [ ] BEFORE pressing Start, select physical **Reheat** but do not start heating.
- [ ] Check the "idle/not heating and Reheat selected" confirmation.
- [ ] Tap **Start automatic signal test** once.
- [ ] Wait for Bluetooth connection and notification subscription, then let **10-second untouched baseline** run without touching the fryer.
- [ ] Follow **three** automatic nine-second prompts: physical **Air Fry**, **Reheat**, **Air Fry**, each once; never tap physical Start.
- [ ] Observe in-app per-step event counts; run completes and disconnects by itself.
- [ ] Tap Copy safe report; paste aggregate counts, changing positions, heuristic summary and time-from-prompt (NOT actual physical press latency).
- [ ] If a phase receives no packet, record incomplete data honestly; do not assume a mode code was identified.
- [ ] Leave page/background/Stop immediately disconnects and clears transient payloads.
- [ ] No raw BLE packet bytes, stable message fingerprints, credentials, peripheral identifiers or SSIDs in export.
- [ ] No heating, no operational write, no TI firmware OAD activity.

## Limits
The only network operation is local BLE subscription to FFF1 (CCCD descriptor configuration write). The device's name is not authenticated. No local status or command protocol has been established. All +1 / XOR / sum relations are mathematical clues only and can arise by chance. Time to first packet is measured from the app's prompt, not the actual moment of physical button press. Keep PR in draft until physical iPhone test is verified.
