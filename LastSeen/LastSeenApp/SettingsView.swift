import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var game: GameStore
    @State private var confirmReplay = false
    @AppStorage("lastseen.portrait.nora") private var noraPortrait = 1
    @AppStorage("lastseen.portrait.eli") private var eliPortrait = 1
    @AppStorage("lastseen.portrait.unit7") private var unit7Portrait = 1

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 5) {
                    Text("LAST SEEN")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                    Text("THE MISSING FLOOR")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Night.muted)
                }
                .padding(.vertical, 9)
            }

            Section("Experience") {
                Toggle(isOn: Binding(
                    get: { game.state.audioEnabled },
                    set: { game.setAudio($0) }
                )) {
                    Label("Audio and ambience", systemImage: "speaker.wave.2")
                }
                Toggle(isOn: Binding(
                    get: { game.state.hapticsEnabled },
                    set: { game.setHaptics($0) }
                )) {
                    Label("Haptic feedback", systemImage: "hand.tap")
                }
                Toggle(isOn: Binding(
                    get: { game.state.slowerText },
                    set: { game.setSlowText($0) }
                )) {
                    Label("Longer dramatic pauses", systemImage: "hourglass")
                }
                Text("Reduce Motion follows your iPhone accessibility settings. Dialogue can always be revealed instantly.")
                    .font(.system(size: 12))
                    .foregroundColor(Night.muted)
            }

            Section("Contact photos") {
                PortraitOptionRow(contact: .nora, count: 4, selected: $noraPortrait)
                PortraitOptionRow(contact: .eli, count: 3, selected: $eliPortrait)
                PortraitOptionRow(contact: .unit7, count: 3, selected: $unit7Portrait)
                Text("Tap a photo to use it everywhere in the game. Photos stay square in the asset catalog and are cropped to circles in conversations and the inbox.")
                    .font(.system(size: 12))
                    .foregroundColor(Night.muted)
            }

            Section("Story notifications") {
                if game.state.notificationsEnabled {
                    Label("Notifications enabled", systemImage: "checkmark.circle.fill")
                        .foregroundColor(Night.accent)
                    Button {
                        game.sendTestNotification()
                    } label: {
                        Label("Send a test banner in 7 seconds", systemImage: "bell")
                    }
                    Button("Turn off story reminders") {
                        game.disableNotifications()
                    }
                    .foregroundColor(Night.danger)
                } else {
                    Button {
                        game.requestNotificationPermission()
                    } label: {
                        Label("Enable optional reminders", systemImage: "bell.badge")
                    }
                }
                Text("Real iOS notifications show a contact name and a short message. Lock-screen quick replies accept an offered story response; other text is kept as a draft. Notification delivery depends on iOS and Focus settings.")
                    .font(.system(size: 12))
                    .foregroundColor(Night.muted)
            }

            Section("Story progress") {
                LabeledContent("Story", value: game.activeContact.map { game.title(for: $0) } ?? "Choose a conversation")
                LabeledContent("Evidence found", value: "\(game.state.clues.count) / 3")
                LabeledContent("Choices made", value: "\(game.state.visitedChoices.count)")
                if let ending = game.endingTitle {
                    LabeledContent("Ending", value: ending)
                }
                Button(role: .destructive) {
                    confirmReplay = true
                } label: {
                    Label("Erase story progress and restart", systemImage: "arrow.counterclockwise")
                }
            }

            Section {
                Text("An original, fictional interactive horror story. The app never accesses your actual calls, contacts, text messages or photos. Works offline.")
                    .font(.system(size: 12))
                    .foregroundColor(Night.muted)
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.1 · iOS 16+")
                        .foregroundColor(Night.muted)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Erase this story?", isPresented: $confirmReplay) {
            Button("Erase and replay", role: .destructive) { game.restart() }
        } message: {
            Text("Only the selected conversation will restart. Other story progress and preferences are preserved.")
        }
    }
}

private struct PortraitOptionRow: View {
    let contact: Contact
    let count: Int
    @Binding var selected: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(contact.name)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(selected) of \(count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Night.muted)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(1...count, id: \.self) { number in
                        Button {
                            selected = number
                        } label: {
                            VStack(spacing: 6) {
                                ContactAvatar(contact: contact, size: 64, option: number)
                                    .padding(3)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(
                                                selected == number ? Night.accent : .clear,
                                                lineWidth: 2.5
                                            )
                                    }
                                    .overlay(alignment: .bottomTrailing) {
                                        if selected == number {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 17))
                                                .foregroundColor(Night.accent)
                                                .background(Night.surface, in: Circle())
                                        }
                                    }
                                Text("Option \(number)")
                                    .font(.system(size: 11))
                                    .foregroundColor(selected == number ? .white : Night.muted)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(contact.name), option \(number)")
                        .accessibilityAddTraits(selected == number ? [.isSelected] : [])
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 7)
    }
}
