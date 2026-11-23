# Crisp Companion Build 1 checklist

Legend: [x] source present/inspected, [ ] needs automated or human verification. Never mark tests passed without evidence.

## Automated / CI
- [ ] XcodeGen generates the SwiftUI project without error.
- [ ] Unsigned iOS 16+ simulator compilation succeeds.
- [ ] Selected iPhone Simulator tests: 11 preset cases, recipe validation and bridge JSON null-state decoding.
- [ ] Unsigned physical iPhone compilation succeeds.
- [ ] Temporary original 1024 PNG AppIcon exists, is referenced and fallback icon PNG is standard format.
- [ ] IPA contains `Payload/CrispCompanion.app/Info.plist`, bundle ID `com.valentinebsaa.crispcompanion`, version `0.1.0`, build number from run.
- [ ] Bridge Python unit tests: offline state never becomes online, remaining time units are converted from seconds.
- [ ] Bridge has **zero write endpoints**; no remote-start string in routed handlers.

## On-device without any VeSync account
- [ ] Cold launch shows Kitchen preview banner, offline status and **no invented temperature/time data**.
- [ ] All four tabs open; no clipping on iPhone portrait, display zoom, or larger text.
- [ ] Selecting presets changes only local planning values; check 175–400°F and 1–60min limits.
- [ ] Save recipe, change tab, force close/reopen, verify persistence; delete, verify permanent removal.
- [ ] Create custom recipe with notes, reject empty name, test long name and stepper bounds.
- [ ] Start manual timer; verify foreground countdown and notification after permission; test denying permission.
- [ ] Clear manual timer and verify no pending alert; relaunch and check remaining time.
- [ ] Preview mode correctly blocks network calls; switch to live with no URL -> useful HTTPS error.
- [ ] Invalid token/URL yields graceful error, never falsely 'connected'.
- [ ] VoiceOver names controls, 12h preferred time labels where displayed, Reduce Motion accessible.
- [ ] AltStore sideload and seven-day refresh using owner's NAS, without deleting other apps.

## Physical fryer test (blocked until legitimately paired)
- [ ] Confirm label and firmware + country variant.
- [ ] VeSync account is authorized and paired to this exact device.
- [ ] NAS bridge reachable only through private HTTPS, bearer token in Keychain, never public HTTP.
- [ ] Read idle -> actual null sensor values, not frozen last readings.
- [ ] Physically start cooking at fryer and verify app status, set temp, remaining minutes.
- [ ] Stop at physical fryer and verify app returns idle.
- [ ] Disconnect Wi-Fi / cloud / NAS and verify 'not connected' without misleading stale state.
- [ ] Full app remains read-only; no remote heater start.

## Stop conditions
Any unexplained state mismatch, heater action, disconnection masked as online, leaking account secrets, failing signature/AltStore install, or incorrect model configuration blocks a live-release claim.
