# DaySix 🍃
**Native iPhone signing companion · v0.1.6**

A dark glass, teal-and-violet iOS dashboard inspired by ReProvision for the seven-day personal-development provisioning cycle. DaySix automatically checks **its own installed Apple provisioning-profile expiration**, tracks other apps you explicitly add, and gates SideStore's **Refresh All Apps** Shortcuts action at **day six**, with local reminders as a fallback.

## Native iPhone Notifications: real Settings integration

DaySix now uses Apple's **UserNotifications** permission system and presents an explicit permission request during first-run onboarding. After the user has responded to the iOS prompt, the installed app can be managed in **iPhone Settings → Apps → DaySix → Notifications** (also discoverable through Settings → Notifications on supported iOS versions). **These are actual OS controls**, not DaySix-branded replacements:

- Allow Notifications, Lock Screen, Notification Center, banners, sounds, badges and delivery preferences remain under Apple's control.
- **More → iPhone Notifications** displays Apple's real authorization, alert, sound and badge statuses and links straight to `UIApplication.openNotificationSettingsURLString`.
- DaySix has individual in-app switches for early health checks, day-six due warnings and six-hour critical warnings. These switches adjust scheduled `UNNotificationRequest` entries, not iOS system permissions.
- **Send Test Notification** schedules a real five-second local banner with the system's default notification sound. A foreground notification delegate allows banners while DaySix is open; Focus, Silent Mode and system settings can still suppress presentation.
- DaySix does not claim APNs remote push support, emergency/critical-alert privileges, guaranteed background execution, or a confirmed on-device signing operation.

The **Signer Lab** build separately inherits SideStore's own iOS authorization and foreground-banner handling. Its expiration notifications are branded **DaySix Signer Lab** so users can distinguish the experimental signer from the DaySix SwiftUI companion. The lab is **not device-approved or ready to install** until its real unsigned IPA passes packaging and physical iOS testing.

## Signer Lab: a real engine technical preview, not a finished DaySix signer

We now have a **reproducible SideStore-derived unsigned IPA build recipe** in
[SignerLab](SignerLab/README.md). Unlike the separate SwiftUI companion, the
upstream code contains actual on-device Apple provisioning, IPA signing, local
VPN installation, and SideStore-style self-refresh. The lab applies a visible
**DaySix Signer Lab** technical-preview name, requests a distinct bundle-ID
suffix and refuses to publish the preview unless identity checks pass. The
companion's UI is **not yet embedded** in the signing engine.

The lab builds SideStore's official AGPLv3 source and records its exact
upstream SHA and dependencies, without copying certificates, credentials or
pairing files. Source and build patches must be available under the applicable
open-source license terms. This preview is **not safe to install beside your
working SideStore yet** because its URL schemes and some app-group/callback
identities may overlap. A unique bundle ID alone does not prove safe
coexistence, nor does compilation prove automatic self-renewal.

The fast Linux tests enforce the preview label, provenance marker and
different bundle ID. The macOS workflow verifies the packaged IPA as well,
but the actual SideStore-derived signing process is unverified until an
unsigned build compiles and a real iOS 27 device passes end-to-end tests.

## New in v0.1.6: verified prerequisites and actual signing engine research

- **Signing enrollment check:** More → Reliability Lab now asks you to confirm that DaySix appears in **SideStore → My Apps**, and that you've tested a successful refresh. These are honest user confirmations, not claims that DaySix can inspect SideStore's private database.
- **Self-renewal readiness warning:** The DaySix card warns if the installed signing application is not confirmed to manage it, even if a good provisioning expiration exists.
- **Real signing engine integration probes:** `DaySix/SignerLab` tests building official SideStore and importing the actual **SideSign** Swift package, separately from DaySix's companion app. These experiments do not handle Apple credentials and do not yet provide in-app IPA signing.
- **Linux policy tests:** A second fast GitHub Actions workflow compiles the Foundation-only signing policy, provisioning reader, and readiness checks, so we can validate those without needing a macOS runner.
- **Xcode 27 runner and queue cleanup:** iPhone and SideStore integration experiments now use GitHub's Xcode 27 macOS runner and cancel superseded builds, to avoid a pileup of outdated jobs.

**Current signer:** SideStore still does the signing. True independent DaySix signing remains a separate engineering milestone. If a new build hasn't passed, don't sideload an unvalidated IPA.

## New in v0.1.5: Apple-permitted reliability safeguards

