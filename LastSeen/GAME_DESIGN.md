# LAST SEEN — Game design and first chapter

> **2026-11-24 direction change:** [OS-first roadmap](OS_FIRST_ROADMAP.md) governs all new development. Build and obtain owner approval of the fictional smartphone in story-disabled Phone Lab before final narrative work. The following describes legacy story-first work and regression fixtures, not the next implementation priority or verified hardware results.

**Internal codename only.** Horror-first, native iPhone narrative RPG.

## Core loop
1. Receive a believable fictional text, photo, voice message, or in-app call.
2. Inspect conversation history and attachments for clues; optionally switch contacts.
3. Choose a meaningful response. Some choices require observed evidence.
4. Update suspicion, trust, evidence and/or survival flags.
5. Show realistic message delays, read receipts, typing animation, and reactions.
6. Let the player continue or pause at will; persist everything.

A branching choice is meaningful if it changes at least one subsequent event, clue, conversation tone, or ending. No fake choices that immediately converge with identical text.

## Visual language
- **iOS familiarity, independent identity.** Portrait-first 390pt-ish adaptive layouts with system type and native SF Symbols where allowed, but original app icon, fictional phone chrome, original screen naming, distinct colors/materials, and no cloned Apple system screens.
- Dark charcoal/black, subdued steel blue, warmer incoming gray, muted danger crimson only when earned; no constant flashing.
- Native keyboard for authored text fields later. Early branching uses an accessible reply tray styled as an input affordance.
- Distinct contact portraits, date separators, selectively visible timestamps, outgoing/incoming bubble tails, multi-line layout, attachment previews, voice note player, and context-aware delayed status changes.
- Three **animated** typing dots during pending messages; must pause when app backgrounds, resume correctly, and never duplicate delivery.
- Incoming reply animations, believable variable reading/composing delays (skipable via fast-text accessibility setting).
- Audio: short original text alert, low-volume atmospheric bed, fictional phone ring, audio recordings, restrained haptics with toggles, subtitled recordings.
- In-app Settings: animation strength/Reduce Motion follow-system, sound/music/haptics, text speed, notification consent/disable, content intensity, replay/save reset.

## First complete playable story: "THE MISSING FLOOR"
**Pitch:** At 1:42 a.m., a neighbor messages the player about sounds coming from a floor that the apartment building doesn't have. Then a voicemail arrives from the player's own number.
**Length goal:** ~20-30 minutes (not a promise, validate with playtests).
**Characters:** Nora (neighbor; initially trusted), Eli (night caretaker; helpful but withholding), and "Unit 7" (unknown sender). Player character is fictional and unnamed.
**Scenes:**
1. Routine neighbor texting becomes strange; player notices conflicting floor numbers in two photos.
2. A caretaker warns the player not to use the elevator; a playable photo detail and old message create competing evidence.
3. A missing call is found in the fictional call history. Playback of a voicemail reveals a lie.
4. A crucial reply: trust Nora, trust Eli, or investigate a location clue. These must produce visibly different story segments.
5. Final consequence with three endings:
   - **Exit:** escape by assembling evidence and identifying the correct floor.
   - **Loop:** escape appears successful, but the inbox resets with changed names.
   - **Taken:** a trust mistake allows the unknown sender into the player's fictional apartment.
**Clue flags:** saw_photo_number, listened_voicemail, read_eli_warning, trusted_nora, trusted_eli, investigated_unit7.
**Reveal guideline:** Keep suspense grounded in message behavior; don't use jump scares every few seconds. Let one ordinary-looking notification become sinister only because of context.

## First-version feature priority
**Must:** inbox; contacts; animated messages; 3-dot typing; delivered/read; timestamps; believable delays; read/unread; choice tray; attached photo; voice note player with captions; in-app call scene; branch flags; multiple endings; local saves; replay; haptic/sound settings.
**Should:** read receipts changing at story beats, skip dialogue timer, original backgrounds, clue gallery, optional local story reminder.
**Later:** user-provided free text understanding; user-generated story maker; network/social, remote pushes, AI chat, procedural narratives.

## Narrative QA rules
- Every branch reaches an ending; no softlocks.
- A clue cannot be referenced before it is available.
- Delayed messages are serialized once, survive app suspension and force-quit, and cannot reorder across contacts.
- Replaying a chapter intentionally resets only that chapter's state.
- In-app notifications do not disclose fictional threats as real-world emergencies.
- Script content is data-driven and editable independently of SwiftUI view code.
