"""Import and verify the exact four creator-supplied corrective sounds."""
import argparse
import hashlib
from pathlib import Path
from zipfile import ZipFile

PACK_SHA = "2b35b10f8325e189739c35435fec8c350ce385c0fe087bda23d7697c60c32dd0"
TRACKS = {
    "PhoneDialerKeypress": ("Last Seen Phone Dialer Keypad.mp3", "f8f22885916fd0a8df29d11c05fa98f03ebb2aadcfaa0bb28ab09108b7b5415e"),
    "PhoneTimerCompleted": ("Last Seen Timer Completed.mp3", "03367cebeb39c1649145a7bb23740b1235238935f4aadbb06dace82024cf46be"),
    "PhonePasscodeKeypress": ("Last Seen Passcode Keypress.mp3", "e89efdd50d7dae8dae6d82655eb992913f485f9b806c7a4776656123dfcab03a"),
    "PhoneAuthenticationFailed": ("Last Seen Authentication Failed.mp3", "aac75760ea4913a41e134571176fdd77dca6cdcac607ef4e29a2f917bb20db37"),
}
def digest(data):
    return hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--zip", type=Path)
    group.add_argument("--verify-bundle", type=Path)
    args = parser.parse_args()
    if args.verify_bundle:
        for name, (_, expected) in TRACKS.items():
            if digest((args.verify_bundle / (name + ".mp3")).read_bytes()) != expected:
                raise SystemExit("Extra bundled sound mismatch: " + name)
        print("Verified four additional phone sounds")
        return
    if digest(args.zip.read_bytes()) != PACK_SHA:
        raise SystemExit("Extra sound ZIP hash mismatch")
    with ZipFile(args.zip) as archive:
        if archive.testzip() is not None:
            raise SystemExit("Extra sound ZIP failed CRC")
        names = [n for n in archive.namelist() if not n.startswith("__MACOSX/")]
        if sorted(names) != sorted(v[0] for v in TRACKS.values()):
            raise SystemExit("Unexpected extra sound archive entries")
        for name, (filename, expected) in TRACKS.items():
            data = archive.read(filename)
            if digest(data) != expected:
                raise SystemExit("Extra sound mismatch: " + filename)
            (Path("LastSeenApp") / (name + ".mp3")).write_bytes(data)
    print("Imported four exact original MP3s")
if __name__ == "__main__":
    main()
