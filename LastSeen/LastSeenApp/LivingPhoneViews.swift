import SwiftUI

struct NeighborAvatar: View {
    let neighbor: Neighbor
    var size: CGFloat = 50

    var body: some View {
        Group {
            if noteID == PhoneWorldStore.tutorialNoteID {
                ScrollView {
                    VStack(alignment: .leading, spacing: 17) {
                        Text(PhoneWorldStore.tutorialNoteTitle).font(.largeTitle.bold())
                        Label("Restored note", systemImage: "lock.doc").font(.caption).foregroundColor(.secondary)
                        Divider()
                        Text(PhoneWorldStore.tutorialNoteBody).font(.body).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(22)
                }.onAppear { world.recordTutorialVisit("note") }
            } else {
                VStack(spacing: 0) {
                    TextField("Title", text: $title)
                        .font(.system(size: 25, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    Divider().padding(.vertical, 14)
                    TextEditor(text: $bodyText)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 16))
                        .padding(.horizontal, 13)
                        .accessibilityLabel("Note body")
                }
            }
        }
        .background(Night.background.ignoresSafeArea())
        .searchable(text: $search, prompt: "Search conversations")
        .navigationTitle("Messages")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: AppPage.contacts) {
                    Image(systemName: "person.crop.rectangle.stack")
                }
            }
        }
    }

    private func row(_ item: PhoneThreadSummary) -> some View {
        HStack(spacing: 13) {
            if let contact = item.contact {
                ContactAvatar(contact: contact, size: 51)
            } else if let neighbor = item.neighbor {
                NeighborAvatar(neighbor: neighbor, size: 51)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.system(size: 16, weight: item.unread > 0 ? .bold : .semibold))
                    Spacer()
                    if let time = item.time {
                        Text(time, style: .time)
                            .font(.system(size: 11))
                            .foregroundColor(Night.muted)
                    }
                }
                HStack {
                    Text(item.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Night.muted)
                        .lineLimit(2)
                    Spacer(minLength: 6)
                    if item.unread > 0 {
                        Text("\(item.unread)")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 7)
                            .frame(minHeight: 22)
                            .background(Night.outgoing, in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func preview(kind: MessageKind, body: String) -> String {
        switch kind {
        case .text: return body
        case .photograph: return "Photo · \(body)"
        case .voiceNote: return "Voice note transcript"
        case .call: return "Call record"
        }
    }
}

struct NeighborConversationView: View {
    let neighbor: Neighbor
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var draft = ""
    @State private var showHelp = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(world.messages(neighbor)) { message in
                            if world.messages(neighbor).first?.id == message.id || world.messages(neighbor).last(where: { $0.at < message.at }).map({ !Calendar.current.isDate($0.at, inSameDayAs: message.at) }) == true {
                                Text(message.at, style: .date).font(.caption).foregroundColor(Night.muted).padding(.top, 8)
                            }
                            HStack {
                                if message.fromPlayer { Spacer(minLength: 55) }
                                VStack(alignment: message.fromPlayer ? .trailing : .leading, spacing: 4) {
                                    Text(message.text)
                                        .font(.system(size: 15))
                                        .padding(12)
                                        .background(message.fromPlayer ? Night.outgoing : Night.incoming,
                                                    in: RoundedRectangle(cornerRadius: 19))
                                        .foregroundColor(.white)
                                    Text(message.at, style: .time)
                                        .font(.system(size: 10))
                                        .foregroundColor(Night.muted)
                                        .padding(.horizontal, 4)
                                }
                                .frame(maxWidth: 280, alignment: message.fromPlayer ? .trailing : .leading)
                                if !message.fromPlayer { Spacer(minLength: 55) }
                            }
                            .id(message.id)
                        }
                        Color.clear.frame(height: 2).id("bottom")
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 14)
                }
                .onChange(of: world.messages(neighbor).count) { _ in
                    world.markRead(neighbor)
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    world.markRead(neighbor)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            Divider()
            if world.choices(neighbor).isEmpty {
                Text("Conversation is quiet for now.")
                    .font(.system(size: 13))
                    .foregroundColor(Night.muted)
                    .padding(18)
            } else {
                VStack(spacing: 8) {
                    ForEach(world.choices(neighbor), id: \.self) { choice in
                        Button {
                            draft = ""
                            _ = world.reply(to: neighbor, text: choice)
                        } label: {
                            HStack {
                                Text(choice)
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.up.message")
                            }
                            .foregroundColor(.white)
                            .padding(11)
                            .background(Night.raised, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    HStack {
                        TextField("Write a reply…", text: $draft, axis: .vertical)
                            .font(.system(size: 14))
                            .lineLimit(1...3)
                            .submitLabel(.send)
                            .onSubmit(send)
                        Button(action: send) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 25))
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(10)
                    .background(Night.surface, in: Capsule())
                }
                .padding(12)
            }
        }
        .background(Night.background.ignoresSafeArea())
        .navigationTitle(neighbor.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    NeighborAvatar(neighbor: neighbor, size: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(neighbor.name).font(.subheadline.bold())
                        Text(neighbor.subtitle).font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: AppPage.worldProfile(neighbor)) {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .alert("Choose an available response", isPresented: $showHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("These conversations are authored and work offline. Select or type one of the suggested responses.")
        }
    }

    private func send() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if world.reply(to: neighbor, text: draft) { draft = "" }
        else { showHelp = true }
    }
}

struct NeighborProfileView: View {
    let neighbor: Neighbor
    @EnvironmentObject private var world: PhoneWorldStore

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                NeighborAvatar(neighbor: neighbor, size: 106)
                VStack(spacing: 5) {
                    Text(neighbor.name)
                        .font(.system(size: 29, weight: .semibold))
                    Text(neighbor.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Night.muted)
                }
                NavigationLink(value: AppPage.worldThread(neighbor)) {
                    Label("Message", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Night.raised, in: RoundedRectangle(cornerRadius: 14))
                }
                Text(neighbor == .maya
                     ? (world.tutorialStarted ? "Maya is a friend of Nora, the original owner of this phone." : "You met Maya through friends in the neighborhood. She sends ordinary updates and makes plans.")
                     : "Denise manages notices and maintenance for Ash Street residents.")
                    .font(.system(size: 14))
                    .foregroundColor(Night.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(17)
                    .background(Night.surface, in: RoundedRectangle(cornerRadius: 15))
            }
            .padding(22)
        }
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Contact")
    }
}
