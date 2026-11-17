# LAST SEEN — iOS 16 technical preflight & acceptance plan
Research date 2026-11-17. No app binary or production implementation committed in this branch.

## Platform
- **iOS deployment target: 16.0**, iPhone first, portrait.
- Swift 5 + SwiftUI UI, native Xcode/XcodeGen generated project.
- Avoid iOS 17+ only dependencies such as SwiftData for required functionality.
- Story scripts: bundled versioned JSON or plist with stable IDs and validated branching graph.
- Saves: Codable + atomically written file in Application Support for the first vertical slice; Core Data if complexity warrants later. Migration/schema version included from v0.1.
- Audio: AVAudioPlayer / AVFAudio; Haptics: UIImpactFeedbackGenerator, later CoreHaptics if needed.
- Notification scheduling: UNUserNotificationCenter for optional chapter reminders/messages; notification request only after explanation and only if player opts in. On activation, reconcile delivery with deterministic story engine; do not assume alert was seen.
- On-screen fiction calls: entirely SwiftUI + bundled dialogue/audio. **Do not use CallKit** for fake VoIP calls; CallKit is designed for legitimate VoIP services.
- Store no real messages, call history, contacts, photos, or personal information.

## Suggested source layout (future work, not yet created)
LastSeen/
  project.yml
  LastSeenApp/
    App/
    Models/
    Engine/
    Storage/
    Screens/
    Components/
    Audio/
    Assets.xcassets/
    Stories/
  Tests/
  Tools/
  README.md
  GAME_DESIGN.md
  TECHNICAL_PLAN.md

## State machine
- The story engine loads validated scenes with stable unique event IDs; events are dialogue, choice, photo, audio, call, timer, flag, and ending.
- Persist StoryProgress: scriptVersion, currentNodeID, deliveredEventIDs, scheduledEventIDs, choiceHistory, clueFlags, perConversationReadState, timestamp/version.
- Enqueue once; check delivered IDs before showing or scheduling. On foreground restart, compute due events from stored deadlines and avoid duplicate playback.
- UI is a projection of state, not the source of truth. This is key to fixing background and replay bugs.
- For v0.1 do not support arbitrary free-text AI. Provide curated, authored choice buttons plus a convincing composer and native focus behavior. AI could be researched after authored branching works.

## Integration into existing repository
Repository: https://github.com/ValentineBSAA/IPhone-Apps
- The existing Berry Block Blast project uses XcodeGen in project.yml, iOS 16.0, SwiftUI, macOS GitHub Actions, simulator tests and an unsigned-IPA artifact.
- Reuse that *structure*, not its game logic or art.
- New workflow should trigger only for LastSeen/** and its own workflow file, avoiding accidental Berry jobs.
- Release process: iOS 16 simulator + xcodebuild generic iOS device compile; inspect built .app MinimumOSVersion; archive unsigned IPA; verify Payload/*.app/Info.plist; publish artifact; sign/install through a user-controlled lawful method; test on iPhone 14 Pro.
- **Unsigned IPA cannot automatically install on any stock iPhone.** Device installation depends on signing or jailbreak-specific tooling. A successful CI run alone does not prove runtime quality.

## V0.1 functional acceptance (must pass)
1. Inbox lists three fictional contacts, unread badge, last-message previews and chronological sorting.
2. Each thread supports multi-line bubbles, portrait layout, timestamps, sensible safe-area padding and back navigation.
3. A scripted incoming message shows three smoothly animated typing dots, removes them, then adds exactly one bubble.
4. Outgoing bubbles animate once; Delivered/Read change at the scripted event; status persists.
5. Response options are tappable exactly once; selection changes later story events; no accidental double advancement.
6. Photo opens in a zoomable detail view; audio note plays, pauses and shows text caption; game audio respects settings.
7. A simulated call is answerable/declinable **only inside the game**, with a visible fiction-safe visual treatment.
8. Force quit during typing and delayed deliveries, relaunch, background, lock/unlock, change screen, and resume with no missing/duplicated events.
9. Three endings are reachable by tests; save/restart clears only when user chooses replay.
10. Accessibility: VoiceOver labels for send, play, choices, speaker, read status; text-size expansion; reduced-motion fallback; no audio-only clues.
11. Optional notifications handle authorized, denied, provisional, Focus, app foreground/background and tap-to-open target conversation. Game remains playable if notifications are blocked.
12. Hardware iPhone 14 Pro / iOS 16: Dynamic Island/safe-area, original keyboard, haptics, sound on/off, scroll at full screen, performance, battery and interruption QA.

## Deferred complexity
- No external server, AI API or user accounts for first iteration.
- No real SMS/phone interception, fake emergency alerts, private system hooks or "system" notifications that pretend to be from Apple.
- No Story Maker until first authored chapter and state engine are stable.
- No App Store submission until public name/IP screening, content rating, original assets and real-device tests are complete.

## Apple and competitor references
- https://developer.apple.com/app-store/review/guidelines/ (notably 1.1.6, 2.1, 4.1, 5.2.5)
- https://developer.apple.com/documentation/usernotifications
- https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
- https://developer.apple.com/design/human-interface-guidelines/notifications
- https://developer.apple.com/design/human-interface-guidelines/designing-for-ios
- https://developer.apple.com/documentation/callkit
- https://developer.apple.com/documentation/corehaptics/
- https://developer.apple.com/documentation/avfaudio/avaudioplayer
- https://developer.apple.com/documentation/coredata
