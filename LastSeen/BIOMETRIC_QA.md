# Last Seen 1.2.2 (11) — optional native biometric unlock

- Test setup toggle off by default and on by explicit choice; existing setup completes without reset.
- On iPhone 14 Pro with Face ID enrolled: tap unlock or swipe up; real iOS prompt/scan, success opens home, cancel/failure stays locked. Test lock-screen notification entry cannot bypass authentication.
- Test optional fallback: Play without biometrics disables preference and unlocks; game remains playable if denied/unavailable/locked out. No real passcode entry in game.
- Settings toggle persists. Re-lock and relaunch; reauthenticate when unlocking. No automatic scans during story or backgrounding.
- Touch ID supported where available; actual physical device testing required. Simulator build does not prove real Face ID.
- No camera, face image, biometric template, cloud access or stored authentication data; only system result. This is optional immersion, not a security boundary for sensitive real data. Preserve previous story, backup, and settings.
- Verify bundle version, iOS 16 minimum, purpose string and all prior restore tests. No narrative claims about identifying Nora via real biometrics.
