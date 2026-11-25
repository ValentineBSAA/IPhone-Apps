# 1.2.3 (12) — Native Phone Polish
## Build 10 physical screenshot review (12 images, 2026-11-24)
Visible evidence: five setup stages displayed, Coastal and Dusk selectable, restore at 38% and 100%, launcher appeared with 11 icons, Messages showed Maya/Denise with 3 unread, Contacts showed both portraits, Settings and Browser displayed. These screens do not certify all controls, persistence, restart, airplane mode, or Face ID. Dusk selected in one screenshot but Coastal later visible; unknown whether user switched back. Not a confirmed persistence failure.
## Implemented in source for build 12
- Keep original iOS status bar; remove duplicate home clock. Use native public APIs; jailbroken aesthetic only, no jailbreak dependency.
- Pre-game out-of-fiction consent review before welcome, optional explicit Face ID/Touch ID and game notification requests, no irrelevant permissions. No real contacts/photo/camera/location/microphone/cloud access. Optional seven-second neutral test alert; no story notifications.
- Type fictional device name, live wallpaper cards sharing the actual shell renderer, longer restore (about ten seconds) with skip/reduced motion, no repeated fictional-device disclaimer inside setup. Keep accessible privacy disclosure in pre-game/settings.
- Fix swipe-up bypass from build 11: route all lock-screen entry actions through optional authentication, not direct state changes. Never block game if authentication unavailable or refused.
- Settings: device details, optional permission review and non-destructive replay setup. Browser: fictional .test address bar, local sites, bookmark/history, navigation. No real internet. Seed ordinary browser history once. Inbox timestamps.
## Physical QA
- [ ] New or upgraded install: permissions screen, accept/deny/skip each permission; continue in every case. Never ask for unrelated resources. Existing completed setup and world survive.
- [ ] Face ID tap and swipe: success unlocks, cancel/failure stays locked, fallback works. Notification card cannot bypass auth. Re-lock, repeat; verify on real enrolled device.
- [ ] Native iOS status bar/charging/service/Wi-Fi remains visible and only one clock on home. Simulated Wi-Fi does not alter physical Wi-Fi.
- [ ] Replay setup without erasing restored notes/messages. Choose custom name and both wallpaper previews, check exact matching home background and persistence on relaunch. Keyboard works and blank name defaults.
- [ ] Restore resume, skip, reduced motion, all eleven apps still work; no automatic horror.
- [ ] Optional test notification: grant, schedule, background, check branded native notification; disable cancels pending test, deny remains playable.
- [ ] Browser address/search local sites, bookmark, back/forward/home, history and clear, no external navigation; verify retained history after restart.
- [ ] iPhone 14 Pro iOS 16 hardware safe areas, text sizes and portrait layout. No claims of pass before testing.
## Next priorities (not implemented here)
Original OS branding and premium icon art; expanded phone and real-looking app switching; Phone app, contacts favorites, call history and in-game audio/voicemail; rich camera roll, video playback, audio/music; larger consistent female-owner snapshot, notes/mail/calendar/files and authentic browser site design; genuine authored message delivery; future optional voice input only if implemented. Original character bible and locally generated media with rights checks. No final horror plot until OS approval. Free and offline.
