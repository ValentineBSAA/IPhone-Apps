# LAST SEEN (working codename) — iOS Horror Game Preproduction
Research completed: 2026-11-17. This folder contains planning documents, not a built app.

## Creative direction
Build an original, offline-first psychological horror role-playing game for iPhone. The player interacts with a fictional phone interface: messaging, contacts, photo attachments, voice notes, calls, and branching choices. The game's tension comes from believable conversational timing, evidence, consequences, and the appearance that the fictional phone itself is becoming unreliable.

**Player experience:** iOS-familiar, dark-first, portrait, native and tactile. Message bubbles, timestamps, delivery/read receipts, believable triple-dot typing animation, auto-scroll, composer/choice UI, faux conversations, swipes, haptics, and subtle audio are actual functioning features, not static art.

## Nonnegotiables
- Deploy to **iOS 16.0** and test on an **iPhone 14 Pro** running iOS 16.
- Use native Swift/SwiftUI. Do not disguise a web page as an app.
- Do not change or interfere with the existing Berry Block Blast project.
- Make the entire first chapter completable **offline** and without requesting account, Contacts, SMS, camera, microphone, or location permissions.
- Preserve progress through force-quit/relaunch, including delayed dialogue and branch flags.
- Fictional calls occur **inside the app only**, not as real telephone or VoIP calls.
- Optional system notifications use UserNotifications, request consent in context, carry clear game/app identity, and respect Focus settings. No fake emergencies or critical alerts.
- Original UI and branding inspired by familiar communication patterns. **Do not clone Apple Messages, Phone, iOS system alerts, or the old Seen app pixel-for-pixel.**
- UI must respect Dynamic Island/safe areas, keyboard, accessibility type sizing, VoiceOver, and Reduce Motion.
- No ads, paywalls, AI service, story sharing, or server required for v0.1.

## Naming research
The working title LAST SEEN is **not cleared** as a public brand:
- App Store: "LAST SEEN - Detective Mystery" by Novarch LLC.
- App Store: "Last Seen: Chat Stories" by Sergey Bragilevskiy, an interactive texting/horror title with typed replies.
Use LAST SEEN as a folder/codename until a distinct release name is screened, including App Store / trademark searches.

## Comparative research
- "Seen" (Polychroma Games, 2016) pioneered chat-story play, branching, Story Maker and sharing. Preserve the *idea* of narrative agency, not its proprietary stories/assets/UI.
- "SIMULACRA" (Kaigan Games): a compelling reference for investigating a fictional phone using messages, photos, and media.
- Apple App Review Guidelines §§4.1, 5.2.5, 2.1, 1.1.6: avoid copycats, confusing impersonation, misleading content and unfinished builds.

## Build phases
1. **0.1 interaction proof:** inbox, chat thread, bubble animation, typing dots, delivered/read receipts, keyboard-aware choices, native haptics, and reliable save/resume.
2. **0.2 playable horror vertical slice:** Chapter 1, photos/voice notes, 3 meaningful branches/endings, fictional incoming call inside app, sound and pause/restart.
3. **0.3 real-device hardening:** iOS 16.0 build and simulator tests, hardware keyboard/safe-area/scroll review, notification consent and denial handling, reinstall and save testing.
4. **Later only after approval:** more chapters, fictional Notes/Photos apps, story creator, optional user-typed replies with constrained response understanding.

See GAME_DESIGN.md and TECHNICAL_PLAN.md for implementation-ready decisions.

## Primary research sources
- https://kotaku.com/games/seen-1
- https://www.appbrain.com/app/seen/com.semickolon.seen
- https://apps.apple.com/us/app/simulacra/id1252035454
- https://apps.apple.com/us/app/last-seen-detective-mystery/id6789976810
- https://apps.apple.com/us/app/last-seen-chat-stories/id6808998440
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
- https://developer.apple.com/design/human-interface-guidelines/designing-for-ios
