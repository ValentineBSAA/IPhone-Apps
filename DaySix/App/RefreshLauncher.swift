import Foundation
import UIKit

/// Apple officially supports launching a named shortcut via
/// shortcuts://run-shortcut?name=...
///
/// The shortcut must exist in the user's Shortcuts library. Running it is
/// not proof of success; the renewal audit still checks the new profile.
@MainActor
enum RefreshLauncher {
    static let name = "DaySix Refresh"

    static func runConfiguredShortcut() {
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "run-shortcut"
        components.queryItems = [URLQueryItem(name: "name", value: name)]
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    static func openShortcutEditor() {
        guard let url = URL(string: "shortcuts://create-shortcut") else { return }
        UIApplication.shared.open(url)
    }

    static func openSideStore() {
        guard let url = URL(string: "sidestore://") else { return }
        UIApplication.shared.open(url)
    }
}
