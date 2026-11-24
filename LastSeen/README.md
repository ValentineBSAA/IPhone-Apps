# LAST SEEN — The Missing Floor

> **2026-11-24 direction change:** [OS-first roadmap](OS_FIRST_ROADMAP.md) governs all new development. Build and obtain owner approval of the fictional smartphone in story-disabled Phone Lab before final narrative work. The following describes legacy story-first work and regression fixtures, not the next implementation priority or verified hardware results.


**Native interactive iPhone horror game** | SwiftUI | iOS 16.0+ | Portrait | Offline

Working internal title, pending public-name clearance. Built as a standalone game in the IPhone-Apps monorepo. It does not use Berry Block Blast code or assets.

## Playable content

**Three independently selectable conversations:** Nora's *The Missing Floor*, Eli's *The Night Shift*, and Unknown Number's *The Seventh Number*. Only the selected story progresses. The other conversations and choices are saved and paused. Nora's story preserves its three endings, and Eli/Unknown each have two additional endings.
- THE EXIT — interpret both media clues correctly.
- THE LOOP — open the wrong door.
- THE TAKEN — trust the wrong voice.

Every scene is authored in LastSeenApp/StoryScript.swift; branch IDs are deterministic and validated in unit tests.

## Real functionality

- Native SwiftUI conversation inbox with contact portraits, sorting, timestamps and unread counts.
- Message bubbles with readable incoming/outgoing layouts, delivered/read receipts, and animated three-dot typing.
- Choice tray with meaningful branches, locked evidence-dependent ending, and functional composer accepting verbatim offered replies.
- Zoomable in-app corridor evidence image, readable voice-note transcript (recorded dialogue not yet available), no pretend voice calls, and original generated suspense ambience.
- iOS haptics, message alert sound, skip typing delays, settings, content persistence across relaunch, replay, and case-file gallery.
- Optional, consent-based local notification banners with believable contact message text and text-input quick replies, subject to iOS permissions/Focus. Free-form replies that don't match an authored choice stay as drafts.
- Original asset-generator script for 1024px native app icon.
- No tracking, accounts, advertisements, API key, or network dependency.

## Build on macOS

For local macOS builds, download the original contact pack from the repository's **Seen contact photos** GitHub Release (tag `Photos-1`), save it as `LastSeen/ContactPhotos.zip`, then go to `LastSeen` and run:

1. brew install xcodegen
2. swift Tools/make_icon.swift
3. python3 Tools/import_contacts.py --zip ContactPhotos.zip --required
4. xcodegen generate --spec project.yml
5. xcodebuild -project LastSeen.xcodeproj -scheme LastSeen -configuration Release -sdk iphoneos -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO build

The minimum supported OS is **iOS 16.0**, including the jailbroken iPhone 14 Pro test target.

## Download IPA from GitHub Actions

Workflow: https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/last-seen-ios16.yml

Open **Actions → LAST SEEN — native iOS 16 horror game → latest successful run → Artifacts**, then select the LAST-SEEN-v1.0.2-iOS16-unsigned artifact. It contains Last-Seen-v1.0.2-iOS16-unsigned.ipa built for physical iPhone hardware. Simulator tests and compile must pass before packaging.

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

The player may type an **exact displayed reply** or tap a response button. Unrestricted AI conversation and Story Maker are not included. No fictional call playback is implemented until original recorded dialogue exists; voice notes currently have readable transcripts; the evidence image is illustrative in-game graphics, not a photoreal photograph. There are three short independent horror stories, not an unlimited catalogue.

The UI uses familiar messaging conventions, but is clearly the fictional LAST SEEN game and not a pixel-identical copy of Messages or Phone. No real contacts, photos, phone calls or text messages are accessed.

**Release status:** Complete first-source implementation. Hardware validation, audio tuning and final public-name clearance remain prerequisites for distribution outside personal testing.

## Asset integration (no manual upload needed)

The ten original square character photographs are published in the GitHub Release [Seen contact photos](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/Photos-1), as `Last-Seen-10-Contact-Portraits.zip`. The GitHub Actions workflow automatically downloads that ZIP, validates it, imports four Nora, three Eli, and three Unit 7 JPEGs into the SwiftUI asset catalog, and fails if any is missing. On-screen avatars are circular, and Settings lets you change portraits at any time. The ZIP remains in the release; it does not need to be committed to a source-code branch.
