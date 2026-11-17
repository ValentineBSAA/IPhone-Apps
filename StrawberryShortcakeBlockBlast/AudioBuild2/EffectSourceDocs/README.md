# Berry Blast Blast • 16 Sound Effects • iOS-ready v1.0

**Purpose:** Import this ZIP as the game's *event-triggered sound effects*. This is separate from the 51-track soundtrack package.

All 16 original user-generated MP3 effects were verified and converted to **16-bit PCM WAV, stereo, 48 kHz** for dependable low-latency in-app playback. No intentional trimming was applied, including to the longer countdown tick. Decoding MP3 removes a small amount of encoder padding/silence.

## Folders
- `audio/menu_ui/` — 3 navigation/start effects
- `audio/puzzle_actions/` — 5 block/clear/combo effects
- `audio/scores_rewards/` — 4 score, reward, victory, and game-over sounds
- `audio/berry_blitz/` — 4 timed-mode cues

## Developer files
- `SFX_MANIFEST.json` maps unique event keys to audio paths and durations.
- `SFX_CATALOG.csv` lists the sound effects and actual measured duration.
- `INTEGRATION.md` describes playback and countdown cautions.
- `SHA256SUMS.txt` verifies converted files.
- `SOURCE_AND_RIGHTS.md` records source and distribution notes.

**Use:** Extract the ZIP and add the WAVs to the iOS app bundle. Trigger effects only for relevant actions; give SFX their own volume control. Do not treat these as playlist music. Upload this ZIP as its own GitHub Release asset.
