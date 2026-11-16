# DaySix Signer Lab (experimental)

This lab tests the **real SideStore on-device signing implementation** as an integration baseline. It is intentionally isolated from the shipping DaySix SwiftUI companion.

## Why we're doing this

The finished product should be a **single iPhone app** that can sign and install a user-selected IPA, manage seven-day Apple provisioning, and re-sign itself. ReProvision Reborn achieves automatic signing with jailbreak-specific privileges. On stock iOS, a viable alternative is SideStore's self-managed signing and VPN/Minimuxer installation pipeline, with iOS Shortcuts-based refresh and honest scheduling limits.

## What the lab does

There are **two distinct deliverables**, neither yet equivalent to a verified
stock-iOS installer:

- **DaySix SwiftUI companion**: the premium dashboard and day-six logic, which
  currently delegates actual signing to SideStore.
- **DaySix Signer Lab**: an experimental, AGPL-licensed derivative of the real
  SideStore signer. It intentionally retains upstream installer logic and UI,
  uses the display name **DaySix Signer Lab**, and must use a separate test
  bundle ID. This is the first codebase that could actually contain an
  independent on-device IPA signing engine.

The standalone preview does not yet include the premium DaySix SwiftUI
dashboard. That UI integration is a separate, subsequent engineering step.

The isolated GitHub Actions workflow:

1. Checks out the **official SideStore/SideStore develop tree**, including submodules.
2. Prints the exact upstream Git commit used. Never accepts a random third-party pre-signed binary.
3. Reads the upstream AGPLv3 license, then attempts the officially documented unsigned-IPA Makefile build (`make build fakesign ipa`) with no Apple ID and no signing secrets.
4. Applies the audited `preview_brand.py` change (display name and preview
   marker) and compiles with an explicit experimental bundle-ID suffix.
5. Inspects the produced IPA to reject official SideStore bundle IDs or
   missing experimental markers, then uploads only inspected artifacts and
   the build log.

The safety checks are run on Linux by
`DaySix/SignerLab/Tests/test_preview_brand.py` as well as before the real
macOS IPA artifact is uploaded. This test is independent of Apple credentials.

**Do not install this preview alongside a working SideStore** until we also
audit its URL schemes, app groups, system callback identifiers, pairing,
self-renewal identity, and Apple account interaction. A distinct bundle ID
alone does not eliminate all conflicts; both apps may still register the
`sidestore://` URL scheme. The preview intentionally does **not** claim
that an iPhone would run it safely today.

A successful upstream build would prove only that the signing-capable SideStore code can be compiled in our CI environment. **It does not create a DaySix-branded integrated signer, and does not prove real device signing or self-refresh.** There is no credential collection, account login, or physical-device access in GitHub Actions.

### Next after a successful probe

- Create a correctly licensed AGPLv3 derivative of the upstream source; preserve copyright, attribution, corresponding source, and build instructions.
- Implement the DaySix visual style and renewal panel **within that signer app**, not as a second iPhone app that uses up an extra free-account slot.
- Add measured stages: Apple login (secure device keychain), provisioning, signing, installation, verified expiry, refreshing. Never conflate a Shortcut request with signature renewal.
- Test actual iOS 27 device pairing, local VPN, free account limits, Apple 2FA, revoked certificates, seven-day expiry, expired signer recovery, and backup/restore of user data.

### Security and licensing

Official upstream: https://github.com/SideStore/SideStore

SideStore uses AGPLv3. SideSign (one dependency) uses GPLv3. Third-party dependencies and Apple entitlements must be audited individually. Any modified integrated app needs appropriate license compliance and transparent source availability. Never commit Apple IDs, passwords, tokens, private keys, pairing records, device identifiers, or entitlements copied from an unrelated paid team.

### Non-goals

- No jailbreak daemon or exploitation of nonpublic kernel privileges.
- No seven-day free provisioning bypass.
- No false claim that iOS will provide guaranteed background execution while locked.

Status: **experiment, not a production signer.**
