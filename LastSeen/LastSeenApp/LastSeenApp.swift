import SwiftUI

@main
struct LastSeenApp: App {
    @UIApplicationDelegateAdaptor(LastSeenAppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("--legacy-story") {
                LegacyStoryRoot()
            } else {
                PhoneSetupRoot()
            }
        }
    }
}

private struct LegacyStoryRoot: View {
    @StateObject private var game = GameStore()
    @StateObject private var world = PhoneWorldStore()
    @Environment(\.scenePhase) private var phase

    var body: some View {
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
