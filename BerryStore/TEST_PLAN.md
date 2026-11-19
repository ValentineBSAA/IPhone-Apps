# BerryStore release gate

## Build and integrity
- [ ] macOS GitHub Actions completes the compiled IPA using pinned upstream source.
- [ ] IPA verification checks executable, `BerryStore` label and our bundle identifier.
- [ ] Corresponding AGPL source and third-party dependency submodules are included.
- [ ] Inspect generated entitlements and extension bundle identifiers before installing.

## First install on iOS 27
- [ ] Leave existing AltStore and other apps installed.
- [ ] Re-sign the IPA for the device through a trusted compatible installer.
- [ ] Confirm BerryStore icon/name, app launch, and that AltStore is unaffected.
- [ ] Obtain and enable LocalDevVPN through an eligible legitimate route.
- [ ] Import/establish compatible pairing data; never post pairing files publicly.

## Refresh and recovery
- [ ] BerryStore manually refreshes itself with cable disconnected.
- [ ] A separately signed IPA installs and launches.
- [ ] Refresh that app without USB connection.
- [ ] Verify certificate countdown, expiry warnings and error explanations.
- [ ] Test reboot, Wi-Fi outage, VPN stop/start, and app relaunch recovery.
- [ ] Evaluate auto refresh only after manual refresh is reliable.

## Product polish
- [ ] Finish in-app branding without removing upstream attribution.
- [ ] Provide curated verified GitHub app source, updates and backups.
- [ ] Test iOS 16 on the jailbroken iPhone 14 Pro independently.
- [ ] Review permissions, signing security and AGPL compliance before a public 1.0.
