# POTS & Posies — current development handoff (2026-11-20)

> **Authoritative handoff for continuing the full original POTS & Posies chat**. The conversation formerly called “POTS & Posies 0.1.8” advanced well beyond that version. Do not reset to 0.1.8 or discard v0.2.x work.

**START HERE:** [Complete master roadmap and all agreed future features](POTS_AND_POSIES_MASTER_ROADMAP.md). It includes the long-term free-premium backlog, versioned plan, polish passes, immutable decisions and physical QA gates.

## Where we are
- Repository: `ValentineBSAA/IPhone-Apps`.
- Source: `POTSTracker/`.
- Baseline on `main`: **v0.2.7, GitHub build 247**, per latest prior-device handoff.
- **Active next build:** v0.2.8 "Premium Guided Care & Native Reminders" on branch `feature/pots-posies-v0.2.8-premium-care`.
- GitHub Actions workflow: `.github/workflows/pots-build-1.yml`. Active pipeline when this handoff was authored: [run 270](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44846154529), source SHA `73dd762e186453e765cb022add377eef6c114592`. At the latest verified check, [CI run 270](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44846154529) **completed successfully**, including the build and automated tests. Physical-device acceptance is still required; always recheck the latest GitHub state before making release claims.
- Build is unsigned; must be signed with an authorized compatible AltStore method. Build success is not physical-device acceptance.

## Immutable project constraints
1. Native SwiftUI **iPhone-first**, **iOS 16.0 minimum**, stable bundle ID `com.valentinebsaa.potstracker` for in-place upgrades. Never delete the installed app to update; preserve its Core Data store, preferences, and legacy backup compatibility.
2. Free, no advertising, purchases, subscriptions or account. No Apple Watch support, dependency, integration or watch UI. No HealthKit entitlement in current AltStore-compatible v0.2.x builds (intentionally removed after early experiments). Experimental fingertip pulse is voluntary and not diagnostic; never imply an iPhone measures blood pressure.
3. Preserve the **13 original approved floral PNG assets**, imported from the release tagged `pots`. Do not generate replacements or change approved filenames.
4. Soft, feminine, approachable, readable presentation, accessible contrast and Midnight true-black theme. Grid-oriented navigation and friendly copy, not clinical or technical warnings. Four-tab root navigation must never inherit stale Journal navigation state.
5. Manual tracking and raw observations, not diagnosis, alerts about emergencies, treatment advice, inferred medication administration, enforced hydration targets, or assumptions that missing days equal healthy days.
6. Personal health records are private. Default local storage; voluntary share/export only. Show understandable warnings that exported JSON, PDF and CSV files contain sensitive health details and are **not separately encrypted by the app**. Do not commit real medical records or private backup examples to this public repo.
7. User specifically requires selected quick-choice tiles, severity/amount chips, multi-choice tags and relevant settings to **deselect when tapped again**. Preserve selection validation for truly required data and safe fallback for mandatory settings.

## Working milestones that must not regress
- v0.1.x: user-approved floral art, quiet Home and 2-column navigation, real local storage, themed layouts, labeled/slow History swipe right=edit/left=delete with confirmation, safe final-item/group/bulk deletion, titled Feeling check-ins, Home logged-today dots, customizable layout, Journal Lock and privacy suppression.
- v0.2.0-v0.2.3: rebrand to POTS & Posies, no HealthKit entitlement for AltStore, user-friendly routing, camera pulse beta with camera permission only on request, intact iOS16 and stable bundle identity.
- v0.2.4: actual edit/save for hydration, medications, sleep/rest and posture, manual symptoms/HR/BP, calendar, 7/30/90/365-day and lifetime observational reports, permission-based local reminders, offline PDF/CSV/full JSON import/export with duplicate-safe restore preview.
- v0.2.5: four-page Today/Your week/Daily wellbeing/Coming up swipe Home carousel; simple native Save to Files → iCloud Drive share sheet, advanced exports tucked away, truthful backup states. **Automatic app-managed iCloud backup only after explicit consent and only if entitled; current AltStore signing usually lacks iCloud Documents entitlement.** Never claim an iCloud server sync merely because a local write succeeded.
- v0.2.6: reduce scary backup/import error copy, make Save Backup tappable, improve personalized tracker summaries/rest/medications/sleep.
- v0.2.7: tap-again-to-clear options and settings; maintain safe defaults and all earlier polished backup flows.
- v0.2.8 candidate: guided optional BP paired readings/average/source and HR context; optional flare-session notes, improved medication profile cabinet (label dosing, schedule, refill notes and remaining supply without predicting adherence); more helpful reports and personalized hydration display; additional on-device reminders for medication, refills, BP, HR, hydration, rest, check-in, journal, personal; opt-in notification type labels and default discreet privacy mode; local **“In 15 minutes” snooze**; no automatic medication logging, diagnosis, prescriptive targets or private dosage text on Lock Screen. Backup format remains backward-compatible and includes medication profiles.

