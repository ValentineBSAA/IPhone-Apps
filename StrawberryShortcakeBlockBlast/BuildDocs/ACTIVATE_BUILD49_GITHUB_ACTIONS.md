# 🍓 Build49 | One GitHub action needed to start native iPhone QA

**Current status:** Build49 source (digital Home seconds, exact 6 AM/6 PM countdown and six approved Blueberry/Moonberry art previews) and regression sources are committed. **No Build49 GitHub Actions run or IPA exists yet.** Build48 is the physically tested working fallback. Never replace it until the new test run finishes green.

The connected GitHub tool refused to create or update a file under `.github/workflows/`. To preserve this authorized owner-only setting, the **complete workflow has been prepared but NOT activated** at:

[Staged, complete Build49 workflow (reviewable YAML)](berry-i7-clock-b49-WORKFLOW-TO-ACTIVATE.yml)

## The one owner action required in GitHub's browser UI

1. Open the **staged workflow file** above in the repo, on branch `feature/berry-i7-live-clock-seconds-b49`.
2. Click **Edit** (pencil). Change its **file path/name** to `../../.github/workflows/berry-i7-clock-b49-private-ipa.yml` (two `../` levels from `StrawberryShortcakeBlockBlast/BuildDocs` to repository root). Commit this move **to the same Build49 branch**, **not** to `main` or Build48.

If the editor does not permit moving a file with `../`, use **Add file → Create new file** at repository root on the Build49 branch, give it exactly the name `.github/workflows/berry-i7-clock-b49-private-ipa.yml`, paste the staged YAML content, and commit to the Build49 branch. The staged file can remain as a harmless historical reference.

The workflow's `push` trigger specifically includes this branch and destination path, so GitHub Actions should start its first run when that file is committed. Verify it under **Actions → Berry Berry Blast | I7 Build49 real clock seconds and Blueberry art IPA**. No change to the owner's installed app occurs.

**Why not run the existing Build48 workflow unchanged?** Its source checks, result names and app Info.plist version assertion hardcode **internal Build48**; it would reject the genuinely new Build49 source, even though the previous Build48 run was green. The staged B49 workflow corrects all those checks.

## What the new run must prove (do not mark completed early)

- [ ] iOS16, original artwork and 67 audio files verified, unchanged bundle `com.valentinebsaa.berryblockblast`, v0.5.16 / internal Build49 / I7 QA.
- [ ] Actual iPhoneOS **Release** and Release-configured simulator compile, retaining PIN-hidden Developer Garden plus Strawberry cheat and exact-balance restore.
- [ ] **9 native iPhone 16e UI tests**, including new Home live seconds screen and old PIN Developer Garden.
- [ ] **180 selected regression tests** (169 existing gameplay/economy/restore + 9 new local time checks + 2 Blueberry/Moonberry approved art checks).
- [ ] Create one **unsigned private** iPhone IPA, verify Info.plist, original audio, PNG catalog, ZIP integrity, SHA-256, then upload GitHub Actions artifact, with no public release or auto-install.
- [ ] Only then ask the owner to back up their installed game and run the short three-item phone checklist already in [I7 handoff](../I7_BUILD49_CLOCK_ARTWORK_QA_HANDOFF.md).

If a CI step fails, fix **the reported root cause on Build49 branch** and rerun the same evidence gate; do not move unverified code to main or assume a prior Build48 result applies to B49.

**Developer Garden is permanent** in installable builds until its owner says otherwise. Moonberry currency, shops and cheats remain planned for Build6; the images in this candidate are read-only previews.
