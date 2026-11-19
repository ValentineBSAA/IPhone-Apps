# v0.1.2: Quiet Home and verified installed build identity

**Source update:** November 19, 2026
**Basis:** iPhone 16e screenshots of v0.1.1 (Home, Log, History Week/Month/Year/All, More).
**Stage:** UI polish to the working Build 1 tracking foundation; this is not the medical-feature Build 2.

## Verified observations from the screenshots

- Four native tabs and the original colorful feature icons work on the real iPhone and are a clear improvement over the original one-page dashboard.
- Home still repeats a large greeting/headline after the native title and spans several distinct sections, even with no entries.
- The empty Recent Activity block adds visual noise before there are records.
- Five check-in options are scattered over an unbalanced 3+2 grid with no indication of the latest selection.
- The Log tab redundantly includes Calendar, Reports, Reminders and Settings, even though History and More exist.
- History repeats "History / Your history" before the range selector; empty week/month/year/all views have a second large empty record card.
- More has full-width low-contrast long tiles and a giant hard-coded "Build 1" statement instead of the exact installed app version.
- **Not app UI:** the floating gray chevron along the right screen edge is not identified as a component of POTS Tracker by the screenshots; do not change app code to remove it without proof.
- No real data was displayed in these screenshots. They confirm visual layout and navigation, **not** successful saved-entry persistence.

## Implemented v0.1.2 design

- **Home:** compact date row + small exact installed version/build label; single Today card with Add an entry and three quick-log actions; balanced optional check-in strip with latest-entry feedback; pinned shortcut 2×2 grid with smaller tiles; Recent Activity only after there are actual entries.
- **Log:** only recording workflows, in 2-column grids: Track now (Symptoms, Heart Rate, Blood Pressure, Journal) and Daily support (Hydration, Medications, Sleep, Posture). No repeated Calendar/Settings tiles.
- **History:** eliminate duplicate headings and large empty-data card; preserve all real Week/Month/Year/All navigation and timestamps. A blank day is always unrecorded, never presumed symptom-free.
- **More:** compact two-column grouped tiles. Home customization + original Settings artwork under Personalize; original Calendar, Reports, Reminders artwork + Privacy under Review & tools. Dark readable labels replace pale teal navigation text.
- **Version visibility:** Home displays \`v0.1.2 · N\`, and More displays the **actual installed** version/build from Info.plist. This works offline and does not misrepresent an automatic update check.
- **Build number:** GitHub Actions sets \`CURRENT_PROJECT_VERSION=$GITHUB_RUN_NUMBER\` during both device and simulator compilation; checks the packaged app's actual \`CFBundleVersion\`, \`CFBundleShortVersionString\` and stable bundle ID before packaging.
- **Compatibility:** preserve bundle ID \`com.valentinebsaa.potstracker\`, iOS 16+ deployment minimum, Core Data schema and storage paths. All 13 approved graphics remain mandatory.

## Physical iPhone regression checklist

- [ ] Open Home on iPhone 16e; the date and small version/build label are readable in the first screenshot.
- [ ] Home is meaningfully shorter than v0.1.1, with no giant duplicated heading.
- [ ] With zero entries, Recent Activity does **not** add a wasted empty section.
- [ ] Try all five check-in options. A tap saves once, the selection indicator follows the latest record, and total entry count updates.
- [ ] Pinned shortcuts show the four original approved icons and readable labels with no truncation or clipping.
- [ ] Log has 8 tracker tiles, grouped into Track now and Daily support. Review-only destinations have moved to More.
- [ ] More shows Customize Home, Settings, Calendar, Reports, Reminders, Privacy and an Installed App version/build line.
- [ ] Compare Home and More build labels: both show the exact same version/build number.
- [ ] Build number increases after a newer GitHub Actions build and installed signed update.
- [ ] Check Home customization still reorders/hides/restores sections and persists after relaunch.
- [ ] Week / Month / Year / All history retains navigation, real entries and an uncluttered empty state.
- [ ] Test adding, editing, deleting, cancelling and backdating synthetic entries in all four Build 1 recording categories.
- [ ] Force quit and restart. Records and customization remain.
- [ ] Switch between tabs and stacked feature views; back navigation behaves normally.
- [ ] Save stays above the keyboard on supported iPhones; no field overlap with the tab bar.
- [ ] Check light and dark appearances, VoiceOver, Dynamic Type, and Low Energy Mode.
- [ ] Install as an in-place update with a compatible signing method; do not delete the existing app or its Core Data store.
- [ ] Test deployment to the iOS 16 iPhone 14 Pro and physical iPhone 16e, without Apple Watch.
- [ ] Confirm Home Screen app icon and feature assets match the approved artwork.
- [ ] Distinguish unsigned IPA compile success from real-device runtime verification.

## Unfinished features and safety boundary

Medication, hydration, sleep/rest, posture observations, clinician reports, reminders, PDF/CSV and backup/restore are still **planned**. They should not falsely claim to record anything until implemented and tested. All useful features remain free; no Apple Watch dependency, advertisements, or accounts.

Use synthetic health entries for testing until local backup/export is fully implemented. Never upload medical details to the public GitHub repo.
