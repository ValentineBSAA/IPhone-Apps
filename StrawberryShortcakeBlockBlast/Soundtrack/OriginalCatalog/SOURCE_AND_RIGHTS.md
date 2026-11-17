# Source, licensing and release checklist

## Source provenance

- Input: user-supplied `BerryBlastBlast-Soundtrack-v1.zip` containing 15 `.m4a` files.
- Input codecs: all **Opus**, 48 kHz, stereo, inside M4A/MP4 containers.
- Deliverable codecs: all **AAC-LC**, 48 kHz stereo, 192 kb/s target bitrate, M4A container.
- Original audio material was not remixed, cut, normalized, or given loop edits; conversion is lossy and duration may change by a few milliseconds.
- Files were renamed to ASCII-safe, consistent `NN-track-name.m4a` filenames and given track/title/album metadata.
- Original file names and SHA-256 fingerprints are stored in `manifest.json` and `TRACKLIST.csv`.

## Before publishing in a public repository or commercial app

The uploader says they have a Suno Premier subscription. **This file package does not independently verify the generation dates, account entitlement, music ownership, or any third-party permissions.** Confirm that each recording was generated and used under the applicable Suno commercial rights. Save evidence of the Suno generation date/link and plan entitlement in your own records. Do not treat this README as a legal certification.

A Suno music-use license does not give permission for third-party franchise names, characters, melodies, logos, or artwork. Public distribution must separately clear any such rights.

There is deliberately **no open-source music license** in this archive. Merely making this archive public does not mean you intend to grant re-use rights to others. If you want to authorize external redistribution or modifications, choose and add an explicit license after reviewing the applicable rights.

## Release checks

- [ ] Confirm commercial-use eligibility for each of the 15 Suno generations.
- [ ] Add or privately record each Suno song URL and creation date.
- [ ] Play all 15 AAC files on the target iPhone.
- [ ] Check relative loudness and transitions in the actual game.
- [ ] Check no unauthorized existing melodies/third-party IP are incorporated.
- [ ] Confirm all app naming, characters, art, and branding rights separately.
