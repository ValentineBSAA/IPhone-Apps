# Berry Block Blast 0.5.7 Build 1, native iPhone iOS 16 source

This is an **updated full source handoff**, not an IPA. No source was pushed to GitHub by this package generation. The game folder, workflows and Codemagic config must be committed to `ValentineBSAA/IPhone-Apps` for a macOS runner to produce an unsigned IPA.

**Full handoff:** `StrawberryShortcakeBlockBlast/` plus `codemagic.yaml`, `.github/workflows/berry-block-blast.yml`, `HANDOFF/`, and original audio.

**Windows patch workflow:** use the separate small PATCH ZIP alongside an existing clone of `ValentineBSAA/IPhone-Apps` and its included `APPLY-0.5.7-PATCH.ps1`. The patch contains only changed files and new icon assets. Full ZIP is for recovery/backup.

Version `0.5.7 (1)`, bundle `com.valentinebsaa.berryblockblast`, iOS minimum `16.0`.

1. Back up the installed app's saved data before the update. Never uninstall it just to sideload.
2. Commit source updates to a test branch; do not overwrite the older tested release until a new IPA passes iPhone testing.
3. Run the **Berry Block Blast 0.5.7 build 1 manual QA** workflow under GitHub Actions (or Codemagic). The workflow compiles an unsigned iPhone application, runs simulator tests and emits the unsigned IPA artifact.
4. Download and sign the actual IPA through your established Windows signer, install as an update on the jailbroken iPhone 14 Pro, and follow `RELEASE-QA-0.5.7-BUILD1.md`.

This ZIP does not contain a compiled or signed IPA because Xcode/iOS SDK is unavailable in the current runtime. See `HANDOFF/BUILD57-STATUS.md` for the exact scope and outstanding tests.
