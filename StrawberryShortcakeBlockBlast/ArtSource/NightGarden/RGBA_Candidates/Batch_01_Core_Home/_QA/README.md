# Batch 1 Night Garden RGBA candidates

Four owner-approved original RGB images were kept unchanged in their ArtSource/Approved_40_Icon_Batches folder. This is a first alpha pass, NOT new AI drawings and NOT an integrated Xcode asset.

Method: identify only near-black (max RGB <= 9) regions connected to the image edge, set those OUTSIDE rounded-square corner mattes to transparency, feather the boundary by 0.85 source pixels, and preserve every original RGB value even where alpha changes. The inner moonlit sky/background is intentional artwork and is NOT removed.

QA: manually compare the four-context preview, 64/96px mobile-size preview, full-resolution petals, transparent border and glow halos. OWNER ACCEPTANCE AND iPhone 16e TESTING PENDING.
 This mask is specific to Batch 1; do not apply blindly to remaining batches.
