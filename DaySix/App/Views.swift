import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum DS {
    static let ink = Color(red: 0.027, green: 0.040, blue: 0.094)
    static let card = Color(red: 0.074, green: 0.097, blue: 0.170)
    static let cardBright = Color(red: 0.104, green: 0.139, blue: 0.216)
    static let mint = Color(red: 0.29, green: 0.96, blue: 0.82)
    static let violet = Color(red: 0.63, green: 0.54, blue: 1.0)
    static let muted = Color(red: 0.65, green: 0.73, blue: 0.82)
    static let amber = Color(red: 1.0, green: 0.77, blue: 0.39)
    static let gradient = LinearGradient(colors: [mint, violet], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(DS.card.opacity(0.96))
                    .overlay {
                        RoundedRectangle(cornerRadius: 23, style: .continuous)
                            .strokeBorder(.white.opacity(0.09), lineWidth: 1)
                    }
            }
    }
}

struct GlowButton: View {
    let title: String
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(DS.ink)
                .background(DS.gradient, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct DaySixRootView: View {
    @AppStorage("daysix.didFinishOnboarding.v1") private var didFinishOnboarding = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "square.grid.2x2.fill") }
            ManagedAppsView()
                .tabItem { Label("My Apps", systemImage: "square.stack.3d.up.fill") }
            RenewalCenterView()
                .tabItem { Label("Renew", systemImage: "arrow.triangle.2.circlepath") }
            IPAInstallView()
                .tabItem { Label("Install", systemImage: "square.and.arrow.down.fill") }
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
        .tint(DS.mint)
        .toolbarColorScheme(.dark, for: .tabBar)
        .fullScreenCover(isPresented: Binding(
            get: { !didFinishOnboarding },
            set: { if !$0 { didFinishOnboarding = true } })) {
            DaySixOnboardingView { didFinishOnboarding = true }
        }
    }
}

struct DaySixBackground<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ZStack {
            DS.ink.ignoresSafeArea()
            RadialGradient(colors: [DS.violet.opacity(0.19), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 430)
                .ignoresSafeArea()
            content
        }
    }
}

struct SectionHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 29, weight: .bold, design: .rounded))
            Text(subtitle).font(.subheadline).foregroundStyle(DS.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: DaySixStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            DaySixBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DAY SIX")
                                    .tracking(4)
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(DS.mint)
                                Text("Your apps, protected.")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                            }
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 31, weight: .medium))
                                .foregroundStyle(DS.gradient)
                                .frame(width: 62, height: 62)
                                .background(DS.cardBright, in: RoundedRectangle(cornerRadius: 19))
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 17) {
                                HStack {
                                    Label("RENEWAL MONITOR", systemImage: "arrow.triangle.2.circlepath")
                                        .font(.caption.bold()).tracking(1.3)
                                        .foregroundStyle(DS.mint)
                                    Spacer()
                                    Text("DAY 6 OF 7")
                                        .font(.caption2.bold())
                                        .foregroundStyle(DS.muted)
                                }
                                Text(store.urgentCount > 0 ? "Renewal needed." :
                                     store.selfExpiresAt == nil ? "Check signing setup." : "Looking good.")
                                    .font(.system(size: 27, weight: .bold, design: .rounded))
                                Text(store.urgentCount > 0
                                     ? "\(store.urgentCount) signature(s) are due, including DaySix itself when necessary."
                                     : store.selfExpiresAt == nil
                                       ? "DaySix's own signing expiry is unknown. Check SideStore, then add other apps to track."
                                       : "DaySix is monitoring its own signature. Other apps can be added below.")
                                    .font(.subheadline)
                                    .foregroundStyle(DS.muted)
                                HStack(spacing: 10) {
                                    Image(systemName: store.urgentCount > 0 ? "exclamationmark.circle.fill" : "checkmark.seal.fill")
                                    Text(store.urgentCount > 0 ? "Action required" : "Tracking active")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(store.urgentCount > 0 ? DS.amber : DS.mint)
                                if store.urgentCount > 0 {
                                    GlowButton(title: "Run Renewal Shortcut", symbol: "arrow.clockwise") {
                                        RefreshLauncher.runConfiguredShortcut()
                                    }
                                    Text("This launches your saved Shortcut. Confirm the new signing date afterward.")
                                        .font(.caption2).foregroundStyle(DS.muted)
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            stat(number: "\(store.apps.count + 1)", label: "Monitored apps", symbol: "square.stack.fill")
                            stat(number: "\(store.urgentCount)", label: "Due now", symbol: "clock.arrow.circlepath")
                        }
                        Text("THIS IPHONE APP")
                            .font(.caption.bold()).tracking(1.5).foregroundStyle(DS.muted)
                        SelfSignatureCard()
                        HStack {
                            Text("UPCOMING RENEWALS")
                                .font(.caption.bold()).tracking(1.5)
                                .foregroundStyle(DS.muted)
                            Spacer()
                            Text("Verified dates only").font(.caption2).foregroundStyle(DS.muted)
                        }
                        if store.apps.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Image(systemName: "plus.app.fill")
                                        .font(.system(size: 28)).foregroundStyle(DS.violet)
                                    Text("Nothing tracked yet").font(.headline)
                                    Text("Import an IPA with SideStore, then add it here to monitor renewal deadlines.")
                                        .font(.subheadline).foregroundStyle(DS.muted)
                                    GlowButton(title: "Track an App", symbol: "plus") { showAdd = true }
                                }
                            }
                        } else {
                            ForEach(store.apps.sorted(by: { $0.refreshDueAt < $1.refreshDueAt }).prefix(4)) { app in
                                TrackedAppCard(app: app)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Designed to be accurate", systemImage: "checkmark.shield")
                                    .font(.headline).foregroundStyle(DS.mint)
                                Text("DaySix doesn't claim that an app renewed until you verify the new expiration date. SideStore and the iOS Shortcuts automation do the signing.")
                                    .font(.footnote).foregroundStyle(DS.muted)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddTrackedAppView() }
        }
    }

    private func stat(number: String, label: String, symbol: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: symbol).foregroundStyle(DS.violet).font(.title3)
                Text(number).font(.system(size: 29, weight: .bold, design: .rounded))
                Text(label).font(.caption).foregroundStyle(DS.muted)
            }
        }
    }
}

