# DaySix 🍃
**Native iPhone signing companion · v0.1.2**

A dark glass, teal-and-violet iOS dashboard for the seven-day personal-development provisioning cycle. DaySix automatically checks **its own installed Apple provisioning-profile expiration**, tracks other apps you explicitly add, and gates SideStore's **Refresh All Apps** Shortcuts action at **day six**, with local reminders as a fallback.

## Important: what actually works

- ✅ A real SwiftUI application project, app dashboard, installed-app *tracking* list, manual verification, remote IPA install handoff (`sidestore://install?url=...`), Files-import/share flow, and local notifications.
- ✅ **DaySix monitors its own signature:** reads the embedded Apple provisioning profile when available, shows its real expiration, and flags it 24 hours before expiry. If no readable profile exists, the status is **Unknown**, never fabricated. Extra reminders appear at six hours remaining.
- ✅ **Renewal History** distinguishes automation attempts from verified self-renewals (an observed increase in Apple's embedded expiration).
- ✅ One-tap **Run DaySix Refresh** uses Apple's documented `shortcuts://run-shortcut` scheme after the named shortcut is configured.
- ✅ **Check DaySix Refresh** App Intent returns true when DaySix itself or a tracked app is due. **Record Refresh Attempt** records an attempted automation without falsely claiming successful signing.
- ✅ An unsigned iOS IPA artifact is produced by GitHub Actions, ready to be signed on the device with an already-working installer.
- ⚠️ **DaySix does not sign IPAs independently.** Actual Apple-account signing, pairing, installation and re-signing run in the SideStore app and its VPN. This is an integrated companion, not a reimplementation of the signing engine.
- ⚠️ There is **no public iOS API to list another app's provisioning expiry or silently install arbitrary IPAs.** The DaySix "My Apps" list is user-maintained. Only mark "Verified renewed" after the signing app shows a new seven-day expiry.
- ⚠️ **iOS does not guarantee exact-time background work.** The Shortcuts action may be delayed or fail, especially on some iOS 27 versions. DaySix also sends fallback local notifications.
- ⚠️ We have not tested this project on physical iPhone hardware. It must be built on GitHub Actions or a macOS/Xcode host, then signed for installation.

## On-iPhone setup (no PC for routine use)

1. Install and configure **SideStore** and **LocalDevVPN** on your iPhone using their official instructions. If you need a zero-PC initial setup on supported iOS versions, review [SideInstaller](https://github.com/FrizzleM/SideInstaller) and its trust/security requirements. You don't enter Apple credentials into DaySix.
2. **For DaySix self-renewal, install or reinstall its IPA through SideStore itself**, not only through an unrelated signer, so **DaySix appears in SideStore → My Apps**. SideStore must manage it for **Refresh All Apps** to re-sign it. The unsigned IPA artifact requires signing first.
3. DaySix automatically inspects **its own** installed signature. Add **other apps** using their last **verified** signing date from SideStore. When DaySix cannot read a profile, check its exact expiry in SideStore.
4. In **Shortcuts**, create a shortcut with the exact name **DaySix Refresh**. Add these actions in order:
   - **Set VPN: Connect LocalDevVPN**
   - **DaySix: Record Refresh Attempt** (records a requested attempt, even if SideStore later fails)
   - **SideStore: Refresh All Apps** (the signing operation)
5. Next create a **Time of Day → Daily → Run Immediately** automation. Add:
   - **DaySix: Check DaySix Refresh** (checks DaySix itself and other tracked apps)
   - **If** result **is true**
   - **Run Shortcut: DaySix Refresh**
   - **End If**
6. Open **DaySix → More → Run Refresh** to test the named shortcut manually and grant necessary permissions. This button opens Apple's own Shortcuts app; it cannot claim that the renewal succeeded.
7. After verifying SideStore's new expiration dates, use **Verified renewed** on other app cards. For DaySix itself, a genuine increase in the embedded Apple provisioning-profile expiration is automatically recorded in **More → Renewal History**. A failed refresh attempt remains an attempt, never a success.

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

**Planned next stage**: an audited, in-app signing/refresh engine using an appropriately licensed signing core. This version **uses SideStore for signing including DaySix itself**; it does not independently sign, install, or refresh apps. No guarantee of exact background execution.

### Build/compatibility testing
The macOS GitHub Actions workflow runs a Foundation-only parser smoke test with a wrapped sample provisioning profile, rejects a malformed profile, and builds an unsigned IPA. The workflow passing **does not** prove on-device SideStore integration. Current iOS 27 reports include failed SideStore Shortcuts refreshes even when manually refreshing works. If the shortcut fails, open SideStore manually and refresh before expiration.

**iPhone test checklist**: install via SideStore; verify DaySix appears in SideStore's managed list; check DaySix's embedded expiry; run the named shortcut; verify a new embedded expiry and audit entry; leave iPhone locked overnight; observe the day-six reminder and daily automation without assuming success.
