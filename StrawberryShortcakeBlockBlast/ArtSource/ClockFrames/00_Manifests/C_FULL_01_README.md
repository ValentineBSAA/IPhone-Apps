# Berry Berry Blast | Clock Frame Family C-FULL-01

VISUAL DESIGN STATUS: 10/10 owner-approved.
- Base: regular Day + Night.
- Halloween: Day + Night.
- Christmas: Day + Night.
- Thanksgiving: Day + Night.
- Birthday: Day + Night.

The images depict **frames only**, never the current time. SwiftUI should render the local
live time with `h:mm a` and all dynamic accessibility labels.

## RGBA review status
C-01/C-02/C-03/C-04/C-05/C-06/C-07/C-09:
  Original images already contain genuine RGBA alpha. Candidates are byte-identical copies.

C-08 Thanksgiving Night and C-10 Birthday Night:
  Original files are RGB with a generated light checkerboard background.
  Separate non-destructive RGBA *candidates* have been computed with an image
  foreground-segmentation pass. Review edge halos at all 3 preview backgrounds,
  96px/240px actual-size reductions, and physical iPhone before accepting alpha.
  No "perfect transparency" or production-ready claim is made.

This ZIP stages ORIGINALS and RGBA_CANDIDATES separately, including SHA-256 manifest,
three contact sheets and small-scale QA. Do not overwrite prior approved 40 Night
Garden originals, 40 Night RGBA files, existing Day icons, or runtime image sets.

Next after owner accepts technical alpha: import to isolated GitHub artwork branch,
verify hashes, then integrate live time overlay into a separate Xcode PR and test
appearance on real iPhone; begin the next seasonal icon semantic family individually.
