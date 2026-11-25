# Build 17 (1.3.4) — cinematic jailbreak
Primary hardware: iPhone 16e. Preserve all saves and existing permissions. Upgrade triggers one-time replay.
- [ ] Verbose console expanded by default during recognition/diagnostics/installation, 63 total deterministic entries; text readable, continuously follows newest line, pause scroll and resume follow both work, collapse/reopen works.
- [ ] Logs stop while cable disconnected/backgrounded; continue with reconnect or fallback; no duplicate lines after relaunch. No actual kernel or USB data access.
- [ ] Recognition 10s, diagnostics 15s, prep 20s, install 65s, completion 3s, automatic restart 15s; 128 active seconds total excluding manual actions. Skip remains available before restart; VoiceOver custom skip action in cutscene.
- [ ] Full-screen black fade (0–1s), animated userspace logo (2–7s), black fade (8–9s), animated respring spinner (10–14s); no extra controls or status bar during cinematic, welcome only after completion. Real iOS system navigation remains available.
- [ ] Distinct UserspaceDown, UserspaceUp, RespringDown, RespringUp sound cues; sound mute and silent mode respected; reduce motion static art; stop sound on background. Theme respring uses same spinner.
- [ ] Existing original icons, Afterglow Glass optional theme, real charging proxy, haptics, security, navigation, data and QA export still work.
References: https://github.com/opa334/Dopamine and https://dopamine.dhinak.net/ (terminology/community inspiration only; no code copied).
Automated tests verify transcript progression and stage boundaries, not visual/audio quality. All functionality is simulated except public power detection, optional native authentication, haptics and permission APIs.

## Build 17 CI correction
Run 45533800649 compiled and passed release identity/assets verification, but RestartArtTests still asserted 125 seconds after the intended 128-second timing change. Removed duplicated total assertion from the art suite; RecoverySecurityTests owns the total timing contract. Added all four audio asset checks to the art suite and a fail-fast release contract preflight before compilation. No runtime changes, no tests skipped. Rebuild 1.3.4 (17) and verify the entire simulator suite before distribution.
