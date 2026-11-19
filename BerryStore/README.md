# BerryStore v0.1.0 (experimental iOS IPA)

Independent, **open-source** iPhone app based on [SideStore](https://github.com/SideStore/SideStore). Source is pinned to the revision in `UPSTREAM_SHA.txt` for reproducibility.

## What is real in this build?

- New home-screen identity: BerryStore icon and displayed app name.
- Own bundle ID: `com.valentine.berrystore.SideStore` (not an in-place replacement of SideStore or AltStore).
- Existing SideStore signing/refresh engine, dependency submodules, and iOS build tooling retained. Xcode's internal target and binary name intentionally remain SideStore for compatibility.
- A GitHub macOS/Xcode 27 workflow produces and **verifies the real compiled IPA** before uploading it.
- Every build uploads corresponding modified source and pinned dependencies for AGPL compliance.

**Current limits:** The packaged IPA is *fake-signed*, meaning it must be re-signed by a compatible installer for your Apple developer account and iPhone. This is not a permanent signing bypass. Actual app installation and self-refresh on iOS 27 are unverified. The underlying SideStore interface retains some upstream identity and documentation links, with attribution. LocalDevVPN/pairing is still required; the inability to download LocalDevVPN from the App Store remains a real blocker.

## Build

Workflow: `.github/workflows/berrystore-ios.yml` on the `berrystore-v0.1` branch. Build downloads SideStore at `UPSTREAM_SHA.txt`, initializes its submodules, invokes `scripts/prepare.py`, compiles and fakesigns with upstream's `make build fakesign ipa`, validates the IPA identity and executable, and uploads the IPA and complete corresponding source archive.

Products:
- `BerryStore-0.1.0-fakesigned.ipa`
- `BerryStore-0.1.0-source.tar.gz`
- `SHA256SUMS.txt`
- `xcodebuild.log` (on success or failure if generated)

No Apple credentials, pairing files, provisioning profiles, private keys, or device identifiers belong in this public repo, CI output, or logs.

## License / attribution

Upstream SideStore copyright and licenses remain intact. Our modifications are available under AGPL-3.0. The original SideStore/AltStore names and trademarks remain with their respective holders; BerryStore is independent and is not sponsored or endorsed by them. Original licenses and notices are included in the source archive. Retain and satisfy all dependency license obligations before public redistribution.

## Safety

Do not delete working AltStore or trust this build as the only way to refresh apps. Device testing and a valid signed installation are prerequisites for calling this a functioning replacement. See `TEST_PLAN.md`.
