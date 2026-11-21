# POTS & Posies | Master Roadmap, Decisions, Status and Acceptance Gates

**Canonical roadmap and continuity document** | Last reconciled: 2026-11-20 (America/Phoenix) / 2026-11-21 UTC  
**Project:** [POTSTracker](../POTSTracker/README.md) in [ValentineBSAA/IPhone-Apps](https://github.com/ValentineBSAA/IPhone-Apps)  
**Former long conversation:** “POTS & Posies 0.1.8” (the title is historical; development advanced well beyond 0.1.8).

> **Purpose:** New chats, developers and test runs should read this page FIRST, then inspect the current code/branch and [active handoff](POTS_AND_POSIES_ACTIVE.md). This page records product decisions, completed work, untested work and deferred plans separately. It is a roadmap, not proof that every checkbox has passed. Do not overwrite the original [research-backed free-premium specification](../POTSTracker/PREMIUM_FEATURE_ROADMAP.md), [historical build checklist](../POTSTracker/BUILD_CHECKLIST.md) or [UX test plans](../POTSTracker/UX_V025.md).

## 1. Current baseline and source of truth

| Item | Verified / expected state |
| --- | --- |
| Baseline on main | v0.2.7 / Build 247 (prior physical-device handoff; check actual installed version on device) |
| Latest candidate | v0.2.8, “Premium Guided Care & Native Reminders” |
| Candidate branch | [feature/pots-posies-v0.2.8-premium-care](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.2.8-premium-care) |
| Candidate commit at review | 73dd762e186453e765cb022add377eef6c114592 |
| GitHub CI | [Run 44846154529](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44846154529), **completed SUCCESS** (build, automated tests, package/artifact checks) |
| Installed build identity | Version 0.2.8 with the GitHub run number stamped into the package (Build 270 for this run) |
| Signing/distribution | Unsigned IPA from Actions, then separately signed using a compatible AltStore method |
| Release status | **Pre-release test candidate, NOT physical-device accepted and NOT approved to merge/release as stable** |
| Minimum OS | iOS 16.0, native iPhone SwiftUI |
| Stable bundle ID | com.valentinebsaa.potstracker |
| Approved art | Thirteen original approved floral icons, one app icon plus twelve feature icons, at POTSTracker/Resources/Icons |
| Current local data | Preserve Core Data schema/store, existing app settings, Journal security, and older JSON backup compatibility |

**Verify current GitHub state before every subsequent change.** This dated snapshot is not an assertion that newer builds don't exist. There may be work on both main and the feature branch. Avoid accidental branch resets, premature merges, and claims that CI success equals physical iPhone QA.

## 2. Permanent product contract (owner approved)

- **Useful premium-quality features, free forever**: no subscriptions, trials, ads, in-app purchases, paywalls, forced accounts, or feature time limits.
- **iPhone-only, iPhone-first and offline-first.** Absolutely **no Apple Watch integration, dependency, companion, watch UI or required wearable**. No background watch-derived readings.
- **No HealthKit/Apple Health entitlement in current v0.2.x**: it was deliberately removed after earlier experiments because AltStore signing could not reliably preserve the capability. Do not silently restore it.
- **Manual, user-controlled health records** from separate devices or subjective observations. The iPhone is not a blood-pressure device. The optional camera fingertip pulse experiment must be permission-based, visibly experimental, local and **never diagnostic**.
- **Private by default:** locally stored records; user explicitly chooses whether to export, save to Files/iCloud Drive, or enable any available backup. iCloud Drive appearing in the iOS Files share sheet is not proof that app-managed iCloud sync or automatic backup is functioning.
- **Preserve user data** and original bundle identifier for safe in-place updates. No destructive migration, data reset, auto-deletion of old records, or silent alteration of existing fields.
- **Approved visual language:** soft floral, feminine, calming, premium yet practical; original custom 13-icon set, readable headings and labels, grid-oriented destinations, uncluttered Home, true-black Midnight theme, accessible contrast, large controls and low-energy-friendly workflows. Native iPhone behavior over elaborate animations.
- **Use non-alarming language.** Restore and backup guidance should be reassuring, specific and readable; clearly explain that backups/exports contain sensitive health information and are **not separately encrypted by the app**. Avoid technical/scary red-error copy for normal validation situations.
- **Tap-again-to-deselect:** tapping a selected optional choice, tag, amount, time preset or setting again must clear it. Distinguish true required-field validation from optional controls. Never silently record a selection the user cleared.
- **No medical interpretation or treatment automation:** do not diagnose POTS, infer adherence, prescribe water/sodium targets, classify readings as health judgments, infer an emergency, present missing days as healthy, or use an automatic notification to mark medication taken. Any trends are observational, not causal or medical advice.
- **Never publish sensitive personal health data or JSON backup samples with actual user records** to this public repository.

## 3. Historical completed implementation milestones (code/features, not blanket QA approval)

### Foundation: original Build 1 and v0.1.1 to v0.1.6
- [x] Real local Core Data logging: feelings/check-ins, symptoms, manual heart rate, blood pressure and journal with date/time and multiple records.
- [x] Approved 13 original icons imported and retained; native iOS 16 build; no account requirement.
- [x] Calm/Quiet Home iterations, customizable Home sections and pinned shortcuts, smaller informative “logged today” status dots (not health scores).
- [x] Four-tab root; Log and More destinations use clear icon-led grids. Editable titled Feeling check-ins with optional note, real Save/Cancel.
- [x] History grouping by date → category → record, with gestures and accessible alternatives. Slow deliberate swipe, right edit / left delete; delete confirmation for rows/groups/days/all.
- [x] Crash prevention when deleting the last record: immutable snapshots/IDs, safe persistence, rollbacks and regression coverage.
- [x] Installed version/build shown unobtrusively from Info.plist, not a misleading hard-coded badge.

### Privacy/navigation: v0.1.7 through v0.2.3
- [x] True-black Midnight theme and lighter theme; optional device-authenticated Journal Lock; hide private content when locked.
- [x] Rebrand to **POTS & Posies** while preserving original bundle ID.
- [x] Apple Health/HealthKit removed from the current AltStore-compatible line (previous experimental support is **not** a current requirement).
- [x] Optional local camera fingertip pulse beta with permission-on-use, no false medical claims or automatic reading.
- [x] Journal, Home, History and tab-root navigation behavior improved; earlier privacy and navigation tests retained.

### Functional expansion: v0.2.4
- [x] Local hydration and optional sodium input, medication events, sleep/rest and voluntary posture observations; records can be reviewed and edited.
- [x] Calendar/history and observational 7/30/90/365-day/lifetime reports; empty days remain unknown.
- [x] User-configured local reminder schedules with quiet hours and permission-on-demand.
- [x] User-triggered CSV/PDF reporting and full JSON backup/import with preview, validation and duplicate-ID handling.
- [x] Earlier GitHub compilation/unit test milestone established; new feature acceptance on real iPhone is a separate gate.

### Home, backups and interaction: v0.2.5 through v0.2.7
- [x] Four-page Home carousel: Today / Your week / Daily wellbeing / Coming up.
- [x] Simplified Save Backup via the native Files share sheet, including user-chosen iCloud Drive as a destination.
- [x] Consent-first, entitlement-aware optional app-managed cloud backup behavior; truthful fallback if iCloud capability is unavailable in sideloaded builds.
- [x] More welcoming restore/backup copy, clear sensitive-data warnings and a correction for disabled/untappable Save Backup.
- [x] Richer summaries for medications, rest, sleep and other everyday trackers.
- [x] Tap-selected-option-again-to-clear behavior and regression coverage; actual device acceptance for every context still required.

## 4. v0.2.8 | Current “Premium Guided Care & Native Reminders” candidate

**State:** code committed on the feature branch; [CI passed](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44846154529), including iOS simulator and device builds, automated tests, identity checks and IPA packaging. **Pending physical QA; do not mark complete.**

**Implemented in candidate source, must be tried on-device:**
- [x] Optional **guided manual BP entry**: calm cuff/position guidance, initial and second reading, optional pulse/source/context, display an average where two readings exist; keep raw readings and do not force a second reading or claim diagnosis.
- [x] **Heart-rate guidance/context**: manual source and relevant recording context; no promise of medical accuracy or automatic sensing.
- [x] **Medication cabinet/profiles**: item/name, user-entered label dose/instructions, schedule/refill information and remaining supply; keep actual taken/skipped records separate from planned reminders. Never infer today’s medication was taken just because it was taken before.
- [x] **Optional flare-session context**: symptom/trigger notes, optional vitals, timing and what helped; recording only, not treatment recommendations.
- [x] **Personal hydration preferences**: optional self-chosen target and ounce display without prescribing or defaulting to a medical goal.
- [x] **Richer observational reporting**: BP plotting and medication event summaries/appointment export entry without converting data to diagnoses.
- [x] **Native local notification refinement**: medication, refill, BP, HR, hydration, rest, check-in, journal and personal schedule categories; discreet notification title/body by default, opt-in type label, no medication name or dose on Lock Screen.
- [x] **Local “In 15 minutes” snooze** and quiet-hours behavior; notification permission requested contextually, never mandatory for manual logging.
- [x] **Backward-compatible JSON**: medication cabinet profiles included in opt-in backups without breaking older records and without assuming all old backups have cabinet data.
- [x] Expanded regression tests for vital metadata, paired BP averages, flare validation, medication backup/deduplication and notification privacy.
- [ ] Confirm **all of the above on a physical iPhone**, alongside old records, data restoration, UI appearance and notification delivery.

**Two requested polish passes (scope carried forward from prior feedback; grouped here for QA, not falsely claimed as two separately validated releases):**
- **Polish A | Small interactions and trust:** repeat-tap-to-clear everywhere appropriate; mandatory-field guardrails; friendly restoration states, active Save Backup button, plain-language privacy copy; clear daily status without overloading Home; privacy-safe confirmations.
- **Polish B | Everyday depth and finish:** premium-feeling medication, rest and sleep workflows and useful side features; relevant contextual summaries, meaningful empty/filled states, polished native reminders, clear cross-links to reports and logs, responsive controls and accessibility review.
- [ ] On-device review both passes end to end, note missing depth rather than hiding it under a version bump. A code-level feature is not automatically a finished user experience.

## 5. Remaining roadmap | All free, version targets are planning labels

### Next: v0.2.8 stabilization and physical acceptance (P0)
- [ ] Preserve v0.2.7 data and settings with a **non-destructive, in-place** install using compatible signing identity. Do not uninstall first.
- [ ] Recheck tappable choices in Feeling, symptoms/severity, hydration quantities, medication states, sleep/rest, posture, flare notes, reminders and reversible settings.
- [ ] Verify guided two-reading BP, manual HR details, medication cabinet CRUD, actual medication event history, optional flare context and reports.
- [ ] Verify notification authorization denied/allowed, quiet hours, recurring weekdays, private vs type-revealed copy, real 15-minute snooze, no implicit adherence.
- [ ] Verify Files backup exists and is readable, preview/counts, duplicate-safe import, **older archive compatibility**, new medication profile round trip, protected Journal handling and accurate consented-cloud state.
- [ ] Verify tab routing after Journal lock, all 13 icons, both themes, low-energy readability, VoiceOver/dynamic type/reduce motion, offline relaunch, timestamp/timezone changes, camera cleanup and record persistence.
- [ ] Record user-confirmed physical pass/fail and screenshots before marking v0.2.8 stable or merging to main. Fix on current branch and rerun CI when needed.

### Proposed v0.2.9 | Deeper daily care and refinement (P1; not promised as complete)
- [ ] Medication schedules, refills, “as needed” event history and clear distinctions between **planned / reminded / taken / skipped / not recorded**. Nothing auto-marks a dose as taken.
- [ ] Better medication edit/review/reminder linking and user-set refill tracking; no dosing recommendations or adherence verdicts.
- [ ] Saved hydration drinks and custom quick sizes, unit labels/conversions and optional clinician/user-entered targets **without invented default prescriptions**.
- [ ] More genuinely helpful rest and sleep routines: user-defined presets, optional wake/rest notes, sleep quality/context and easy amendment, no forced collection.
- [ ] Continued guided BP/HR usability tuning, easier record-source labels and optional position/timing context.
- [ ] Friendly coach-mark/onboarding copy explaining privacy, permissions, backups, notifications and medical limitations; all dismissible.
- [ ] Full on-device regression for every feature added; do not claim version complete from CI alone.

### Proposed v0.3.0 | Context, flare history and clinician-ready review (P1/P2)
- [ ] Expand already-started flare recording into a **cohesive session timeline** linking manually chosen symptoms, vitals, posture, possible triggers, rest, medication notes and follow-ups; fully optional.
- [ ] Richer **noncausal** trends across days, times of day and symptoms with transparent sample counts, missing days and limits.
- [ ] Stronger doctor/appointment exports: one-page summary plus optional details, medication changes, manually chosen notes, trend charts, date filters and category privacy preview.
- [ ] Better shortcuts/quick-entry presets and possibly user-configured home actions, without adding complexity to daily logging.
- [ ] Optional personal appointment questions and clinician notes (no automatic clinical interpretation).
- [ ] Accessible long-range calendar/report list alternative, 365/366-day date correctness and export validation with synthetic test data.

### Longer-term: original advanced free-premium backlog (P2, after stability)
- [ ] Custom symptom and measurement trackers with units, schema-safe storage/migration, rename/archive and export support.
- [ ] Optional native vector body map for symptom locations/notes with accessible non-map alternative.
- [ ] Additional optional lifestyle contexts: meals, heat, activity, caffeine, fatigue, brain fog, compression, temperature, menstrual context, personally chosen events. Do not require users to disclose any category.
- [ ] Optional posture observation enhancements, incomplete-session handling and clear stop/cancel; **never** pressure people who feel faint to complete a standing test.
- [ ] Carefully explained pattern comparisons, with denominators, missing-day visibility, limited data caveats and no causal inference or arbitrary clinical scores.
- [ ] Native iPhone Home Screen widgets with **private/neutral default display**; never reveal sensitive content on Lock Screen without express consent.
- [ ] Optional user-authored care-plan notes and tap-to-call personal contact, **no automated emergency detection/messaging**.
- [ ] Optional separately encrypted/passphrase-protected manual backup design, only after cryptographic and restore QA; current backups should be represented accurately as not separately encrypted.
- [ ] Localization as user needs justify; accessibility, contrast, VoiceOver, dynamic text and fatigue-friendly flows remain permanent work.
- [ ] Robust first-run explanation, tutorial, straightforward privacy policy, export/import visibility and informed consent.
- [ ] Public-distribution legal/privacy review including applicable US consumer health app rules. Never assert HIPAA compliance without verification.

**Explicitly out of scope unless the owner reverses a decision:** Apple Watch or wearable integration; HealthKit in the current sideloaded line; account/cloud-login requirements; subscription/premium tiers; auto-generated diagnoses, medication dosing, hydration/sodium prescriptions, emergency alert promises; surveillance/analytics, ads, forced streaks, or hidden data upload.

## 6. Release and regression checklist: every build, no exceptions

- [ ] Compare against **latest main and active branch**; inspect code changes, pending CI, any open PR and this roadmap before editing.
- [ ] Preserve v0.2.x data and backup schema compatibility, stable bundle ID, iOS 16 minimum, exact 13 approved icons, no Apple Watch/HealthKit entitlements.
- [ ] Unit tests: all historic regression suites plus tests for each new feature. Simulator AND unsigned physical iPhone target compilation. Verify app Info.plist version, rolling build and identity, Assets.car/icons and IPA contents.
- [ ] Verify no new path implies automatic medication administration, diagnoses, invented patient data or mandatory health permissions.
- [ ] Provide unsigned IPA only after GitHub artifacts exist; label clearly **unsigned / requires signing**. No hardcoded or fake sandbox download links.
- [ ] Get actual physical iPhone testing before stable release; capture fail/pass and fix failures. Never claim TestFlight/App Store acceptance, successful AltStore signing, notification delivery or iCloud entitlement merely from CI.
- [ ] Update this master roadmap, [active handoff](POTS_AND_POSIES_ACTIVE.md), [build checklist](../POTSTracker/BUILD_CHECKLIST.md) and relevant UX test plan with what changed and what is still pending.
- [ ] Do not add private medical records, device logs with personally identifying data, backups, Apple certificates, secrets or provisioning keys to GitHub.

## 2026-11-20 follow-up: v0.2.9 Daily Care implementation started

- **Newest development branch:** [feature/pots-posies-v0.2.9-daily-care](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.2.9-daily-care), built from the successful 0.2.8 commit.
- **Draft review:** [PR #52](https://github.com/ValentineBSAA/IPhone-Apps/pull/52) against 0.2.8 so that changes remain isolated.
- **CI workflow:** [run 44848307666](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44848307666) **completed SUCCESS**, Build 272. GitHub artifact ID 14684427221 exists. The extracted unsigned IPA was independently zip-integrity-checked: version 0.2.9, bundle build 272, app ID `com.valentinebsaa.potstracker`, min iOS 16.0, Assets.car present. **User subsequently reported all the v0.2.9 functions checked on their iPhone were working (specific edge-case QA still separate).**
- **Candidate code implemented:** four adjustable hydration quick amounts and four independently adjustable rest/sleep durations, cancellable/resettable settings, tap-again-to-clear, medication cabinet last explicitly recorded event, manual medication logging shortcut, prevention of dismissing a medication profile on failed Save, separate sleep/rest totals and medication status counts without assumed adherence.
- **New tests and physical QA:** `POTSTracker/Tests/PosiesDailyCareTests.swift` and [v0.2.9 test plan](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/pots-posies-v0.2.9-daily-care/POTSTracker/UX_V029.md).
- **Not implemented yet:** full medication schedule automation, custom lifestyle tracker schema, advanced observational comparisons, encrypted backup, widgets and clinician appointment workflow; retain them in the roadmap. The user later reported v0.2.9 physical checks worked; a redesign of the medication cabinet remains to be tested. Do not automatically treat previously untested edge cases as verified.

## 2026-11-20 user feedback: v0.2.9 physical success and v0.2.10 reference-library redesign

- **User report:** on a real iPhone, user checked the v0.2.9 features and said “I've checked everything it works.” Their medication-cabinet screenshot shows a previously saved Ibuprofen profile and the overly tall introductory card. Respect this as **user-reported working behavior**, not proof of every untested edge case; avoid rebuilding validated functionality.
- **Requested refinement:** the current cabinet is too bare bones. Replace its bulky repeated header, add a large organized medication library, familiar generic and brand names, explanatory labels, short safety cautions and links to full authoritative drug labeling.
- **New v0.2.10 source:** [feature/pots-posies-v0.2.10-medication-library](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.2.10-medication-library); [draft PR #65](https://github.com/ValentineBSAA/IPhone-Apps/pull/65) targets v0.2.9.
- **Code committed:** 159 offline searchable generic names across 11 browsing categories, brand aliases, curated brief cautions with 17 direct reviewed NIH MedlinePlus links plus FDA/NLM DailyMed. Existing profile names can match exactly for safety notes without any data rewrite. Search/chip filters and compact two-column cabinet/shortcut layout replace the current crowded screen.
- **Medical safety contract:** no medication database is comprehensive, no automatic dose, strength, schedule, intake or refill deduction; no POTS treatment recommendations. Full current warnings and interactions are on official drug labels; this app offers *short orientation only*. A preset creates a blank user-editable draft, not a real medication event.
- **Source references:** [MedlinePlus](https://medlineplus.gov/druginformation.html), [DailyMed](https://dailymed.nlm.nih.gov/dailymed/), [FDA drug information](https://www.fda.gov/drugs/information-consumers-and-patients-drugs/find-information-about-drug). Recognized brands/formulations can vary by country and over time; user must verify exact product.
- **CI:** [v0.2.10 Actions run 44865791186](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44865791186) is the newest source build at this handoff; earlier compile diagnostics exposed a Swift URL-type error that has been corrected at commit `665230dd2f2e9707b6f1591e7f232eac41718946`. **Do not claim a passing or downloadable IPA without checking the latest conclusion/artifact.** Physical iPhone QA for this redesigned screen is still pending. [Detailed checklist](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/pots-posies-v0.2.10-medication-library/POTSTracker/UX_V0210.md).
- **Remaining roadmap:** clinician-ready exports, custom trackers, richer rest/med routines, encrypted backups, careful noncausal insights, optional privacy-safe widgets remain planned. No loss of earlier decisions or Watch/HealthKit exclusions.

## 2026-11-20 update | Next version locked to v0.3.0

- **v0.2.10 Build 282 is complete:** [GitHub Actions run 44865791186](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44865791186) finished SUCCESS. Unsigned IPA artifact ID **14691489567** is available. The ZIP archive and IPA were independently verified: CFBundleShortVersionString **0.2.10**, CFBundleVersion **282**, ID `com.valentinebsaa.potstracker`, minimum iOS **16.0**, Assets.car present. This is **automated build and package acceptance**, not proof of physical iPhone medication-catalog QA.
- **User explicitly chose v0.3.0 next**, skipping 0.2.11. This is a semantic version decision and must not be silently reverted in later chats.
- **New next-development branch:** [feature/pots-posies-v0.3.0-next-milestone](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.3.0-next-milestone), based on the completed v0.2.10 code. The version transition commit `9aa7c9ae93c995dda9f5fba393e0527949c4d3c6` updates `POTSTracker/project.yml` to marketing version **0.3.0** and the GitHub Actions workflow name, validation and unsigned IPA naming to **v0.3.0**.
- **Draft PR #69:** [v0.3.0 next milestone](https://github.com/ValentineBSAA/IPhone-Apps/pull/69) targets v0.2.10. It is deliberately **draft and unmerged**. The initial v0.3.0 commit is **version-only/technical preparation**. Do not claim that planned 0.3.0 enhancements have been implemented yet.
- **Initial v0.3.0 baseline CI:** [run 44868132574](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868132574) was running when the handoff was written. Verify its outcome before promising a v0.3.0 download; a successful smoke-test build is not a complete feature release.
- **Future version scope:** continue the original v0.3.0 plan for optional flare timelines, careful noncausal pattern reviews, appointment/clinician export improvements, low-energy accessibility and thorough non-destructive physical QA. See [v0.3.0 acceptance plan](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/pots-posies-v0.3.0-next-milestone/POTSTracker/UX_V030.md).
- **Protected continuity:** keep the successful v0.2.10 artifact/branch intact, same app ID, private local records and older JSON backup compatibility, no Apple Watch/HealthKit, all-free features and original approved 13 icons. Physical iPhone testing of v0.2.10 medication-library redesign remains separately pending unless user confirms otherwise.

## 7. Links and archival references

- [Active handoff](POTS_AND_POSIES_ACTIVE.md)
- [Original extensive free-premium research and four-build acceptance specification](../POTSTracker/PREMIUM_FEATURE_ROADMAP.md)
- [Full historical build/checklist](../POTSTracker/BUILD_CHECKLIST.md)
- [App README and feature history](../POTSTracker/README.md)
- [v0.2.4 physical-device regression plan](../POTSTracker/UX_V024.md)
- [v0.2.5 physical-device regression plan](../POTSTracker/UX_V025.md)
- [Current v0.2.8 source branch](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.2.8-premium-care)
- [Current v0.2.8 CI run](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44846154529)
- [Approved original icon archive](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/pots)

## 8. Continuity protocol for the next chat

1. Read **this document and the active handoff** before proposing features or a build; do not go back to the 0.1.8-era scaffold.
2. Fetch fresh GitHub branch/CI/PR state, review actual source and outstanding QA. Treat version labels and this dated status as snapshots.
3. Resume the **latest v0.2.10 medication cabinet build/test loop** unless a newer accepted build exists; v0.2.9 was user-reported working. Retain **all previously approved design, data, privacy and interaction decisions**.
4. Move verified work from “candidate/awaiting physical QA” to “device accepted” only on evidence; keep deferred plans visible and never quietly drop features.
5. If older chat details are unavailable, preserve what's documented and mark any reconstruction or newly proposed enhancement as such. Never invent approval, testing or implementation.

**Latest CI note (2026-11-20 Phoenix):** v0.2.10 simulator and unsigned iPhone source compiled successfully in run 281, but a stale CI source-function grep failed after the refactor. It was fixed in commit `ce3217c224c82121ebe628c84240044e7fdea1d1`. Latest replacement CI is [run 282](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44865791186). Check the **conclusion and actual artifact** before describing an installable build; physical QA of the redesigned screen remains open.
