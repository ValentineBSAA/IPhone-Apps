import SwiftUI

/// A fictional contact directory within LAST SEEN. It never reads the user's
/// actual iPhone address book, Call History, FaceTime or iMessage conversations.
struct ContactBookView: View {
    @EnvironmentObject private var game: GameStore
    @State private var searchText = ""

    private var matching: [Contact] {
        guard !searchText.isEmpty else { return Contact.allCases }
        return Contact.allCases.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(matching) { contact in
                    NavigationLink(value: AppPage.profile(contact, false)) {
                        HStack(spacing: 14) {
                            ContactAvatar(contact: contact, size: 53)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(contact.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(Night.muted)
                            }
                            Spacer()
                            if game.ending(for: contact) != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Night.accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Saved contacts")
            } footer: {
                Text("These contacts belong to the fictional story. No real iPhone contacts are imported.")
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
        .scrollContentBackground(.hidden)
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ContactProfileView: View {
    let contact: Contact
    let fromConversation: Bool

    @EnvironmentObject private var game: GameStore
    @Environment(\.dismiss) private var dismiss

    private var contactNote: String {
        switch contact {
        case .nora: return "Neighbor · Apartment 402 · Building A"
        case .eli: return "On-site caretaker · Building maintenance"
        case .unit7: return "Unverified number · Identity unknown"
        }
    }

    private var contactAddress: String {
        switch contact {
        case .nora: return "Apartment 402, Ash Street"
        case .eli: return "Maintenance office, Ash Street"
        case .unit7: return "Unknown"
        }
    }

    private var displayPhone: String {
        switch contact {
        case .nora: return "Fictional contact · Number unavailable"
        case .eli: return "Fictional work contact · Number unavailable"
        case .unit7: return "Unlisted number"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    ContactAvatar(contact: contact, size: 116)
                    Text(contact.name)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                    Text(contact.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Night.muted)
                }
                .padding(.top, 15)

                HStack(spacing: 10) {
                    if fromConversation {
                        Button { dismiss() } label: {
                            profileAction("Message", symbol: "message.fill", active: true)
                        }
                    } else {
                        NavigationLink(value: contact) {
                            profileAction("Message", symbol: "message.fill", active: true)
                        }
                    }
                    profileAction("Call", symbol: "phone.fill", active: false)
                    profileAction("Video", symbol: "video.fill", active: false)
                }
                .buttonStyle(.plain)

                VStack(spacing: 1) {
                    infoRow(title: "phone", value: displayPhone)
                    infoRow(title: "home", value: contactAddress)
                    infoRow(title: "notes", value: contactNote)
                    infoRow(title: "story", value: game.title(for: contact))
                    infoRow(title: "conversation", value: "\(game.messages(in: contact.id).count) messages")
                }
                .background(Night.surface, in: RoundedRectangle(cornerRadius: 16))

                NavigationLink {
                    ContactMediaView(contact: contact)
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(Night.accent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Photos & attachments")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Images shared in this fictional conversation")
                                .font(.system(size: 12))
                                .foregroundColor(Night.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Night.muted)
                    }
                    .padding(16)
                    .background(Night.surface, in: RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 7) {
                    Label("Voice calling is not yet available", systemImage: "mic.slash")
                        .font(.system(size: 13, weight: .semibold))
                    Text("The future in-game voice mode will only be enabled when actual character dialogue, microphone consent and speech-recognition testing are ready. Nothing is recording you.")
                        .font(.system(size: 12))
                        .foregroundColor(Night.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(Night.raised, in: RoundedRectangle(cornerRadius: 15))
            }
            .padding(.horizontal, 19)
            .padding(.bottom, 36)
        }
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Contact")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func profileAction(_ title: String, symbol: String, active: Bool) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 20))
            Text(title)
                .font(.system(size: 12, weight: .medium))
            if !active {
                Text("Later")
                    .font(.system(size: 9))
                    .opacity(0.6)
            }
        }
        .foregroundColor(active ? Night.accent : Night.muted)
        .frame(maxWidth: .infinity)
        .frame(height: 75)
        .background(Night.surface, in: RoundedRectangle(cornerRadius: 13))
        .accessibilityLabel(active ? title : "\(title), not yet available")
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Night.accent)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
    }
}

struct ContactMediaView: View {
    let contact: Contact
    @EnvironmentObject private var game: GameStore
    @State private var selected: GameMessage?

    private var sharedPhotos: [GameMessage] {
        game.messages(in: contact.id).filter { $0.kind == .photograph }
    }

    var body: some View {
        ScrollView {
            if sharedPhotos.isEmpty {
                VStack(spacing: 13) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 37))
                    Text("No photographs shared yet")
                        .font(.system(size: 17, weight: .medium))
                    Text("Attachments will appear here as your story continues.")
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(Night.muted)
                .frame(maxWidth: .infinity)
                .padding(.top, 90)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(sharedPhotos) { photo in
                        Button {
                            selected = photo
                            if game.state.activeThread == contact.id { game.inspect(photo) }
                        } label: {
                            StoryPhotograph(assetName: photo.photoAssetName)
                                .frame(height: 210)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("View \(photo.body)")
                    }
                }
                .padding(15)
            }
        }
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Shared Photos")
        .sheet(item: $selected) { item in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 15) {
                        StoryPhotograph(assetName: item.photoAssetName)
                            .frame(maxWidth: .infinity)
                        Text(item.body)
                            .font(.system(size: 13))
                            .foregroundColor(Night.muted)
                    }.padding(16)
                }
                .background(Night.background.ignoresSafeArea())
                .navigationTitle("Photograph")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { selected = nil }
                    }
                }
            }.preferredColorScheme(.dark)
        }
    }
}
