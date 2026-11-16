# DaySix integration checkpoint

Safe, standalone Swift module intended to be **integrated into the existing DaySix native iPhone app**. It does not replace the earlier premium dashboard or signing laboratory.

## What is implemented and testable

- `.ipa` ZIP index validation and detection of `Payload/<App>.app/Info.plist` without extracting the IPA or reading the entire app into memory.
- An explicit **Sign & Install** handoff through the `SigningInstalling` protocol. If a real implementation is configured, the service actually calls it after import validation; otherwise the app gets an honest setup error.
- A distinction between **installation requested** and **installation confirmed**. No fake green installed status.
- Renewal planning for the sixth day of a seven-day signing window, or earlier for a profile that expires sooner.
- Deterministic Swift tests (`swift test`).

## What is still required for an installable product

1. Integrate this module into the previous DaySix v0.1.7 SwiftUI project, rather than starting the UI over.
2. Connect `SigningInstalling` to the SideStore-derived signing and on-device install engine using the original project's actual signing API. This module deliberately does **not** pretend that Apple's Files picker or Share Sheet installs IPAs.
3. Handle iOS Files security-scoped URLs: call `startAccessingSecurityScopedResource`, copy the selected IPA to sandbox storage, then call `DaySixImportService.signAndInstall(ipa:)` from a clear confirmation action.
4. Wire the result into the premium progress sheet with actual stages, actionable errors, and a distinction between install submitted and device-confirmed.
5. Register iOS notification permission, categories, and scheduled expiry reminders using `UNUserNotificationCenter`. iPhone Settings > Notifications will expose the app after notification authorization is requested.
6. Treat `BGTaskScheduler` renewal as **best effort**: iOS may delay or skip background execution. Provide a reliable day-six notification and a prominent manual Refresh button.
7. Run Xcode build and physical-iPhone signing, installation and day-six renewal tests before claiming success.

### Platform boundary

Apple's free Personal Team profiles expire after seven days. This module does not bypass that limit, produce signing certificates, enroll in Apple's developer program, or guarantee silent install/renewal.

### Tests

```bash
swift test
```

The integration package targets iOS 16+ and macOS 13+, with Foundation-only runtime code.

## SwiftUI integration samples

The optional `iOS/` directory contains a real Files-picker -> secure copy -> **Sign & Install** UI and a native `UNUserNotificationCenter` reminder adapter. These are not part of the cross-platform test package; add them to the existing iPhone Xcode target after wiring a real signing engine. They have not yet been compiled using Xcode or verified on an iPhone.