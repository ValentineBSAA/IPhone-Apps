import SwiftUI
import UserNotifications

/// Neutral, offline phone prototype. No GameStore or story routing is constructed here.
struct PhoneLabView: View {
    @StateObject private var world = PhoneWorldStore(storageURL: RestoredPhoneBackup.url)
    @State private var path = NavigationPath()
    @State private var locked: Bool
    init(startUnlocked: Bool = false) { _locked = State(initialValue: !startUnlocked) }
    @State private var panel: LabPanel?
    @State private var recent: [LabApp] = []
    @AppStorage("lastseen.lab.wallpaper") private var wallpaper = 0
    @AppStorage("lastseen.lab.brightness") private var brightness = 0.9
    @AppStorage("lastseen.lab.wifi") private var wifi = true
    @AppStorage("lastseen.setup.device") private var device = "My phone"

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                backdrop
                if locked { lockScreen } else { launcher }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LabApp.self) { app in
                destination(app)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button { path = NavigationPath() } label: {
                                Image(systemName: "house").accessibilityLabel("Return to phone home")
                            }
                        }
                    }
            }
            .navigationDestination(for: AppPage.self) { page in
                switch page {
                case .worldThread(let neighbor): NeighborConversationView(neighbor: neighbor)
                case .worldProfile(let neighbor): NeighborProfileView(neighbor: neighbor)
                case .note(let id): PhoneNoteEditorView(noteID: id)
                default: Text("Not available in Phone Lab")
                }
            }
        }
        .environmentObject(world)
        .tint(Color(red: 0.36, green: 0.81, blue: 0.76))
        .preferredColorScheme(.dark)
        .overlay {
            Color.black.opacity(max(0, 1 - brightness) * 0.75)
                .ignoresSafeArea().allowsHitTesting(false)
        }
        .sheet(item: $panel) { item in
            NavigationStack {
                Group {
                    switch item {
                    case .controls: controls
                    case .notifications: notifications
                    case .recent:
                        List {
                            if recent.isEmpty { Text("No recent apps").foregroundColor(.secondary) }
                            ForEach(recent) { app in
                                Button { panel = nil; open(app) } label: {
                                    Label(app.rawValue, systemImage: app.symbol)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(item.rawValue)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { panel = nil }
                } }
            }
            .environmentObject(world)
            .preferredColorScheme(.dark)
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [NotificationRouter.storyNotificationID])
            center.removeDeliveredNotifications(withIdentifiers: [NotificationRouter.storyNotificationID])
        }
    }

    private var backdrop: some View {
        let colors: [Color] = wallpaper == 1
            ? [Color(red: 0.34, green: 0.18, blue: 0.32), Color(red: 0.12, green: 0.12, blue: 0.22)]
            : [Color(red: 0.14, green: 0.34, blue: 0.41), Color(red: 0.07, green: 0.12, blue: 0.24)]
        return ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.05)).frame(width: 340, height: 340).offset(x: 150, y: 170)
            Circle().strokeBorder(.white.opacity(0.10), lineWidth: 1).frame(width: 300, height: 300).offset(x: -120, y: -100)
        }.ignoresSafeArea()
    }

    private var unread: Int { Neighbor.allCases.reduce(0) { $0 + world.countUnread($1) } }

    private var lockScreen: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "lock.fill").font(.title3)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 5) {
                    Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.headline)
                    Text(context.date, style: .time)
                        .font(.system(size: 68, weight: .thin, design: .rounded))
                        .monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                }
            }
            if unread > 0 {
                Button { panel = .notifications } label: {
                    HStack {
                        Image(systemName: "message.fill").font(.title2)
                        VStack(alignment: .leading) {
                            Text("Messages").font(.headline)
                            Text("\(unread) unread messages").font(.subheadline)
                        }
                        Spacer()
                    }.padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 19))
                }.buttonStyle(.plain)
            }
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { locked = false }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "chevron.up").font(.title3)
                    Text("Unlock").font(.headline)
                }.frame(maxWidth: .infinity).padding(.vertical, 15)
            }.buttonStyle(.plain)
            Text("Fictional phone · Phone Lab").font(.caption2).foregroundColor(.white.opacity(0.6))
        }
        .padding(24)
        .foregroundColor(.white)
        .gesture(DragGesture(minimumDistance: 40).onEnded { value in
            if value.translation.height < -50 {
                withAnimation(.easeInOut(duration: 0.25)) { locked = false }
            }
        })
    }

    private var launcher: some View {
        VStack(spacing: 16) {
            HStack {
                Button { panel = .notifications } label: {
                    Label("Notifications", systemImage: "bell")
                        .labelStyle(.iconOnly).font(.title3)
                }
                Spacer()
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(context.date, style: .time).font(.subheadline).monospacedDigit()
                }
                Spacer()
                Button { panel = .controls } label: {
                    Image(systemName: wifi ? "slider.horizontal.3" : "wifi.slash")
                        .font(.title3).accessibilityLabel("Quick settings")
                }
            }.padding(.horizontal, 7)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 24) {
                    ForEach(LabApp.allCases.filter { !$0.inDock }) { app in icon(app) }
                }.padding(.top, 22).padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            Spacer(minLength: 0)
            HStack {
                Button { withAnimation { locked = true } } label: {
                    Label("Lock", systemImage: "lock").font(.caption)
                }
                Spacer()
                Button { panel = .recent } label: {
                    Label("Recent apps", systemImage: "square.on.square").font(.caption)
                }
            }.padding(.horizontal, 12)
            HStack(spacing: 7) {
                ForEach(LabApp.allCases.filter(\.inDock)) { app in icon(app) }
            }.padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 27))
        }
        .padding(.horizontal, 17).padding(.vertical, 12)
        .buttonStyle(.plain).foregroundColor(.white)
    }

    private func open(_ app: LabApp) {
        locked = false
        recent.removeAll { $0 == app }
        recent.insert(app, at: 0)
        path = NavigationPath()
        path.append(app)
    }

    private func icon(_ app: LabApp) -> some View {
        Button { open(app) } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [app.color, app.color.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 55, height: 55)
                        .overlay { Image(systemName: app.symbol).font(.system(size: 24, weight: .medium)) }
                    if app == .messages && unread > 0 {
                        Text("\(unread)").font(.caption2.bold()).padding(5)
                            .background(.red, in: Capsule()).offset(x: 5, y: -5)
                    }
                }
                Text(app.rawValue).font(.system(size: 11, weight: .medium))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
    }

    private var controls: some View {
        Form {
            Section("Fictional device controls") {
                LabeledContent("Device name", value: device)
                Toggle("Simulated Wi-Fi", isOn: $wifi)
                VStack(alignment: .leading) {
                    Text("Phone display brightness")
                    Slider(value: $brightness, in: 0.35...1)
                }
                Picker("Wallpaper", selection: $wallpaper) {
                    Text("Coastal").tag(0)
                    Text("Dusk").tag(1)
                }
            }
            Section {
                Text("These controls change only the in-game phone, never your real iPhone settings.").font(.footnote)
            }
        }
    }

    private var notifications: some View {
        List {
            if unread == 0 { Text("You're all caught up.").foregroundColor(.secondary) }
            ForEach(Neighbor.allCases) { person in
                if world.countUnread(person) > 0 {
                    Button {
                        panel = nil
                        open(.messages)
                        path.append(AppPage.worldThread(person))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(person.name).font(.headline)
                            Text(world.messages(person).last?.text ?? "").font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func destination(_ app: LabApp) -> some View {
        switch app {
        case .messages: LabPeopleView(messages: true)
        case .contacts: LabPeopleView(messages: false)
        case .notes: PhoneNotesView()
        case .calendar: PhoneCalendarView()
        case .mail: PhoneMailView(lab: true)
        case .photos: LabPhotosView()
        case .clock: LabClockView()
        case .calculator: LabCalculatorView()
        case .settings:
            controls.navigationTitle("Settings")
        case .files: LabFilesView()
        case .browser: LabBrowserView(wifi: wifi)
        }
    }
}

private enum LabPanel: String, Identifiable {
    case controls = "Quick settings", notifications = "Notifications", recent = "Recent apps"
    var id: String { rawValue }
}

private enum LabApp: String, CaseIterable, Identifiable {
    case messages = "Messages", contacts = "Contacts", photos = "Photos", notes = "Notes", calendar = "Calendar", mail = "Mail", clock = "Clock", calculator = "Calculator", settings = "Settings", files = "Files", browser = "Browser"
    var id: String { rawValue }
    var inDock: Bool { [.messages, .contacts, .browser, .settings].contains(self) }
    var symbol: String {
        switch self {
        case .messages: return "message.fill"
        case .contacts: return "person.crop.circle.fill"
        case .photos: return "photo.on.rectangle"
        case .notes: return "note.text"
        case .calendar: return "calendar"
        case .mail: return "envelope.fill"
        case .clock: return "clock"
        case .calculator: return "plus.forwardslash.minus"
        case .settings: return "gearshape.fill"
        case .files: return "folder.fill"
        case .browser: return "globe"
        }
    }
    var color: Color {
        switch self {
        case .messages: return .teal
        case .contacts: return .indigo
        case .photos: return .pink
        case .notes: return .orange
        case .calendar: return .red
        case .mail: return .blue
        case .clock: return .gray
        case .calculator: return .brown
        case .settings: return .gray
        case .files: return .cyan
        case .browser: return .mint
        }
    }
}

private struct LabPeopleView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    let messages: Bool
    @State private var search = ""
    var body: some View {
        List {
            ForEach(Neighbor.allCases.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) ||
                (messages && world.messages($0).contains { $0.text.localizedCaseInsensitiveContains(search) }) }) { person in
                NavigationLink(value: messages ? AppPage.worldThread(person) : AppPage.worldProfile(person)) {
                    HStack(spacing: 12) {
                        NeighborAvatar(neighbor: person, size: 49)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(person.name).font(.headline)
                            Text(messages ? (world.messages(person).last?.text ?? "") : person.subtitle)
                                .font(.subheadline).foregroundColor(.secondary).lineLimit(2)
                        }
                        Spacer()
                        if messages && world.countUnread(person) > 0 {
                            Text("\(world.countUnread(person))").font(.caption.bold())
                                .padding(6).background(.teal, in: Capsule())
                        }
                    }.padding(.vertical, 5)
                }
            }
        }.navigationTitle(messages ? "Messages" : "Contacts").searchable(text: $search)
    }
}

