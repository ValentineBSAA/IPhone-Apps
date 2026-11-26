import SwiftUI
import AVFoundation

@main
@MainActor
struct LastSeenApp: App {
    @UIApplicationDelegateAdaptor(LastSeenAppDelegate.self) private var appDelegate
    @State private var relayRecoveryRequired=false
    init() {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--luma-relay-clean-test") {
            for key in ["installed","versions","history","safeMode","sources","compactIcons","tealTheme","pendingCommit"] {
                UserDefaults.standard.removeObject(forKey: "lastseen.relay." + key)
            }
        }
        #endif
        // Complete an interrupted world/settings reset before choosing the opening route.
        _ = try? LumaRestoreJournal.recover(worldURL:RestoredPhoneBackup.url,defaults:.standard)
        _relayRecoveryRequired=State(initialValue:!RelayTransactionReceipt.recover())
    }
    var body: some Scene {
        WindowGroup {
            root
        }
    }
    @ViewBuilder private var root: some View {
        if relayRecoveryRequired {
            RelayStartupRecoveryView {relayRecoveryRequired=false}
        } else { normalOrFixtureRoot }
    }
    @ViewBuilder private var normalOrFixtureRoot:some View {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--luma-ui-test") {
            PhoneLabView(startUnlocked: true, uiFixture: true)
        } else {
            normalRoot
        }
        #else
        normalRoot
        #endif
    }
    @ViewBuilder private var normalRoot: some View {
            if ProcessInfo.processInfo.arguments.contains("--legacy-story") {
                LegacyStoryRoot()
            } else {
                PhonePermissionsGate()
            }
    }
}

@MainActor
private struct RelayStartupRecoveryView:View {
    let onRecovered:()->Void
    @State private var malformed=RelayTransactionReceipt.malformed()
    @State private var confirm=false
    @State private var notice=""
    @Environment(\.scenePhase) private var phase
    var body:some View {
        VStack(alignment:.leading,spacing:16) {
            Label("Package recovery required",systemImage:"exclamationmark.shield").font(.title2.bold())
            Text("An unfinished package commit needs attention before the phone opens. Your records and checkpoints are retained.")
            Button("Retry recovery") {
                guard phase == .active else{return}
                if RelayTransactionReceipt.recover(){onRecovered()}
                else {malformed=RelayTransactionReceipt.malformed();notice="Recovery could not finish."}
            }.buttonStyle(.borderedProminent)
            if malformed {
                Button("Preserve receipt and enter Safe Mode"){confirm=true}.buttonStyle(.bordered)
            }
            Text(notice).font(.caption).foregroundColor(.secondary)
        }.padding(24).preferredColorScheme(.dark)
            .confirmationDialog("Preserve the unreadable transaction?",isPresented:$confirm,titleVisibility:.visible) {
                Button("Continue in Safe Mode",role:.destructive) {
                    guard phase == .active else{return}
                    do {try RelayTransactionReceipt.quarantineMalformed();onRecovered()}
                    catch {notice="Could not preserve the receipt. No new package transaction was started."}
                }
                Button("Cancel",role:.cancel){}
            } message:{Text("The original receipt will be archived. Installed package records may still require review in Patchline. Optional tweaks will be paused; no checkpoint will be replaced.")}
    }
}

@MainActor
private struct LegacyStoryRoot: View {
    @StateObject private var game = GameStore()
    @StateObject private var world = PhoneWorldStore()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        if world.recoveryRequired || world.settingsRecoveryRequired {
            VStack(spacing:16) {
                Label("Legacy save unavailable",systemImage:"externaldrive.badge.exclamationmark").font(.title2.bold())
                Text("The legacy world and any unresolved settings receipt are preserved. This mode does not share the main phone's checkpoints.")
                if world.settingsRecoveryRequired {
                    Button("Retry settings recovery"){guard phase == .active else{return};world.retrySettingsRecovery()}.buttonStyle(.bordered).disabled(phase != .active)
                }
            }.padding(24)
        } else { legacyBody }
    }
    private var legacyBody:some View {
            NavigationStack {
                PhoneHomeView()
                    .navigationDestination(for: Contact.self) { contact in
                        ConversationView(contact: contact)
                    }
                    .navigationDestination(for: AppPage.self) { page in
                        switch page {
                        case .messages: PhoneMessagesView()
                        case .photos: PhonePhotoLibraryView()
                        case .notes: PhoneNotesView()
                        case .calendar: PhoneCalendarView()
                        case .mail: PhoneMailView()
                        case .worldThread(let neighbor): NeighborConversationView(neighbor: neighbor)
                        case .worldProfile(let neighbor): NeighborProfileView(neighbor: neighbor)
                        case .note(let id): PhoneNoteEditorView(noteID: id)
                        case .settings: SettingsView()
                        case .evidence: EvidenceView()
                        case .contacts: ContactBookView()
                        case .profile(let contact, let fromConversation):
                            ContactProfileView(contact: contact, fromConversation: fromConversation)
                        }
                    }
            }
            .environmentObject(game)
            .environmentObject(world)
            .tint(Night.accent)
            .preferredColorScheme(.dark)
            .onAppear {
                NotificationRouter.shared.store = game
                game.clearReminder()
                game.beginOrResume()
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notice in
                if let raw = notice.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                   AVAudioSession.InterruptionType(rawValue: raw) == .began { game.stopAmbience() }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { notice in
                if let raw = notice.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                   AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable { game.stopAmbience() }
            }
            .onDisappear { game.suspend() }
            .onChange(of: phase) { newPhase in
                switch newPhase {
                case .active:
                    game.clearReminder()
                    game.beginOrResume()
                case .background:
                    game.suspend()
                    game.scheduleReturnReminder()
                case .inactive:
                    game.suspend()
                @unknown default:
                    game.suspend()
                }
            }
    }
}

enum AppPage: Hashable {
    case messages
    case photos
    case notes
    case calendar
    case mail
    case worldThread(Neighbor)
    case worldProfile(Neighbor)
    case note(String)
    case settings
    case evidence
    case contacts
    case profile(Contact, Bool)
}
