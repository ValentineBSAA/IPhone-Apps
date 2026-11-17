import SwiftUI

@main
struct LastSeenApp: App {
    @StateObject private var game = GameStore()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                InboxView()
                    .navigationDestination(for: Contact.self) { contact in
                        ConversationView(contact: contact)
                    }
                    .navigationDestination(for: AppPage.self) { page in
                        switch page {
                        case .settings: SettingsView()
                        case .evidence: EvidenceView()
                        }
                    }
            }
            .environmentObject(game)
            .sheet(item: $game.presentedCall) { call in
                FictionalCallView(message: call)
                    .environmentObject(game)
                    .presentationDetents([.large])
            }
            .tint(Night.accent)
            .preferredColorScheme(.dark)
            .onAppear {
                game.clearReminder()
                game.beginOrResume()
            }
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
}

enum AppPage: Hashable {
    case settings
    case evidence
}
