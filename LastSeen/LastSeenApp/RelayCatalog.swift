import Foundation

/// Local game content only. Package records are data, never executable downloads.
struct RelayPackage: Identifiable, Equatable {
    let id: String
    let title: String
    let version: String
    let source: String
    let category: String
    let icon: String
    let summary: String
    let detail: String
    let essential: Bool
    init(_ id: String, _ title: String, _ version: String, _ source: String, _ category: String, _ icon: String, _ summary: String, _ detail: String, essential: Bool = false) {
        self.id = id; self.title = title; self.version = version; self.source = source
        self.category = category; self.icon = icon; self.summary = summary; self.detail = detail; self.essential = essential
    }
}

struct RelaySource: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let icon: String
    let description: String
    let essential: Bool
}

enum RelayCatalog {
    static let sources = [
        RelaySource(id: "core", name: "Patchline Core", address: "https://core.patchline.example/", icon: "cpu", description: "Bootstrap and essential system components", essential: true),
        RelaySource(id: "studio", name: "Afterglow Studio", address: "https://studio.patchline.example/", icon: "paintpalette.fill", description: "Themes and LumaShell customization", essential: false),
        RelaySource(id: "utilities", name: "Nightshift Utilities", address: "https://utilities.patchline.example/", icon: "wrench.and.screwdriver.fill", description: "Lock screen and everyday tweaks", essential: false)
    ]
    static let defaultSources = "core|studio|utilities"
    static var requiredSourceIDs: Set<String> { Set(sources.map(\.id)) }
    static func recoveredSources(_ raw: String) -> String {
        encoded(ids(raw).intersection(requiredSourceIDs).union(requiredSourceIDs))
    }
    static let packages = [
        RelayPackage("bootstrap", "Patchline Bootstrap", "2.0.0", "core", "System", "shippingbox.fill", "Essential rootless environment", "Core package catalog and services for this phone.", essential: true),
        RelayPackage("loader", "Patchline Loader", "1.2.0", "core", "System", "cpu", "LumaShell tweak support", "Loads the phone's bundled customization settings.", essential: true),
        RelayPackage("relay", "Relay Package Manager", "1.1.0", "core", "System", "archivebox.fill", "Manage installed packages", "Browse local repositories, review changes and manage tweaks.", essential: true),
        RelayPackage("midnight", "Midnight Glass", "1.1.0", "studio", "Themes", "moon.stars.fill", "Midnight-blue wallpaper", "Adds a deep-blue wallpaper to the phone. Removing restores the default if selected."),
        RelayPackage("compact", "Compact Grid", "1.1.0", "studio", "Tweaks", "square.grid.3x3.fill", "Smaller launcher icons", "Reduces the size of launcher and dock icons."),
        RelayPackage("teal", "Afterglow Glass", "1.1.0", "studio", "Themes", "paintpalette.fill", "Ten hand-designed glass icons", "Replaces ten app icons with the approved Afterglow glass set. Calculator and Relay keep their stock artwork."),
        RelayPackage("clearlabels", "Clean Slate", "1.0.0", "studio", "Tweaks", "textformat", "Hide home-screen app labels", "Removes labels from the launcher and dock while preserving accessibility names."),
        RelayPackage("dockglass", "Ghost Dock", "1.0.0", "studio", "Tweaks", "rectangle.bottomthird.inset.filled", "Transparent dock", "Removes the material background from the dock."),
        RelayPackage("seconds", "Second Hand", "1.0.0", "utilities", "Lock Screen", "clock", "Show seconds on the lock screen", "Adds live seconds to the lock-screen clock."),
        RelayPackage("quietbadges", "Quiet Badges", "1.0.0", "utilities", "Tweaks", "bell.slash", "Hide launcher badges", "Hides the red unread count on app icons. Messages and notification history remain intact."),
        RelayPackage("fieldnotes", "Field Notes", "1.0.0", "utilities", "Utilities", "notebook", "Personal investigation notebook", "Keep your own observations and questions, separate from the restored records."),
        RelayPackage("pocketclipboard", "Pocket Clipboard", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Capture selected public text locally.", "Capture selected public text locally."),
        RelayPackage("clipglass", "ClipGlass", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Pin a selected record above the phone.", "Pin a selected record above the phone."),
        RelayPackage("quickpulse", "QuickPulse", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Add shortcuts to Control Center.", "Add shortcuts to Control Center."),
        RelayPackage("lumaplus", "LumaPlus", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Customize the launcher layout.", "Customize the launcher layout."),
        RelayPackage("afterglowstudio", "Afterglow Studio", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Preview and apply local themes.", "Preview and apply local themes."),
        RelayPackage("rootexplorer", "Root Explorer", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Browse the public restored file catalog.", "Browse the public restored file catalog."),
        RelayPackage("pulseterminal", "Pulse Terminal", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Run invented, local diagnostic commands.", "Run invented, local diagnostic commands."),
        RelayPackage("powerdeck", "PowerDeck", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Access safe restart and maintenance controls.", "Access safe restart and maintenance controls."),
        RelayPackage("tweakhub", "TweakHub", "1.0.0", "utilities", "Utilities", "wrench.and.screwdriver", "Review installed packages and service certifications.", "Review installed packages and service certifications."),
        RelayPackage("fivegrid", "Five Across", "1.0.0", "utilities", "Tweaks", "square.grid.3x3", "Five-column home screen", "Displays five icons across the launcher, with smaller icon sizing.")
    ]
    static func package(_ id: String) -> RelayPackage? { packages.first { $0.id == id } }
    static func source(_ id: String) -> RelaySource? { sources.first { $0.id == id } }
    static func ids(_ value: String) -> Set<String> { Set(value.split(separator: "|").map(String.init)) }
    static func encoded(_ values: Set<String>) -> String { values.sorted().joined(separator: "|") }
    static func installed(_ id: String, userIDs: Set<String>) -> Bool {
        package(id)?.essential == true || userIDs.contains(id)
    }
    static func available(_ id: String, flags: Set<String>) -> Bool {
        if id == "fieldnotes" { return RecoveryCircuit.unlocked(flags) }
        if let tool = LumaUtility(rawValue: id) { return flags.contains(tool.flag) }
        return true
    }
    static func visible(_ p: RelayPackage, sources: Set<String>, installed: Set<String>, flags: Set<String> = []) -> Bool {
        (available(p.id, flags: flags) || installed.contains(p.id)) && (p.essential || sources.contains(p.source) || installed.contains(p.id))
    }
    static func versions(_ raw: String) -> [String: String] {
        var result: [String: String] = [:]
        for item in raw.split(separator: "|") {
            let parts = item.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 { result[parts[0]] = parts[1] }
        }
        return result
    }
    static func encodedVersions(_ values: [String: String]) -> String {
        values.keys.sorted().map { $0 + "=" + (values[$0] ?? "") }.joined(separator: "|")
    }
    static func installedVersion(_ p: RelayPackage, versions: [String: String]) -> String {
        if p.essential { return p.version }
        return versions[p.id] ?? (["midnight", "compact", "teal"].contains(p.id) ? "1.0.0" : p.version)
    }
}

enum RelayAction: String, Equatable {
    case install = "Install", remove = "Remove", upgrade = "Upgrade"
}

struct RelayChange: Identifiable, Equatable {
    let package: RelayPackage
    let action: RelayAction
    var id: String { package.id }
}

enum RelayPlan {
    /// Deduplicate by package ID; never allow a core package to be removed.
    static func queue(_ change: RelayChange, into current: [RelayChange]) -> [RelayChange] {
        guard !change.package.essential else { return current }
        return current.filter { $0.id != change.id } + [change]
    }
    static func valid(_ changes: [RelayChange], sources: Set<String>, installed: Set<String>, flags: Set<String> = []) -> Bool {
        !changes.isEmpty && Set(changes.map(\.id)).count == changes.count && changes.allSatisfy { c in
            guard let p = RelayCatalog.package(c.id), p == c.package, !p.essential, (c.action == .remove || RelayCatalog.available(c.id, flags: flags)) else { return false }
            switch c.action {
            case .install: return sources.contains(p.source) && !installed.contains(p.id)
            case .remove: return installed.contains(p.id)
            case .upgrade: return sources.contains(p.source) && installed.contains(p.id)
            }
        }
    }
    static func applying(_ changes: [RelayChange], to installed: Set<String>, versions: [String: String]) -> (Set<String>, [String: String]) {
        var ids = installed
        var v = versions
        for change in changes where !change.package.essential {
            if change.action == .remove { ids.remove(change.id); v.removeValue(forKey: change.id) }
            else { ids.insert(change.id); v[change.id] = change.package.version }
        }
        return (ids, v)
    }
}