struct TrackedAppCard: View {
    @EnvironmentObject private var store: DaySixStore
    let app: TrackedApp
    @State private var confirmVerified = false
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 12) {
                    Image(systemName: "app.fill")
                        .font(.title2).foregroundStyle(DS.gradient)
                        .frame(width: 46, height: 46)
                        .background(DS.cardBright, in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.name).font(.headline)
                        Text(app.bundleID.isEmpty ? "Manually tracked" : app.bundleID)
                            .font(.caption).lineLimit(1).foregroundStyle(DS.muted)
                    }
                    Spacer()
                    Text(app.isExpired ? "Expired" : app.isDue ? "Due" : "\(app.daysLeft)d")
                        .font(.caption.bold())
                        .foregroundStyle(app.isDue ? DS.amber : DS.mint)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background((app.isDue ? DS.amber : DS.mint).opacity(0.1),
                                    in: Capsule())
                }
                HStack {
                    Label("Expires \(app.expiresAt.formatted(date: .abbreviated, time: .omitted))",
                          systemImage: "calendar")
                        .font(.caption).foregroundStyle(DS.muted)
                    Spacer()
                    Button("Verified renewed") { confirmVerified = true }
                        .font(.caption.bold()).foregroundStyle(DS.mint)
                }
                if app.lastAttempt != nil && app.isDue {
                    Text("Automation attempted. Confirm the new expiry in SideStore.")
                        .font(.caption2).foregroundStyle(DS.amber)
                }
            }
        }
        .confirmationDialog("Did SideStore show a renewed seven-day expiry?",
                            isPresented: $confirmVerified, titleVisibility: .visible) {
            Button("Yes, I verified it") { store.verifyRenewed(app) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This changes the renewal date only after you confirm a real successful signing.")
        }
    }
}

struct ManagedAppsView: View {
    @EnvironmentObject private var store: DaySixStore
    @State private var showAdd = false
    var body: some View {
        NavigationStack {
            DaySixBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(title: "My Apps",
                                       subtitle: "DaySix monitors itself; add other apps to track them.")
                        SelfSignatureCard()
                        GlowButton(title: "Add Tracked App", symbol: "plus.app.fill") { showAdd = true }
                        if store.apps.isEmpty {
                            GlassCard {
                                Text("No apps added yet. iOS does not allow DaySix to scan your installed apps automatically.")
                                    .font(.subheadline).foregroundStyle(DS.muted)
                            }
                        }
                        ForEach(store.apps) { app in
                            TrackedAppCard(app: app)
                                .contextMenu {
                                    Button("Remove from Tracking", systemImage: "trash", role: .destructive) {
                                        store.delete(app)
                                    }
                                }
                        }
                        Text("Hold an app card to remove it. Removing a card does not uninstall the app.")
                            .font(.caption).foregroundStyle(DS.muted)
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddTrackedAppView() }
        }
    }
}

