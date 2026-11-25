import SwiftUI

/// Bundled, free visual tweaks only. Never downloads or installs executable code.
struct RelayPackagesView: View {
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @AppStorage("lastseen.lab.wallpaper") private var wallpaper = 0
    @AppStorage("lastseen.relay.compactIcons") private var compactIcons = false
    @State private var pending: String?
    @State private var progress = 0
    @AppStorage("lastseen.relay.tealTheme") private var tealTheme = false
    @State private var respringing = false
    @State private var themeAction: Bool?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let packages = [
        Package(id: "midnight", title: "Midnight Glass", icon: "moon.stars.fill", detail: "Adds a midnight-blue wallpaper."),
        Package(id: "compact", title: "Compact Grid", icon: "square.grid.3x3.fill", detail: "Makes launcher icons slightly smaller."),
        Package(id: "teal", title: "Afterglow Glass", icon: "paintpalette.fill", detail: "Ten original teal-glass phone icons. Applies after a simulated respring.")
    ]
    var body: some View {
        List {
            Section {
                Label("Relay", systemImage: "shippingbox.fill").font(.largeTitle.bold()).foregroundColor(.teal)
                Text("Local repository • All packages are free").font(.caption).foregroundColor(.secondary)
            }
            Section("Available packages") {
                ForEach(packages) { package in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            if package.id == "teal" { OpeningArt(name: "Theme_Messages", size: 46) } else { Image(systemName: package.icon).font(.title2).foregroundColor(.teal) }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(package.title).font(.headline)
                                Text(package.detail).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(isInstalled(package.id) ? "Installed" : "Free").font(.caption).foregroundColor(.teal)
                        }
                        if package.id == "teal" {
                            HStack(spacing: 8) {
                                ForEach(Array(ApprovedArt.theme.prefix(5)), id: \.self) { name in OpeningArt(name: name, size: 35) }
                            }.accessibilityLabel("Afterglow Glass theme preview")
                        }
                        Button(isInstalled(package.id) ? "Remove" : "Install") {
                            if package.id == "teal" && isInstalled(package.id) { themeAction = false; respringing = true }
                            else if isInstalled(package.id) { remove(package.id) } else { progress = 0; pending = package.id }
                        }.buttonStyle(.bordered).disabled(pending != nil)
                        if pending == package.id {
                            ProgressView(value: Double(progress), total: 100).tint(.teal)
                        }
                    }.padding(.vertical, 5)
                }
            }
            Section("System") {
                Button { themeAction = nil; respringing = true } label: {
                    Label("Respring", systemImage: "arrow.clockwise")
                }.disabled(pending != nil)
            }
            Section("About") {
                Text("Relay changes only the in-game appearance. No real packages, jailbreak or network access.").font(.footnote).foregroundColor(.secondary)
            }
        }.navigationTitle("Relay").navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $respringing) {
            ThemeRespringView {
                if let apply = themeAction {
                    var ids = Set(installed.split(separator: "|").map(String.init))
                    if apply { ids.insert("teal") } else { ids.remove("teal") }
                    installed = ids.sorted().joined(separator: "|")
                    tealTheme = apply
                    OpeningQA.record(apply ? "Afterglow theme applied" : "Original theme restored")
                }
                themeAction = nil; respringing = false
            }
        }
        .task(id: pending) {
            guard let id = pending else { return }
            while progress < 100 && !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 80_000_000) } catch { return }
                progress = min(100, progress + (reduceMotion ? 100 : 10))
            }
            guard !Task.isCancelled, pending == id else { return }
            if id == "teal" { pending = nil; themeAction = true; respringing = true; return }
            var ids = Set(installed.split(separator: "|").map(String.init)); ids.insert(id)
            installed = ids.sorted().joined(separator: "|")
            if id == "midnight" { wallpaper = 2 }
            if id == "compact" { compactIcons = true }
            pending = nil
        }
    }
    private func isInstalled(_ id: String) -> Bool { installed.split(separator: "|").contains(Substring(id)) }
    private func remove(_ id: String) {
        var ids = Set(installed.split(separator: "|").map(String.init)); ids.remove(id)
        installed = ids.sorted().joined(separator: "|")
        if id == "midnight" && wallpaper == 2 { wallpaper = 0 }
        if id == "compact" { compactIcons = false }
    }
    private struct Package: Identifiable {
        let id: String
        let title: String
        let icon: String
        let detail: String
    }
}
