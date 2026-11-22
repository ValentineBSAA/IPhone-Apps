#!/usr/bin/env python3
"""Patch the pinned SideStore UIKit shell with DaySix's simple SwiftUI home.

The upstream My Apps, signing, installation, authentication, and refresh
pipelines stay intact. The new home only forwards taps to these real actions.
"""
from pathlib import Path


def one(path: Path, old: str, new: str) -> None:
    if not path.is_file():
        raise FileNotFoundError(path)
    original = path.read_text(encoding="utf-8")
    count = original.count(old)
    if count != 1:
        raise RuntimeError(
            f"DaySix navigation patch expected one match, got {count}: "
            f"{path}: {old[:90]!r}")
    path.write_text(original.replace(old, new), encoding="utf-8")


def patch(root: Path) -> None:
    tab = root / "AltStore" / "TabBarController.swift"
    one(tab, "@preconcurrency import UIKit",
        "@preconcurrency import UIKit\nimport SwiftUI")

    one(tab, """    private enum Tab: Int, CaseIterable
    {
        case news
        case sources
        case browse
        case myApps
        case settings
    }""", """    private enum Tab: Int, CaseIterable
    {
        case home
        case myApps
        case settings
    }""")

    one(tab, "    private var sourcesViewController: SourcesViewController!",
        """    private var sourcesViewController: SourcesViewController!
    private var sourcesNavigationController: UINavigationController?""")

    one(tab, """        let browseNavigationController = self.viewControllers![Tab.browse.rawValue] as! UINavigationController
        browseNavigationController.tabBarItem.image = UIImage(systemName: "bag")
        
        let sourcesNavigationController = self.viewControllers![Tab.sources.rawValue] as! UINavigationController
        self.sourcesViewController = sourcesNavigationController.viewControllers.first as? SourcesViewController""",
        """        // Pinned upstream uses a 5-tab storyboard. Keep the real
        // My Apps signer and settings, and simplify only the visible shell.
        guard let original = self.viewControllers,
              original.count == 5,
              let apps = original[3] as? UINavigationController,
              let sources = original[1] as? UINavigationController,
              let settings = original[4] as? UINavigationController
        else {
            assertionFailure("DaySix expected pinned upstream tab layout")
            return
        }
        self.sourcesNavigationController = sources
        self.sourcesViewController = sources.viewControllers.first as? SourcesViewController
        let homeView = DaySixSignerHomeView(
            importIPA: { [weak self] in self?.showRealInstaller() },
            showApps: { [weak self] in self?.selectedIndex = Tab.myApps.rawValue },
            refreshApps: { [weak self] in self?.renewRealApps() },
            openSettings: { [weak self] in self?.selectedIndex = Tab.settings.rawValue },
            openSources: { [weak self] in self?.presentSources(self as Any) },
            readStatus: {
                // The upstream database is the authority for managed apps.
                // This snapshot does not infer an installation from a button tap.
                let context = DatabaseManager.shared.viewContext
                let renewable = InstalledApp.fetchAppsForRefreshingAll(in: context)
                let ownSigner = InstalledApp.fetchAltStore(in: context)
                return DaySixSigningSnapshot(
                    renewableAppCount: renewable.count,
                    selfExpiry: ownSigner?.expirationDate
                )
            }
        )
        let home = UINavigationController(
            rootViewController: UIHostingController(rootView: homeView))
        home.setNavigationBarHidden(true, animated: false)
        home.tabBarItem = UITabBarItem(
            title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
        apps.tabBarItem = UITabBarItem(
            title: "My Apps", image: UIImage(systemName: "square.stack.fill"), tag: 1)
        settings.tabBarItem = UITabBarItem(
            title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 2)
        self.viewControllers = [home, apps, settings]
        self.selectedIndex = Tab.home.rawValue
        self.tabBar.tintColor = UIColor(
            red: 0.25, green: 0.95, blue: 0.80, alpha: 1)
        debugLog("[DaySix] Real signer with simplified navigation loaded")""")

    one(tab, "        self.selectedIndex = Tab.sources.rawValue",
        """        guard let sources = self.sourcesNavigationController else { return }
        sources.modalPresentationStyle = .pageSheet
        self.present(sources, animated: true)""")

    # Upstream's Files picker already calls InstallAppDialog and then
    # AppManager.shared.install when the user confirms. Expose that exact
    # flow to our simplified home instead of opening an inert share sheet
    # or a non-attached navigation bar popover.
    apps_file = root / "AltStore" / "My Apps" / "MyAppsViewController.swift"
    # Upstream declares the picker and refresh actions in private
    # extensions. Keep them private and add narrow, internal wrappers
    # alongside them IN THE SAME SOURCE FILE so Swift's access rules hold.
    with apps_file.open("a", encoding="utf-8") as file:
        file.write("""
#if !os(tvOS)
extension MyAppsViewController {
    func daySixOpenIPAFromFiles() {
        self.presentDocumentPicker()
    }

    func daySixRefreshManagedApps() {
        self.refreshAllApps(UIBarButtonItem(barButtonSystemItem: .refresh,
                                           target: nil, action: nil))
    }
}
#endif
""")

    actions = """private extension TabBarController
{
    func showRealInstaller()
    {
        // Choose a real IPA file. On selection, the existing
        // MyAppsViewController UIDocumentPickerDelegate presents upstream's
        // InstallAppDialog and calls AppManager.shared.install on approval.
        self.selectedIndex = Tab.myApps.rawValue
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let navigation = self.viewControllers?[Tab.myApps.rawValue] as? UINavigationController,
                  let apps = navigation.viewControllers.first as? MyAppsViewController
            else { return }
            navigation.popToRootViewController(animated: false)
            apps.loadViewIfNeeded()
            apps.daySixOpenIPAFromFiles()
        }
    }

    func renewRealApps()
    {
        // This invokes the genuine SideStore refresh pipeline.
        self.selectedIndex = Tab.myApps.rawValue
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let navigation = self.viewControllers?[Tab.myApps.rawValue] as? UINavigationController,
                  let apps = navigation.viewControllers.first as? MyAppsViewController
            else { return }
            apps.daySixRefreshManagedApps()
        }
    }
}

"""
    one(tab,
        """private extension TabBarController
{
    @objc func importApp(_ notification: Notification)""",
        actions + """private extension TabBarController
{
    @objc func importApp(_ notification: Notification)""")

    view = Path(__file__).with_name("DaySixSignerHome.swift")
    if not view.is_file():
        raise FileNotFoundError(view)
    source = view.read_text(encoding="utf-8")
    if ("private struct DaySixSignerHomeView: View" not in source
            or "let importIPA: () -> Void" not in source
            or "let refreshApps: () -> Void" not in source):
        raise RuntimeError("DaySix SwiftUI home source missing required actions")
    with tab.open("a", encoding="utf-8") as out:
        out.write("\n\n" + source + "\n")
