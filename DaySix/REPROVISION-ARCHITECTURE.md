# DaySix: ReProvision-inspired signer architecture

## Product goal
Install DaySix once on a non-jailbroken iPhone; use the iPhone, not Windows, for future IPA installation and Apple free-account refresh. DaySix itself must be renewed too, normally 24 hours before expiry, with an explicit failure notification if unattended execution is unsuccessful.

## Implemented in DaySix
1. Premium SwiftUI Home, My Apps, Install, Renew, More tabs.
2. An explicit signing queue: actual embedded expiration of DaySix when readable; manual expiration fallback; user-entered other-app expirations.
3. Configurable 12/24/36/48-hour renewal window and automatic-request toggle (24h is the default).
4. A daily iOS Shortcuts decision intent, a named `DaySix Refresh` Shortcut launcher, and SideStore's `Refresh All Apps` action as the real signing backend.
5. Renewal attempts and independently observed provisioning-profile changes are recorded separately.
6. Date-based local notifications and a manual-rescue flow.

## Why ReProvision itself cannot be dropped into a stock iPhone app

ReProvision Reborn was designed for jailbroken devices, and its reliable background automation uses a privileged daemon. An ordinary sideloaded iOS app cannot install or keep that jailbreak daemon running, enumerate all installed apps, or silently use SpringBoard's privileged installation functions.

Under stock iOS, BGTaskScheduler grants discretionary background execution. It is NOT a substitute for a guaranteed daemon. Even SideStore's Shortcuts action may fail on some iOS 27 configurations when it cannot access authentication credentials in the background.

Sources:
- ReProvision Reborn: https://github.com/sohsatoh/ReProvision-Reborn
- SideStore: https://github.com/SideStore/SideStore
- Apple background execution: https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app
- SideStore iOS 27 credential issue: https://github.com/SideStore/SideStore/issues/1584

## Additional real iOS options audited in November 2026

- **Apple Shortcuts personal automations** permit system triggers like Time of Day and Charger. Multiple triggers can safely call DaySix's decision intent; an independent emergency automation can call SideStore without DaySix itself. The six-hour DaySix cooldown reduces accidental duplicate Apple signing requests.
- **BGAppRefreshTask** is available with background fetch and a permitted task identifier. DaySix v0.1.5 uses it only to inspect expiry and notify if iOS schedules it. It is not a privileged daemon, a timed guarantee, or a background IPA signer.
- **BGContinuedProcessingTask (newer iOS)** may support user-started operations continuing after leaving the app in a future integrated signer. It does NOT authorize scheduled re-signing independently of normal iOS restrictions.
- **SideInstaller** (https://sideinstaller.net/) can bootstrap iOS 27 signing entirely on-device, with local pairing and app installation. Its custom license restricts incorporation; do not simply copy its Rust/Swift signing core into DaySix.
- **Tetherless** (https://github.com/pwnapplehat/TetherlessiOS) advertises a self-renewing signer with a native Shortcuts refresh action, but these vendor claims are not independent physical-device validation of DaySix and do not create an API that DaySix can silently call.
- **Apple free personal teams** still have seven-day provisioning and a three-app-per-device limit. A separate DaySix and SideStore installation costs two slots, which is why a single-app integrated signing target is a genuine future improvement.

## Next milestone: genuine integrated signing engine
The current DaySix app is a **SideStore companion**. For a **single-app signer** that does not require a separate SideStore icon, rebuild DaySix on top of SideStore's existing on-device signing and installation core rather than copying ReProvision's privileged daemon into this SwiftUI starter.

Suggested implementation sequence:
- [ ] Audit SideStore AGPLv3 source, third-party dependencies, code-signing entitlements, provisioning flow, and compatible iOS 27 releases.
- [ ] Build a separate, fully compliant AGPLv3 signing-capable DaySix target or fork, preserving source attribution and corresponding-source availability. Do not mix copied AGPL code into other unrelated apps without a license review.
- [ ] Retain SideStore's proven Apple account sign-in, secure credential storage, anisette compatibility, VPN/Minimuxer device communication, bundle signing and installation mechanisms.
- [ ] Expose signing stages to the DaySix UI through a typed adapter: queued → authenticating → downloading → provisioning → signing → installing → verifying → success/failure. No "completed" state without a verified new expiration.
- [ ] Register and manage the signer app itself, and test renewal without resetting unrelated app data.
- [ ] Verify provisioning profile, signing identity and install receipt after every install; authenticate the actual signed app, not merely a passed Shortcut.
- [ ] Build a configurable background policy with a generous renewal buffer, retry/backoff, proactive on-open checks, local notifications, and clear recovery prompts. Do not guarantee exact-time background execution on stock iOS.
- [ ] Conduct end-to-end testing on physical iOS 27 hardware with a free Apple account: initial installation, offline interval, locked phone, VPN disconnection, 2FA challenge, app update, exhausted three-app limit, self-renewal, and expired-profile recovery.

## Security and operational guardrails
- Do not send Apple credentials, pairing records, signing certificates, or private keys to a service controlled by DaySix without explicit user opt-in and proper independent security review.
- Do not import or redistribute signing code without honoring the license (SideStore and ReProvision Reborn are AGPLv3).
- Do not silently disable Apple account verification or bypass Apple's 7-day limitation.
- Do not claim an app was renewed if the new provisioning expiration is not verifiable.
- A compiler-successful unsigned IPA is **not** proof of successful on-device authentication, installation, or background signing.

## Current limitation
**DaySix does not independently sign itself or any IPA.** SideStore is needed for the signing operation. DaySix can decide when to request a renewal, show the signing queue, and verify its own new provisioning expiration when available. Reliable jailbroken-daemon-like unattended renewal cannot be guaranteed on an unjailbroken iPhone.
