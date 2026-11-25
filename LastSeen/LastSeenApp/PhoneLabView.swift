import SwiftUI
import UserNotifications
import LocalAuthentication

/// Neutral, offline phone prototype. No GameStore or story routing is constructed here.
struct PhoneLabView: View {
    @StateObject private var world = PhoneWorldStore(storageURL: RestoredPhoneBackup.url)
    @State private var path = NavigationPath()
    @State private var locked: Bool
    init(startUnlocked: Bool = false) { _locked = State(initialValue: !startUnlocked) }
    @State private var panel: LabPanel?
    @State private var recent: [LabApp] = []
    @AppStorage("lastseen.lab.wallpaper") private var wallpaper = 0
    @AppStorage("lastseen.relay.compactIcons") private var compactIcons = false
    @AppStorage("lastseen.relay.installed") private var relayInstalled = ""
    @AppStorage("lastseen.lab.brightness") private var brightness = 0.9
    @AppStorage("lastseen.lab.wifi") private var wifi = true
    @AppStorage("lastseen.setup.device") private var device = "My phone"
    @AppStorage("lastseen.security.ownerVerified") private var ownerVerified = false
    @AppStorage("lastseen.security.appearanceEnrolled") private var appearanceEnrolled = false
    @State private var showOwnerPasscode = false
    @AppStorage("lastseen.recovery.stage") private var recoveryStage = 6
    @AppStorage("lastseen.recovery.progress") private var recoveryProgress = 100
    @AppStorage("lastseen.recovery.simulated") private var recoverySimulated = false
    private var biometricUnlock: Bool { OwnerSecurityPolicy.canUseBiometrics(ownerVerified: ownerVerified, appearanceEnrolled: appearanceEnrolled) }
    @State private var authContext: LAContext?
    @State private var authNotice = ""
    @AppStorage("lastseen.permissions.reviewed.v1") private var permissionsReviewed = true
    @AppStorage("lastseen.lab.nativeAlerts") private var nativeAlerts = false
    @AppStorage("lastseen.setup.stage") private var setupStage = 5
    @AppStorage("lastseen.setup.progress") private var setupProgress = 100
    @State private var testNotice = ""
    @State private var confirmSetupReplay = false
    @State private var showOpeningQA = false

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
        .sheet(isPresented: $showOwnerPasscode) {
            ScrollView {
                OwnerPasscodeView(onSuccess: {
                    ownerVerified = true; showOwnerPasscode = false; authNotice = ""; locked = false
                }, onCancel: { showOwnerPasscode = false })
            }.preferredColorScheme(.dark).presentationDetents([.large])
        }
        .onAppear {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [NotificationRouter.storyNotificationID])
            center.removeDeliveredNotifications(withIdentifiers: [NotificationRouter.storyNotificationID])
        }
    }

    private var backdrop: some View { PhoneWallpaper(selection: wallpaper).ignoresSafeArea() }

    private var unread: Int { Neighbor.allCases.reduce(0) { $0 + world.countUnread($1) } }

    private var lockScreen: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: biometricUnlock ? "faceid" : "lock.fill").font(.title3)
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
                Button { if biometricUnlock { requestUnlock() } else { panel = .notifications } } label: {
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
                requestUnlock()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "chevron.up").font(.title3)
                    Text(biometricUnlock ? "Authenticate to unlock" : "Unlock").font(.headline)
                }.frame(maxWidth: .infinity).padding(.vertical, 15)
            }.buttonStyle(.plain).disabled(authContext != nil)
            if !authNotice.isEmpty { Text(authNotice).font(.caption).multilineTextAlignment(.center) }
            if biometricUnlock {
                Button("Use owner passcode") { showOwnerPasscode = true }.font(.subheadline).disabled(authContext != nil)
                Button("Explore public apps") { authNotice = ""; locked = false }.font(.caption).disabled(authContext != nil)
            }
            Text("Swipe up to open").font(.caption2).foregroundColor(.white.opacity(0.6))
        }
        .padding(24)
        .foregroundColor(.white)
        .gesture(DragGesture(minimumDistance: 40).onEnded { value in
            if value.translation.height < -50 { requestUnlock() }
        })
    }

    private func requestUnlock() {
        guard locked, authContext == nil else { return }
        authNotice = ""
        guard biometricUnlock else {
            withAnimation(.easeInOut(duration: 0.25)) { locked = false }
            return
        }
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = ""
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authNotice = "Biometrics unavailable. Use the fictional owner passcode or open public apps."
            return
        }
        authContext = context
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your fictional Last Seen phone.") { success, _ in
            DispatchQueue.main.async {
                guard authContext === context else { return }
                authContext = nil
                if success {
                    withAnimation(.easeInOut(duration: 0.25)) { locked = false }
                } else {
                    authNotice = "Unlock cancelled or unsuccessful. Use the fictional owner passcode or open public apps."
                }
            }
        }
    }

    private var launcher: some View {
        VStack(spacing: 16) {
            HStack {
                Button { panel = .notifications } label: {
                    Label("Notifications", systemImage: "bell")
                        .labelStyle(.iconOnly).font(.title3)
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
        OpeningQA.record("Opened in-game app: \(app.rawValue)")
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
                        .frame(width: compactIcons ? 47 : 55, height: compactIcons ? 47 : 55)
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
            Section("Device") {
                LabeledContent("Device name", value: device)
                NavigationLink { ProtectedAreaView(area: .security) } label: {
                    Label("Face ID & Passcode", systemImage: "lock.shield")
                }
                LabeledContent("Appearance", value: biometricUnlock ? "Registered" : "Locked")
                Toggle("Wi-Fi (in-game)", isOn: $wifi)
                VStack(alignment: .leading) {
                    Text("Display brightness")
                    Slider(value: $brightness, in: 0.35...1)
                }
                Picker("Wallpaper", selection: $wallpaper) {
                    Text("Coastal").tag(0)
                    Text("Dusk").tag(1)
                    if relayInstalled.split(separator: "|").contains("midnight") { Text("Midnight Glass").tag(2) }
                }
            }
            Section("Notifications and privacy") {
                LabeledContent("Native game alerts", value: nativeAlerts ? "Enabled in game" : "Off")
                Button("Review optional permissions") { panel = nil; permissionsReviewed = false }
                if nativeAlerts {
                    Button("Schedule test notification (7 seconds)") { scheduleTestAlert() }
                    if !testNotice.isEmpty { Text(testNotice).font(.caption).foregroundColor(.secondary) }
                }
                Text("Last Seen never reads your real contacts, messages or photos. Device controls affect only the game.").font(.footnote).foregroundColor(.secondary)
            }
            Section("About") {
                LabeledContent("Software", value: "1.3.1 (14)")
                Button("Developer Diagnostics") { showOpeningQA = true }
                Button("Replay phone setup") { confirmSetupReplay = true }
            }
        }
        .sheet(isPresented: $showOpeningQA) { OpeningDiagnosticsView() }
        .confirmationDialog("Replay phone setup?", isPresented: $confirmSetupReplay) {
            Button("Replay setup") { OpeningQA.record("Phone setup replay requested"); panel = nil; setupProgress = 0; setupStage = 0 }
            Button("Replay entire introduction") { OpeningQA.record("Introduction replay requested"); panel = nil; setupProgress = 0; setupStage = 0; recoveryProgress = 0; recoverySimulated = false; recoveryStage = 0 }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your restored phone records and story saves will not be erased.")
        }
    }

    private func scheduleTestAlert() {
        guard nativeAlerts else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                DispatchQueue.main.async { testNotice = "Notifications are disabled in iOS Settings." }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Last Seen"
            content.body = "Game notification test. No story event has been triggered."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false)
            center.add(UNNotificationRequest(identifier: "lastseen-lab-test", content: content, trigger: trigger)) { error in
                DispatchQueue.main.async { testNotice = error == nil ? "Test scheduled. Leave the app to see the iOS alert." : "Unable to schedule the test." }
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
        case .notes: PhoneNotesView(lab: true)
        case .calendar: PhoneCalendarView()
        case .mail: PhoneMailView(lab: true)
        case .photos: LabPhotosView()
        case .clock: LabClockView()
        case .calculator: LabCalculatorView()
        case .settings:
            controls.navigationTitle("Settings")
        case .files: LabFilesView()
        case .browser: LabBrowserView(wifi: wifi)
        case .relay: RelayPackagesView()
        }
    }
}

