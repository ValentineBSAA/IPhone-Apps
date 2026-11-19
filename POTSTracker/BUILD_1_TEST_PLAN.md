# POTS Tracker, Build 1: physical iPhone test plan

**Status:** To be tested. Source and build workflow are present; no claims of successful compilation or device testing yet. Do not test with someone's actual health information until private backup and restore are implemented.

## Build / install gate
- [ ] GitHub Actions `POTS Tracker | Build 1 iOS 16 unsigned IPA` is green
- [ ] Unsigned IPA artifact exists and contains `Payload/POTSTracker.app/Info.plist`
- [ ] Artifact is signed using an authorized signing method and installed on an iPhone running supported iOS (minimum 16.0)
- [ ] App launches without crashing, internet access or an account
- [ ] 13 approved icon PNGs are in `Resources/Icons`; artwork appears in the dashboard and a valid Home Screen AppIcon asset is supplied
- [ ] Test in light and dark mode, Dynamic Type, and iPhone screen sizes

## Real manual-entry smoke test (synthetic numbers ONLY)
1. Launch the app and confirm today starts with 0 entries and a neutral **Not recorded** week.
2. Tap **Better**, then **Worse**; confirm two distinct timestamped check-ins are retained.
3. Open **Symptoms**, choose Dizziness, optionally choose 6/10, add a note, Save; confirm in the recent timeline.
4. Open **Heart Rate**, enter example `85 bpm`, choose sitting, save; confirm correct unit and position.
5. Open **Blood Pressure**, enter example `115/75 mmHg`, choose lying down, save; confirm correct units and distinct values.
6. Open **Journal**, add a synthetic free-form note, save and re-open it for editing.
7. Edit each entry, change its date to an earlier day, and confirm it moves to that day's history.
8. Delete a synthetic record and confirm deletion; cancel a deletion and confirm record remains.
9. Force quit and relaunch, then reboot the phone; verify saved data stays.
10. Disable Wi-Fi/cellular with airplane mode and repeat logging; no network connection must be required.
11. Turn on **Larger, simpler controls** in settings. Confirm larger buttons and one-tap check-in.
12. Open all 12 tiles. Existing Build 1 features must work; later-build features must clearly say not yet implemented, not pretend to save data.
13. Inspect History; unrecorded days must show **Not recorded**, not 0 symptoms.
14. Verify app gives no automated POTS diagnosis, medication advice, fluid/sodium prescription or unsafe standing-test instruction.

## Edge cases and follow-up tests
- [ ] Leap day and year boundary; multiple entries same day
- [ ] DST transition, travel/time-zone change, time of day formatting
- [ ] Invalid manual numeric input, blank required fields, notes with long text
- [ ] Force quit during save and database corruption response
- [ ] Core Data migration across upgrade; SQLite file-protection validation
- [ ] Locked device, accessibility VoiceOver labels, large-text clipping
- [ ] Low-storage handling and safe recovery
- [ ] Backup/restore, PDF/CSV, medications, reminders, monthly/yearly charts later

## Safety gate
Treat this as **pre-release experimental software**. Local export and restore are not available in Build 1. Do not store irreplaceable private medical data in it. Never send real health logs/screenshots, API secrets or certificates to the public GitHub repository.

Report each issue with build identifier, iOS version and the smallest synthetic reproduction steps, not patient details.