- **Opportunistic BGAppRefreshTask watchdog:** DaySix registers a permitted Background App Refresh task and requests periodic iOS-granted wakeups to recheck expiration and issue a warning. It does **not** execute signing in the background. Apple can delay, deny or skip it, especially after force-quit, with Low Power Mode, or when Background App Refresh is restricted.
- **Reliability Lab:** New More-screen guide for checking SideStore detection, Background App Refresh availability, notification authorization, and low-power mode, plus a last-check timestamp.
- **Multiple Shortcuts triggers:** Daily and optional charger-connected automations can both request the same named DaySix Refresh shortcut. A shared per-app **six-hour cooldown** prevents accidental rapid repeat signing requests; manual rescue is never blocked.
- **Independent lifeboat:** An optional second personal automation can call SideStore directly without any DaySix App Intent, so it can still run if DaySix's own signature expires. Daily direct signing can increase Apple provisioning traffic, so this is an opt-in fallback, not enabled by DaySix.
- **Early preflight alert:** Default 48 hours before expiry, or earlier for users choosing a longer renewal window. Day-six reminders and a six-hour final warning still apply.
- **Alert preservation fix:** Reopening DaySix no longer cancels a pending alert and then suppresses its replacement, preventing silent missed expiry notifications.
- **Emergency CTA:** Home dashboard offers a one-tap renewal shortcut when an expiration is due.

**No guaranteed always-on execution:** The added background task is an advisory deadline check only. Only the installed signer (SideStore in this version) can attempt re-signing; even its Shortcut may fail on iOS 27. Neither this task nor an extra Shortcut can run a completely expired DaySix executable.

## New in v0.1.4: ReProvision-style Renewal Center

The **Renew** tab now has a premium signing queue including DaySix itself, an enable/disable control for automatic refresh requests, and configurable **12-, 24-, 36-, or 48-hour** lead times before signature expiration. **24 hours remains the default**, so this is day six of a seven-day free signature.

These settings are functional: the renewal window changes the actual stored expiration calculations, the daily Shortcuts Boolean decision and notification scheduling. Disabling automatic requests prevents the Shortcuts gate from requesting a refresh. Manual **Run DaySix Refresh** remains available.

**This is a ReProvision-inspired user interface and working scheduler decision layer, not ReProvision's jailbreak signing daemon.** SideStore remains the signing/install engine; exact-time background execution is not guaranteed. See [REPROVISION-ARCHITECTURE.md](REPROVISION-ARCHITECTURE.md) for the engineering path toward a true single-app signer and AGPLv3 obligations.

## Important: what actually works

- ✅ A real SwiftUI application project, app dashboard, installed-app *tracking* list, manual verification, remote IPA install handoff (`sidestore://install?url=...`), Files-import/share flow, and local notifications.
- ✅ **DaySix monitors its own signature:** reads the embedded Apple provisioning profile when available, shows its real expiration, and flags it 24 hours before expiry. If no readable profile exists, the user can manually enter the exact expiration shown in SideStore. This fallback schedules reminders without pretending that the signature was verified. Extra reminders appear at six hours remaining.
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
3. DaySix automatically inspects **its own** installed signature. Add **other apps** using their last **verified** signing date from SideStore. When DaySix cannot read a profile, use **My Apps → DaySix → Enter SideStore expiration** to set its actual expiration date as an explicitly manual fallback.
4. In **Shortcuts**, create a shortcut with the exact name **DaySix Refresh**. Add these actions in order:
   - **Set VPN: Connect LocalDevVPN**
   - **Open URLs: `sidestore://`** (opens SideStore, which may avoid iOS 27 background authentication failures)
   - **Wait 5 seconds** for SideStore to initialize
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
- [Apple background task guidance](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app)
- [Apple personal automation triggers](https://support.apple.com/guide/shortcuts/add-automations-apdfbdbd7123/ios)

**Planned next stage**: an audited, in-app signing/refresh engine using an appropriately licensed signing core. A user-initiated signing session could also explore iOS 26+ continued background processing, but it does not replace timed self-renewal. This version **uses SideStore for signing including DaySix itself**; it does not independently sign, install, or refresh apps. No guarantee of exact background execution.

### Build/compatibility testing
The macOS GitHub Actions workflow compiles the RenewalPolicy and SelfProvisioning models, runs Foundation-only smoke tests for profile parsing, manual fallback, preflight warnings, cooldown and configurable day-six scheduling, then builds an unsigned IPA. Actual iOS BGTaskScheduler execution still requires physical-device testing. The workflow passing **does not** prove on-device SideStore integration. Current iOS 27 reports include failed SideStore Shortcuts refreshes when its process is not alive even though manual refreshing works. Opening `sidestore://` before the refresh can improve some setups, but often requires the phone to be unlocked; it is NOT a guaranteed locked-screen daemon. If the shortcut fails, open SideStore manually and refresh before expiration.

**iPhone test checklist**: install via SideStore; verify DaySix appears in SideStore's managed list; check DaySix's embedded expiry; run the named shortcut; verify a new embedded expiry and audit entry; leave iPhone locked overnight; observe the day-six reminder and daily automation without assuming success.
