import SwiftUI

@main
struct LastSeenApp: App {
    @UIApplicationDelegateAdaptor(LastSeenAppDelegate.self) private var appDelegate
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
                        case .contacts: ContactBookView()
                        case .profile(let contact, let fromConversation):
                            ContactProfileView(contact: contact, fromConversation: fromConversation)
                        }
                    }
            }
            .environmentObject(game)
            .tint(Night.accent)
            .preferredColorScheme(.dark)
            .onAppear {
                NotificationRouter.shared.store = game
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
    case contacts
    case profile(Contact, Bool)
}
