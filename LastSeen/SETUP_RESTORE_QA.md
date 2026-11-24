# Last Seen 1.2.1 (10) — New Phone / Wrong Backup
Source implementation; release requires successful CI and device QA.
- Launch fresh or upgrade from 1.2.0: welcome and setup should appear. Existing story and earlier Phone Lab world files remain separate. No real cloud, account or credentials.
- Choose device name and wallpaper, navigate back and continue. Restore progress displays categories. Interrupt during restore, reopen, and verify resume; skip animation and reduced motion complete safely.
- Confirm restore completion transitions directly to home. Relaunch reaches lock screen without onboarding. Settings retains selected device name.
- Open Messages, Notes and Mail; notice consistent provisional owner Nora Bennett, with ordinary historical correspondence and dates. Open Photos and view existing owner portrait. Do not expect complete camera roll or videos yet.
- Change a note, relaunch, and confirm it is preserved. Developer launch argument --replay-setup replays setup without overwriting the restored world. Existing story regression launch argument stays available.
- Repeat all Phone Lab checks in PHONE_LAB_QA.md; no horror story activation.
- Test on iPhone 14 Pro/iOS 16.0 and in airplane mode. No actual phone settings or real account access.
- Automated tests verify local snapshot creation, owner consistency, unread counts and idempotent preservation of edits. CI must compile, test, verify version/build/minimum OS, capture setup screen and package unsigned IPA.
## Open work
Nora and her portrait are provisional. Final owner name, character photos, full photo library, videos, calls, app completeness and horror narrative remain deferred. No paid runtime services. Onboarding visual language is a prototype. Old lab world file remains intact; preference settings can be shared.
