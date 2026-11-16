#!/usr/bin/env python3
"""No-network tests for the separate-bundle DaySix signer technical preview."""
from __future__ import annotations

import importlib.util
import json
import plistlib
import tempfile
import unittest
import zipfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "preview_brand.py"
spec = importlib.util.spec_from_file_location("preview_brand", SCRIPT)
preview = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(preview)


class PreviewSafetyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "upstream"
        (self.root / "AltStore").mkdir(parents=True)
        self.plist = self.root / "AltStore" / "Info.plist"
        self.baseline = {
            "CFBundleName": "SideStore",
            "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
            "CFBundleURLTypes": [
                {"CFBundleURLSchemes": ["sidestore"]},
            ],
            "CFBundleShortVersionString": "0.7.0",
        }
        self.plist.write_bytes(plistlib.dumps(self.baseline))
        self.provenance = preview.patch(self.root, "abc123def")

    def make_ipa(self, bundle_id, label=None, preview_marker=True):
        info = {
            "CFBundleIdentifier": bundle_id,
            "CFBundleDisplayName": label or preview.DISPLAY_NAME,
            "DaySixSignerLabPreview": preview_marker,
        }
        path = self.root / "preview.ipa"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("Payload/SideStore.app/Info.plist",
                             plistlib.dumps(info))
        return path

    def test_patch_preserves_original_handler(self):
        modified = plistlib.loads(self.plist.read_bytes())
        self.assertEqual(modified["CFBundleDisplayName"], preview.DISPLAY_NAME)
        self.assertEqual(modified["CFBundleURLTypes"],
                         self.baseline["CFBundleURLTypes"])
        meta = json.loads(self.provenance.read_text())
        self.assertEqual(meta["upstream_commit"], "abc123def")
        self.assertFalse(meta["iphone_self_renewal_tested"])

    def test_unique_id_is_required(self):
        for official in ["com.SideStore.SideStore",
                         "com.SideStore.SideStore.Beta"]:
            with self.subTest(bundle_id=official):
                with self.assertRaises(RuntimeError):
                    preview.verify_ipa(self.make_ipa(official))
        result = preview.verify_ipa(
            self.make_ipa("com.SideStore.SideStore.DAY6LAB001"))
        self.assertEqual(result["display_name"], preview.DISPLAY_NAME)

    def test_preview_marker_is_required(self):
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(self.make_ipa(
                "com.SideStore.SideStore.DAY6LAB001",
                preview_marker=False))

    def test_correct_label_is_required(self):
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(self.make_ipa(
                "com.SideStore.SideStore.DAY6LAB001", label="SideStore"))

    def test_missing_app_rejected(self):
        path = self.root / "empty.ipa"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("README.txt", "bad input")
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(path)


if __name__ == "__main__":
    unittest.main(verbosity=2)
