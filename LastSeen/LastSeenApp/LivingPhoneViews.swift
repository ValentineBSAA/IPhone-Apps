import SwiftUI

struct NeighborAvatar: View {
    let neighbor: Neighbor
    var size: CGFloat = 50

    var body: some View {
        ZStack {
            if neighbor == .unknown {
                Circle().fill(Color.gray.opacity(0.25))
                Image(systemName: "person.fill.questionmark").font(.system(size: size * 0.42)).foregroundColor(.secondary)
            } else if let photograph = PortraitImages.load(neighbor.portraitAssetName) {
                Image(uiImage: photograph)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                // Missing art should be detected by runtime asset tests, not
                // silently allowed into a public-facing release.
                Circle()
                    .fill(RadialGradient(
                        colors: [neighbor.hue, neighbor.hue.opacity(0.28), Night.surface],
                        center: .topLeading, startRadius: 0, endRadius: size))
                Text(neighbor.initials)
                    .font(.system(size: size * 0.30, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1))
        .accessibilityLabel(neighbor == .unknown ? "Unverified sender" : "\(neighbor.name) contact photograph")
    }
}

/// One launcher, one set of app icons. No duplicated dock, clipped icons, fake
/// system widgets or initial flood of unread *messages* on the home screen.
struct PhoneHomeView: View {
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var world: PhoneWorldStore

    private var unreadThreads: Int {
        let storyCount = Contact.allCases.filter { game.unreadCount(in: $0.id) > 0 }.count
        let ordinaryCount = Neighbor.visible(in: world.state).filter { world.countUnread($0) > 0 }.count
        return storyCount + ordinaryCount
    }

    private var latestNeighbor: Neighbor {
        let maya = world.messages(.maya).last?.at ?? .distantPast
        let denise = world.messages(.denise).last?.at ?? .distantPast
        return maya >= denise ? .maya : .denise
    }

    private var upcoming: PhoneEvent? {
        let now = Date()
        return world.state.events
            .filter { $0.endsAt > now }
            .sorted { $0.startsAt < $1.startsAt }
            .first
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.17, blue: 0.25),
                    Color(red: 0.075, green: 0.095, blue: 0.16),
                    Color(red: 0.07, green: 0.075, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        TimelineView(.periodic(from: .now, by: 20)) { context in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.66))
                                Text(context.date, style: .time)
                                    .font(.system(size: 38, weight: .light, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.top, 18)

                        if let event = upcoming {
                            NavigationLink(value: AppPage.calendar) {
                                HStack(alignment: .center, spacing: 13) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white.opacity(0.82))
                                        .frame(width: 40, height: 40)
                                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(event.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(event.startsAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.60))
                                    }
                                    Spacer(minLength: 4)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.55))
                                }
                                .padding(14)
                                .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 19))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 19)
                                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 24) {
                            appIcon("Messages", symbol: "message.fill",
                                    tint: Color(red: 0.24, green: 0.62, blue: 0.43),
                                    destination: .messages, badge: unreadThreads)
                            appIcon("Contacts", symbol: "person.crop.circle.fill",
                                    tint: Color(red: 0.42, green: 0.49, blue: 0.67),
                                    destination: .contacts)
                            appIcon("Photos", symbol: "photo.on.rectangle.angled",
                                    tint: Color(red: 0.78, green: 0.49, blue: 0.39),
                                    destination: .photos)
                            appIcon("Notes", symbol: "note.text",
                                    tint: Color(red: 0.79, green: 0.63, blue: 0.34),
                                    destination: .notes)
                            appIcon("Calendar", symbol: "calendar",
                                    tint: Color(red: 0.68, green: 0.41, blue: 0.46),
                                    destination: .calendar)
                            appIcon("Mail", symbol: "envelope.fill",
                                    tint: Color(red: 0.35, green: 0.49, blue: 0.76),
                                    destination: .mail)
                            appIcon("Settings", symbol: "gearshape.fill",
                                    tint: Color(red: 0.45, green: 0.46, blue: 0.54),
                                    destination: .settings)
                        }
                        .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 13) {
                            HStack {
                                Text("Recent")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.70))
                                Spacer()
                                NavigationLink(value: AppPage.messages) {
                                    Text("Messages")
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }

                            NavigationLink(value: AppPage.worldThread(latestNeighbor)) {
                                HStack(spacing: 11) {
                                    NeighborAvatar(neighbor: latestNeighbor, size: 43)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(latestNeighbor.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(world.messages(latestNeighbor).last?.text ?? "")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.64))
                                            .lineLimit(2)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.40))
                                }
                                .padding(13)
                                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 17))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 10)

                        Spacer(minLength: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 530)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { world.reconcile(with: game) }
        .onChange(of: game.state.clues) { _ in world.reconcile(with: game) }
    }

    private func appIcon(_ name: String, symbol: String, tint: Color,
                         destination: AppPage, badge: Int = 0) -> some View {
        NavigationLink(value: destination) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 17)
                        .fill(LinearGradient(colors: [tint, tint.opacity(0.68)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 59, height: 59)
                        .overlay {
                            Image(systemName: symbol)
                                .font(.system(size: 25, weight: .medium))
                                .foregroundColor(.white)
                        }
                    if badge > 0 {
                        Text(badge > 9 ? "9+" : String(badge))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .frame(minHeight: 19)
                            .background(Color(red: 0.85, green: 0.24, blue: 0.30), in: Capsule())
                            .offset(x: 6, y: -7)
                    }
                }
                Text(name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
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
        let ordinary: [PhoneThreadSummary] = Neighbor.visible(in: world.state).map { neighbor in
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
    var reactive = false
    @Environment(\.scenePhase) private var phase
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var draft = ""
    @State private var showHelp = false
    @State private var showSuggestions = false

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
                                if message.fromPlayer { Spacer(minLength: 20) }
                                else { NeighborAvatar(neighbor: neighbor, size: 28) }
                                VStack(alignment: message.fromPlayer ? .trailing : .leading, spacing: 4) {
                                    Text(message.text)
                                        .font(.body)
                                        .padding(12)
                                        .background(message.fromPlayer ? Night.outgoing : Night.incoming,
                                                    in: BubbleShape(outgoing: message.fromPlayer))
                                        .foregroundColor(.white)
                                    Text(message.at, style: .time)
                                        .font(.system(size: 10))
                                        .foregroundColor(Night.muted)
                                        .padding(.horizontal, 4)
                                    if reactive && message.fromPlayer && message.receiptTracked == true {
                                        Text(message.recipientReadAt == nil ? "Delivered" : "Read")
                                            .font(.caption2).foregroundColor(Night.muted)
                                    }
                                }
                                .frame(maxWidth: 280, alignment: message.fromPlayer ? .trailing : .leading)
                                if !message.fromPlayer { Spacer(minLength: 20) }
                                else {
                                    Image(RestoredPhoneBackup.ownerPortrait).resizable().scaledToFill()
                                        .frame(width: 28, height: 28).clipShape(Circle())
                                        .accessibilityLabel("Nora's phone")
                                }
                            }
                            .id(message.id)
                        }
                        if reactive {
                            TimelineView(.periodic(from: .now, by: 0.3)) { context in
                                if world.isTyping(neighbor, now: context.date) {
                                    HStack {
                                        NeighborAvatar(neighbor: neighbor, size: 28)
                                        TypingDots()
                                        Text("Typing").font(.caption).foregroundColor(Night.muted)
                                        Spacer()
                                    }.accessibilityLabel(neighbor.name + " is typing")
                                }
                            }
                        }
                        Color.clear.frame(height: 2).id("bottom")
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 14)
                }
                .onChange(of: world.messages(neighbor).count) { _ in
                    if phase == .active && (!reactive || world.visibleThread == neighbor) { world.markRead(neighbor) }
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    if reactive { world.visibleThread = neighbor }
                    if phase == .active { world.markRead(neighbor) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            Divider()
            if !reactive && world.choices(neighbor).isEmpty {
                Text("Conversation is quiet for now.")
                    .font(.system(size: 13))
                    .foregroundColor(Night.muted)
                    .padding(18)
            } else {
                VStack(spacing: 8) {
                    if reactive && !world.choices(neighbor).isEmpty {
                        Button { showSuggestions.toggle() } label: {
                            Label(showSuggestions ? "Hide suggested replies" : "Show suggested replies",
                                  systemImage: showSuggestions ? "chevron.down" : "chevron.up").font(.caption)
                        }
                    }
                    ForEach((!reactive || showSuggestions) ? world.choices(neighbor) : [], id: \.self) { choice in
                        Button {
                            draft = ""
                            if reactive { _ = world.sendReactive(to: neighbor, text: choice) }
                            else { _ = world.reply(to: neighbor, text: choice) }
                        } label: {
                            HStack {
                                Text(choice)
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.up.message")
                            }
                            .foregroundColor(.white)
                            .padding(11)
                            .lumaSurface(radius: 14)
                        }
                        .buttonStyle(.plain)
                    }
                    HStack {
                        TextField("Message", text: $draft, axis: .vertical)
                            .font(.system(size: 14))
                            .lineLimit(1...3)
                            .submitLabel(.send)
                            .onSubmit(send)
                        Button(action: send) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30)).frame(width: 44, height: 44)
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(10)
                    .lumaSurface(radius: 24)
                }
                .padding(12)
            }
        }
        .onDisappear { if reactive && world.visibleThread == neighbor { world.visibleThread = nil } }
        .onChange(of: phase) { if $0 == .active && reactive && world.visibleThread == neighbor { world.markRead(neighbor) } }
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
        .alert(reactive ? "Message not sent" : "Choose an available response", isPresented: $showHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reactive ? "Keep messages under 2,000 characters and allow pending replies to arrive." : "These conversations are authored and work offline. Select or type one of the suggested responses.")
        }
    }

    private func send() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if (reactive ? world.sendReactive(to: neighbor, text: draft) : world.reply(to: neighbor, text: draft)) { draft = "" }
        else { showHelp = true }
    }
}

