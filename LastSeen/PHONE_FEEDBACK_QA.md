# Build 22 — Phone Feedback QA (iPhone 16e)

- [ ] Upgrade from Build 21, with existing saved phone. Tutorial resets once; first Maya message arrives after a brief pause, visibly and with two-tone sound/haptic feedback if enabled.
- [ ] Test while on fictional lock screen, home screen, in other apps and in Maya conversation. Each newly arrived message triggers a cue, including when a message is read immediately.
- [ ] Existing restored history, opening Messages, outgoing-only events and read/unread changes do not retrigger effects. Relaunch and lock/unlock do not replay old alerts.
- [ ] Settings > Sounds & Haptics: normal, suspense and scare previews distinct. Test sound only, vibration only, both off; horror toggle disables suspense/scare previews but not normal message cue.
- [ ] Test silent mode and physical volume. Native alerts permission is not required. Haptics subject to system settings/hardware. Stop effects on background.
- [ ] Settings > About > Replay message tutorial: confirm returns to fictional lock screen and restarts Maya tutorial. Cancel changes nothing. Original messages, unrelated notes, protected clue note, owner verification, installed packages and wallpaper remain; no duplicate clue note. Repeat replay twice.
- [ ] Follow tutorial again through note, files, and protected journal; check natural feedback for subsequent incoming messages.
- [ ] Existing approved jailbreak, welcome, Relay repair, navigation and settings remain intact. No new horror story reveal in this build.
- [ ] Automated audio decoding, incoming detection, replay tests and full simulator regression suite; verify IPA v1.3.9 build 22 min iOS 16. Physical sensation and sound not proven in simulator.