private enum LabPanel: String, Identifiable {
    case controls = "Quick settings", notifications = "Notifications", recent = "Recent apps"
    var id: String { rawValue }
}

private enum LabApp: String, CaseIterable, Identifiable {
    case messages = "Messages", contacts = "Contacts", photos = "Photos", notes = "Notes", calendar = "Calendar", mail = "Mail", clock = "Clock", calculator = "Calculator", settings = "Settings", files = "Files", browser = "Browser", relay = "Relay"
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
        case .relay: return "shippingbox.fill"
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
        case .relay: return .teal
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
                        if messages, let latest = world.messages(person).last {
                            Text(latest.at, style: .time).font(.caption2).foregroundColor(.secondary)
                        }
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
                NavigationLink { ProtectedAreaView(area: .photos) } label: {
                    Label("Private album", systemImage: "lock.fill").padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
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
    let documents = ["Building handbook": "Ash Street residents: please keep the entrance clear and contact Denise at the building office for maintenance requests.", "Book reservation": "Maple Street Bookshop — reservation held until the end of this week.\nReservation reference: 241607.", "Coffee plans": "Meet Maya at the cafe opposite the bookstore. Confirm the day by text.", "Desk reminder": "Private folders use the six-digit reference from my book reservation. — Nora"]
    @State private var search = ""
    var body: some View {
        List {
            NavigationLink { ProtectedAreaView(area: .files) } label: { Label("Protected files", systemImage: "lock.doc") }
            ForEach(documents.keys.sorted().filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) }, id: \.self) { name in
                NavigationLink {
                    ScrollView { Text(documents[name] ?? "").frame(maxWidth: .infinity, alignment: .leading).padding() }
                        .navigationTitle(name)
                } label: { Label(name, systemImage: "doc.text") }
            }
        }.navigationTitle("Files").searchable(text: $search)
    }
}

