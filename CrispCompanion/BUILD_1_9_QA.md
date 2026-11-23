# Crisp Companion v0.1.9: Time Difference QA

## Scope
Read-only FFF1 notification comparison for physically selected Air Fry durations 10 → 11 → 10 → 11 → 10 minutes. No heating, no value reads/writes, no OAD or Wi-Fi provisioning. FFF1 notification subscription configures CCCD.

## CI
- [ ] Simulator compile and XCTest pass
- [ ] Unsigned iOS 16 physical build pass
- [ ] IPA artifact verified and downloadable
- [ ] No characteristic command/read regression
- [ ] Original app data preserved on in-place upgrade

## Owner physical test
- [ ] Physically select Air Fry 10 minutes, do not press Start
- [ ] Confirm idle/not heating in the app; start
- [ ] Leave fryer untouched through eight-second baseline
- [ ] Change to 11, confirm on iPhone, wait seven seconds
- [ ] Change to 10, confirm, wait seven seconds
- [ ] Change to 11, confirm, wait seven seconds
- [ ] Change to 10, confirm, wait seven seconds
- [ ] Automatic disconnect and privacy-safe report
- [ ] Stop, background and screen exit disconnect; existing recipes remain
- [ ] Interpret only repeatable, reversible masked signature differences; no decoded status/control claim

## Known limitations
This test checks only notifications that arrive while connected, not encrypted or authenticated traffic. Negative result cannot rule out another protocol/transport. A positive result cannot establish duration encoding without more evidence.
