import SwiftUI

struct PhonePhotoLibraryView: View {
    @EnvironmentObject private var game: GameStore
    @State private var search = ""
    @State private var selected: GameMessage?

    private var photos: [GameMessage] {
        Contact.allCases.flatMap { game.messages(in: $0.id) }
            .filter { $0.kind == .photograph && $0.photoAssetName != nil }
            .filter {
                search.isEmpty ||
                $0.body.localizedCaseInsensitiveContains(search) ||
                (Contact(rawValue: $0.thread)?.name ?? "")
                    .localizedCaseInsensitiveContains(search)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Shared memories")
                            .font(.system(size: 25, weight: .semibold))
                        Text("Photos appear here as contacts share them.")
                            .font(.system(size: 13))
                            .foregroundColor(Night.muted)
                    }
                    Spacer()
                }
                if photos.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 6),
                                        GridItem(.flexible(), spacing: 6)], spacing: 6) {
                        ForEach(photos) { photo in
                            Button {
                                game.inspect(photo)
                                selected = photo
                            } label: {
                                StoryPhotograph(assetName: photo.photoAssetName)
                                    .frame(height: 190)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .overlay(alignment: .bottomLeading) {
                                        Text(Contact(rawValue: photo.thread)?.name ?? "Unknown")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(7)
                                            .background(.black.opacity(0.55), in: Capsule())
                                            .padding(7)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Photograph from \(Contact(rawValue: photo.thread)?.name ?? "Unknown")")
                        }
                    }
                }
            }
            .padding(17)
        }
        .background(Night.background.ignoresSafeArea())
        .searchable(text: $search, prompt: "Search shared photos")
        .navigationTitle("Photos")
        .sheet(item: $selected) { photo in
            PhonePhotoDetailView(message: photo)
                .environmentObject(game)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 37))
            Text("No photos yet")
                .font(.system(size: 17, weight: .medium))
            Text("Shared images will appear here as your conversations continue.")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
        }
        .foregroundColor(Night.muted)
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Night.surface, in: RoundedRectangle(cornerRadius: 18))
        .padding(.top, 20)
    }
}

struct PhonePhotoDetailView: View {
    let message: GameMessage
    @EnvironmentObject private var game: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StoryPhotograph(assetName: message.photoAssetName, fit: true)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(scale)
                        .gesture(MagnificationGesture()
                            .onChanged { scale = max(1, min(4, $0)) }
                            .onEnded { _ in withAnimation { scale = 1 } })
                        .onTapGesture(count: 2) {
                            withAnimation { scale = scale > 1 ? 1 : 2 }
                        }
                        .padding(.vertical, 22)

                    Text(message.body)
                        .font(.system(size: 17, weight: .medium))
                    HStack {
                        Text(Contact(rawValue: message.thread)?.name ?? "Unknown")
                        Spacer()
                        Text(message.createdAt, format: .dateTime.month().day().hour().minute())
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Night.muted)

                    if let asset = message.photoAssetName,
                       let description = StoryPhotoCatalog.labels[asset] {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.74))
                    }
                    Label("Pinch or double-tap to inspect", systemImage: "hand.draw")
                        .font(.system(size: 12))
                        .foregroundColor(Night.muted)
                }
                .padding(18)
            }
            .background(Night.background.ignoresSafeArea())
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { game.inspect(message) }
        }
        .preferredColorScheme(.dark)
    }
}

struct PhoneNotesView: View {
    var lab = false
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var search = ""

    private var notes: [PhoneNote] {
        world.state.notes.filter {
            search.isEmpty ||
            $0.title.localizedCaseInsensitiveContains(search) ||
            $0.body.localizedCaseInsensitiveContains(search)
        }.sorted {
            if $0.pinned != $1.pinned { return $0.pinned }
            return $0.modifiedAt > $1.modifiedAt
        }
    }

