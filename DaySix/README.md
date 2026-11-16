# DaySix 🍃
**Native iPhone signing companion · v0.1.0**

A dark glass, teal-and-violet iOS dashboard for the seven-day personal-development provisioning cycle. DaySix tracks apps you explicitly add, calculates a **day-six** renewal threshold, provides an installation handoff to **SideStore**, exposes two native **Shortcuts** actions, and schedules local expiration reminders.

## Important: what actually works

- ✅ A real SwiftUI application project, app dashboard, installed-app *tracking* list, manual verification, remote IPA install handoff (`sidestore://install?url=...`), Files-import/share flow, and local notifications.
- ✅ **Check DaySix Refresh** App Intent returns true only when the tracked renewal window is due. **Record Refresh Attempt** records an attempted automation without lying about successful signing.
- ✅ An unsigned iOS IPA artifact is produced by GitHub Actions, ready to be signed on the device with an already-working installer.
- ⚠️ **DaySix does not sign IPAs independently.** Actual Apple-account signing, pairing, installation and re-signing run in the SideStore app and its VPN. This is an integrated companion, not a reimplementation of the signing engine.
- ⚠️ There is **no public iOS API to list another app's provisioning expiry or silently install arbitrary IPAs.** The DaySix "My Apps" list is user-maintained. Only mark "Verified renewed" after the signing app shows a new seven-day expiry.
- ⚠️ **iOS does not guarantee exact-time background work.** The Shortcuts action may be delayed or fail, especially on some iOS 27 versions. DaySix also sends fallback local notifications.
- ⚠️ We have not tested this project on physical iPhone hardware. It must be built on GitHub Actions or a macOS/Xcode host, then signed for installation.

## On-iPhone setup (no PC for routine use)

1. Install and configure **SideStore** and **LocalDevVPN** on your iPhone using their official instructions. If you need a zero-PC initial setup on supported iOS versions, review [SideInstaller](https://github.com/FrizzleM/SideInstaller) and its trust/security requirements. You don't enter Apple credentials into DaySix.
2. Install the **DaySix IPA** signed by your on-device installer (unsigned builds from the Actions artifact require device signing).
3. Add each app to DaySix, using its last **verified** signing date from SideStore.
4. In **Shortcuts** create a **Time of Day → Daily → Run Immediately** automation, with these actions:
   - **DaySix: Check DaySix Refresh**
   - **If** result **is true**
   - **Set VPN: Connect LocalDevVPN**
   - **SideStore: Refresh All Apps** (native action exposed by SideStore)
   - **DaySix: Record Refresh Attempt**
   - **End If**
5. Run the Shortcut manually once to grant the needed permissions. Keep SideStore configured and use DaySix's reminders as a safety net.
6. After confirming SideStore shows renewed expiration dates, use **Verified renewed** on each DaySix app card. DaySix never treats an automation attempt as verified success.

**Why daily rather than running a single alarm on day six?** Shortcuts supplies a repeatable daily trigger; DaySix's boolean action gates the signing operation so it is invoked only when due. Exact scheduling is controlled by iOS, and a user may need to open SideStore when its background operation fails.

## Build

This repository includes an XcodeGen `project.yml` and a macOS GitHub Actions workflow at `.github/workflows/daysix-ios.yml`. GitHub Actions generates the app icon, creates the Xcode project and builds an **unsigned** IPA. To build locally on macOS:

```bash
cd DaySix
python3 -m pip install Pillow
python3 scripts/make_icon.py
brew install xcodegen
xcodegen generate
xcodebuild -project DaySix.xcodeproj -scheme DaySix -configuration Release -sdk iphoneos -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

### Security

DaySix does **not** collect Apple IDs, passwords, anisette tokens, pairing records or certificates. Never trust a random pre-signed installer; review its official source. SideStore and SideInstaller are independent projects, not affiliated with DaySix. We do not bundle SideInstaller source or redistribute its official IPA. The custom SideInstaller license imposes conditions; review it before incorporating its code.

### References
- [SideStore user guide](https://docs.sidestore.io/docs/installation/install.html)
- [SideStore URL scheme](https://docs.sidestore.io/docs/advanced/url-schema)
- [SideStore GitHub](https://github.com/SideStore/SideStore)
- [SideInstaller GitHub](https://github.com/FrizzleM/SideInstaller)

**Planned next stage**: an audited, in-app signing/refresh engine using a compatible, appropriately licensed signing core and real installed-app metadata. Not included or claimed working in v0.1.0.