struct NeighborProfileView: View {
    let neighbor: Neighbor
    var phoneLab = false
    @EnvironmentObject private var world: PhoneWorldStore

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                NeighborAvatar(neighbor: neighbor, size: 132)
                    .padding(12).background(LumaDesign.accent.opacity(0.12), in: Circle())
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
                if phoneLab && neighbor != .unknown {
                    HStack(spacing: 12) {
                        NavigationLink(value: LumaCallRoute(neighbor: neighbor)) {
                            Label("Call", systemImage: "phone.fill").frame(maxWidth: .infinity, minHeight: 44)
                        }.buttonStyle(.bordered)
                        Button {
                            world.toggleFavoriteContact(neighbor)
                        } label: {
                            Label((world.state.favoriteContacts ?? []).contains(neighbor.id) ? "Favorited" : "Favorite",
                                  systemImage: (world.state.favoriteContacts ?? []).contains(neighbor.id) ? "star.fill" : "star")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }.buttonStyle(.bordered)
                    }
                }
                Text(neighbor == .maya
                     ? (world.tutorialStarted ? "Maya is a friend of Nora, the original owner of this phone." : "You met Maya through friends in the neighborhood. She sends ordinary updates and makes plans.")
                     : (neighbor == .denise ? "Denise manages notices and maintenance for Ash Street residents." : neighbor.subtitle))
                    .font(.body)
                    .foregroundColor(Night.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(17)
                    .lumaSurface()
            }
            .padding(22)
        }
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Contact")
    }
}
