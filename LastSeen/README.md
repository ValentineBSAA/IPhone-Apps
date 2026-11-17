# LAST SEEN — The Missing Floor

**Native interactive iPhone horror game** | SwiftUI | iOS 16.0+ | Portrait | Offline

Working internal title, pending public-name clearance. Built as a standalone game in the IPhone-Apps monorepo. It does not use Berry Block Blast code or assets.

## Playable content

Chapter 1: **The Missing Floor**. Nora Bennett texts at 1:42 a.m. about footsteps above the building's top floor. A caretaker and an unlisted number begin sending contradictory messages. Inspect the photo and recorded voice clues, answer a fictional incoming call, choose whom to trust, and reach one of **three complete endings**:
- THE EXIT — interpret both media clues correctly.
- THE LOOP — open the wrong door.
- THE TAKEN — trust the wrong voice.

Every scene is authored in LastSeenApp/StoryScript.swift; branch IDs are deterministic and validated in unit tests.

## Real functionality

- Native SwiftUI conversation inbox with contact portraits, sorting, timestamps and unread counts.
- Message bubbles with readable incoming/outgoing layouts, delivered/read receipts, and animated three-dot typing.
- Choice tray with meaningful branches, locked evidence-dependent ending, and functional composer accepting verbatim offered replies.
- Zoomable in-app corridor evidence image, fictional voice recording via offline iOS text-to-speech, readable transcript, in-game call screen with answer/decline, and original generated suspense ambience.
- iOS haptics, message alert sound, skip typing delays, settings, content persistence across relaunch, replay, and case-file gallery.
- Optional, consent-based native local reminders when away from the story. No real phone or SMS calls.
- Original asset-generator script for 1024px native app icon.
- No tracking, accounts, advertisements, API key, or network dependency.

## Build on macOS

From the repository root, go to LastSeen and run:

1. brew install xcodegen
2. swift Tools/make_icon.swift
3. xcodegen generate --spec project.yml
4. xcodebuild -project LastSeen.xcodeproj -scheme LastSeen -configuration Release -sdk iphoneos -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO build

The minimum supported OS is **iOS 16.0**, including the jailbroken iPhone 14 Pro test target.

## Download IPA from GitHub Actions

Workflow: https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/last-seen-ios16.yml

Open **Actions → LAST SEEN — native iOS 16 horror game → latest successful run → Artifacts**, then select the LAST-SEEN-v1.0.0-iOS16-unsigned artifact. It contains Last-Seen-v1.0.0-iOS16-unsigned.ipa built for physical iPhone hardware. Simulator tests and compile must pass before packaging.

**Unsigned IPA warning:** This is a real native application bundle but not a signed App Store app. Installation requires signing or compatible trusted jailbreak-oriented tooling. A green GitHub Actions build does not substitute for a test on the physical phone.

## Files

- LastSeenApp/Models.swift: saved state, game messages, contacts, scripted events.
- LastSeenApp/StoryScript.swift: complete branching chapter and endings.
- LastSeenApp/GameStore.swift: observable story engine, event delivery, saving, permissions, voice.
- LastSeenApp/LastSeenApp.swift: app entry point, scene lifecycle, native navigation.
- LastSeenApp/InboxView.swift, ConversationView.swift, SettingsView.swift: playable interface.
- LastSeenApp/Theme.swift: custom iOS-like dark UI, responsive bubbles, animated typing, procedural image.
- LastSeenApp/AudioAtmosphere.swift: original generated ambient audio.
- Tests/StoryEngineTests.swift: branch, evidence, restart, and graph tests.
- Tools/make_icon.swift: icon generator.
- TECHNICAL_PLAN.md, GAME_DESIGN.md, QA.md: design and acceptance.

## Scope and limits

The player may type an **exact displayed reply** or tap a response button. Unrestricted AI conversation and Story Maker are not included. Audio dialogue is synthesized, not professionally voice-acted; the evidence image is illustrative in-game graphics, not a photoreal photograph. The story is one complete playable episode, not an unlimited catalogue.

The UI uses familiar messaging conventions, but is clearly the fictional LAST SEEN game and not a pixel-identical copy of Messages or Phone. No real contacts, photos, phone calls or text messages are accessed.

**Release status:** Complete first-source implementation. Hardware validation, audio tuning and final public-name clearance remain prerequisites for distribution outside personal testing.
