import SwiftUI

struct NeighborAvatar: View {
    let neighbor: Neighbor
    var size: CGFloat = 50

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [neighbor.hue, neighbor.hue.opacity(0.28), Night.surface],
                                 center: .topLeading, startRadius: 0, endRadius: size))
            .overlay {
                Text(neighbor.initials)
                    .font(.system(size: size * 0.30, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1))
            .accessibilityLabel(neighbor.name)
    }
}

struct PhoneHomeView: View {
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var world: PhoneWorldStore

    private var unread: Int {
        let a = Contact.allCases.reduce(0) { $0 + game.unreadCount(in: $1.id) }
        let b = Neighbor.allCases.reduce(0) { $0 + world.countUnread($1) }
        return a + b
    }

    var body: some View {
        GeometryReader { size in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.15, blue: 0.25),
                             Color(red: 0.06, green: 0.07, blue: 0.11),
                             Color(red: 0.14, green: 0.13, blue: 0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Circle()
                    .fill(Color(red: 0.33, green: 0.36, blue: 0.52).opacity(0.17))
                    .frame(width: 420, height: 420)
                    .blur(radius: 94)
                    .offset(x: -140, y: -210)
                    .accessibilityHidden(true)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        TimelineView(.periodic(from: .now, by: 20)) { clock in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(clock.date, format: .dateTime.weekday(.wide).month(.wide).day())
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.73))
                                Text(clock.date, style: .time)
                                    .font(.system(size: 54, weight: .light, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.top, 12)
                        .accessibilityElement(children: .combine)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "building.2")
                                    .foregroundColor(Night.accent)
                                Text("ASH STREET")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            Text("Your world, one message at a time.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.89))
                            Text(unread == 0 ? "Nothing urgent right now." :
                                    "\(unread) unread \(unread == 1 ? "message" : "messages")")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.62))
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.09)))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 22) {
                            phoneApp("Messages", "message.fill", Color(red: 0.26, green: 0.61, blue: 0.48), .messages, badge: unread)
                            phoneApp("Contacts", "person.crop.rectangle.stack.fill", Color(red: 0.44, green: 0.52, blue: 0.66), .contacts)
                            phoneApp("Photos", "photo.on.rectangle.angled", Color(red: 0.77, green: 0.51, blue: 0.44), .photos)
                            phoneApp("Notes", "note.text", Color(red: 0.75, green: 0.61, blue: 0.35), .notes)
                            phoneApp("Calendar", "calendar", Color(red: 0.67, green: 0.40, blue: 0.45), .calendar)
                            phoneApp("Mail", "envelope.fill", Color(red: 0.38, green: 0.52, blue: 0.78), .mail)
                            phoneApp("Settings", "gearshape.fill", Color(red: 0.45, green: 0.46, blue: 0.55), .settings)
                        }
                        .padding(.vertical, 13)

                        Spacer(minLength: max(0, size.size.height * 0.10))

                        HStack(spacing: 24) {
                            NavigationLink(value: AppPage.messages) {
                                dockApp("message.fill", tint: Color(red: 0.26, green: 0.61, blue: 0.48), label: "Messages")
                            }
                            NavigationLink(value: AppPage.contacts) {
                                dockApp("person.crop.circle", tint: Color(red: 0.43, green: 0.52, blue: 0.67), label: "Contacts")
                            }
                            NavigationLink(value: AppPage.photos) {
                                dockApp("photo.fill.on.rectangle.fill", tint: Color(red: 0.70, green: 0.50, blue: 0.49), label: "Photos")
                            }
                            VStack(spacing: 6) {
                                Image(systemName: "phone.slash.fill")
                                    .font(.system(size: 23))
                                    .foregroundColor(.white.opacity(0.44))
                                    .frame(width: 58, height: 58)
                                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 17))
                                Text("Phone")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            .accessibilityLabel("Phone calls are unavailable")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 9)
                        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 27))
                    }
                    .padding(.horizontal, 23)
                    .padding(.bottom, 18)
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { world.reconcile(with: game) }
        .onChange(of: game.state.clues) { _ in world.reconcile(with: game) }
    }

    private func phoneApp(_ title: String, _ symbol: String, _ tint: Color,
                          _ destination: AppPage, badge: Int = 0) -> some View {
        NavigationLink(value: destination) {
            VStack(spacing: 7) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [tint.opacity(0.96), tint.opacity(0.59)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 62, height: 62)
                        .overlay {
                            Image(systemName: symbol)
                                .font(.system(size: 27, weight: .medium))
                                .foregroundColor(.white)
                        }
                    if badge > 0 {
                        Text("\(min(badge, 99))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .frame(minHeight: 19)
                            .background(Night.danger, in: Capsule())
                            .offset(x: 8, y: -8)
                    }
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func dockApp(_ symbol: String, tint: Color, label: String) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 17)
                .fill(tint)
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 23))
                        .foregroundColor(.white)
                }
            Text(label).font(.system(size: 11)).foregroundColor(.white)
        }
    }
}

private struct PhoneThreadSummary: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let time: Date?
    let unread: Int
    let contact: Contact?
    let neighbor: Neighbor?
}

struct PhoneMessagesView: View {
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var search = ""
    @State private var unreadOnly = false

    private var threads: [PhoneThreadSummary] {
        let main: [PhoneThreadSummary] = Contact.allCases.map { contact in
            let msgs = game.messages(in: contact.id)
            let last = msgs.last
            return PhoneThreadSummary(
                id: contact.id, title: contact.name,
                subtitle: last.map { preview(kind: $0.kind, body: $0.body) }
                    ?? "Tap to start a conversation",
                time: last?.createdAt,
                unread: game.unreadCount(in: contact.id),
                contact: contact, neighbor: nil
            )
        }
        let ordinary: [PhoneThreadSummary] = Neighbor.allCases.map { neighbor in
            let msgs = world.messages(neighbor)
            return PhoneThreadSummary(
                id: neighbor.id, title: neighbor.name,
                subtitle: msgs.last?.text ?? "",
                time: msgs.last?.at,
                unread: world.countUnread(neighbor),
                contact: nil, neighbor: neighbor
            )
        }
        return (main + ordinary).filter {
            (!unreadOnly || $0.unread > 0) &&
            (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search)
             || $0.subtitle.localizedCaseInsensitiveContains(search))
        }.sorted {
            ($0.time ?? .distantPast) > ($1.time ?? .distantPast)
        }
    }

    var body: some View {
        List {
            Section {
                Toggle("Unread only", isOn: $unreadOnly)
                    .tint(Night.accent)
                    .font(.system(size: 13))
                    .listRowBackground(Night.surface)
            }
            Section {
                ForEach(threads) { item in
                    if let contact = item.contact {
                        NavigationLink(value: contact) { row(item) }
                    } else if let neighbor = item.neighbor {
                        NavigationLink(value: AppPage.worldThread(neighbor)) { row(item) }
                    }
                }
            } header: {
                Text("Conversations")
            } footer: {
                Text("All messages and contacts are fictional and exist only inside LAST SEEN.")
            }
            .listRowBackground(Night.surface)
        }
        .scrollContentBackground(.hidden)
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
                        Text("Today")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Night.muted)
                            .padding(.top, 16)
                        ForEach(world.messages(neighbor)) { message in
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
                     ? "You met Maya through friends in the neighborhood. She sends ordinary updates and makes plans."
                     : "Denise handles notices and maintenance for the building. This is an in-game contact, not a real phone number.")
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
