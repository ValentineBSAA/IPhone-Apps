# Crisp Companion v0.1.4 — Preset Mapping QA

## CI gates
- [ ] iOS 16+ SwiftUI simulator compilation, XCTest and Release device build pass.
- [ ] iPhone unsigned IPA artifact version = 0.1.4, same bundle ID and existing recipe data.
- [ ] BLE source static guard excludes readValue/writeValue and firmware GATT OAD.
- [ ] Tests prove proper 12-step order; repeated messages compare only within ephemeral HMAC session; channel separation, idle flag, erase and no auto connection work.

## Physical-device safety test (no heating)
- [ ] App installed over v0.1.3; saved recipes retained and four tabs still work.
- [ ] Settings > Preset Mapping: explicit idle/non-heating confirmation.
- [ ] Connection finds CAF-P583S-KUS and subscribes only FFF1/F000FFE2. CCCD subscription is explicitly acknowledged as descriptor configuration write.
- [ ] 10-second untouched idle baseline completes before any preset is armed.
- [ ] One preset at a time: tap Arm, then press that preset on physical fryer, no Start; observe five-second window and packet count.
- [ ] Test in displayed order: Chicken, Veggies, Steak, Fries, Seafood, Frozen, Air Fry, Keep Warm, Reheat, Bake, Roast, Broil.
- [ ] Second pass repeats exactly the same order without opening/closing the page, preserving the same session-only HMAC key.
- [ ] Results show per-preset packet counts, identical signatures across passes (if any), and patterns already seen during idle baseline.
- [ ] Stopping, leaving page, backgrounding or five-minute session timeout disconnects immediately; leaving also clears results and ephemeral key.
- [ ] No raw packet values, hashes, network SSIDs, tokens or peripheral identifiers are displayed/exported. A user-initiated Copy safe counts button exports only preset names and aggregate counts.
- [ ] Physical fryer remains safe and idle; if any unexpected operation or heat occurs, stop.

## Interpretation
If repeated patterns match on the same preset across passes, investigate further in a *different* controlled test; matching a notification does not establish that it encodes that preset. If no repeatability, counter/time-dependent packets are possible. Five-second capture windows can include unrelated messages. No remote commands or useful live temperature are proven.
