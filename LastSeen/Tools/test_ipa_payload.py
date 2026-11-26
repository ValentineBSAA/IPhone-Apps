"""Offline archive fixtures; no actual game compilation or packaging."""
import io
from pathlib import Path
import stat
import tempfile
import unittest
import warnings
import zipfile
from verify_ipa_payload import verify_payload

class PayloadTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.app = Path(self.tmp.name) / "LastSeen.app"
        (self.app / "Resources").mkdir(parents=True)
        (self.app / "LastSeen").write_bytes(b"executable fixture")
        (self.app / "Resources" / "sample.bin").write_bytes(b"media fixture")
        self.prefix = "Payload/LastSeen.app/"
        self.good = [(self.prefix + "LastSeen", b"executable fixture"),
                     (self.prefix + "Resources/sample.bin", b"media fixture")]

    def check(self, entries):
        stream = io.BytesIO()
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(stream, "w") as archive:
                for name, data in entries:
                    archive.writestr(name, data)
        with zipfile.ZipFile(stream) as archive:
            return verify_payload(archive, self.app)

    def test_exact_payload(self):
        self.assertEqual(self.check([("Payload/", b""), (self.prefix, b"")] + self.good), 2)

    def test_missing_file(self):
        with self.assertRaisesRegex(ValueError, "Missing IPA files"):
            self.check(self.good[:1])

    def test_changed_file(self):
        with self.assertRaisesRegex(ValueError, "differs"):
            self.check([self.good[0], (self.good[1][0], b"changed")])

    def test_extra_file(self):
        with self.assertRaisesRegex(ValueError, "Unexpected IPA file"):
            self.check(self.good + [(self.prefix + "extra.txt", b"extra")])

    def test_duplicate_file(self):
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.check(self.good + self.good[:1])

    def test_unsafe_paths(self):
        for name in ("../escape", "/absolute", self.prefix + "../escape", self.prefix + "a//b", self.prefix + "./alias", self.prefix + "a\\b"):
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, "Unsafe"):
                self.check(self.good + [(name, b"bad")])

    def test_archive_symlink(self):
        entry = zipfile.ZipInfo(self.prefix + "link")
        entry.create_system = 3
        entry.external_attr = (stat.S_IFLNK | 0o777) << 16
        with self.assertRaisesRegex(ValueError, "symlink"):
            self.check(self.good + [(entry, b"LastSeen")])

    def test_compiled_symlink(self):
        (self.app / "link").symlink_to(self.app / "LastSeen")
        with self.assertRaisesRegex(ValueError, "symlink"):
            self.check(self.good)

    def test_external_directory(self):
        with self.assertRaisesRegex(ValueError, "outside app payload"):
            self.check(self.good + [("Other/", b"")])

if __name__ == "__main__":
    unittest.main()