private struct LabPhotosView: View {
    @State private var selection: Neighbor?
    @AppStorage("lastseen.lab.favoritePhotos") private var favorites = ""
    @State private var onlyFavorites = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Toggle("Favorites only", isOn: $onlyFavorites)
                Text("Camera roll").font(.headline)
                if !onlyFavorites {
                    NavigationLink {
                        VStack(spacing: 20) {
                            Image(RestoredPhoneBackup.ownerPortrait).resizable().scaledToFit()
                            Text("Portrait · saved last week").font(.caption).foregroundColor(.secondary)
                        }.padding().navigationTitle("Photo")
                    } label: {
                        VStack(alignment: .leading) {
                            Image(RestoredPhoneBackup.ownerPortrait).resizable().scaledToFill().frame(height: 190).clipped()
                            Text("Last week").font(.caption)
                        }
                    }.buttonStyle(.plain)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Neighbor.allCases.filter { !onlyFavorites || isFavorite($0) }) { person in
                        Button { selection = person } label: {
                            VStack {
                                NeighborAvatar(neighbor: person, size: 115)
                                Text(person.name).font(.caption)
                            }.frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain)
                    }
                }
            }.padding()
        }.navigationTitle("Photos")
        .sheet(item: $selection) { person in
            VStack(spacing: 24) {
                Spacer()
                NeighborAvatar(neighbor: person, size: 230)
                Text(person.name).font(.title2)
                Button { toggle(person) } label: {
                    Label(isFavorite(person) ? "Remove favorite" : "Favorite", systemImage: isFavorite(person) ? "heart.fill" : "heart")
                }
                Spacer()
                Button("Done") { selection = nil }.padding()
            }.padding().presentationDetents([.large])
        }
    }
    private func isFavorite(_ p: Neighbor) -> Bool { favorites.split(separator: "|").contains(Substring(p.id)) }
    private func toggle(_ p: Neighbor) {
        var ids = Set(favorites.split(separator: "|").map(String.init))
        if ids.contains(p.id) { ids.remove(p.id) } else { ids.insert(p.id) }
        favorites = ids.sorted().joined(separator: "|")
    }
}

