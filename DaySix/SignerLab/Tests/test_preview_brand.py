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
        runtime_bundle = self.root / "Shared" / "Extensions" / "Bundle+AltStore.swift"
        runtime_bundle.parent.mkdir(parents=True, exist_ok=True)
        runtime_bundle.write_text(
            '    @objc dynamic static let storeAppBundleIdentifier = "com.SideStore.SideStore"\n'
            '    @objc dynamic static let appbundleIdentifier = "com.SideStore.SideStore"\n',
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
        pipeline = (
            self.root / "SideStore" / "Core" / "Operations"
            / "PipelineOperations" / "PerformBackupRestoreOperation.swift"
        )
        pipeline.parent.mkdir(parents=True, exist_ok=True)
        pipeline.write_text(
            'let callbackURL = URL(string: "sidestore://")!\n',
            encoding="utf-8")

        helper = self.root / "SideBackup" / "SideBackupApp.swift"
        helper.parent.mkdir(parents=True, exist_ok=True)
        helper.write_text(
            'guard let scheme = responseURL.scheme, scheme.hasPrefix("sidestore") else {\n'
            '    debugLog(logger, "does not start with \'sidestore\'. Aborting launch.")\n',
            encoding="utf-8")
        backup_plist = self.root / "SideBackup" / "Info.plist"
        backup_plist.write_bytes(plistlib.dumps({
            "CFBundleURLTypes": [{"CFBundleURLSchemes": ["sidebackup"]}]
        }))

        notifier = (self.root / "SideStore" / "Core" / "Operations"
                    / "StandaloneOperations"
                    / "ScheduleExpirationWarningNotificationOperation.swift")
        notifier.parent.mkdir(parents=True, exist_ok=True)
        notifier.write_text(
            "SideStore Expiring Soon\n"
            "SideStore Expiring Extremely Soon\n"
            "SideStore Expired\n"
            "SideStore will expire in 24 hours.\n"
            "SideStore will expire in 6 hours!\n"
            "SideStore has expired.\n"
            "content.sound = .default\n",
            encoding="utf-8")
        tab = self.root / "AltStore" / "TabBarController.swift"
        tab.write_text("""@preconcurrency import UIKit

extension TabBarController
{
    private enum Tab: Int, CaseIterable
    {
        case news
        case sources
        case browse
        case myApps
        case settings
    }
}

final class TabBarController: UITabBarController
{
    private var sourcesViewController: SourcesViewController!

    override func viewDidLoad() {
        let browseNavigationController = self.viewControllers![Tab.browse.rawValue] as! UINavigationController
        browseNavigationController.tabBarItem.image = UIImage(systemName: "bag")
        
        let sourcesNavigationController = self.viewControllers![Tab.sources.rawValue] as! UINavigationController
        self.sourcesViewController = sourcesNavigationController.viewControllers.first as? SourcesViewController
    }
    func presentSources(_ sender: Any) {
        self.selectedIndex = Tab.sources.rawValue
    }
}

private extension TabBarController
{
    @objc func importApp(_ notification: Notification)
    {
        self.selectedIndex = Tab.myApps.rawValue
    }
}
""", encoding="utf-8")

        apps_source = self.root / "AltStore" / "My Apps" / "MyAppsViewController.swift"
        apps_source.parent.mkdir(parents=True, exist_ok=True)
        apps_source.write_text(
            "    private func presentDocumentPicker()\n"
            "    {\n"
            "        let documentPickerViewController = UIDocumentPickerViewController()\n"
            "        documentPickerViewController.delegate = self\n"
            "        self.present(documentPickerViewController, animated: true, completion: nil)\n"
            "    }\n"
            "    func documentPickerDidPick() {\n"
            "        InstallAppDialog.present(ipaURL: fileURL, from: self) {\n"
            "            AppManager.shared.install(.url(fileURL), presentingViewController: self)\n"
            "        }\n"
            "    }\n",
            encoding="utf-8")

        self.provenance = preview.patch(self.root, "abc123def")

    def make_ipa(self, bundle_id, label=None, preview_marker=True,
                 widget_id=None, backup_id=None, primary_scheme=None,
                 backup_scheme="daysixbackup"):
        info = {
            "CFBundleIdentifier": bundle_id,
            "CFBundleDisplayName": label or preview.DISPLAY_NAME,
            "CFBundleName": preview.DISPLAY_NAME,
            "DaySixSignerLabPreview": preview_marker,
            "CFBundleURLTypes": [{
                "CFBundleURLName": "DaySix Signer Lab General",
                "CFBundleURLSchemes": [
                    primary_scheme if primary_scheme is not None else preview.PREVIEW_URL_SCHEME
                ]
            }, {
                "CFBundleURLName": "DaySix Signer Lab Backup",
                "CFBundleURLSchemes": ["sidestore-" + preview.PREVIEW_BUNDLE_ID]
            }],
        }
        widget_info = {
            "CFBundleIdentifier": widget_id or preview.PREVIEW_BUNDLE_ID + ".AltWidget"
        }
        backup_info = {
            "CFBundleIdentifier": backup_id or preview.PREVIEW_BUNDLE_ID + ".SideBackup",
            "CFBundleURLTypes": [
                {"CFBundleURLSchemes": [backup_scheme]}
            ],
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
        self.assertEqual(modified["CFBundleName"], preview.DISPLAY_NAME)
        self.assertEqual(modified["CFBundleURLTypes"][0]["CFBundleURLName"],
                         "DaySix Signer Lab General")
        self.assertEqual(modified["CFBundleURLTypes"][0]["CFBundleURLSchemes"],
                         [preview.PREVIEW_URL_SCHEME])
        self.assertNotEqual(modified["CFBundleURLTypes"],
                            self.baseline["CFBundleURLTypes"])
        meta = json.loads(self.provenance.read_text())
        self.assertEqual(meta["upstream_commit"], "abc123def")
        self.assertFalse(meta["iphone_self_renewal_tested"])
        self.assertEqual(meta["expected_bundle_id"], preview.PREVIEW_BUNDLE_ID)
        tab_source = (self.root / "AltStore" / "TabBarController.swift").read_text()
        self.assertIn("private struct DaySixSignerHomeView: View", tab_source)
        self.assertIn("func showRealInstaller()", tab_source)
        self.assertIn("apps.daySixOpenIPAFromFiles()", tab_source)
        self.assertNotIn("apps.sideloadApp(button)", tab_source)
        picker_source = (
            self.root / "AltStore" / "My Apps" / "MyAppsViewController.swift"
        ).read_text()
        self.assertIn("    func daySixOpenIPAFromFiles()", picker_source)
        self.assertIn("    private func presentDocumentPicker()", picker_source)
        self.assertIn("InstallAppDialog.present(ipaURL: fileURL", picker_source)
        self.assertIn("AppManager.shared.install", picker_source)
        self.assertIn("func renewRealApps()", tab_source)
        self.assertIn("let readStatus: () -> DaySixSigningSnapshot", tab_source)
        self.assertIn("signingStatusCard", tab_source)
        self.assertIn("InstalledApp.fetchAppsForRefreshingAll", tab_source)
        self.assertIn("InstalledApp.fetchAltStore", tab_source)
        self.assertIn("selfExpiry: ownSigner?.expirationDate", tab_source)
        self.assertIn("status = readStatus()", tab_source)
        self.assertNotIn(".contentTransition(.numericText())", tab_source)
        self.assertIn("A successful build or a refresh request does not prove", tab_source)
        self.assertIn("apps.daySixRefreshManagedApps()", tab_source)
        self.assertIn("self.refreshAllApps(", picker_source)
        self.assertIn("SwiftUI.Button(action: importIPA)", tab_source)
        self.assertIn("self.viewControllers = [home, apps, settings]", tab_source)
        self.assertNotIn("self.selectedIndex = Tab.sources.rawValue", tab_source)
        self.assertIn(
            "BASE_BUNDLE_ID                                  = $(ORG_IDENTIFIER).signerlab",
            (self.root / "Build.xcconfig").read_text())
        self.assertIn("ORG_IDENTIFIER=com.valentinebsaa.daysix",
                      (self.root / "Makefile").read_text())
        runtime_helper = (
            self.root / "Shared" / "Extensions" / "Bundle+AltStore.swift"
        ).read_text()
        self.assertEqual(runtime_helper.count(preview.PREVIEW_BUNDLE_ID), 2)
        self.assertNotIn("com.SideStore.SideStore", runtime_helper)
        pipeline = (
            self.root / "SideStore" / "Core" / "Operations"
            / "PipelineOperations" / "PerformBackupRestoreOperation.swift"
        ).read_text()
        self.assertIn('URL(string: "daysixlab://")', pipeline)
        self.assertNotIn('URL(string: "sidestore://")', pipeline)
        backup_swift = (self.root / "SideBackup" / "SideBackupApp.swift").read_text()
        self.assertIn('scheme == "daysixlab"', backup_swift)
        self.assertIn('scheme.hasPrefix("sidestore-")', backup_swift)
        notifier = (self.root / "SideStore" / "Core" / "Operations"
                    / "StandaloneOperations"
                    / "ScheduleExpirationWarningNotificationOperation.swift"
                   ).read_text()
        self.assertIn("DaySix Signer Lab Expiring Soon", notifier)
        self.assertIn("DaySix Signer Lab Expired", notifier)
        self.assertNotIn("SideStore Expiring Soon", notifier)
        self.assertIn("content.sound = .default", notifier)
        backup_plist = plistlib.loads(
            (self.root / "SideBackup" / "Info.plist").read_bytes()
        )
        self.assertEqual(
            backup_plist["CFBundleURLTypes"][0]["CFBundleURLSchemes"],
            ["daysixbackup"]
        )
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

    def test_official_url_scheme_is_rejected(self):
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(self.make_ipa(
                preview.PREVIEW_BUNDLE_ID, primary_scheme="sidestore"))
        result = preview.verify_ipa(self.make_ipa(
            preview.PREVIEW_BUNDLE_ID,
            primary_scheme=preview.PREVIEW_URL_SCHEME))
        self.assertEqual(result["bundle_id"], preview.PREVIEW_BUNDLE_ID)

    def test_backup_url_scheme_does_not_conflict(self):
        with self.assertRaises(RuntimeError):
            preview.verify_ipa(self.make_ipa(
                preview.PREVIEW_BUNDLE_ID,
                backup_scheme="sidebackup"))
        result = preview.verify_ipa(self.make_ipa(
            preview.PREVIEW_BUNDLE_ID,
            backup_scheme="daysixbackup"))
        self.assertEqual(result["bundle_id"], preview.PREVIEW_BUNDLE_ID)

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
