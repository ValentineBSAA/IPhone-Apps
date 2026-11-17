# LAST SEEN v1.0.0 — Quality gates

**Platform:** native iOS 16.0; primary real-world target: iPhone 14 Pro with Dynamic Island.
**Release state:** Development build. CI validation required; signed installation and on-device verification not yet completed.

## Automatic checks (Tests/StoryEngineTests.swift)
- All three endings reachable.
- Alternate introductory routes converge correctly.
- Exit choice remains locked until photo and audio have actually been inspected.
- No repeated event IDs even across multiple scene transitions.
- Replay resets narrative without changing audio/haptic preferences.
- All scene graph destinations exist and no terminal scene lacks an ending.

## Manual test matrix

### First launch, onboarding and inbox
- Launch without any permissions; offline story starts.
- Contact list shows Nora, Eli, Unknown Number; new incoming bubble updates preview.
- Unread badge appears only for messages not yet viewed.
- Opening a thread marks incoming messages read; reopening does not lose history.
- iPhone Home indicator, keyboard and navigation avoid Dynamic Island and safe area.

### Conversation presentation
- Incoming gray and outgoing blue bubbles wrap multiline text.
- Three typing dots visibly animate; they disappear before message appears.
- Incoming message only displays once; chronology preserved.
- Delivery/read receipts change when the contact responds.
- Reveal button skips one delay only, never a choice or multiple beats.
- Typed exact displayed response works; unsupported free text clearly explains limitation.
- Choice buttons cannot double-send. Locked choice explains clue prerequisites.
- Text size, VoiceOver, and Reduce Motion accessibility behavior.

### Media and phone features
- Photo clue opens, can zoom, closes cleanly, and marks evidence.
- Voice note reads aloud through built-in TTS, can be stopped, has readable transcript and marks clue.
- Incoming fictional call appears in-game; answer/decline both work; call is explicitly labelled fictional.
- Sound/haptic toggles persist; game is playable with no audio.

### Suspensions and notifications
- Exit/force-quit halfway through typing, restart: event resumes once.
- Lock/unlock and app switching do not skip or duplicate beats.
- Optional reminders require user permission and don't block story when denied.
- Reminders use LAST SEEN identity and do not claim to be real calls or emergencies.
- Finish three endings, replay, force-quit and confirm saved state.

### Real-device checks
- Exact iOS 16.0 build MinimumOSVersion in app Info.plist.
- iPhone 14 Pro portrait, notch/Dynamic Island, keyboard and safe areas.
- Screen taps, haptics, text scroll position, dark mode, reduced motion, VoiceOver.
- Battery/thermals during longer sessions (synthesized ambience loop).
- Notifications with Focus enabled and disabled.
- Verify iPhone installation method and packaging before calling release stable.

## Deferred
- Free-form AI, external chat services, real VoIP, contact/SMS access, online story sharing.
- New episodes, professional character portraits and recorded voice talent.
- Public brand selection and app-store publication.