private struct LabClockView: View {
    @State private var started: Date?
    @State private var elapsed: TimeInterval = 0
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            VStack(spacing: 28) {
                Text(context.date, style: .time).font(.system(size: 60, weight: .thin)).monospacedDigit()
                Text(context.date, format: .dateTime.weekday(.wide).month().day())
                Divider()
                Text("Stopwatch").font(.headline)
                Text(String(format: "%.1f s", elapsed + (started.map { context.date.timeIntervalSince($0) } ?? 0)))
                    .font(.system(size: 48, weight: .light)).monospacedDigit()
                HStack {
                    Button(started == nil ? "Start" : "Stop") {
                        if let start = started { elapsed += Date().timeIntervalSince(start); started = nil }
                        else { started = Date() }
                    }.buttonStyle(.borderedProminent)
                    Button("Reset") { started = nil; elapsed = 0 }.buttonStyle(.bordered)
                }
                Spacer()
            }.padding()
        }.navigationTitle("Clock")
    }
}

private struct LabCalculatorView: View {
    @State private var display = "0"
    @State private var first: Double?
    @State private var operation: String?
    @State private var replace = true
    let keys = ["C","±","%","÷","7","8","9","×","4","5","6","−","1","2","3","+","0",".","="]
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(display).font(.system(size: 52, weight: .light)).lineLimit(1).minimumScaleFactor(0.3)
                .frame(maxWidth: .infinity, alignment: .trailing).padding()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(keys, id: \.self) { key in
                    Button { press(key) } label: {
                        Text(key).font(.title2).frame(maxWidth: .infinity).frame(height: 54)
                            .background(["÷","×","−","+","="].contains(key) ? Color.teal : Color.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 15))
                    }.buttonStyle(.plain)
                }
            }
        }.padding().navigationTitle("Calculator")
    }
    private func press(_ key: String) {
        if key == "C" { display = "0"; first = nil; operation = nil; replace = true; return }
        if ["÷","×","−","+","="].contains(key) {
            let right = Double(display) ?? 0
            if let left = first, let op = operation, !replace || key == "=" {
                let result: Double
                switch op {
                case "+": result = left + right
                case "−": result = left - right
                case "×": result = left * right
                default: result = right == 0 ? .nan : left / right
                }
                display = result.isFinite ? String(format: "%.10g", result) : "Error"
            }
            first = key == "=" ? nil : Double(display)
            operation = key == "=" ? nil : key
            replace = true
        } else if key == "±" || key == "%" {
            let value = Double(display) ?? 0
            display = String(format: "%.10g", key == "±" ? -value : value / 100)
        } else {
            if replace || display == "Error" { display = key == "." ? "0." : key; replace = false }
            else if key != "." || !display.contains(".") {
                if display.count < 16 { display = display == "0" && key != "." ? key : display + key }
            }
        }
    }
}