## Open acceptance gates
- [ ] Confirm run 270 ends **success** including ALL unit tests, compilation, icon validation, metadata (v0.2.8 build number), unsigned IPA upload; if failed, inspect failing step/logs, fix on the **same feature branch**, rerun and use the new artifact rather than an older build.
- [ ] Sign via AltStore-compatible process using same bundle identifier/signing context, install **over** v0.2.7 on actual iPhone, and confirm all previous sample records, settings, Journal lock, Home layout and all 13 icons survive. Never claim tested until user confirms.
- [ ] Check every clear-on-second-tap selection across Feeling, quick hydration amounts, medication statuses, sleep/rest durations, severity, posture, reminders, settings; a cleared optional choice must not create a record.
- [ ] Test BP paired measurements, optional HR context, flare sessions, medication cabinet add/edit/delete, medicine log/history/refill, quiet hours, permission-denied reminders, privacy mode, notification snooze and that notifications **never** imply a dose was taken.
- [ ] Test manual backup can be created and saved in Files, data counts match archive, restore preview is human-friendly, existing IDs skip duplicates, medication cabinet profiles round-trip, private Journal gate works and confidential data warnings remain visible.
- [ ] Smoke test reports, 365-day history, both themes, navigation after Journal, voiceover/reduce motion, offline re-launch, low battery and camera flashlight cleanup.
- [ ] Keep new version an **experimental build** until physical QA passes. Do not merge to `main` prematurely or promise automatic iCloud sync under AltStore.

## Useful links
- [v0.2.8 feature branch](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.2.8-premium-care/POTSTracker)
- [v0.2.8 CI run 270](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44846154529)
- [Existing features and QA history](../POTSTracker/BUILD_CHECKLIST.md)
- [v0.2.5 device QA plan](../POTSTracker/UX_V025.md)
- [Complete master roadmap and cross-chat decisions](POTS_AND_POSIES_MASTER_ROADMAP.md)
- [Premium feature roadmap](../POTSTracker/PREMIUM_FEATURE_ROADMAP.md)

## Next-chat instruction
Read this handoff and **fetch latest branch and workflow state from GitHub first**. Do not assume the older chat title means v0.1.8 is the working version. Continue the current v0.2.8 test/fix loop, preserving all approved previous work. After device feedback, increment the semantic version for the following build and keep QA and handoff updated.

## Newer staged work: v0.2.9 (do not skip physical QA)