    var body: some View {
        List {
            if lab {
                LumaHeader(title: "Your notes", detail: "\(notes.count) notes on this phone", symbol: "note.text").listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                NavigationLink { ProtectedAreaView(area: .notes, onOpened: { world.recordTutorialVisit("journal") }) } label: { Label("Locked notes", systemImage: "lock.fill") }
            }
            Section {
                ForEach(notes) { note in
                    NavigationLink(value: AppPage.note(note.id)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                if note.pinned {
                                    Image(systemName: "pin.fill").foregroundColor(Night.gold)
                                        .font(.system(size: 11))
                                }
                                Text(note.title.isEmpty ? "Untitled" : note.title)
                                    .font(.headline)
                                Spacer()
                                Text(note.modifiedAt, style: .date)
                                    .font(.system(size: 11))
                                    .foregroundColor(Night.muted)
                            }
                            Text(note.body.isEmpty ? "No additional text" : note.body.replacingOccurrences(of: "\n", with: " "))
                                .lineLimit(2)
                                .font(.subheadline)
                                .foregroundColor(Night.muted)
                        }
                        .padding(.vertical, 5)
                    }
                    .swipeActions(edge: .trailing) {
                        if note.id != PhoneWorldStore.tutorialNoteID {
                            Button(role: .destructive) { world.removeNote(note.id) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        Button { world.togglePin(note.id) } label: {
                            Label(note.pinned ? "Unpin" : "Pin", systemImage: "pin")
                        }
                        .tint(Night.gold)
                    }
                }
            } header: {
                Text("\(notes.count) Notes")
            }
            .listRowBackground(Night.surface)
        }
        .searchable(text: $search, prompt: "Search notes")
        .scrollContentBackground(.hidden)
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    _ = world.addNote()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Create note")
            }
        }
    }
}

struct PhoneNoteEditorView: View {
    let noteID: String
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var title = ""
    @State private var bodyText = ""

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
        .navigationTitle(noteID == PhoneWorldStore.tutorialNoteID ? "Note" : "Edit note")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let n = world.state.notes.first(where: { $0.id == noteID }) {
                title = n.title
                bodyText = n.body
            }
        }
        .onDisappear {
            world.updateNote(noteID, title: title, body: bodyText)
        }
    }
}

