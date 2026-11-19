# POTS Tracker: Master Development Checklist

**Companion research and acceptance criteria:** [PREMIUM_FEATURE_ROADMAP.md](PREMIUM_FEATURE_ROADMAP.md). Every listed premium-quality feature remains free when implemented; this checklist tracks actual implementation, not marketing promises.

**As of 2026-11-19:** Build 1 compiled and installed on iPhone 16e; screenshots verify dashboard and feature artwork. Build 1.1 Calm Home redesign is committed, with regression tests and new IPA validation in progress. Do not mark implementation complete without proof. ✅ = verified, ⬜ = to do, ⚠️ = blocked.

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
- [x] All 12 approved feature images visibly rendered in iPhone 16e Build 1 screenshots
- [ ] Verify the app's 13th image (Home Screen icon) and v0.1.1 layout on physical device

## Verified CI Build 1 success (2026-11-19)
- [x] [GitHub Actions run 44606479837](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44606479837) completed **success**
- [x] All 13 approved icons validated and Apple-ready asset catalog produced
- [x] Simulator compile and physical iPhone target compile passed
- [x] Unsigned IPA packaged and uploaded as `POTS-Tracker-Build-1-iOS16-unsigned`, GitHub artifact ID `14569179161` (~34.4 MB artifact archive)
- [ ] Sign and install IPA on a physical iPhone, confirm graphics and CRUD/persistence, complete `BUILD_1_TEST_PLAN.md`

**Warning:** CI build is not a physical-device functional test. This pre-release build lacks backup/restore. Do not store irreplaceable patient records.


## v0.1.1 Calm Home redesign (based on physical iPhone 16e screenshots, 2026-11-19)
- [x] Remove giant introduction and one-screen feature catalog from Home
- [x] Add persistent four-tab navigation: Home / Log / History / More
- [x] Compact Today card with three quick-entry shortcuts and optional check-in strip
- [x] Group all 12 approved feature images in dedicated Log grids
- [x] Replace empty double-sheet category pages with navigation-pushed summary/add/history pages
- [x] Add persistent Home customization: reorder/hide modules, pin/unpin/reorder feature shortcuts, compact/comfortable settings and reset
- [x] Implement data-backed History Week / Month / Year / All views (not fabricated charts)
- [x] Keep Save accessible above the keyboard on manual entry forms
- [x] Preserve existing bundle ID and Core Data schema for in-place upgrades
- [x] Add Home layout regression unit tests and a [real-device QA plan](UX_REDESIGN_V011.md)
- [x] Add GitHub Actions concurrency to supersede outdated build runs
- [ ] Verify v0.1.1 full simulator and device compilation
- [ ] Verify native unit tests execute and pass on a simulator
- [ ] Package unsigned v0.1.1 IPA and inspect its contents
- [ ] Update installed iPhone 16e app **without deleting existing test records**
- [ ] Check screenshot layout, back behavior, tabs, customized Home persistence and keyboard-safe saving
- [ ] Check iOS 16.0 iPhone 14 Pro compatibility and VoiceOver/Dynamic Type

**Release gate:** Build 1.1 is a UI revision, not a claim that Build 2 hydration/medication/sleep features are implemented. No real patient data until backup/restore is functional and tested.


