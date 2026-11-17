# Berry Blast Blast • Original Soundtrack (51 tracks) • iOS-ready v1.2

**Purpose:** Import this ZIP into the iOS app as *background music*. This is the music package, **not** the sound-effects package.

- **51 complete instrumental tracks**, not shortened or edited into jingles.
- Original user-supplied files were identified as **Opus audio in `.m4a` containers**, which is not the AAC format commonly expected by an iOS app.
- Converted to **AAC-LC, stereo, 48 kHz, approximately 160 kbps**, retaining complete track lengths (re-encoding is lossy).
- Folder names represent **exclusive, intentionally curated playlists**, not just a renaming of the sequential soundtrack.

## Audio directories / counts

| Folder | Purpose | Tracks |
|---|---|---:|
| `audio/main_menu/` | Main menu & settings | 11 |
| `audio/relaxed_gameplay/` | Cozy/relaxed standard play | 11 |
| `audio/upbeat_gameplay/` | Lively standard play | 11 |
| `audio/victory_results/` | Full-length results or achievement-screen music | 11 |
| `audio/berry_blitz/` | Timed Berry Blitz mode | 7 |

## Developer files

- `AUDIO_MANIFEST.json` maps stable track IDs, filenames, playlists, and technical details.
- `TRACKLIST.csv` is a human-friendly catalog.
- `playlists/*.m3u8` lists actual bundled files for each game mode; it is optional at runtime.
- `INTEGRATION.md` includes suggested integration behavior.
- `SHA256SUMS.txt` verifies the final delivered files.
- `SOURCE_AND_RIGHTS.md` lists provenance and required rights checks.

**How to use:** Extract the ZIP, add `audio/` to the Xcode app target's bundled resources, read the manifest to bind playlists, then test all 51 files on an actual iPhone. Do not load tracks from GitHub at runtime. Upload this ZIP as a GitHub Release asset to avoid bloating commit history.
