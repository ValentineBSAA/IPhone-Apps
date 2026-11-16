#!/usr/bin/env python3
"""No-network tests for the separate-bundle DaySix signer technical preview."""
from __future__ import annotations

import importlib.util
import io
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
        (self.root / "Build.xcconfig").write_text(
            "ORG_IDENTIFIER = com.SideStore\n"
            "BASE_BUNDLE_ID                                  = $(ORG_IDENTIFIER).SideStore\n",
            encoding="utf-8")
        (self.root / "Makefile").write_text(
            "COMMON_BUILD_SETTINGS = ORG_IDENTIFIER=com.SideStore\n",
            encoding="utf-8")
        for name, extension in [
            ("AltStore", ""),
            ("AltWidget", ".AltWidget"),
        ]:
            entitlements = self.root / name / "Resources" / "ReleaseEntitlements.plist"
            entitlements.parent.mkdir(parents=True, exist_ok=True)
            entitlements.write_text(
                "<plist><dict><key>application-identifier</key>"
                "<string>XYZ0123456.com.SideStore.SideStore"
                + extension + "</string>"
                "<key>com.apple.security.application-groups</key>"
                "<array><string>group.com.SideStore.SideStore</string></array>"
                "</dict></plist>",
                encoding="utf-8")
        self.provenance = preview.patch(self.root, "abc123def")

    def make_ipa(self, bundle_id, label=None, preview_marker=True,
                 widget_id=None, backup_id=None):
        info = {
            "CFBundleIdentifier": bundle_id,
            "CFBundleDisplayName": label or preview.DISPLAY_NAME,
            "DaySixSignerLabPreview": preview_marker,
        }
        widget_info = {
            "CFBundleIdentifier": widget_id or preview.PREVIEW_BUNDLE_ID + ".AltWidget"
        }
        backup_info = {
            "CFBundleIdentifier": backup_id or preview.PREVIEW_BUNDLE_ID + ".SideBackup"
        }
        nested_data = io.BytesIO()
        with zipfile.ZipFile(nested_data, "w") as nested:
            nested.writestr("Payload/SideBackup.app/Info.plist",
                            plistlib.dumps(backup_info))
        path = self.root / "preview.ipa"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("Payload/SideStore.app/Info.plist",
                             plistlib.dumps(info))
            archive.writestr(
                "Payload/SideStore.app/PlugIns/AltWidgetExtension.appex/Info.plist",
                plistlib.dumps(widget_info))
            archive.writestr("Payload/SideStore.app/SideBackup.ipa",
                             nested_data.getvalue())
        return path

    def test_patch_preserves_original_handler(self):
        modified = plistlib.loads(self.plist.read_bytes())
        self.assertEqual(modified["CFBundleDisplayName"], preview.DISPLAY_NAME)
        self.assertEqual(modified["CFBundleURLTypes"],
                         self.baseline["CFBundleURLTypes"])
        meta = json.loads(self.provenance.read_text())
        self.assertEqual(meta["upstream_commit"], "abc123def")
        self.assertFalse(meta["iphone_self_renewal_tested"])
        self.assertEqual(meta["expected_bundle_id"], preview.PREVIEW_BUNDLE_ID)
        self.assertIn(
            "BASE_BUNDLE_ID                                  = $(ORG_IDENTIFIER).signerlab",
            (self.root / "Build.xcconfig").read_text())
        self.assertIn("ORG_IDENTIFIER=com.valentinebsaa.daysix",
                      (self.root / "Makefile").read_text())
        for relative in [
            "AltStore/Resources/ReleaseEntitlements.plist",
            "AltWidget/Resources/ReleaseEntitlements.plist",
        ]:
            payload = (self.root / relative).read_text()
            self.assertIn("group." + preview.PREVIEW_BUNDLE_ID, payload)
            self.assertNotIn("group.com.SideStore.SideStore", payload)
            self.assertIn(preview.PREVIEW_BUNDLE_ID, payload)

    def test_unique_id_is_required(self):
        for official in ["com.SideStore.SideStore",
                         "com.SideStore.SideStore.Beta"]:
            with self.subTest(bundle_id=official):
                with self.assertRaises(RuntimeError):
                    preview.verify_ipa(self.make_ipa(official))
        for not_expected in [
            "com.SideStore.SideStore.DAY6LAB001",
            "com.valentinebsaa.daysix",
            "com.valentinebsaa.daysix.signerlab2"
        ]:
            with self.subTest(bundle_id=not_expected):
                with self.assertRaises(RuntimeError):
                    preview.verify_ipa(self.make_ipa(not_expected))
        result = preview.verify_ipa(
            self.make_ipa(preview.PREVIEW_BUNDLE_ID))
        self.assertEqual(result["display_name"], preview.DISPLAY_NAME)

    def test_preview_marker_is_required(self):
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(self.make_ipa(
                preview.PREVIEW_BUNDLE_ID,
                preview_marker=False))

    def test_correct_label_is_required(self):
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(self.make_ipa(
                preview.PREVIEW_BUNDLE_ID, label="SideStore"))

    def test_nested_app_ids_cannot_impersonate_sidestore(self):
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(self.make_ipa(
                preview.PREVIEW_BUNDLE_ID,
                widget_id="com.SideStore.SideStore.AltWidget"))
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(self.make_ipa(
                preview.PREVIEW_BUNDLE_ID,
                backup_id="com.SideStore.SideStore.SideBackup"))

    def test_unknown_upstream_config_rejected(self):
        # A changed upstream identity scheme must not silently produce an IPA.
        self.plist.write_bytes(plistlib.dumps(self.baseline))
        with self.assertRaises(RuntimeError):
            preview.patch(self.root, "another-commit")

    def test_missing_app_rejected(self):
        path = self.root / "empty.ipa"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("README.txt", "bad input")
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(path)


if __name__ == "__main__":
    unittest.main(verbosity=2)