## v0.1.2 Quiet Home and rolling installed version
- [x] Review iPhone 16e v0.1.1 UI screenshots; identify duplicate headings, redundant tiles, empty states and contrast issues
- [x] Shorten Home heading, date row and action area
- [x] Make optional check-in a balanced, smaller 3+2 grid, highlighting the most recent choice
- [x] Hide Recent Activity when there are no entries and reduce pinned shortcut card size
- [x] Keep only the 8 recording-related original icon categories on Log
- [x] Organize review and settings into readable, smaller 2-column More grids with approved artwork
- [x] Remove duplicate History title and redundant empty-record panel
- [x] Read installed app version and build number dynamically from Info.plist on Home and More
- [x] Configure GitHub Actions to increment the bundle build number from \`GITHUB_RUN_NUMBER\`
- [x] Configure CI to verify version, build and stable bundle identifier before packaging IPA
- [x] Add build-metadata tests, screenshot review and [v0.1.2 physical QA plan](UX_REDESIGN_V012.md)
- [ ] Verify v0.1.2 iPhone simulator/device compilation
- [ ] Verify v0.1.2 automatic tests
- [ ] Inspect real v0.1.2 unsigned IPA and packaged Info.plist
- [ ] Sign and install v0.1.2 as an update on physical iPhone 16e
- [ ] Verify actual v0.1.2 screen layout and live installed version/build number
- [ ] Verify persistent records and Home settings survive the upgrade
- [ ] Verify iOS 16 device and all custom artwork remain supported

**App version is not a claim of release readiness:** v0.1.2 is another experimental UI iteration. Medical tracking must remain local and free. There is no reliable export/backup yet, so do not store irreplaceable records.

## v0.1.3 Single-version footer and product-depth checkpoint (iPhone 16e feedback)
- [x] Confirm v0.1.2 build 44 on physical iPhone 16e using screenshots.
- [x] Remove repeated version badge from Home.
- [x] Replace the oversized Installed App information card with one understated More footer showing the real installed version and rolling build number.
- [x] Keep a brief pre-release backup limitation in More; preserve detailed privacy guidance elsewhere.
- [x] Keep all 13 approved icons, original four-tab structure, Home preferences, iOS 16 and Core Data store unchanged.
- [x] Set v0.1.3 and keep automatic CI build-number stamping and IPA identity verification.
- [ ] Verify v0.1.3 GitHub simulator/device compilation, tests and IPA.
- [ ] Verify More is the **only** visible place showing the version on a physical iPhone.
- [ ] Test synthetic symptom, heart-rate, blood-pressure and check-in entries end-to-end, then verify on Home and History after app relaunch.
- [ ] Decide whether to add *conditional*, data-driven Today summaries (latest user-entered reading/episode) rather than add empty decorative widgets.
- [ ] Prioritize functional hydration/medication/rest tracking and tested backup/restore rather than repeatedly redesigning a still-empty history.
- [ ] Accessibility review of empty/filled states in large text, VoiceOver and Low Energy Mode.

**Design assessment:** The clean navigation works on real hardware. What's still missing is useful context after recording, enough completed logging categories, and confidence in end-to-end persistence, not another layer of decorative cards. Never imply the app takes automatic readings or makes medical judgments.


## v0.1.4 final-entry crash regression and grouped swipe history
- [x] Reproduced issue in written device report: 4 check-ins displayed; app exited after deleting final record.
- [x] Replace unsafe EntryCard views holding deleted Core Data managed objects with immutable RecordSnapshot rows.
- [x] Route editor by NSManagedObjectID, resolving object only when editing starts.
- [x] Move destructive confirmation to stable parent History/category view, not disappearing row.
- [x] Add rollback/error handling around deletion.
- [x] Add expandable History tree: date → category → individual entries; all records remain individually accessible.
- [x] Add swipe-right Edit, swipe-left Delete reveal; require confirmation to delete; add tap/context menu/VoiceOver alternatives.
- [x] Replace bulky category history cards with compact grouped swipeable rows.
- [x] Rework Home recent rendering to use safe snapshots.
- [x] Add regression unit tests for deletion of last record, four same-day check-ins and multiple categories/dates.
- [x] Keep current 13 custom icons, local storage paths, bundle ID, iOS 16 minimum and single version footer.
- [ ] Confirm GitHub simulator/device compile and all unit tests pass.
- [ ] Confirm IPA contains v0.1.4, increasing build number, original assets, correct bundle ID.
- [ ] **On physical iPhone:** create 4 entries, delete 4→3→2→1→0 without crashing; cancel delete; edit via swipe; verify all tabs and date grouping.
- [ ] Test repeated navigation, scrolling/gestures, relaunch, and persistence; check Low Energy Mode and VoiceOver.
- [ ] Design **future** grouped notifications/reminders by date/type, with non-noisy opt-in settings; do not mark notifications built.
- [ ] Test entire [v0.1.4 regression plan](UX_REGRESSION_V014.md).

## v0.1.5 Unified status dots & titled check-in notes (iPhone screenshots)
- [x] Confirm grouped History day→category→record behavior on iPhone 16e screenshots, retaining final-record deletion regression.
- [x] Replace oversized, buried Home Recent Activity cards with four small **logged today** indicators for Feeling, Symptoms, Heart rate and Blood Pressure.
- [x] Status dots indicate only whether a category was recorded today, never a clinical reading or health quality.
- [x] Make dots tappable to open relevant forms; keep History as the complete entry list.
- [x] Keep existing Home customization preference IDs; reorder the prior unmodified default layout so dots appear just beneath Today.
- [x] Make Quick Check-in choices open a pre-filled editor rather than instantly recording repeated one-word entries.
- [x] Add editable title, optional note, recorded date/time, explicit Save and Cancel for check-ins.
- [x] Store selected feeling separately from the editable title using existing fields, with backward compatibility for old check-ins.
- [x] Display title, feeling and notes in grouped History; preserve check-in edit/delete action safety.
- [x] Add new check-in format tests and update Home layout/history regression assertions.
- [x] Preserve original icons, iOS 16 minimum, version display once in More, app identifier and Core Data schema.
- [ ] Confirm v0.1.5 device and simulator compilation, IPA packaging and tests.
- [ ] Run entire real-device [v0.1.5 QA plan](UX_V015.md).
- [ ] Validate Save / Cancel / legacy check-in editing / status dot accuracy / last-record deletion on iPhone 16e.
- [ ] Confirm no status dot suggests a medical diagnosis or penalizes missing entries.
- [ ] Confirm notification grouping remains planned, not falsely presented as implemented.

## v0.1.6: responsive swipe and bulk delete (iPhone 16e feedback)
- [x] Preserve correct Feeling dot behavior: it clears after the last recorded feeling is removed.
- [x] Keep check-in Save disabled until a feeling has been chosen; do not change intentional validation.
- [x] Replace finicky per-row drag/hold interaction with consistent full-width quick flicks.
- [x] Make swipe rails fully opaque and labeled, instead of translucent colored overlays on text.
- [x] Swipe individual entry: Edit (right), confirm Delete (left).
- [x] Swipe a category within a day: Open/Close (right), confirm delete whole category (left).
- [x] Swipe a day group: Open/Close (right), confirm delete whole day (left).
- [x] On All History, include a swipe-accessible Clear all action with typed DELETE confirmation.
- [x] Use immutable record IDs and transactional bulk deletes with save/rollback.
- [x] Add tests for deleting a whole day, only one category, all records and duplicate IDs.
- [x] Preserve all artwork, customizable Home, rolling build number in More, native iOS 16 and no Apple Watch.
- [ ] Run GitHub v0.1.6 simulator/device compilation, unit tests and version validation.
- [ ] Verify v0.1.6 IPA and test [v0.1.6 physical iPhone checklist](UX_V016.md).
- [ ] Verify swipe from any horizontal position and natural vertical scrolling without conflict.
- [ ] Verify day/category/all deletion leaves unrelated records intact and never crashes on final deletion.

## v0.1.7: slow clear gestures, OLED black, optional Journal Lock and Apple Health
- [x] Keep working swipe edit/delete and confirmation; remove competing long-press.
- [x] Slow swipe animation to 0.34s, reveal actions only on deliberate drags, tap opens with no action overlay.
- [x] True OLED black dark background, near-black cards, vibrant but accessible teal, preserving original art.
- [x] Optional Face ID/device-passcode Journal Lock, enable/disable authenticated and prompt explained.
- [x] Guard Journal destination, History editing, Home recent titles and grouped History against locked Journal content.
- [x] Require Journal unlock to include private records in full History deletion.
- [x] Explain Journal UI gate is not standalone encryption.
- [x] Add voluntary Apple Health read-only steps, walking distance, flights climbed; no Apple Watch or Health writing.
- [x] Add correct Info.plist descriptions and HealthKit entitlement; no automatic permission prompts.
- [ ] Verify unsigned IPA compiles on iOS 16 with these permissions.
- [ ] Confirm signing profile preserves HealthKit capability; re-signing may need a compatible Apple Developer profile.
- [ ] Test all Face ID/passcode and Apple Health permission flows on actual iPhone.
- [ ] Check swipe/tap separation and true black theme on iPhone 16e.
- [ ] Full [v0.1.7 physical QA checklist](UX_V017.md) including privacy leak and previous delete regressions.