private struct LabFilesView: View {
    let documents = ["Building handbook": "Ash Street residents: please keep the entrance clear and contact Denise at the building office for maintenance requests.", "Book reservation": "Maple Street Bookshop — reservation held until the end of this week.", "Coffee plans": "Meet Maya at the cafe opposite the bookstore. Confirm the day by text."]
    @State private var search = ""
    var body: some View {
        List(documents.keys.sorted().filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) }, id: \.self) { name in
            NavigationLink {
                ScrollView { Text(documents[name] ?? "").frame(maxWidth: .infinity, alignment: .leading).padding() }
                    .navigationTitle(name)
            } label: { Label(name, systemImage: "doc.text") }
        }.navigationTitle("Files").searchable(text: $search)
    }
}

private struct LabBrowserView: View {
    let wifi: Bool
    @State private var search = ""
    @AppStorage("lastseen.lab.history") private var history = ""
    @AppStorage("lastseen.lab.bookmarks") private var bookmarks = ""
    let pages = ["Maple Street Bookshop": "Open 10–6. Reserved books are held for seven days.", "Ash Street Residents": "Building office notices, elevator inspections and community events.", "Maple Cafe": "Coffee, pastries and sandwiches. Across from the bookshop."]
    var body: some View {
        List {
            Section("Offline local pages") {
                ForEach(pages.keys.sorted().filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) }, id: \.self) { name in
                    NavigationLink {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text(name).font(.largeTitle.bold())
                                Text(pages[name] ?? "")
                                Button(bookmarks.contains(name) ? "Remove bookmark" : "Bookmark") {
                                    var entries = Set(bookmarks.split(separator: "|").map(String.init))
                                    if entries.contains(name) { entries.remove(name) } else { entries.insert(name) }
                                    bookmarks = entries.sorted().joined(separator: "|")
                                }.buttonStyle(.bordered)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding()
                        }.navigationTitle("Local page").onAppear {
                            if !history.split(separator: "|").contains(Substring(name)) { history += (history.isEmpty ? "" : "|") + name }
                        }
                    } label: { Label(name, systemImage: "globe") }
                }
            }
            Section("Bookmarks") {
                if bookmarks.isEmpty { Text("No bookmarks").foregroundColor(.secondary) }
                ForEach(bookmarks.split(separator: "|").map(String.init), id: \.self) { name in
                    NavigationLink(name) { Text(pages[name] ?? "").padding().navigationTitle(name) }
                }
            }
            Section("History") {
                if history.isEmpty { Text("No history").foregroundColor(.secondary) }
                ForEach(history.split(separator: "|").map(String.init), id: \.self) { name in
                    NavigationLink(name) { Text(pages[name] ?? "").padding().navigationTitle(name) }
                }
                if !history.isEmpty { Button("Clear history", role: .destructive) { history = "" } }
            }
            Section { Text(wifi ? "Simulated Wi-Fi on. Pages are bundled offline." : "Simulated Wi-Fi off. Saved pages remain available.").font(.footnote) }
        }.navigationTitle("Browser").searchable(text: $search, prompt: "Search local sites")
    }
}
