# Phone Lab 1.2.0 (9) — first shell prototype
Source implementation only until CI passes and physical iPhone testing is complete. Default launch is the fictional phone; the legacy game is retained behind the --legacy-story launch argument for developer regression tests. The app identifier and iOS 16 minimum are unchanged. No horror scripts have been expanded.
## Physical device test gate
- [ ] Launch in airplane mode; lock screen displays correct time; tap Unlock and swipe up.
- [ ] Home grid and dock fit without clipping; all eleven icons open their intended app; use Back/Home.
- [ ] Lock, unlock, open recent apps, choose an app again.
- [ ] Notification center lists ordinary unread threads; tapping routes correctly; read counts update.
- [ ] Quick settings: wallpaper changes, simulated Wi-Fi changes browser status, brightness visibly dims content only. Relaunch and verify persistence; actual iOS settings unaffected.
- [ ] Messages and Contacts: Maya and Denise only; search, profiles, authored replies, badges; no horror story, timers or notifications.
- [ ] Notes: create, edit, pin, delete, relaunch; Calendar: browse date and see appointments; Mail: read state persists.
- [ ] Photos: view the two existing portrait assets, favorite/unfavorite and filter. This is a prototype album, not a finished camera roll.
- [ ] Browser: local pages, history, bookmarks, search; Files: open documents; Calculator: basic arithmetic, divide-by-zero; Clock: live time and stopwatch.
- [ ] Force quit/relaunch and repeat; confirm no legacy progress is changed, story reminders do not appear and no network/account is required.
- [ ] Check 14 Pro iOS 16.0 hardware and accessibility, large text and reduced motion.
## Open work
Original OS identity/icon art; expanded everyday phone history and photo/video assets; phone/voicemail/calls; music/recordings; richer mail, calendar and media interactions; browser visual design; persistent drafts and realistic message delays; consistent virtual time and full app-state restoration; app switcher currently recent-app shortcuts, not snapshots; secondary device tests. No new story production until user approves the shell. Free/offline, no required API or paid service.
