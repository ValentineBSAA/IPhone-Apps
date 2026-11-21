# Berry Berry Blast | Daily Harvest | H1-B03

8/8 original designs individually visually approved by owner, one at a time.
- Halloween Day/Night, Christmas Day/Night, Thanksgiving Day/Night, Birthday Day/Night.
- These assets are illustrated calendar + strawberry harvest basket Home tiles, NOT live dates.

## Original and RGBA protocol
Every original image's exact original PNG bytes are preserved in Originals/.
Five originals already have transparent RGBA data and their candidate images are exact byte-identical copies.
Three originals contain baked light checkerboard RGB backgrounds: DH-01, DH-03, DH-07. Their candidates were extracted using foreground matte separation non-destructively. DH-01 had its internal calendar-paper areas explicitly restored after QA detected missing cream pixels. The three cleanup candidates still need human review for edge halos and tiny floating elements.

See JSON and CSV manifests for exact SHA-256, file counts, modes and staging flags.
All eight visuals are approved. This does NOT mean all eight RGBA mattes are approved, app assets are imported or an IPA has been built.

Do not overwrite original Day icons, previous Night Garden 40/40 images, clock frames, Berry Story 8, or cottage art. Avoid overwriting game data, rewards, daily status, clock and purchase behavior.

Next: owner checks RGBA proofs. Then upload ZIP to GitHub release under dedicated tag through separately verified importer, and stage image binaries in isolated artwork branch. Only later merge an Xcode integration branch after real-device QA.
