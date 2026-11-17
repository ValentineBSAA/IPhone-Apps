# Berry Blast Blast - Original Soundtrack (v1.0)

**15 tracks | 31:36 total | iOS-ready AAC-LC M4A audio**

This package organizes the 15 instrumentals provided for the Berry Blast Blast puzzle-game project.

## What is included

- `audio/`: 15 standardized, numbered `.m4a` files for app integration.
- `manifest.json`: exact track names, audio data, suggested roles, file hashes, and original-source fingerprints.
- `playlists.json`: proposed calm/default, upbeat, high-score, menu, and victory playlists.
- `TRACKLIST.csv`: track list for spreadsheet/editor use.
- `SOURCE_AND_RIGHTS.md`: source format details and rights checklist.
- `SHA256SUMS.txt`: SHA-256 checksums of every packaged file except the checksum list itself.

## Important: the supplied files were Opus, not AAC

Even though the originals ended with `.m4a`, inspection showed **Opus audio in MP4/M4A containers**, stereo at 48 kHz. They are **not AAC**. To reduce iOS playback surprises, each was re-encoded to **AAC-LC** at **192 kb/s**, stereo, 48 kHz, with Apple-compatible M4A output. This is a lossy-to-lossy conversion and does not improve the original sound quality. The user-uploaded original ZIP has not been changed.

## Full track list

| # | Track | Length | Suggested placement |
|---:|---|---:|---|
| 01 | Welcome to Berryland | 1:55 | Main menu / title screen |
| 02 | Berry Block Boogie | 1:49 | Classic block-puzzle gameplay |
| 03 | Strawberry Sugar Rush | 2:17 | High-score / energetic gameplay |
| 04 | Jam Jar Jamboree | 1:47 | Playful, lighter gameplay |
| 05 | Sweetest Victory | 1:37 | Results / celebration theme (full song, not a short stinger) |
| 06 | Strawberry Morning | 2:22 | Relaxing gameplay |
| 07 | Rainy Day at the Berry Café | 2:04 | Relaxing gameplay |
| 08 | Twilight in Berryland | 2:48 | Relaxing gameplay |
| 09 | A Little Berry Picnic | 2:02 | Relaxing gameplay |
| 10 | Moonlight and Strawberry Dreams | 2:25 | Relaxing nighttime gameplay |
| 11 | Blueberry Breeze | 1:40 | Relaxing gameplay |
| 12 | Peach Blossom Afternoon | 2:40 | Relaxing gameplay |
| 13 | Raspberry Rainfall | 2:37 | Relaxing gameplay |
| 14 | Vanilla Cream Skies | 1:19 | Relaxing gameplay |
| 15 | The Berry Garden Waltz | 2:16 | Relaxing gameplay |

## Suggested in-game behavior

Use the 10 calm tracks (#06-#15) in the default background rotation. Track #01 is a suggested menu theme; tracks #02 and #04 suit brighter gameplay; #03 suits energetic high-score gameplay. Track #05 is a full-length victory/results theme, **not** a short sound effect.

Shuffle while avoiding immediate repeats. Allow separate music/SFX volumes. Consider ~3-second crossfades for background playlists, but do not crossfade into a scoring stinger or interrupt a live session. Keep background music uninterrupted when opening menus if desired.

These suggestions are based on intended track roles and names; the ZIP has been technically inspected, not creatively approved by listening on an iPhone. Test all transitions and volume levels on a physical iPhone before release. Tracks are not edited into seamless loops; do not assume sample-accurate loop points.

## Use in an iPhone project

Copy the `audio/` M4A files into your app bundle and include them as resources. Use `manifest.json` for filenames/roles, or generate typed track IDs from it. Use `AVAudioPlayer` or `AVAudioEngine` for playback. Check the actual destination project structure before adding or replacing files.

## GitHub release

Recommended: attach this complete ZIP as a **GitHub Release asset**, rather than committing every large audio binary repeatedly to Git history. The ZIP is a distributable bundle. If the project repo must include the music assets, copy the `audio/` folder and manifest into the intended asset directory, then commit once.

See `SOURCE_AND_RIGHTS.md` before publicly redistributing this package.
