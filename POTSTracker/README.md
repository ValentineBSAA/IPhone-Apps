# POTS Tracker (working title)

**Status:** Build 1 native IPA compiled successfully and launched on an iPhone 16e. User-provided screenshots confirmed the custom feature artwork. **v0.1.1 Calm Home redesign source has been committed and is awaiting new CI and real-device regression testing.** The 13 approved original icon PNGs remain in `Resources/Icons/`.

A free, privacy-first native **iPhone** utility for tracking lived experiences of Postural Orthostatic Tachycardia Syndrome (POTS). Designed for a family member who wants useful daily records and 7-day, monthly, 365/366-day, and lifetime history without paid features.

## Non-negotiable requirements

- Native SwiftUI iPhone app, aiming for iOS 16 or later (minimum OS to be validated on the test device).
- No Apple Watch, wearable requirement, Watch-specific UI or Watch integration.
- No subscription, advertisement, account creation, purchase or paywall.
- Manual heart-rate and blood-pressure readings from an external validated device. The iPhone alone is **not** a blood-pressure monitor.
- Entries may be recorded multiple times per day, edited later or skipped entirely. Missing days are **unknown**, not healthy days.
- Seven-day home overview with monthly, full-year (365/366 days), custom range and lifetime history.
- Bright, accessible utility design with labeled **grid cards** and optional low-energy/large-control logging.
- Data stays locally on the iPhone by default. Share/export is explicit user action, not background transmission.
- Medication, fluids, food, sodium/electrolytes, sleep, activity, posture, triggers, symptom severity, episodes and free-form journal records all planned, with user-controlled enable/disable.
- Calendar reminders and doctor-ready reports must remain free.

## Main screens

Home; Quick Log; Heart Rate; Blood Pressure; Symptoms; Hydration; Medications; Sleep; History Calendar; Reports; Posture; Reminders; Journal; Settings. Main navigation uses clear labels with custom icons and no long settings lists as the primary experience.

## Medical safety

This is a **recording and communication aid, not a diagnostic or treatment device**. Do not automatically diagnose POTS, interpret readings as emergencies, recommend sodium/fluid/medication targets, change treatment or generate misleading medical alerts. Physician-prescribed targets can be entered manually if needed. Health trends are observational, not proof of causation. Provide clearly worded medical disclaimer and emergency escalation guidance.

## Artwork

The approved art set is **13 distinct 1024 x 1024 PNG images**, one Home Screen app icon and 12 feature icons. Their exact names, categories and integrity requirements are in `assets/ICON_MANIFEST.md`. Full master assets are packaged as `POTS_13_Color_Matched_Icons.zip` in the originating conversation.

Do **not** replace the approved artwork with automatically generated substitutes; the import helper validates exact expected filenames. See `tools/import_icons.py`.

## Development workflow

1. Confirm icon import and privacy-first scaffold.
2. Implement real local persistence and human-readable quick logging.
3. Add trustworthy charts, full-year history, reminders and exports.
4. Run physical-device testing (including offline launch, permission denial, timezone changes and data restore).
5. Publish only after real-device validation.

Track progress in [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md), the [research-backed premium-quality (all-free) roadmap](PREMIUM_FEATURE_ROADMAP.md), and GitHub Issues.

No personal medical details, test logs containing identifying health data, credentials or backups belong in this public repository.

## Build 1 working source (implementation pending CI verification)

Implemented in `Sources/`: an iOS 16-compatible SwiftUI dashboard, all 12 feature cards, large-control mode, one-tap optional check-ins, seven-day activity count, manually entered symptom/heart-rate/blood-pressure/journal records with editing and deletion, plus private on-device Core Data SQLite persistence.

- Current recording screens: Symptoms, Heart Rate, Blood Pressure, Daily Journal.
- Current history: last 7 days, including entries from prior days; blank days stay blank.
- Settings: Low Energy Mode, show/hide explanations, privacy and safety information.
- **Not implemented yet:** hydrated/fluid tracking, medications, sleep, posture sessions, reminders, full-year charts, PDF/CSV, local backup/restore and optional observations. Their feature cards explicitly say they're planned.
- **Artwork gate:** Build 1 requires all 13 original PNGs and the native generated image sets. The workflow halts when they are missing instead of displaying substitute artwork.
- **Important:** the app has no export or restore function yet. **Do not store irreplaceable real health data in Build 1.** Deleting this experimental version may remove locally saved entries.

### Build on GitHub

The repository contains `project.yml` and [the native iOS 16 build workflow](../.github/workflows/pots-build-1.yml). On source updates or manual dispatch, GitHub Actions runs XcodeGen, attempts an unsigned simulator build and an unsigned physical-device build, then uploads an IPA artifact **if compilation succeeds**.

An unsigned IPA is not install-ready: it must be signed or installed using a compatible authorized signing workflow. Never commit a signing certificate or password to this public repository.

See [the Build 1 test plan](BUILD_1_TEST_PLAN.md) and [the premium feature roadmap](PREMIUM_FEATURE_ROADMAP.md).


## Approved artwork imported successfully

The [Pots Artwork GitHub Release](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/pots) contains `approved-icon-pack.zip`, SHA-256 `338a9fe79ffd6ac144e31b334cb812c2b815b46f68d9a85bd896df2e91efbc62`.

On November 19, 2026, [the import workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44606165350) completed successfully: it verified the ZIP checksum, checked 13 original PNGs at 1024 × 1024, and committed them to [`POTSTracker/Resources/Icons/`](Resources/Icons/). No substitute art was generated. The Build 1 workflow now creates the Xcode catalog from these originals and refuses missing icons.

**Verified:** Build 1 simulator/device compilation and in-app custom icon rendering on the physical iPhone 16e. **Still to verify:** the Home Screen AppIcon and redesigned v0.1.1 screens, record persistence across upgrade, accessibility and regression tests.


## v0.1.1 "Calm Home" UX revision

See [UX_REDESIGN_V011.md](UX_REDESIGN_V011.md) for actual iPhone screenshot findings, new structure and the physical test checklist. The default is a short Home with one Today card, compact check-in, four pinned shortcuts and three recent records. All 12 categories are now in a grouped **Log** tab; History has week/month/year/lifetime views; More contains customization and safety settings. Home sections and pinned icons can be independently rearranged, hidden or restored. Category pages are pushed rather than presented as tall nested sheets.

This is an interface revision, **not** full Build 2. Hydration, medication, sleep, posture, reminders, PDF/CSV and backup are still future work, with no fee when implemented. The app keeps the existing bundle ID and Core Data schema for an in-place test-device update. Do not delete the installed Build 1 app just to update it, as local data has no backup/export yet.
