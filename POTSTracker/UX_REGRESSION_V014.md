# POTS Tracker v0.1.4: History crash fix and expandable groups

**Reported:** On a real iPhone 16e, after creating four check-ins on 2026-11-19, deleting records repeatedly crashed the app when deleting the last remaining record. Source-level diagnosis without an iOS crash log: the old SwiftUI EntryCard held the live Core Data NSManagedObject and attached its confirmation dialog to a view that disappears upon deletion. Both are risky. The fix avoids them; only a physical repeat test can establish that the crash is resolved.

## Actual device evidence
- Four "Better" check-ins persisted and appeared in Home and Week History; the seven-day count updated to 4.
- UI showed four large identical History cards, which became difficult to scan.
- Deleting the last item closed the app unexpectedly.
- The Log tab displayed the approved original icon artwork.
- User requested swipe gestures and nested date/category/entry groups, with an eventual non-cluttered notifications/reminders interface.

## Implemented fixes
- **Safety:** Rows are now immutable RecordSnapshot values rather than live Core Data objects.
- **Safety:** Edit sheets retain only stable NSManagedObjectIDs and fetch the object when presented; if removed, the sheet shows an unavailable state.
- **Safety:** Delete action resolves the object from its ID at the time of action, checks deletion state, saves or rolls back and surfaces errors.
- **Safety:** Both History and per-category screens own delete confirmation/alerts. The confirmation remains mounted while the final row, group, or category disappears.
- **Layout:** History is now a collapsible tree: day (count) → entry type (count) → compact individual entries with timestamps. All groups start collapsed, with each level independently expanded.
- **No lost history:** Existing records, duplicate timestamps and multiple check-ins per day are preserved without silently merging events.
- **Gesture:** Swipe an individual entry right for Edit; swipe left for Delete. Swipe reveals actions, **never deletes automatically**. Delete still requires confirmation. Tap and long-press context menu are accessible alternatives.
- **Category screens:** Short rows instead of giant entries, grouped by day, using the same safe action pattern.
- **Home:** Recent activity and Today's counts are derived from immutable snapshots rather than live objects.
- **Privacy:** All data remains local; no clinical or automatic measurement claims, no extra personal data required.
- **Notifications:** Reminder/notification center is not implemented yet. Add a future grouping policy (day → reminder type → events), with user controls and no noisy automatic push feed. Do not mark this as built.

## Regression: highest priority
- [ ] On an actual iPhone, create 1 check-in, delete it from expanded History tree, confirm screen remains open with "Nothing recorded" and 0 counts.
- [ ] Create 4 "Better" check-ins. They must appear as **one date group** containing **one Check-ins group (4)** with 4 individual rows.
- [ ] Delete each row through swipe-left → Delete → Confirm, checking 4→3→2→1→0 without a crash.
- [ ] Try cancelling Delete; count and row must remain unchanged.
- [ ] Try deleting the final row from the category page as well.
- [ ] Swipe right → Edit; modify the entry; return to History and verify updated content.
- [ ] Swipe left and right while scrolling vertically; gestures should not interfere with everyday scrolling.
- [ ] Try long press context menu and VoiceOver actions without using gestures.
- [ ] Create two categories on one day, then two different dates; expand/collapse independently and check count accuracy.
- [ ] Change date and time of an entry, reopen History: it must move to the correct date group.
- [ ] Cancel an edit; no accidental deletion or change.
- [ ] After clearing records, go to Home, Log, Week, Month, Year and All: no crashes, empty states are legible.
- [ ] Force quit/restart and repeat the last-entry deletion test.
- [ ] In-place update from v0.1.3; original test data and customization must survive.
- [ ] Dark mode, Dynamic Type, low-energy controls, iPhone 16e and iOS 16 iPhone 14 Pro.
- [ ] Check installed version exactly once under More, still stamped by GitHub run number.
- [ ] All approved custom icons remain intact.

## CI tests
- [x] Authored in-memory Core Data test: deleting last record leaves an empty fetch and empty group tree while an immutable snapshot stays readable.
- [x] Authored in-memory test: four same-day check-ins remain four records but group under one date/category.
- [x] Authored in-memory test: entries on distinct dates and in distinct categories split into correct nested groups.
- [ ] Observe passing GitHub Actions test run on macOS iPhone Simulator.
- [ ] Verify app in a real iPhone session. Unit tests do **not** prove SwiftUI's sheet/gesture behavior on hardware.

## Next priority after crash fix
Once real-device stability is confirmed, improve entry details and Today summaries with real values. The other tracker functions (hydration, medications, rest, posture, reminders, PDF/CSV and backups) are future work. No further purely cosmetic redesign until deletion and persistence are reliable.
