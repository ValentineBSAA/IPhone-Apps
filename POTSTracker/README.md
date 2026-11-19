# POTS Tracker (working title)

**Status:** pre-build planning and approved artwork stage. No executable app has been built yet.

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

Track progress in [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md) and GitHub Issues.

No personal medical details, test logs containing identifying health data, credentials or backups belong in this public repository.
