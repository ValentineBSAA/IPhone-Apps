# POTS Tracker: Master Development Checklist

**Companion research and acceptance criteria:** [PREMIUM_FEATURE_ROADMAP.md](PREMIUM_FEATURE_ROADMAP.md). Every listed premium-quality feature remains free when implemented; this checklist tracks actual implementation, not marketing promises.

**As of 2026-11-19:** planning only. Do not mark implementation complete without proof. ✅ = verified, ⬜ = to do, ⚠️ = blocked.

## 0. Approved requirements and design
- [x] Native iPhone-first utility, no Apple Watch or wearables
- [x] Free forever core functionality; no subscriptions, ads, premium tier or accounts
- [x] Manual tracking of condition-related experiences; no diagnostic claims
- [x] 7-day tracking + full 365/366-day calendar + unlimited lifetime record
- [x] Ability to record more than one measurement or episode per day
- [x] Bright, coordinated glossy multi-color icon art approved: 1 app + 12 category icons
- [x] Labeled grid-card UI, light/dark theme, fatigue-friendly quick-entry philosophy
- [ ] Exact approved 13 full-resolution PNGs imported to GitHub and validated (**must not mark done from a ZIP manifest alone**)
- [ ] Select public display name after basic trademark/App Store search (POTS Tracker is placeholder)
- [ ] Check accessibility text contrast, Dynamic Type and reduced motion in real UI
- [ ] Identify target family member's device / supported OS when available, without collecting health history

## 1. Repository and iPhone build system
- [x] Create dedicated `POTSTracker/` space within `IPhone-Apps` repo
- [x] Write project requirements and master checklist
- [ ] Add SwiftUI Xcode project/configuration targeting **iOS 16+**, validate simulator and real device
- [ ] Distinct bundle ID / display name / launch icon; verify icon fits Apple's unrounded app icon asset rules (no pre-rounded black margins)
- [ ] GitHub Actions macOS build with exported unsigned IPA artifact if supported; signing outside source control
- [ ] Tests and no-secret CI; no user data or personally identifying logs in artifacts
- [ ] Document Windows 11 + GitHub Actions build and user-signed sideload workflow, no false promise of permanent signing

## 2. Data model and storage
- [ ] Local persistent database using iOS 16-compatible technology (Core Data or SQLite; avoid SwiftData's iOS 17 minimum)
- [ ] Each entry has timestamp, timezone context, source/manual flag, optional notes and a stable record ID
- [ ] Symptoms: customizable options, severity 0–10, onset/duration, context, triggers, recovery
- [ ] Heart rate: bpm, posture (supine/sitting/standing), measurement method, time since change
- [ ] Blood pressure: systolic/diastolic, posture, measurement method, optional context
- [ ] Orthostatic observation log: timestamped posture measurements (not automatic diagnosis); user may stop whenever unwell
- [ ] Events: dizziness, near-faint, faint, palpitations, headache, nausea, brain fog, fatigue and custom symptoms
- [ ] Fluids and electrolytes/sodium: optional entry units and food details, no default medical targets
- [ ] Medication schedule and actual taken/skipped records, without dose advice
- [ ] Sleep, rest, activity, meal, temperature/heat context, illness, menstrual-cycle context **optional/off by default** with controls
- [ ] Multi-entry per day, edit/backfill, deletion + confirmation/undo; no fabricated zero readings
- [ ] Storage migration and integrity check; no data loss across upgrades
- [ ] Private app data protection on disk; optional device passcode/biometric lock where available

## 3. Native interface
- [ ] Main dashboard: quick log, today's summary, 7-day calendar, recent logs and next reminders
- [ ] Grid views for all 12 features with approved image, text label and accessible tap targets
- [ ] Single-tap low-energy mode with big controls and minimal typing
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
- [ ] Build 1 IPA produced, installed and verified on a real device
- [ ] Release only after physical verification and regression tests

## Build increments
- **Build 1:** native shell, asset mapping, Home grid, real local data storage, quick symptom/HR/BP entries and journal, sample-data mode clearly marked
- **Build 2:** medication/fluid/sleep/posture records, local reminders, more accessible low-energy flow
- **Build 3:** full 7-day/month/year charts, doctor PDF/CSV, local backup/restore and quality gates
- **Build 4:** polish, test automation, real-device feedback and public release

**Do not request or expose the family member's medical information in GitHub.**