struct PhoneCalendarView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var selectedDay: Date
    init(initialDay: Date = Date()) { _selectedDay = State(initialValue: initialDay) }

    private var matching: [PhoneEvent] {
        world.state.events
            .filter { Calendar.current.isDate($0.startsAt, inSameDayAs: selectedDay) }
            .sorted { $0.startsAt < $1.startsAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                LumaHeader(title: selectedDay.formatted(.dateTime.weekday(.wide).month(.wide).day()), detail: "\(matching.count) scheduled events", symbol: "calendar")
                DatePicker("Selected day", selection: $selectedDay, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Night.accent)
                    .padding(10)
                    .lumaSurface()

                Button("Today") { selectedDay = Date() }.buttonStyle(.bordered)
                Text("Scheduled")
                    .font(.system(size: 19, weight: .semibold))
                if matching.isEmpty {
                    Text("Nothing scheduled for this day.")
                        .font(.system(size: 14))
                        .foregroundColor(Night.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .lumaSurface(radius: 16)
                } else {
                    ForEach(matching) { event in
                        VStack(alignment: .leading, spacing: 9) {
                            Text(event.title)
                                .font(.system(size: 16, weight: .semibold))
                            Text(event.startsAt, format: .dateTime.hour().minute())
                                .font(.system(size: 12))
                                .foregroundColor(Night.accent)
                            Text(event.detail)
                                .font(.system(size: 13))
                                .foregroundColor(Night.muted)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Night.surface, in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                Text("Upcoming events").font(.headline).padding(.top, 6)
                ForEach(world.state.events.filter { $0.endsAt >= Date() }.sorted { $0.startsAt < $1.startsAt }) { event in
                    Button { selectedDay = event.startsAt } label: {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(Night.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title).font(.subheadline.bold())
                                Text(event.startsAt, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption)
                        }.padding(12).background(Night.surface, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                }
            }
            .padding(18)
        }
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PhoneMailItem: Identifiable {
    let id: String
    let from: String
    let subject: String
    let body: String
    let date: Date
}

struct PhoneMailView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage private var readIDs: String
    private let lab: Bool

    init(lab: Bool = false) {
        self.lab = lab
        _readIDs = AppStorage(wrappedValue: "", lab ? "lastseen.restored.mail.read" : "lastseen.mail.read")
    }
    @State private var selected: String?
    @State private var search = ""
    @State private var unreadOnly = false
    private var filteredMail: [PhoneMailItem] {
        mails.filter { mail in
            (!unreadOnly || !isRead(mail)) && (search.isEmpty || [mail.from, mail.subject, mail.body].contains { $0.localizedCaseInsensitiveContains(search) })
        }
    }

    private var mails: [PhoneMailItem] {
        let date = world.state.createdAt
        return [
            PhoneMailItem(id: "building-update", from: "Ash Street Building Office",
                subject: "Upcoming elevator maintenance",
                body: "Hello residents,\n\nThis is an advance notice that an elevator inspection is being arranged for this week. We will post the confirmed time in the lobby and notify residents when the contractor has approved the schedule.\n\nThe front entrance and stairwell remain available.\n\nThank you,\nDenise\nBuilding Office",
                date: date.addingTimeInterval(-3600)),
            PhoneMailItem(id: "bookstore", from: "Maple Street Bookshop",
                subject: "Your reservation is ready",
                body: (lab ? "Hi Nora,\n\n" : "Hi there,\n\n") + "The book you reserved is ready for pickup. We'll hold it through the end of the week.\n\nThanks for shopping locally,\nMaple Street Bookshop",
                date: date.addingTimeInterval(-10800)),
            PhoneMailItem(id: "building-bulletin", from: "Ash Street Neighbors",
                subject: "Community notice",
                body: "Hi neighbors,\n\nThe lobby noticeboard has a new calendar for building maintenance and community events. Please check for updates before making plans.\n\nHave a good week,\nAsh Street Neighbors",
                date: date.addingTimeInterval(-86400))
        ]
    }

    var body: some View {
        List {
            if lab { LumaHeader(title: "Inbox", detail: "\(mails.filter { !isRead($0) }.count) unread messages", symbol: "envelope.fill").listRowInsets(EdgeInsets()).listRowBackground(Color.clear) }
            Section {
                Picker("Mailbox", selection: $unreadOnly) {
                    Text("All mail").tag(false)
                    Text("Unread").tag(true)
                }.pickerStyle(.segmented)
            }
            if filteredMail.isEmpty { Text("No matching mail").foregroundColor(.secondary) }
            ForEach(filteredMail) { mail in
                Button {
                    selected = mail.id
                    if !readIDs.split(separator: "|").contains(Substring(mail.id)) {
                        readIDs += (readIDs.isEmpty ? "" : "|") + mail.id
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if !isRead(mail) { Circle().fill(Color.blue).frame(width: 8, height: 8) }
                            Text(mail.from)
                                .font(.system(size: 16, weight: isRead(mail) ? .regular : .bold))
                            Spacer()
                            Text(mail.date, style: .date)
                                .font(.system(size: 11))
                                .foregroundColor(Night.muted)
                        }
                        Text(mail.subject)
                            .font(.subheadline.weight(.semibold))
                        Text(mail.body.replacingOccurrences(of: "\n", with: " "))
                            .lineLimit(2)
                            .font(.system(size: 12))
                            .foregroundColor(Night.muted)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .listRowBackground(Night.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Night.background.ignoresSafeArea())
        .navigationTitle("Mail")
        .searchable(text: $search, prompt: "Search mail")
        .sheet(item: Binding<MailSelection?>(
            get: { selected.map(MailSelection.init(id:)) },
            set: { selected = $0?.id }
        )) { selection in
            NavigationStack {
                ScrollView {
                    if let item = mails.first(where: { $0.id == selection.id }) {
                        VStack(alignment: .leading, spacing: 17) {
                            Text(item.subject)
                                .font(.system(size: 27, weight: .semibold))
                            Text("From: \(item.from)")
                                .font(.system(size: 14))
                                .foregroundColor(Night.muted)
                            Text(item.date, format: .dateTime.month().day().hour().minute())
                                .font(.system(size: 12))
                                .foregroundColor(Night.muted)
                            Divider()
                            Text(item.body)
                                .font(.system(size: 16))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(19)
                    }
                }
                .background(Night.background.ignoresSafeArea())
                .navigationTitle("Message")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { selected = nil }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func isRead(_ item: PhoneMailItem) -> Bool {
        readIDs.split(separator: "|").contains(Substring(item.id))
    }
}

private struct MailSelection: Identifiable {
    let id: String
}
