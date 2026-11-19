# POTS Tracker: Master Development Checklist

**Companion research and acceptance criteria:** [PREMIUM_FEATURE_ROADMAP.md](PREMIUM_FEATURE_ROADMAP.md). Every listed premium-quality feature remains free when implemented; this checklist tracks actual implementation, not marketing promises.

**As of 2026-11-19:** Build 1 source code committed, compilation and device validation outstanding. Do not mark implementation complete without proof. ✅ = verified, ⬜ = to do, ⚠️ = blocked.

## 0. Approved requirements and design
- [x] Native iPhone-first utility, no Apple Watch or wearables
- [x] Free forever core functionality; no subscriptions, ads, premium tier or accounts
- [x] Manual tracking of condition-related experiences; no diagnostic claims
- [x] 7-day tracking + full 365/366-day calendar + unlimited lifetime record
- [x] Ability to record more than one measurement or episode per day
- [x] Bright, coordinated glossy multi-color icon art approved: 1 app + 12 category icons
- [x] Labeled grid-card UI, light/dark theme, fatigue-friendly quick-entry philosophy
- [x] All 13 approved full-resolution PNGs imported to GitHub and validated (GitHub Actions run 44606165350, 2026-11-19)
- [ ] Select public display name after basic trademark/App Store search (POTS Tracker is placeholder)
- [ ] Check accessibility text contrast, Dynamic Type and reduced motion in real UI
- [ ] Identify target family member's device / supported OS when available, without collecting health history

## 1. Repository and iPhone build system
- [x] Create dedicated `POTSTracker/` space within `IPhone-Apps` repo
- [x] Write project requirements and master checklist
- [x] Add SwiftUI Xcode project/configuration targeting **iOS 16+** (source committed)
- [x] **Verify successful Xcode simulator and device builds** (GitHub Actions run 44606479837)
- [ ] Distinct bundle ID / display name / launch icon; verify icon fits Apple's unrounded app icon asset rules (no pre-rounded black margins)
- [x] Commit macOS GitHub Actions workflow for unsigned simulator/device builds and IPA packaging
- [x] **Verify GitHub Action completed successfully and uploaded real unsigned IPA artifact** (run 44606479837; artifact 14569179161); signing outside source control
- [ ] Tests and no-secret CI; no user data or personally identifying logs in artifacts
- [ ] Document Windows 11 + GitHub Actions build and user-signed sideload workflow, no false promise of permanent signing

## 2. Data model and storage
- [x] Implement iOS 16-compatible Core Data SQLite model and local store in source
- [ ] Verify persistence across app termination/reboot/update, migration and backup
- [ ] Each entry has timestamp, timezone context, source/manual flag, optional notes and a stable record ID
- [ ] Symptoms: customizable options, severity 0–10, onset/duration, context, triggers, recovery
- [ ] Heart rate: bpm, posture (supine/sitting/standing), measurement method, time since change
- [ ] Blood pressure: systolic/diastolic, posture, measurement method, optional context
- [ ] Orthostatic observation log: timestamped posture measurements (not automatic diagnosis); user may stop whenever unwell
- [ ] Events: dizziness, near-faint, faint, palpitations, headache, nausea, brain fog, fatigue and custom symptoms
- [ ] Fluids and electrolytes/sodium: optional entry units and food details, no default medical targets
- [ ] Medication schedule and actual taken/skipped records, without dose advice
- [ ] Sleep, rest, activity, meal, temperature/heat context, illness, menstrual-cycle context **optional/off by default** with controls
- [x] Implement multi-entry, backdated entry, edit, confirmed delete and blank-day handling in source
- [ ] Verify all CRUD flows and add an undo mechanism after device testing
- [ ] Storage migration and integrity check; no data loss across upgrades
- [ ] Private app data protection on disk; optional device passcode/biometric lock where available

## 3. Native interface
- [x] Source for main dashboard: quick log, today's summary, seven-day overview and recent logs
- [ ] Next-reminder summary (Build 2); verify dashboard on real iPhone
- [x] Source for 12 accessible labeled feature grid cards using **only the approved custom icons**
- [x] GitHub CI blocks builds when any approved PNG is missing; Xcode image set and Home Screen icon generation are configured
- [x] Verify all 13 original PNG binaries exist under `Resources/Icons` and pass import validation
- [ ] Verify all icon assets render correctly in the built app on a real iPhone
- [x] Source for one-tap daily check-in and low-energy large controls
- [ ] Verify low-energy mode with real-world accessibility testing
- [ ] Fast number keypad with units; do not pretend the phone itself measures HR/BP
- [ ] Readable charts with accessibility table alternatives
- [ ] Light and dark mode, 12-hour clock, readable large text and contrast
- [ ] Proper focus/safe area handling for iPhone screen sizes and keyboards
- [ ] Empty-state guides, save confirmation, error messages and offline behavior

