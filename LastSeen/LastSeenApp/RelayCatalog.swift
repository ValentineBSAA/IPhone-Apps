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
    var gate: String? = nil
}

enum RelayCatalog {
    static let sources = [
        RelaySource(id: "core", name: "Patchline Core", address: "https://core.patchline.example/", icon: "cpu", description: "Bootstrap and essential system components", essential: true),
        RelaySource(id: "studio", name: "Afterglow Studio", address: "https://studio.patchline.example/", icon: "paintpalette.fill", description: "Themes and LumaShell customization", essential: false),
        RelaySource(id: "utilities", name: "Nightshift Utilities", address: "https://utilities.patchline.example/", icon: "wrench.and.screwdriver.fill", description: "Lock screen and everyday tweaks", essential: false)
,
        RelaySource(id: "folio", name: "Folio Works", address: "https://folio-tools.example/", icon: "book", description: "Readable local web pages", essential: false, gate: "web.visited.repo-folio"),
        RelaySource(id: "postbox", name: "Postbox Labs", address: "https://postbox-tools.example/", icon: "paperclip", description: "Local correspondence utilities", essential: false, gate: "web.visited.repo-postbox"),
        RelaySource(id: "leaf", name: "Leaf Paper", address: "https://leaf-paper.example/", icon: "doc.richtext", description: "Document readability tools", essential: false, gate: "web.visited.repo-leaf"),
        RelaySource(id: "chronicle", name: "Chronicle Works", address: "https://chronicle-tools.example/", icon: "clock", description: "Local timeline and activity display", essential: false, gate: "web.visited.repo-chronicle"),
        RelaySource(id: "bench", name: "Benchcraft", address: "https://benchcraft-tools.example/", icon: "desktopcomputer", description: "Repair console extensions", essential: false, gate: "web.visited.repo-bench")
    ]
    static let defaultSources = "core|studio|utilities"
    static var requiredSourceIDs: Set<String> { ["core","studio","utilities"] }
    static func sourceAuthorized(_ id:String,flags:Set<String>)->Bool {
        guard let source=source(id) else{return false}
        return source.gate.map { flags.contains($0) } ?? true
    }
    static func recoveredSources(_ raw: String,flags:Set<String> = []) -> String {
        encoded(Set(ids(raw).filter { sourceAuthorized($0,flags:flags) }).union(requiredSourceIDs))
    }
    static func sourceForAddress(_ raw:String,flags:Set<String>)->RelaySource? {
        let q=raw.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
        let normalized=q.hasSuffix("/") ? q : q+"/"
        return sources.first { $0.address.lowercased()==normalized && sourceAuthorized($0.id,flags:flags) }
    }
    static func tweakActive(_ id:String,installed:String,safeMode:Bool,flags:Set<String>)->Bool {
        guard !safeMode, ids(installed).contains(id), available(id,flags:flags) else { return false }
        let optional = ids(installed)
        let effective = optional.union(packages.filter(\.essential).map(\.id))
        return requirements(id).isSubset(of: effective) && conflicts(id).isDisjoint(with: optional)
    }
    static let packages = [
        RelayPackage("veil","VEIL","1.0.0","utilities","Applications","eye.slash","Local anonymous browser","Browse authorized fictional archived pages. No real network connection."),
        RelayPackage("relay-support", "Relay Support", "1.0.0", "utilities", "Applications", "headset", "Personal technical support", "Install Alex Morgan's standalone support application for local technical guides. Removing the package hides the app but preserves its separate history. Available during simulated Safe Mode."),
        RelayPackage("bootstrap", "Patchline Bootstrap", "2.0.0", "core", "System", "shippingbox.fill", "Essential rootless environment", "Core package catalog and services for this phone.", essential: true),
        RelayPackage("loader", "Patchline Loader", "1.2.0", "core", "System", "cpu", "LumaShell tweak support", "Loads the phone's bundled customization settings.", essential: true),
        RelayPackage("relay", "Relay Package Manager", "1.1.0", "core", "System", "archivebox.fill", "Manage installed packages", "Browse local repositories, review changes and manage tweaks.", essential: true),
        RelayPackage("midnight", "Midnight Glass", "1.1.0", "studio", "Themes", "moon.stars.fill", "Midnight-blue wallpaper", "Adds a deep-blue wallpaper to the phone. Removing restores the default if selected."),
        RelayPackage("compact", "Compact Grid", "1.1.0", "studio", "Tweaks", "square.grid.3x3.fill", "Smaller launcher icons", "Reduces the size of launcher and dock icons."),
        RelayPackage("teal", "Afterglow Glass", "1.1.0", "studio", "Themes", "paintpalette.fill", "Ten hand-designed glass icons", "Replaces ten app icons with the approved Afterglow glass set. Calculator and Relay keep their stock artwork."),
        RelayPackage("clearlabels", "Clean Slate", "1.0.0", "studio", "Tweaks", "textformat", "Hide home-screen app labels", "Removes labels from the launcher and dock while preserving accessibility names."),
        RelayPackage("dockglass", "Ghost Dock", "1.0.0", "studio", "Tweaks", "rectangle.bottomthird.inset.filled", "Transparent dock", "Removes the material background from the dock."),
        RelayPackage("dockcontrast", "Slate Dock", "1.0.0", "studio", "Tweaks", "rectangle.bottomthird.inset.filled", "High-contrast dock background", "Adds an opaque, high-contrast dock surface. Conflicts with Ghost Dock."),
        RelayPackage("privatepreview", "Preview Shield", "1.0.0", "utilities", "Lock Screen", "eye.slash.fill", "Hide lock-screen message previews", "Hides message previews while the simulated phone is locked. Removing restores the previous viewing preference."),
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
,
        RelayPackage("readerfocus", "Reader Focus", "1.0.0", "folio", "Accessibility", "book", "Larger text in the browser", "Adds larger, more comfortable text to local website articles."),
        RelayPackage("mailattach", "Attachment Lens", "1.0.0", "postbox", "Utilities", "paperclip", "Find mail with readable attachments", "Adds an Attachments mailbox for currently accessible documents."),
        RelayPackage("documentzoom", "Document Zoom", "1.0.0", "leaf", "Accessibility", "doc.richtext", "Larger document text and table cells", "Adds a reading-size control to the native document reader."),
        RelayPackage("socialtime", "Post Timestamp", "1.0.0", "chronicle", "Utilities", "clock", "Show detailed social post timestamps", "Shows time as well as date on the three local social feeds."),
        RelayPackage("workbenchmetrics", "Diagnostics Strip", "1.0.0", "bench", "Utilities", "desktopcomputer", "Additional repair console status", "Shows available document count and installed optional package count at the connected repair workstation.")
    ]
    static func requirements(_ id: String) -> Set<String> {
        guard let p = package(id) else { return [] }
        if p.essential { return id == "bootstrap" ? [] : id == "loader" ? ["bootstrap"] : ["bootstrap","loader"] }
        return ["bootstrap","loader"]
    }
    static func conflicts(_ id: String) -> Set<String> {
        switch id {
        case "dockglass": return ["dockcontrast"]
        case "dockcontrast": return ["dockglass"]
        default: return []
        }
    }
    static func publisher(_ p: RelayPackage) -> String { source(p.source)?.name ?? "Unknown publisher" }
    static func package(_ id: String) -> RelayPackage? { packages.first { $0.id == id } }
    static func source(_ id: String) -> RelaySource? { sources.first { $0.id == id } }
    static func ids(_ value: String) -> Set<String> { Set(value.split(separator: "|").map(String.init)) }
    static func encoded(_ values: Set<String>) -> String { values.sorted().joined(separator: "|") }
    static func installed(_ id: String, userIDs: Set<String>) -> Bool {
        package(id)?.essential == true || userIDs.contains(id)
    }
    static func available(_ id: String, flags: Set<String>) -> Bool {
        guard let p=package(id),sourceAuthorized(p.source,flags:flags) else{return false}
        if id == "veil" { return ["phone-tutorial-finished","web.visited.archive",VeilArchive.discovery].allSatisfy { flags.contains($0) } }
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
    static func problems(_ changes: [RelayChange], sources: Set<String>, installed: Set<String>, flags: Set<String> = [], versions: [String: String]? = nil) -> [String] {
        if changes.isEmpty { return ["The queue is empty."] }
        if Set(changes.map(\.id)).count != changes.count { return ["The queue contains duplicate packages."] }
        var errors: [String] = []
        for c in changes {
            guard let p = RelayCatalog.package(c.id), p == c.package, !p.essential else {
                errors.append("A package is protected or no longer matches its index."); continue
            }
            if c.action != .remove && (!RelayCatalog.available(c.id, flags: flags) || !sources.contains(p.source)) {
                errors.append("A queued package is no longer available from an enabled source."); continue
            }
            switch c.action {
            case .install:
                if installed.contains(p.id) { errors.append(p.title + " is already installed.") }
            case .remove:
                if !installed.contains(p.id) { errors.append(p.title + " is no longer installed.") }
            case .upgrade:
                if !installed.contains(p.id) { errors.append(p.title + " is no longer installed.") }
                else if let versions, RelayCatalog.installedVersion(p, versions: versions) == p.version { errors.append(p.title + " is already up to date.") }
            }
        }
        guard errors.isEmpty else { return errors }
        let (next, _) = applying(changes, to: installed, versions: versions ?? [:])
        let effective = next.union(RelayCatalog.packages.filter(\.essential).map(\.id))
        // Validate the final state, allowing removal of a conflicting package
        // in the same transaction. Do not strand existing saves with unrelated
        // invalid records: only report conflicts introduced by this queue.
        for c in changes where c.action != .remove {
            if !RelayCatalog.requirements(c.id).isSubset(of: effective) { errors.append(c.package.title + " has missing requirements.") }
            if !RelayCatalog.conflicts(c.id).isDisjoint(with: next) {
                errors.append(c.package.title + " conflicts with an installed package. Queue its removal first.")
            }
        }
        return errors
    }
    static func valid(_ changes: [RelayChange], sources: Set<String>, installed: Set<String>, flags: Set<String> = [], versions: [String: String]? = nil) -> Bool {
        problems(changes, sources: sources, installed: installed, flags: flags, versions: versions).isEmpty
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
