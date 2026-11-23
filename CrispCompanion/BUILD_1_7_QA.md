# Crisp Companion v0.1.7 — Passive FFF1 Header Check QA

## Automated release gates
- [ ] GitHub Actions bridge-tests and static safety guard pass, including BLEHeaderCheck.swift.
- [ ] iOS 16+ Simulator compile and all XCTest pass.
- [ ] iPhone Release build + unsigned IPA is genuine, archive CRC valid, CFBundleIdentifier `com.valentinebsaa.crispcompanion`, version 0.1.7 and minimum iOS 16.
- [ ] Synthetic tests verify matching kettle-like A5/type/length, bad-magic, unknown-type, wrong-length, short frame, sequence wrap, cap/reset, and safe aggregate reporting.
- [ ] No changes to saved recipe/store schema, timers, previous diagnostics, or VeSync cloud logic.
- [ ] No characteristic `readValue()`, `writeValue()`, `discoverDescriptors()`, LAN command, heater or firmware OTA operations. `setNotifyValue(true)` on FFF1 is a CCCD descriptor config write, disclosed in app.

## Real-device test on owner's iPhone; strictly idle, non-heating
- [ ] Install v0.1.7 over v0.1.6 using the same AltStore identity, recipes retained.
- [ ] On COSORI's physical panel select Reheat **without Start**; wait until it remains idle.
- [ ] Settings > Header Check > confirm selected mode and not heating > Start once.
- [ ] Only FFF0/FFF1 discovered; no firmware/OAD access. Wait while 10-second baseline runs untouched.
- [ ] At the 12-second prompt tap physical **Air Fry** once, do not press physical Start.
- [ ] Report shows count of 10-byte notifications, kettle-style first-byte, recognized type, header payload length, complete matches, +1 sequence and constant sum evidence; **never exposes actual byte values**.
- [ ] After completion BLE disconnects; Copy safe report contains aggregate counts only.
- [ ] Stop, page exit, or app background disconnects and discards even transient seq/sum metadata.
- [ ] Inconclusive/no packets is reported honestly and does not auto-retry dangerous commands.

## Interpretation
A matching 6-byte `A5, type, seq, lengthLo, lengthHi, check` header is not proof the fryer and the separate COSORI kettle share status semantics or operational control. A mismatch is a reason to investigate another frame format, not to write guessed opcodes to the fryer. No control commands in v0.1.7.