## 4. Calendar, patterns and reports
- [ ] Day view: unlimited entries; 7-day trends
- [ ] 30/31-day months, 365/366-day year, weekly/monthly comparisons, all-time history
- [ ] Backdated record edits; preserve real timestamps; handle travel, DST and leap years
- [ ] Highlight gaps as "Not recorded"; never treat blank as symptom-free
- [ ] Symptom frequency, severity distributions and context comparisons without causal assertions
- [ ] Export selected date ranges as CSV + readable PDF with units, timezone/date and legend
- [ ] Doctor summary with customizable symptoms, medications, measurements and notes
- [ ] Share-sheet export is opt-in and clearly warns reports can reveal private health data
- [ ] Local manual backup + restore with import preview, validation, deduplication and conflict handling
- [ ] No app-imposed history truncation or paid history unlock

## 5. Reminders and safeguarding
- [ ] Local notifications for user-chosen medication, hydration and check-in schedules
- [ ] Reminder controls: snooze, skip, quiet hours, optional neutral lock-screen text
- [ ] App works fully if notification access is denied
- [ ] No automated disease diagnosis, emergency classification or medication/fluid targets
- [ ] Describe limits of manual readings and prompt clinician discussion for persistent/worsening problems
- [ ] Include emergency guidance: severe chest pain, breathing trouble, prolonged fainting or serious injury warrant urgent medical attention
- [ ] Avoid incentivizing over-measurement or streak-based pressure on difficult days

## 6. Quality, privacy and release gate
- [ ] Automated unit tests for storage, units, filtering, leap years, timezone, export math, duplication and import
- [ ] UI test: create, edit, search, delete, restore, restart, airplane mode, low battery, denial of permissions
- [ ] Physical iPhone: 7 consecutive days test data, day rollover, 365-day synthetic history and long-run scrolling
- [ ] Confirm *every* user-visible feature is functional, not mock screens/placeholders
- [ ] No data transmitted to analytics, crash log services or third parties by default
- [ ] Verify 13 images are correctly mapped and not blurry/cropped; confirm launch icon previews
- [ ] Local backup failure and restore conflict tests; no personal data committed to GitHub
- [ ] Final README, changelog, license choice, privacy statement and acknowledgements
- [x] Build 1 unsigned IPA produced by GitHub Actions
- [ ] Build 1 signed, installed and verified on a real iPhone
- [ ] Release only after physical verification and regression tests

## Build increments
- **Build 1:** native shell, asset mapping, Home grid, real local data storage, quick symptom/HR/BP entries and journal, sample-data mode clearly marked
- **Build 2:** medication/fluid/sleep/posture records, local reminders, more accessible low-energy flow
- **Build 3:** full 7-day/month/year charts, doctor PDF/CSV, local backup/restore and quality gates
- **Build 4:** polish, test automation, real-device feedback and public release

**Do not request or expose the family member's medical information in GitHub.**

## Build 1 source handoff
- [x] SwiftUI dashboard, Core Data model, manual entry forms, seven-day history, feature navigation, settings and medical disclaimer committed
- [x] Date-window and Core Data unit tests authored (not yet verified to run)
- [x] XcodeGen configuration and GitHub Actions build pipeline authored
- [x] CI compiler and simulator/device build pass (run 44606479837)
- [x] IPA artifact uploaded on GitHub (artifact 14569179161; 34,400,158 bytes)
- [ ] Download artifact ZIP and inspect contained IPA on local host
- [ ] Signed and installed on test iPhone
- [ ] Device smoke tests pass with synthetic, non-personal entries
- [ ] Confirm original 13 approved PNGs imported into app and actual app icon supplied

## Custom icon correction (2026-11-19)
- [x] Removed generic SF Symbol icon fallback from all 12 feature cards
- [x] Added native Xcode asset-catalog generator for the exact approved PNGs, including Apple-compatible opaque app icon
- [x] Made CI fail fast when the full original asset set is missing
- [x] Locate and import the original archive from the **Pots Artwork** release (`pots` tag, `approved-icon-pack.zip`)
- [x] Verify all 13 high-resolution PNGs committed under `Resources/Icons`
- [ ] Verify all 13 approved images properly display in the built iPhone app

## Verified CI Build 1 success (2026-11-19)
- [x] [GitHub Actions run 44606479837](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44606479837) completed **success**
- [x] All 13 approved icons validated and Apple-ready asset catalog produced
- [x] Simulator compile and physical iPhone target compile passed
- [x] Unsigned IPA packaged and uploaded as `POTS-Tracker-Build-1-iOS16-unsigned`, GitHub artifact ID `14569179161` (~34.4 MB artifact archive)
- [ ] Sign and install IPA on a physical iPhone, confirm graphics and CRUD/persistence, complete `BUILD_1_TEST_PLAN.md`

**Warning:** CI build is not a physical-device functional test. This pre-release build lacks backup/restore. Do not store irreplaceable patient records.
