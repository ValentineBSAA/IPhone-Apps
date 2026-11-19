import importlib.util
import plistlib
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT=Path(__file__).resolve().parents[1]
def load(path,name):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

prep=load(ROOT/"scripts/prepare.py","berry_prepare")
verify=load(ROOT/"scripts/verify_ipa.py","berry_verify")

class BerryStoreTests(unittest.TestCase):
    def test_generated_icon(self):
        png=prep.berry_png(48)
        self.assertTrue(png.startswith(b"\x89PNG\r\n\x1a\n"))
        self.assertGreater(len(png),200)
        self.assertEqual(int.from_bytes(png[16:20],"big"),48)

    def test_upstream_mismatch_aborts(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"Makefile"
            p.write_text("ORG_IDENTIFIER=com.Other")
            with self.assertRaises(RuntimeError):
                prep.require_replace(p,"ORG_IDENTIFIER=com.SideStore","ORG_IDENTIFIER=com.valentine.berrystore")

    def test_plist_branded(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"Info.plist"
            p.write_bytes(plistlib.dumps({"CFBundleName":"SideStore"}))
            prep.modify_plist(p,lambda obj:obj.update({"CFBundleDisplayName":"BerryStore"}))
            self.assertEqual(plistlib.loads(p.read_bytes())["CFBundleDisplayName"],"BerryStore")

    def test_bad_ipa_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"bad.ipa"
            with zipfile.ZipFile(p,"w") as z:
                z.writestr("Payload/SideStore.app/Info.plist",plistlib.dumps({
                    "CFBundleIdentifier":verify.EXPECTED_ID,
                    "CFBundleDisplayName":verify.EXPECTED_NAME}))
            with self.assertRaises(ValueError):
                verify.verify(p)

    def test_correct_ipa_accepted(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"ok.ipa"
            with zipfile.ZipFile(p,"w") as z:
                z.writestr("Payload/SideStore.app/Info.plist",plistlib.dumps({
                    "CFBundleIdentifier":verify.EXPECTED_ID,
                    "CFBundleDisplayName":verify.EXPECTED_NAME}))
                z.writestr("Payload/SideStore.app/SideStore",b"bin"*500)
            self.assertEqual(len(verify.verify(p)),64)

if __name__=="__main__":
    unittest.main()
