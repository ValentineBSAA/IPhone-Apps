import SwiftUI

struct InboxView: View {
    @EnvironmentObject private var game: GameStore
    @State private var confirmRestart = false

    private var sortedContacts: [Contact] {
        Contact.allCases.sorted {
            (game.messages(in: $0.id).last?.createdAt ?? .distantPast)
                > (game.messages(in: $1.id).last?.createdAt ?? .distantPast)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionEyebrow(text: "A STORY TOLD THROUGH YOUR SCREEN")
                    Text("LAST SEEN")
                        .font(.system(size: 41, weight: .black, design: .rounded))
                        .tracking(-1.2)
                    Text(game.activeContact.map { game.title(for: $0) } ?? "Choose a conversation")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Night.muted)
                }
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(Night.gold)
                        TimelineView(.periodic(from: .now, by: 15)) { clock in
                            Text(clock.date, style: .time)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        }
                        Spacer()
                        Text(game.state.activeThread == nil ? "SELECT A STORY" : (game.state.endingID == nil ? "ACTIVE STORY" : "STORY COMPLETE"))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(Night.muted)
                    }

                    Text(game.state.activeThread == nil
                         ? "Choose Nora, Eli, or the unknown number. Each conversation tells its own story."
                         : (game.state.endingID == nil
                             ? "Only your selected conversation advances. The other stories stay paused."
                             : "This story is finished. You can replay it or try another contact."))
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        Label("\(game.state.clues.count) clues", systemImage: "eye")
                        Label("\(game.state.visitedChoices.count) choices", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Night.muted)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 19)
                        .fill(LinearGradient(colors: [
                            Color(red: 0.20, green: 0.18, blue: 0.25),
                            Night.surface
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 19)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        SectionEyebrow(text: "Conversations")
                        Spacer()
                        let unread = Contact.allCases.reduce(0) { $0 + game.unreadCount(in: $1.id) }
                        if unread > 0 {
                            Text("\(unread) unread")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Night.accent)
                        }
                    }

                    VStack(spacing: 0) {
                        ForEach(sortedContacts) { contact in
                            NavigationLink(value: contact) {
                                contactRow(contact)
                            }
                            .buttonStyle(.plain)
                            if contact != sortedContacts.last {
                                Divider().overlay(Night.raised).padding(.leading, 75)
                            }
                        }
                    }
                    .background(Night.surface, in: RoundedRectangle(cornerRadius: 19))
                }

                if game.state.choiceReady {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "ellipsis.bubble.fill")
                            .foregroundColor(Night.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Someone is waiting for your answer")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Open \(game.activeContact?.name ?? "your selected contact") to decide what happens next.")
                                .font(.system(size: 12))
                                .foregroundColor(Night.muted)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Night.raised, in: RoundedRectangle(cornerRadius: 17))
                }

                if game.state.endingID != nil {
                    endingCard
                }

                NavigationLink(value: AppPage.evidence) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.stack.3d.up")
                        Text("Evidence & discoveries")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(17)
                    .background(Night.surface, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .background(Night.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppPage.settings) {
                    Image(systemName: "gearshape")
                        .accessibilityLabel("Settings")
                }
            }
        }
        .confirmationDialog(
            "Start a new story?",
            isPresented: $confirmRestart,
            titleVisibility: .visible
        ) {
            Button("Erase progress and replay", role: .destructive) { game.restart() }
        } message: {
            Text("Only the active conversation will restart. Your other stories and preferences are preserved.")
        }
    }

    private func contactRow(_ contact: Contact) -> some View {
        let latest = game.messages(in: contact.id).last
        let unread = game.unreadCount(in: contact.id)
        return HStack(spacing: 13) {
            ContactAvatar(contact: contact, size: 55)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(contact.name)
                        .font(.system(size: 16, weight: unread > 0 ? .bold : .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    if let latest {
                        Text(latest.createdAt, style: .time)
                            .font(.system(size: 11))
                            .foregroundColor(Night.muted)
                    }
                }
                HStack(spacing: 7) {
                    Text(latest.map { preview($0) } ?? "Tap to start · \(game.title(for: contact))")
                        .font(.system(size: 13))
                        .foregroundColor(Night.muted)
                        .lineLimit(2)
                    Spacer(minLength: 3)
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .frame(minHeight: 23)
                            .background(Night.outgoing, in: Capsule())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(Night.muted)
                    }
                }
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func preview(_ message: GameMessage) -> String {
        switch message.kind {
        case .text: return message.body
        case .photograph: return "📷 Photo attachment"
        case .voiceNote: return "Voice note · transcript"
        case .call: return "Call record (no audio)"
        }
    }

    private var endingCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionEyebrow(text: "An ending discovered")
            Text(game.endingTitle ?? "THE END")
                .font(.system(size: 27, weight: .bold, design: .serif))
            Text(game.endingDetail)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
            Button {
                confirmRestart = true
            } label: {
                Label("Replay and change your fate", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(14)
            }
            .buttonStyle(.plain)
            .background(Night.danger.opacity(0.24), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Night.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).strokeBorder(Night.danger.opacity(0.34))
        }
    }
}

struct EvidenceView: View {
    @EnvironmentObject private var game: GameStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                SectionEyebrow(text: "Case file 001")
                Text("Evidence")
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                Text("Some details only become important after you open them in a conversation.")
                    .font(.subheadline)
                    .foregroundColor(Night.muted)

                evidenceTile("The reflected hallway", clue: "photograph",
                             symbol: "photo", detail: "A mirror displays 07 above a frozen clock: 01:43.")
                evidenceTile("A voice that doesn't belong", clue: "voiceNote",
                             symbol: "waveform", detail: "The message warns you about the elevator and the missing floor.")
                evidenceTile("The unknown caller", clue: "call",
                             symbol: "phone.arrow.down.left", detail: "The voice on the other end knows the floor count.")
            }
            .padding(20)
        }
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Case File")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func evidenceTile(_ title: String, clue: String, symbol: String, detail: String) -> some View {
        let found = game.state.clues.contains(clue)
        return HStack(alignment: .top, spacing: 13) {
            Image(systemName: found ? symbol : "lock.fill")
                .font(.system(size: 20))
                .frame(width: 38, height: 40)
                .foregroundColor(found ? Night.accent : Night.muted)
            VStack(alignment: .leading, spacing: 6) {
                Text(found ? title : "Undiscovered clue")
                    .font(.system(size: 16, weight: .semibold))
                Text(found ? detail : "Inspect the relevant message to reveal this evidence.")
                    .font(.system(size: 13))
                    .foregroundColor(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Night.surface, in: RoundedRectangle(cornerRadius: 15))
    }
}
