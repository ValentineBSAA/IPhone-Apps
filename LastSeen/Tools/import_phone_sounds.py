"""Import the exact creator-supplied sound pack, ignoring macOS metadata."""
import argparse
import hashlib
from pathlib import Path
from zipfile import ZipFile

PACK_SHA = "bbb41062ce6dbbfc4d7073110feb59dacda975f63f5d151cf2aff12094678981"
TRACKS = {
    "PhoneIncomingText": ("Last Seen Incoming text message.mp3", "159935f52e93fe3dffa0131aa3cf0259acbc4449ef6b0d45ca8ef977d7c77f76"),
    "PhoneOutgoingText": ("Last Seen Outgoing text message.mp3", "379e1ba4b0a539639c16b209cb6b6a248e60b33d60b5547fb6a8fa0f1664f580"),
    "PhoneGeneralNotification": ("Last Seen General notification.mp3", "7ed45ff1daa0c5a4c57bc9803a04ef207ee2b2e4573001678f3f2bb0d160ba6d"),
    "PhoneIncomingCall": ("Last Seen Incoming Phone Call.mp3", "8b9daf065dbac925fddcd164328a207e97c04ee257fc01ca50b669b17f7c876c"),
    "PhoneLock": ("Last Seen Phone lock.mp3", "ecb02e9ffed72746e4e13602f8573a95fe9783d70dcef52d3659ecd11d568e6f"),
    "PhoneUnlock": ("Last Seen Phone unlock.mp3", "81bd95e5e867f6443b58bf89ece9960c912b1b07ffbef182b7a0f267118e1146"),
    "PhoneCorruptedNotification": ("Last Seen Horror Corrupted message notification.mp3", "103140d1a9daeaabb84e5b051ac8454c1b3ec0dcef5b2c10c887dad9150377dc"),
    "PhoneUnknownCaller": ("Last Seen Horror Unknown caller.mp3", "2175da6474cbc123460689e7bc89a610973ba77bce0879e2e073907f99aa215f"),
    "PhoneHeartbeat": ("Last Seen Horror Electronic heartbeat.mp3", "c6cc171bf792474f4d594f98513e50187d788e6d51b5dd69b04666f54fa2f836"),
    "PhoneAnomaly": ("Last Seen Horror Sudden system anomaly this one needs to be looped a few times to be effective.mp3", "aba91f45ce8b3c56d9587ca0243f368b2af47be421b7314e7e60d7a7781a8ab6"),
    "PhonePhantomVibration": ("Last Seen Horror Phantom vibration this one also needs to be looped a few times to be effective.mp3", "69b7de62f14ac5373acdd038d98faf7a3ab96e00e202710e964635a23898d68b"),
}

def digest(data):
    return hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", type=Path)
    parser.add_argument("--verify-bundle", type=Path)
    args = parser.parse_args()
    if args.verify_bundle:
        for name, (_, expected) in TRACKS.items():
            path = args.verify_bundle / (name + ".mp3")
            if digest(path.read_bytes()) != expected:
                raise SystemExit("Bundled audio mismatch: " + name)
        print("Verified all 11 original MP3 files in compiled app.")
        return
    if not args.zip:
        parser.error("--zip or --verify-bundle required")
    if digest(args.zip.read_bytes()) != PACK_SHA:
        raise SystemExit("Creator sound pack ZIP SHA-256 mismatch")
    destination = Path("LastSeenApp")
    with ZipFile(args.zip) as archive:
        if archive.testzip() is not None:
            raise SystemExit("Corrupt sound pack")
        for name, (filename, expected) in TRACKS.items():
            data = archive.read("Last Seen Sounds/" + filename)
            if digest(data) != expected:
                raise SystemExit("Sound content mismatch: " + filename)
            (destination / (name + ".mp3")).write_bytes(data)
            print(name + ".mp3", len(data), "verified")
    print("Imported 11 original one-shot effects; no transcoding or looping.")
if __name__ == "__main__":
    main()