- Source branch: [feature/pots-posies-v0.2.9-daily-care](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.2.9-daily-care); [draft PR #52](https://github.com/ValentineBSAA/IPhone-Apps/pull/52) targets the v0.2.8 branch.
- Code adds adjustable hydration/rest shortcuts, recent manual medication status in cabinet, safer profile saving, separate rest/sleep totals and new tests. [v0.2.9 physical QA plan](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/pots-posies-v0.2.9-daily-care/POTSTracker/UX_V029.md).
- [GitHub Actions run 44848307666](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44848307666) **completed SUCCESS**. GitHub artifact `POTS-and-Posies-v0.2.9-iOS16-unsigned` (artifact ID `14684427221`), Build 272. The unsigned IPA was separately inspected and verified: v0.2.9, Build 272, correct `com.valentinebsaa.potstracker` ID, iOS 16.0 minimum and present Assets.car. **Physical iPhone acceptance remains outstanding.** Neither v0.2.8 nor v0.2.9 should be called physically verified merely because GitHub CI passed.
- Do not accidentally reset from v0.2.9 to 0.1.8, or merge draft candidates into main before physical QA.

## Current next milestone: v0.2.10 Medication Reference Library

- User confirmed that everything checked on v0.2.9 worked on their iPhone; their screenshot shows a saved Ibuprofen profile but a tall, bare-bones medication cabinet. This is **user-reported physical QA**, not independently validated edge cases.
- [Development branch](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.2.10-medication-library) and [draft PR #65](https://github.com/ValentineBSAA/IPhone-Apps/pull/65) introduce a compact grid-first cabinet, 159 searchable generic medication names across 11 categories, brand aliases, concise safety notes, and official MedlinePlus/DailyMed links. The library is offline and informational only. No automatic doses/schedules/intake, diagnostic treatment suggestions, or background health collection.
- [Build run 44865791186](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44865791186) is the current candidate after correcting a compile error in the earlier medication link source. Check completion, unit tests and actual IPA before sending download links. New physical QA is required for this redesign.
- [Physical iPhone QA](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/pots-posies-v0.2.10-medication-library/POTSTracker/UX_V0210.md) includes generic/brand search, category tiles, official link-out, draft with blank dose/schedule, existing profile and backup preservation, privacy, medication event status, accessibility and themes.
- **Never copy a library warning into personal medical instructions or confuse brief source-derived cautions with complete product labeling.** Existing old backups and medication events are preserved.

**Latest CI note (2026-11-20 Phoenix):** v0.2.10 simulator and unsigned iPhone source compiled successfully in run 281, but a stale CI source-function grep failed after the refactor. It was fixed in commit `ce3217c224c82121ebe628c84240044e7fdea1d1`. Latest replacement CI is [run 282](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44865791186). Check the **conclusion and actual artifact** before describing an installable build; physical QA of the redesigned screen remains open.
## 2026-11-20 update | Next version locked to v0.3.0

- **v0.2.10 Build 282 is complete:** [GitHub Actions run 44865791186](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44865791186) finished SUCCESS. Unsigned IPA artifact ID **14691489567** is available. The ZIP archive and IPA were independently verified: CFBundleShortVersionString **0.2.10**, CFBundleVersion **282**, ID `com.valentinebsaa.potstracker`, minimum iOS **16.0**, Assets.car present. This is **automated build and package acceptance**, not proof of physical iPhone medication-catalog QA.
- **User explicitly chose v0.3.0 next**, skipping 0.2.11. This is a semantic version decision and must not be silently reverted in later chats.
- **New next-development branch:** [feature/pots-posies-v0.3.0-next-milestone](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.3.0-next-milestone), based on the completed v0.2.10 code. The version transition commit `9aa7c9ae93c995dda9f5fba393e0527949c4d3c6` updates `POTSTracker/project.yml` to marketing version **0.3.0** and the GitHub Actions workflow name, validation and unsigned IPA naming to **v0.3.0**.
- **Draft PR #69:** [v0.3.0 next milestone](https://github.com/ValentineBSAA/IPhone-Apps/pull/69) targets v0.2.10. It is deliberately **draft and unmerged**. The initial v0.3.0 commit is **version-only/technical preparation**. Do not claim that planned 0.3.0 enhancements have been implemented yet.
- **Initial v0.3.0 baseline CI:** [run 44868132574](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868132574) was running when the handoff was written. Verify its outcome before promising a v0.3.0 download; a successful smoke-test build is not a complete feature release.
- **Future version scope:** continue the original v0.3.0 plan for optional flare timelines, careful noncausal pattern reviews, appointment/clinician export improvements, low-energy accessibility and thorough non-destructive physical QA. See [v0.3.0 acceptance plan](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/pots-posies-v0.3.0-next-milestone/POTSTracker/UX_V030.md).
- **Protected continuity:** keep the successful v0.2.10 artifact/branch intact, same app ID, private local records and older JSON backup compatibility, no Apple Watch/HealthKit, all-free features and original approved 13 icons. Physical iPhone testing of v0.2.10 medication-library redesign remains separately pending unless user confirms otherwise.


## v0.3.0 premium medication cabinet | New implementation pass (2026-11-20)

- **Owner request:** v0.2.10 medication cabinet still feels too manual. Clean it up and add dropdown-based choices, real *user-entered* medication label strength units (mg, mcg, g, IU, mEq, etc.), clear medication forms, frequency, remaining bottle inventory and US measurement presentation. Medication-themed custom icon generation is temporarily unavailable, so use built-in SF Symbols rather than blocking code work.
- **Implementation branch:** [feature/pots-posies-v0.3.0-next-milestone](https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/pots-posies-v0.3.0-next-milestone), [draft PR #69](https://github.com/ValentineBSAA/IPhone-Apps/pull/69). Source commits `93a68b4a3f46a57ef80384bf681d96a255c3b0f1` and compatibility fix `12b3fdf2e42dc51d10ccbd5b3703b64d964b4de6`.
- **Implemented:** optional structured strength and unit, medicine form selection, user-provided schedule, remaining quantity and selectable inventory units (including US fl oz for container inventory only), refill date, collapsible directions/notes, a compact bottle preview and readable two-column saved-cabinet cards. Unit/form/schedule menus can be cleared. No generated bottle artwork yet.
- **Critical safety rule:** do not infer medication dosage from the 159-name reference catalog, or infer `mg` from an older text value like `400`. Never automatically assign directions, dispense, calculate dosage, decrement supply or mark an entry taken. Oral-liquid dosing is represented in **mL**, not US fluid ounces, teaspoons, or tablespoons; US fl oz only describes *bottle inventory*. Resource: [NCPDP FDA-hosted medication labeling guidance](https://www.fda.gov/media/88498/download).
- **Data guarantees:** new fields are OPTIONAL Codable members on existing profile, preserving legacy `labelDose` and `remainingSupply` values, including zero. Core Data schema, backup format, 13 approved images, stable ID `com.valentinebsaa.potstracker`, iOS 16 minimum, offline model and no Apple Watch/HealthKit integration remain unchanged.
- **Tests:** `POTSTracker/Tests/PosiesMedicationCabinetPolishTests.swift` checks old-profile decoding, structured round-trips, numeric and unit validation, catalog draft non-prescribing, and US fl oz inventory selection.
- **Latest candidate CI:** [run 44868754092](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868754092) started after the latest code update. Check actual result and unsigned IPA before calling a build ready. No v0.3.0 device approval yet.
- **Still on the v0.3.0 roadmap:** optional flare timelines, transparent noncausal patterns, clinician exports, advanced low-energy UI and physical QA. This is a cabinet polish increment, not a claim those features were completed.

## v0.3.0 Build 285 automated acceptance (2026-11-20 Phoenix)

- [GitHub Actions run 44868754092](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868754092) **completed SUCCESS** at commit `12b3fdf2e42dc51d10ccbd5b3703b64d964b4de6`, including simulator/iPhone builds, regression tests and unsigned IPA package. Artifact ID `14692729730` (`POTS-and-Posies-v0.3.0-iOS16-unsigned`) is available.
- Unsigned IPA was extracted and ZIP integrity verified. Actual `Info.plist` confirms `CFBundleShortVersionString=0.3.0`, `CFBundleVersion=285`, `CFBundleIdentifier=com.valentinebsaa.potstracker`, `MinimumOSVersion=16.0`; `Assets.car` and app icon present. The delivered direct IPA is `POTS-and-Posies-v0.3.0-build285-unsigned.ipa`.
- **Still pending:** real iPhone QA for structured medication strength/units, container/form/schedule dropdown, decimal bottle inventory, cancelling and editing, old saved Ibuprofen `400` without inferred `mg`, JSON backup/restore, reminders, official safety links, themes/VoiceOver, and data persistence. Build success does not equal physical acceptance.
- **Not yet part of the build:** planned v0.3.0 flare timeline, clinician export and advanced noncausal trends. Do not merge draft PR #69 or label feature milestone stable until developed and tested.