struct AddTrackedAppView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DaySixStore
    @State private var name = ""
    @State private var bundleID = ""
    @State private var renewalDate = Date.now
    @State private var sourceURL = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("App details") {
                    TextField("App name", text: $name)
                    TextField("Bundle ID (optional)", text: $bundleID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("IPA download URL (optional)", text: $sourceURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                }
                Section("Last successful signing") {
                    DatePicker("Verified on", selection: $renewalDate,
                               in: ...Date.now, displayedComponents: .date)
                    Text("DaySix will flag renewal six calendar days after this date. Set the date shown by your signing app.")
                        .font(.footnote).foregroundStyle(DS.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.ink)
            .navigationTitle("Track an App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.add(name: name, bundleID: bundleID,
                                  lastVerifiedRenewal: renewalDate, sourceURL: sourceURL)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
        .tint(DS.mint)
    }
}

struct IPAInstallView: View {
    @State private var urlInput = ""
    @State private var showImporter = false
    @State private var importedFile: URL?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            DaySixBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionHeading(title: "Install an IPA",
                                       subtitle: "A clean handoff to SideStore's on-device signer.")
                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("From a download URL", systemImage: "link")
                                    .font(.headline).foregroundStyle(DS.mint)
                                TextField("https://example.com/app.ipa", text: $urlInput)
                                    .keyboardType(.URL).textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(13)
                                    .background(DS.ink, in: RoundedRectangle(cornerRadius: 12))
                                GlowButton(title: "Open Installer", symbol: "arrow.down.circle.fill") {
                                    let input = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard let remote = URL(string: input),
                                          remote.scheme?.lowercased() == "https",
                                          remote.host != nil else {
                                        error = "Enter a valid HTTPS IPA download URL."
                                        return
                                    }
                                    var components = URLComponents()
                                    components.scheme = "sidestore"
                                    components.host = "install"
                                    components.queryItems = [URLQueryItem(name: "url", value: remote.absoluteString)]
                                    guard let destination = components.url else {
                                        error = "Could not form the SideStore install link."
                                        return
                                    }
                                    UIApplication.shared.open(destination) { opened in
                                        if !opened {
                                            DispatchQueue.main.async {
                                                error = "SideStore must be installed and configured first."
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("From Files", systemImage: "folder.fill")
                                    .font(.headline).foregroundStyle(DS.violet)
                                Text("Import a local .ipa, then use the share sheet to send it to a compatible signing app.")
                                    .font(.subheadline).foregroundStyle(DS.muted)
                                Button {
                                    showImporter = true
                                } label: {
                                    Label("Choose an IPA File", systemImage: "doc.badge.plus")
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity).padding(14)
                                        .background(DS.cardBright, in: RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                                if let file = importedFile {
                                    HStack {
                                        Text(file.lastPathComponent).lineLimit(1).font(.caption)
                                        Spacer()
                                        ShareLink(item: file) {
                                            Label("Share to Signer", systemImage: "square.and.arrow.up")
                                                .font(.subheadline.bold()).foregroundStyle(DS.mint)
                                        }
                                    }
                                }
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 7) {
                                Label("What happens next?", systemImage: "checkmark.shield.fill")
                                    .foregroundStyle(DS.mint).font(.headline)
                                Text("SideStore handles account authentication, signing, pairing and installation. DaySix never asks for your Apple password or certificate.")
                                    .font(.footnote).foregroundStyle(DS.muted)
                                Text("A remote IPA must come from a source you trust.")
                                    .font(.footnote.bold()).foregroundStyle(DS.amber)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
                do {
                    let selected = try result.get()
                    guard selected.pathExtension.lowercased() == "ipa" else {
                        error = "Select a file ending in .ipa."
                        return
                    }
                    let access = selected.startAccessingSecurityScopedResource()
                    defer { if access { selected.stopAccessingSecurityScopedResource() } }
                    let destination = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + "-" + selected.lastPathComponent)
                    try FileManager.default.copyItem(at: selected, to: destination)
                    importedFile = destination
                } catch {
                    self.error = error.localizedDescription
                }
            }
            .alert("Installation", isPresented: Binding(
                get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
        }
    }
}

struct MoreView: View {
    @EnvironmentObject private var store: DaySixStore
    private let recipe = "FIRST: In Shortcuts, create a shortcut named DaySix Refresh.\n1. Set VPN: Connect LocalDevVPN\n2. Open URLs: sidestore://\n3. Wait 5 seconds (iOS 27 workaround)\n4. DaySix: Record Refresh Attempt\n5. SideStore: Refresh All Apps\n\nTHEN: In Shortcuts → Automation → Time of Day → Daily → Run Immediately:\n1. DaySix: Check DaySix Refresh\n2. If result is True\n3. Run Shortcut: DaySix Refresh\n4. End If\n\nOn iOS 27, opening SideStore may require the iPhone to be unlocked. If unattended automation cannot wake SideStore, open it manually when notified. No success is assumed until the expiry changes."
    var body: some View {
        NavigationStack {
            DaySixBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionHeading(title: "More", subtitle: "Automation, connection, and preferences.")
                        GlassCard {
                            VStack(alignment: .leading, spacing: 13) {
                                Label("Day-six automation", systemImage: "clock.arrow.2.circlepath")
                                    .font(.headline).foregroundStyle(DS.mint)
                                Text("Use a named 'DaySix Refresh' Shortcut for one-tap manual renewal and a separate daily automation that calls it only when DaySix detects a due signature. SideStore still performs signing, including DaySix itself if SideStore manages the installation.")
                                    .font(.subheadline).foregroundStyle(DS.muted)
                                HStack(spacing: 10) {
                                    Button {
                                        RefreshLauncher.runConfiguredShortcut()
                                    } label: {
                                        Label("Run Refresh", systemImage: "arrow.clockwise")
                                            .font(.subheadline.bold())
                                    }
                                    Button {
                                        RefreshLauncher.openShortcutEditor()
                                    } label: {
                                        Label("New Shortcut", systemImage: "plus")
                                            .font(.subheadline.bold())
                                    }
                                }
                                .tint(DS.mint)
                                Text(recipe).font(.footnote).foregroundStyle(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(13)
                                    .background(DS.ink, in: RoundedRectangle(cornerRadius: 12))
                                Button {
                                    UIPasteboard.general.string = recipe
                                } label: {
                                    Label("Copy Setup Steps", systemImage: "doc.on.doc")
                                        .font(.subheadline.bold()).foregroundStyle(DS.mint)
                                }
                            }
                        }
                        NavigationLink {
                            ReliabilityCenterView()
                        } label: {
                            GlassCard {
                                HStack(spacing: 13) {
                                    Image(systemName: "lifepreserver.fill")
                                        .font(.title2).foregroundStyle(DS.mint)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Reliability Lab").font(.headline)
                                        Text("Background checks, automation backups and rescue steps.")
                                            .font(.caption).foregroundStyle(DS.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(DS.muted)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            RenewalHistoryView()
                        } label: {
                            GlassCard {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.title2).foregroundStyle(DS.violet)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Renewal History").font(.headline)
                                        Text("See actual signing changes and Shortcuts attempts.")
                                            .font(.caption).foregroundStyle(DS.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(DS.muted)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $store.remindersEnabled) {
                                    Label("Day-six reminders", systemImage: "bell.badge.fill")
                                }
                                .tint(DS.mint)
                                Button {
                                    store.requestNotificationPermission()
                                } label: {
                                    Label("Enable iPhone Notifications", systemImage: "bell")
                                        .foregroundStyle(DS.mint)
                                }
                                Text("Local reminders still work when a background refresh cannot run.")
                                    .font(.footnote).foregroundStyle(DS.muted)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 13) {
                                Label("Signing & setup", systemImage: "shield.lefthalf.filled")
                                    .font(.headline).foregroundStyle(DS.violet)
                                Button("Open SideStore") { openSideStore() }
                                Link("SideStore installation instructions",
                                     destination: URL(string: "https://docs.sidestore.io/docs/installation/install.html")!)
                                Link("Official SideInstaller project",
                                     destination: URL(string: "https://github.com/FrizzleM/SideInstaller")!)
                                Text("To renew DaySix itself, it must be listed in SideStore's My Apps. Reinstall it from inside SideStore if necessary. Apple still limits free developer signatures to seven days.")
                                    .font(.footnote).foregroundStyle(DS.muted)
                            }
                            .tint(DS.mint)
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("DaySix \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev")").font(.subheadline.bold())
                                Text("Local-first. No analytics. No Apple credentials stored. Tracking is manual until a verified signer integration is available.")
                                    .font(.footnote).foregroundStyle(DS.muted)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private func openSideStore() {
    guard let url = URL(string: "sidestore://") else { return }
    UIApplication.shared.open(url)
}
