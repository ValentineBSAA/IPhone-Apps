# 0.5.7 Build 1 integrated development handoff

Working base: uploaded 0.5.6 Build 3 iOS16 source ZIP. Original testing was on a jailbroken iPhone 14 Pro running iOS 16. Apple bundle ID and 0.5.6 saved keys are unchanged.

**Integrated in this source:** fixed drag anchor/invalid overlays, premium blocks, named icon catalog, home Berry Boutique, wardrobe Inventory, offline personal leaderboard, local Daily calendar, unlock and Game Over text, helper semantics, optional purchased Berry Hint, original 51-track +16-SFX bundle, mild season colors.

**Caveats:** Source/parser/engine checks succeeded locally; Apple iOS SwiftUI typechecking, Mac simulator, signed install, FPS, touch behavior and runtime QA are unverified. No IPA has been built or pushed to GitHub.

**Do next:** push source to a test branch in `ValentineBSAA/IPhone-Apps`, run updated GitHub Actions or Codemagic, fix any SwiftUI compiler warnings or errors reported by actual Xcode, install unsigned IPA after signing, and collect iPhone 14 Pro screenshots/reports before publishing a stable release.

See the dedicated QA sheet. Preserve the legacy rollback. Do not silently rewrite the 51 original audio tracks, mascot or app icon.
