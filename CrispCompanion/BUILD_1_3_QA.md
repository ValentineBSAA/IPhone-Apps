# Crisp Companion v0.1.3: physical iPhone packet-comparison QA

Source added; mark checks passed only after specific evidence.

## Automated
- [ ] CI simulator compilation, XCTest, iPhone release compilation and IPA artifact succeed.
- [ ] No `readValue()`, `writeValue()`, descriptor discovery or heater commands in the two diagnostic sources.
- [ ] HMAC keyed hashing compares same payload only within one session, zero stable hashes or payload export.
- [ ] 2 allowed notification characteristics only. No TI OAD access.
- [ ] Stable bundle ID, iOS 16+, v0.1.3, saved recipes unaffected.
- [ ] Baseline/adjustment simulator tests pass for repeated packets, changed packets, cross-channel separation and clearing.

## Physical iPhone, while the fryer remains idle and not heating
- [ ] Install over v0.1.2 and verify recipes persist.
- [ ] Settings > Packet Comparison shows separate first baseline and second adjustment stage.
- [ ] Confirm idle toggle; start untouched baseline and leave fryer controls untouched for the entire **45s after subscription**.
- [ ] See baseline packets/unique patterns, complete flag and disconnected status.
- [ ] Start physical adjustments stage (only after baseline complete); physically cycle presets/time/temp. Tap Mark adjustment after each change. Do NOT press Start.
- [ ] Let second stage finish; check pattern counts and 'new patterns' / 'patterns in both'.
- [ ] Confirm no raw payload, hash, device ID, SSID, credentials or remote control outputs visible.
- [ ] Stop early cancels; leaving page or backgrounding immediately disconnects and clears in-memory comparison.
- [ ] No unexpected heating, device mode changes caused by app, or abnormal behavior.
- [ ] Repeating baseline resets prior comparison, without overwriting saved recipes.

## Interpret carefully
'New patterns' means new ephemeral-keyed HMAC signatures. It may reflect counters, timestamps, or messages unrelated to cooking. It **does not establish local status** or make any control command safe. A zero count likewise does not rule out control.
Bluetooth `setNotifyValue` configures CCCD and is a BLE descriptor write. No characteristic writes are issued.