private struct LabBrowserView: View {
    let wifi: Bool
    @State private var search = ""
    @State private var selected: String?
    @State private var forwardPage: String?
    @AppStorage("lastseen.lab.history") private var history = ""
    @AppStorage("lastseen.lab.bookmarks") private var bookmarks = ""
    @AppStorage("lastseen.lab.browserSeeded") private var seeded = false
    private let pages = ["Maple Street Bookshop": "Open 10–6. Reserved books are held for seven days.", "Ash Street Residents": "Building office notices, elevator inspections and community events.", "Maple Cafe": "Coffee, pastries and sandwiches. Across from the bookshop."]
    private let addresses = ["Maple Street Bookshop": "maplebooks.test", "Ash Street Residents": "ashstreet.test", "Maple Cafe": "maplecafe.test"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search or enter address", text: $search)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.go)
                    .onSubmit { if let name = matching.first { visit(name) } }
                if !search.isEmpty {
                    Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
                }
            }.padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal).padding(.vertical, 8)
            if let name = selected {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Image(systemName: name == "Maple Cafe" ? "cup.and.saucer.fill" : name == "Maple Street Bookshop" ? "books.vertical.fill" : "building.2.fill")
                                .font(.largeTitle)
                            Spacer()
                            Text("LOCAL").font(.caption2.weight(.semibold))
                        }.foregroundColor(.white)
                        Text(name).font(.largeTitle.bold()).foregroundColor(.white)
                        Divider()
                        Text(pages[name] ?? "").font(.title3)
                        if name == "Maple Street Bookshop" {
                            Text("Your reserved books").font(.headline)
                            Text("Pick up in store before the end of the week.")
                        } else if name == "Ash Street Residents" {
                            Text("Resident noticeboard").font(.headline)
                            Text("Please contact the building office for maintenance updates.")
                        } else {
                            Text("Today's menu").font(.headline)
                            Text("Espresso · Cappuccino · Pastries · Sandwiches")
                        }
                        Label("Saved page · available offline", systemImage: "checkmark.circle").font(.caption).foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
                    .background(Color.teal.opacity(0.15), in: RoundedRectangle(cornerRadius: 24)).padding()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(search.isEmpty ? "Start page" : "Search results").font(.title2.bold())
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(matching, id: \.self) { name in
                                Button { visit(name) } label: {
                                    VStack(alignment: .leading, spacing: 7) {
                                        Image(systemName: "globe").font(.title).foregroundColor(.teal)
                                        Text(name).font(.subheadline.bold())
                                        Text(addresses[name] ?? "").font(.caption2).foregroundColor(.secondary)
                                    }.frame(maxWidth: .infinity, alignment: .leading).padding(13)
                                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                }.buttonStyle(.plain)
                            }
                        }
                        if matching.isEmpty { Text("No saved sites match this search.").foregroundColor(.secondary) }
                        if search.isEmpty {
                            siteSection("Bookmarks", names: entries(bookmarks))
                            siteSection("History", names: entries(history).reversed())
                            if !history.isEmpty { Button("Clear history", role: .destructive) { history = "" }.font(.caption) }
                        }
                    }.padding()
                }
            }
            Divider()
            HStack {
                Button { forwardPage = selected; selected = nil; search = "" } label: { Image(systemName: "chevron.backward") }.disabled(selected == nil)
                Spacer()
                Button { if let name = forwardPage { visit(name) } } label: { Image(systemName: "chevron.forward") }.disabled(forwardPage == nil || selected != nil)
                Spacer()
                Button { selected = nil; search = ""; forwardPage = nil } label: { Image(systemName: "house") }
                Spacer()
                Button { if let name = selected { toggleBookmark(name) } } label: {
                    Image(systemName: selected.map { entries(bookmarks).contains($0) } == true ? "bookmark.fill" : "bookmark")
                }.disabled(selected == nil)
            }.font(.title3).padding(.horizontal, 25).padding(.vertical, 14)
            Text(wifi ? "Saved sites • Wi-Fi enabled in game" : "Saved sites • Wi-Fi disabled in game").font(.caption2).foregroundColor(.secondary).padding(.bottom, 4)
        }
        .navigationTitle("Browser").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !seeded {
                if history.isEmpty { history = "Maple Cafe|Maple Street Bookshop" }
                if bookmarks.isEmpty { bookmarks = "Maple Street Bookshop" }
                seeded = true
            }
        }
    }
    private var matching: [String] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return pages.keys.sorted().filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) || (addresses[$0]?.localizedCaseInsensitiveContains(query) ?? false) }
    }
    private func entries(_ value: String) -> [String] {
        value.split(separator: "|").map(String.init).filter { pages[$0] != nil }
    }
    private func siteSection<S: Sequence>(_ title: String, names: S) -> some View where S.Element == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(Array(names), id: \.self) { name in
                Button { visit(name) } label: {
                    HStack {
                        Image(systemName: title == "History" ? "clock" : "bookmark").foregroundColor(.teal)
                        Text(name)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    }.padding(10)
                }.buttonStyle(.plain)
            }
        }
    }
    private func visit(_ name: String) {
        guard pages[name] != nil else { return }
        selected = name
        search = addresses[name] ?? ""
        forwardPage = nil
        history = (entries(history).filter { $0 != name } + [name]).joined(separator: "|")
    }
    private func toggleBookmark(_ name: String) {
        var values = entries(bookmarks)
        if values.contains(name) { values.removeAll { $0 == name } } else { values.append(name) }
        bookmarks = values.joined(separator: "|")
    }
}
