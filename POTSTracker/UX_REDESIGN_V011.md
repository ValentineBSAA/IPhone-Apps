# POTS Tracker v0.1.1: Calm Home UX revision

**Status:** Native source committed. CI and physical iPhone validation are separate acceptance gates.
**Test hardware:** real iPhone 16e screenshots from Build 1, November 19, 2026. Keep iOS 16+ compatibility for the iPhone 14 Pro test bench too.

## What we learned from Build 1 screenshots
- The giant "Your daily companion" heading occupied an unnecessary portion of the first screen.
- Today, check-in, 7-day counts, 12 icon cards, activity and privacy all piled into one long dashboard.
- Repeated large white rounded cards lacked a primary visual hierarchy.
- Feature screens used an enormous full-screen sheet with almost no useful content below one oversized action.
- A second modal could be stacked over a category modal. This made hierarchy and navigation harder to understand.
- The original 13 approved multicolor glossy icons **do work on the real iPhone** and must remain unchanged.

## v0.1.1 layout decisions
- Four persistent native tabs: **Home, Log, History, More**. No mandatory account or network calls.
- Home defaults to **compact** and shows in order:
  1. Small date + "Your day, at a glance" heading.
  2. One Today card (latest check-in, entry count, "Log something", three quick actions).
  3. Optional two-row one-tap check-in (not a large extra card).
  4. Four pinned trackers arranged in a compact 2×2 grid.
  5. Three recent records arranged in small grid tiles rather than full history.
- Full 12-icon gallery lives in **Log**, grouped: Track now, Daily support, Review & organize.
- **History** houses real Week / Month / Year / All views. Monthly calendar day selection and year-month navigation use Core Data; missing dates remain "not recorded", not healthy days.
- **More** houses Home customization, comfort settings, safety and privacy; no repeated giant menu on Home.
- **Home customization**: rearrange or hide modules, pin/unpin/reorder any of 12 feature shortcuts, choose compact/comfortable spacing and restore defaults without clearing health records.
- **Category screens**: pushed navigation, aligned icon/title, record count, last-seven-day count, one primary Add action, honest small empty state and actual saved records.
- **Entry editor**: Save remains available at the bottom above the keyboard, with explicit Done keyboard control. Do not confuse a saved record with app-based measurement.
- All 13 approved PNGs remain mandatory. No generic substitutions or replacement artwork.
- Features not implemented yet continue to say "Coming in Build 2/3" with no fake tracking or saving.

## Regression checklist for next physical iPhone test
- [ ] Fresh launch: Home is calm and usable without scrolling through 12 category tiles.
- [ ] Home quick Log opens Log tab; three quick actions open real editable forms.
- [ ] One-tap check-in creates **exactly one** record per tap and counts update live.
- [ ] Scroll through Home; no page/header overlap or modal stack.
- [ ] Log tab displays 12 approved icons in exactly 3 groups of 4. Tiles and text respond.
- [ ] The four Build 1 record categories open via a pushed page; **Back** returns to Log/Home, without black overlapping sheets.
- [ ] New entry, cancel, save, edit and delete work; updates show on Home, category and History.
- [ ] Numeric keypad does not hide Save; tapping Done dismisses keyboard.
- [ ] History Week, Month, Year and All reflect actual saved records. Tap a monthly day to filter, tap again to restore month.
- [ ] Long lifetime history remains accessible without a premium limit.
- [ ] Home Customize: reorder modules, hide a module, pin a different category, reorder pins, choose comfortable layout.
- [ ] Switch tabs and force quit/relaunch: Home customization and existing health records persist.
- [ ] Restore layout defaults changes layout only, not records.
- [ ] Low Energy Mode enlarges controls without overlapping text.
- [ ] Light and dark mode and larger iPhone font sizes readable.
- [ ] iPhone 14 Pro iOS 16 compatibility tested; iPhone 16e tested.
- [ ] Future features display correct "coming" wording and do not claim data was recorded.
- [ ] Home Screen icon and all category images match the approved 13 PNGs.
- [ ] Do not delete/reinstall until export/backup is available; update in place and confirm existing test entries survive.

## Known unfinished features
Hydration, meds, sleep, posture logs, local reminders, PDF/CSV, backup/restore and full advanced analyses remain on the separately tracked feature roadmap. UI polish is **not** the same as their implementation.

## Safe test data
Use made-up readings and notes only. Build 1.1 remains a test build without backup/export. No real health details or patient screenshots should be committed to this public repository.
