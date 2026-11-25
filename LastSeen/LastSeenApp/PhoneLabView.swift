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
    @State private var pendingThread: Neighbor?
    @State private var banner: PhoneAlert?
    @State private var observedIncoming: Set<String> = []
    @State private var searchQuery = ""
    @AppStorage("lastseen.lab.hideLockPreviews") private var hideLockPreviews = false
    private var alerts: [PhoneAlert] { PhoneAlertCatalog.alerts(in: world.state, unreadOnly: true) }
    private var incomingIDs: [String] {
        Neighbor.allCases.flatMap { world.messages($0).filter { !$0.fromPlayer }.map(\.id) }
    }
    @AppStorage("lastseen.lab.wallpaper") private var wallpaper = 0
    @AppStorage("lastseen.relay.compactIcons") private var compactIcons = false
    @AppStorage("lastseen.relay.tealTheme") private var tealTheme = false
    @AppStorage("lastseen.relay.installed") private var relayInstalled = ""
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    private func tweak(_ id: String) -> Bool { !safeMode && RelayCatalog.ids(relayInstalled).contains(id) }
    private var smallIcons: Bool { (!safeMode && compactIcons) || tweak("fivegrid") }
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
    @AppStorage("lastseen.lab.deferSystemEdges") private var deferSystemEdges = true

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                backdrop
                if locked { lockScreen } else { launcher }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LabApp.self) { app in
                destination(app)
                    .safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button { path = NavigationPath() } label: {
                                Image(systemName: "house").accessibilityLabel("Return to phone home")
                            }
                        }
                    }
            }
            .navigationDestination(for: PhoneCalendarRoute.self) { route in
                PhoneCalendarView(initialDay: route.day).safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
            }
            .navigationDestination(for: PhoneFileRoute.self) { route in
                PhoneDocumentView(title: route.title).safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
            }
            .navigationDestination(for: AppPage.self) { page in
                Group {
                    switch page {
                    case .worldThread(let neighbor): NeighborConversationView(neighbor: neighbor)
                    case .worldProfile(let neighbor): NeighborProfileView(neighbor: neighbor)
                    case .note(let id): PhoneNoteEditorView(noteID: id)
                    default: Text("Not available in Phone Lab")
                    }
                }.safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
            }
        }
        .environmentObject(world)
        .defersSystemGestures(on: deferSystemEdges ? [.top, .bottom] : [])
        .tint(Color(red: 0.36, green: 0.81, blue: 0.76))
        .preferredColorScheme(.dark)
        .overlay {
            Color.black.opacity(max(0, 1 - brightness) * 0.75)
                .ignoresSafeArea().allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            if let alert = banner, !locked, panel == nil {
                PhoneNotificationCard(alert: alert) {
                    banner = nil; openThread(alert.neighbor)
                }.padding(.horizontal, 14).padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task(id: banner?.id) {
            guard let id = banner?.id else { return }
            do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
            if banner?.id == id { withAnimation { banner = nil } }
        }
        .onChange(of: incomingIDs) { ids in
            let added = Set(ids).subtracting(observedIncoming)
            observedIncoming = Set(ids)
            if let newest = PhoneAlertCatalog.alerts(in: world.state, unreadOnly: true).first(where: { added.contains($0.id) }), !locked {
                withAnimation(.easeOut(duration: 0.25)) { banner = newest }
            }
        }
        .sheet(item: $panel) { item in
            NavigationStack {
                Group {
                    switch item {
                    case .controls: quickControls
                    case .search: phoneSearch
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
                    ownerVerified = true; showOwnerPasscode = false; completeUnlock()
                }, onCancel: { showOwnerPasscode = false; pendingThread = nil })
            }.preferredColorScheme(.dark).presentationDetents([.large])
        }
        .onAppear {
            observedIncoming = Set(incomingIDs)
            let firstTutorial = !world.tutorialStarted
            world.startPhoneTutorial()
            observedIncoming = Set(incomingIDs)
            if firstTutorial && !locked { banner = alerts.first }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [NotificationRouter.storyNotificationID])
            center.removeDeliveredNotifications(withIdentifiers: [NotificationRouter.storyNotificationID])
        }
    }

    private var backdrop: some View { PhoneWallpaper(selection: safeMode && wallpaper == 2 ? 0 : wallpaper).ignoresSafeArea() }

    private var unread: Int { Neighbor.allCases.reduce(0) { $0 + world.countUnread($1) } }

    private var lockScreen: some View {
        VStack(spacing: 12) {
            Image(systemName: biometricUnlock ? "faceid" : "lock.fill")
                .font(.title3).padding(.top, 12)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 3) {
                    Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day()).font(.headline)
                    Group {
                        if tweak("seconds") { Text(context.date, format: .dateTime.hour().minute().second()) }
                        else { Text(context.date, style: .time) }
                    }.font(.system(size: 78, weight: .light, design: .rounded))
                        .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                }.frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 30).onEnded { value in
                        if value.translation.height < -40 { pendingThread = nil; requestUnlock() }
                    })
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !alerts.isEmpty {
                        HStack {
                            Text("Notifications").font(.headline)
                            Spacer()
                            Text("\(unread) unread").font(.caption).foregroundColor(.white.opacity(0.72))
                        }.padding(.horizontal, 4)
                        ForEach(alerts) { alert in
                            PhoneNotificationCard(alert: alert, hidePreview: biometricUnlock || hideLockPreviews) {
                                pendingThread = alert.neighbor
                                requestUnlock()
                            }
                        }
                    } else {
                        Label("No new notifications", systemImage: "bell.slash").font(.caption)
                            .foregroundColor(.white.opacity(0.65)).frame(maxWidth: .infinity).padding(.top, 22)
                    }
                }.padding(.vertical, 4)
            }.scrollIndicators(.hidden).frame(maxHeight: .infinity).layoutPriority(1)
            if !authNotice.isEmpty { Text(authNotice).font(.caption).multilineTextAlignment(.center) }
            if biometricUnlock {
                Button("Use owner passcode") { showOwnerPasscode = true }.font(.subheadline).disabled(authContext != nil)
                Button("Explore public apps") { pendingThread = nil; authNotice = ""; locked = false }.font(.caption).disabled(authContext != nil)
            }
            Button {
                pendingThread = nil; requestUnlock()
            } label: {
                VStack(spacing: 7) {
                    Image(systemName: "chevron.up").font(.headline)
                    Text(biometricUnlock ? "Authenticate to unlock" : "Swipe up to open").font(.subheadline.weight(.medium))
                    Capsule().fill(.white.opacity(0.8)).frame(width: 110, height: 5)
                }.frame(maxWidth: .infinity).padding(.vertical, 12).contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(authContext != nil)
                .gesture(DragGesture(minimumDistance: 16).onEnded { value in
                    if value.translation.height < -20 { pendingThread = nil; requestUnlock() }
                })
        }.padding(.horizontal, 18).padding(.vertical, 10).foregroundColor(.white)
    }

    private func completeUnlock() {
        authNotice = ""
        withAnimation(.easeInOut(duration: 0.25)) { locked = false }
        if let neighbor = pendingThread { pendingThread = nil; openThread(neighbor) }
    }

    private func openThread(_ neighbor: Neighbor) {
        panel = nil
        banner = nil
        open(.messages)
        path.append(AppPage.worldThread(neighbor))
    }

    private func requestUnlock() {
        guard locked, authContext == nil else { return }
        authNotice = ""
        guard biometricUnlock else {
            completeUnlock()
            return
        }
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = ""
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            pendingThread = nil
            authNotice = "Biometrics unavailable. Use the fictional owner passcode or open public apps."
            return
        }
        authContext = context
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your fictional Last Seen phone.") { success, _ in
            DispatchQueue.main.async {
                guard authContext === context else { return }
                authContext = nil
                if success {
                    completeUnlock()
                } else {
                    pendingThread = nil
                    authNotice = "Unlock cancelled or unsuccessful. Use the fictional owner passcode or open public apps."
                }
            }
        }
    }

    // Deliberately inside the app safe area. Real iOS edge gestures remain available.
    private var gameHomeHandle: some View {
        Button {
            returnHome()
        } label: {
            VStack(spacing: 5) {
                Capsule().fill(Color.white.opacity(0.65)).frame(width: 100, height: 5)
                Text("Home · swipe up").font(.system(size: 10)).foregroundColor(.secondary)
            }.frame(maxWidth: .infinity).frame(height: 42).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .background(.ultraThinMaterial)
            .accessibilityLabel("Return to in-game home")
            .gesture(DragGesture(minimumDistance: 16).onEnded { value in
                if value.translation.height < -20 { returnHome() }
                else if abs(value.translation.width) > 50 && abs(value.translation.height) < 35 {
                    returnHome(); panel = .recent
                    OpeningQA.record("In-game recent apps gesture")
                }
            })
    }

    private func returnHome() {
        withAnimation(.easeInOut(duration: 0.22)) { path = NavigationPath() }
        OpeningQA.record("Returned to in-game home")
    }

    private func pullDown(_ target: LabPanel) -> some Gesture {
        DragGesture(minimumDistance: 15).onEnded { value in
            if value.translation.height > 28 && abs(value.translation.width) < value.translation.height {
                panel = target
                OpeningQA.record(target == .controls ? "In-game quick settings gesture" : "In-game notifications gesture")
            }
        }
    }

    private var launcher: some View {
        VStack(spacing: 16) {
            if safeMode {
                Button { open(.relay) } label: { Label("Safe Mode • open Relay to exit", systemImage: "exclamationmark.shield").font(.caption).foregroundColor(.orange) }
            }
            HStack {
                Button { panel = .notifications } label: {
                    Label("Notifications", systemImage: "bell")
                        .labelStyle(.iconOnly).font(.title3).frame(width: 64, height: 44).contentShape(Rectangle())
                }.simultaneousGesture(pullDown(.notifications))
                Spacer()
                Button { panel = .controls } label: {
                    Image(systemName: wifi ? "slider.horizontal.3" : "wifi.slash")
                        .font(.title3).frame(width: 64, height: 44).contentShape(Rectangle()).accessibilityLabel("Quick settings")
                }.simultaneousGesture(pullDown(.controls))
            }.padding(.horizontal, 7)
            ScrollView {
                VStack(spacing: 16) {
                    Button {
                        searchQuery = ""; panel = .search
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                            Text("Search phone").font(.subheadline)
                            Spacer()
                        }.foregroundColor(.white.opacity(0.85)).padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: tweak("fivegrid") ? 5 : 4), spacing: 24) {
                    ForEach(LabApp.allCases.filter { !$0.inDock }) { app in icon(app) }
                    }.padding(.top, 5).padding(.bottom, 12)
                }
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
            }.padding(12).background {
                if !tweak("dockglass") { RoundedRectangle(cornerRadius: 27).fill(.ultraThinMaterial) }
            }
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
                    if app == .patchline || app == .relay {
                        OpeningArt(name: app == .patchline ? "Opening_Unlock" : "Opening_Install", size: smallIcons ? 43 : 55)
                    } else if !safeMode, tealTheme, let asset = ApprovedArt.themeName(for: app.rawValue) {
                        Image(asset).resizable().scaledToFit()
                            .frame(width: smallIcons ? 43 : 55, height: smallIcons ? 43 : 55)
                    } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [app.color, app.color.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: smallIcons ? 43 : 55, height: smallIcons ? 43 : 55)
                        .overlay { Image(systemName: app.symbol).font(.system(size: 24, weight: .medium)) }
                    }
                    if app == .messages && unread > 0 && !tweak("quietbadges") {
                        Text("\(unread)").font(.caption2.bold()).padding(5)
                            .background(.red, in: Capsule()).offset(x: 5, y: -5)
                    }
                }
                if !tweak("clearlabels") {
                    Text(app.rawValue).font(.system(size: 11, weight: .medium))
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain).accessibilityLabel(app.rawValue)
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
            Section("Jailbreak") {
                LabeledContent("Environment", value: safeMode ? "Safe Mode" : "Rootless")
                LabeledContent("Installed tweaks", value: String(RelayCatalog.ids(relayInstalled).count))
                NavigationLink { RelayPackagesView(onRestart: { panel = nil; returnHome(); locked = true }) } label: { Label("Manage packages in Relay", systemImage: "shippingbox.fill") }
            }
            Section("Gestures") {
                Toggle("Immersive screen-edge gestures", isOn: $deferSystemEdges)
                Text("Use the in-game gestures first. Repeat a system-edge swipe to access real iOS controls. Turn this off for standard iOS gesture priority.").font(.footnote).foregroundColor(.secondary)
            }
            Section("Notifications and privacy") {
                Toggle("Hide lock-screen message previews", isOn: $hideLockPreviews)
                LabeledContent("Native game alerts", value: nativeAlerts ? "Enabled in game" : "Off")
                Button("Review optional permissions") { panel = nil; permissionsReviewed = false }
                if nativeAlerts {
                    Button("Schedule test notification (7 seconds)") { scheduleTestAlert() }
                    if !testNotice.isEmpty { Text(testNotice).font(.caption).foregroundColor(.secondary) }
                }
                Text("Last Seen never reads your real contacts, messages or photos. Device controls affect only the game.").font(.footnote).foregroundColor(.secondary)
            }
            Section("About") {
                LabeledContent("Software", value: "1.3.8 (21)")
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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notification Center").font(.largeTitle.bold()).padding(.top, 5)
                Text("Recent messages").font(.subheadline).foregroundColor(.secondary)
                ForEach(PhoneAlertCatalog.alerts(in: world.state, unreadOnly: false)) { alert in
                    PhoneNotificationCard(alert: alert) { openThread(alert.neighbor) }
                }
                if PhoneAlertCatalog.alerts(in: world.state, unreadOnly: false).isEmpty {
                    Text("You're all caught up.").foregroundColor(.secondary)
                }
            }.padding(16)
        }.background(Night.background.ignoresSafeArea())
    }

    private var quickControls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text("Control Center").font(.largeTitle.bold())
                HStack(spacing: 12) {
                    Button { wifi.toggle() } label: {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: wifi ? "wifi" : "wifi.slash").font(.title)
                            Text("Wi-Fi").font(.headline)
                            Text(wifi ? "On" : "Off").font(.caption)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                            .background(wifi ? Color.blue.opacity(0.65) : Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain)
                    Button { hideLockPreviews.toggle() } label: {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: hideLockPreviews ? "lock.fill" : "bell.fill").font(.title)
                            Text("Previews").font(.headline)
                            Text(hideLockPreviews ? "Hidden" : "Visible").font(.caption)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label("Brightness", systemImage: "sun.max").font(.headline)
                    Slider(value: $brightness, in: 0.35...1)
                }.padding(17).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                Button { panel = nil; open(.settings) } label: {
                    Label("Open Settings", systemImage: "gearshape.fill").frame(maxWidth: .infinity).padding(12)
                }.buttonStyle(.bordered)
            }.padding(18)
        }.background(Night.background.ignoresSafeArea())
    }

    private var phoneSearch: some View {
        List {
            Section {
                TextField("Search apps, messages, notes and files", text: $searchQuery)
                    .autocorrectionDisabled()
            }
            let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty {
                Text("Search restored phone contents. Protected records are not indexed.").font(.subheadline).foregroundColor(.secondary)
            } else {
                let apps = LabApp.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(q) }
                let results = PhonePublicSearch.results(query: q, world: world.state, documents: PhonePublicFiles.documents)
                if apps.isEmpty && results.isEmpty { Text("No results").foregroundColor(.secondary) }
                if !apps.isEmpty {
                    Section("Applications") {
                        ForEach(apps) { app in
                            Button { panel = nil; open(app) } label: { Label(app.rawValue, systemImage: app.symbol) }
                        }
                    }
                }
                Section("Public records") {
                    ForEach(results) { result in
                        Button { openSearchResult(result) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: result.symbol).foregroundColor(.teal).frame(width: 30)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title).font(.headline)
                                    Text(result.subtitle).font(.caption).foregroundColor(.secondary).lineLimit(2)
                                }
                            }.padding(.vertical, 4)
                        }
                    }
                }
            }
        }.listStyle(.insetGrouped)
    }

    private func openSearchResult(_ result: PhoneSearchResult) {
        guard let app = LabApp(rawValue: result.destination) else { return }
        panel = nil
        open(app)
        if let detail = result.detail {
            switch app {
            case .messages: if let n = Neighbor(rawValue: detail) { path.append(AppPage.worldThread(n)) }
            case .contacts: if let n = Neighbor(rawValue: detail) { path.append(AppPage.worldProfile(n)) }
            case .notes: path.append(AppPage.note(detail))
            case .files: path.append(PhoneFileRoute(title: detail))
            case .calendar: if let event = world.state.events.first(where: { $0.id == detail }) { path.append(PhoneCalendarRoute(day: event.startsAt)) }
            default: break
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
        case .relay: RelayPackagesView(onRestart: { returnHome(); recent.removeAll(); locked = true })
        case .patchline: PatchlineControlView(openRelay: { open(.relay) }, onRestart: { returnHome(); recent.removeAll(); locked = true })
        }
    }
}

private enum LabPanel: String, Identifiable {
    case controls = "Quick settings", notifications = "Notifications", recent = "Recent apps", search = "Search"
    var id: String { rawValue }
}

private enum LabApp: String, CaseIterable, Identifiable {
    case messages = "Messages", contacts = "Contacts", photos = "Photos", notes = "Notes", calendar = "Calendar", mail = "Mail", clock = "Clock", calculator = "Calculator", settings = "Settings", files = "Files", browser = "Browser", relay = "Relay", patchline = "Patchline"
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
        case .patchline: return "lock.open.fill"
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
        case .patchline: return .teal
        }
    }
}

private struct LabPeopleView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    let messages: Bool
    @State private var search = ""
    @State private var unreadOnly = false
    private var people: [Neighbor] {
        let result = Neighbor.allCases.filter { n in
            (!messages || !unreadOnly || world.countUnread(n) > 0) &&
            (search.isEmpty || n.name.localizedCaseInsensitiveContains(search) ||
             (messages && world.messages(n).contains { $0.text.localizedCaseInsensitiveContains(search) }))
        }
        return messages ? result.sorted { (world.messages($0).last?.at ?? .distantPast) > (world.messages($1).last?.at ?? .distantPast) }
            : result.sorted { $0.name < $1.name }
    }
    var body: some View {
        List {
            if messages {
                Section {
                    Picker("Conversations", selection: $unreadOnly) {
                        Text("All messages").tag(false)
                        Text("Unread").tag(true)
                    }.pickerStyle(.segmented)
                }
            } else {
                Section("Owner card") {
                    HStack(spacing: 13) {
                        Image(RestoredPhoneBackup.ownerPortrait).resizable().scaledToFill().frame(width: 58, height: 58).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(RestoredPhoneBackup.ownerName).font(.title3.bold())
                            Text("Restored contact card").font(.caption).foregroundColor(.secondary)
                        }
                    }.padding(.vertical, 7)
                }
            }
            Section(messages ? "Conversations" : "Contacts") {
                if people.isEmpty { Text(messages && unreadOnly ? "No unread messages" : "No matches").foregroundColor(.secondary) }
                ForEach(people) { person in
                    NavigationLink(value: messages ? AppPage.worldThread(person) : AppPage.worldProfile(person)) {
                        HStack(spacing: 12) {
                            NeighborAvatar(neighbor: person, size: 52)
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(person.name).font(.headline)
                                    Spacer(minLength: 3)
                                    if messages, let latest = world.messages(person).last {
                                        Text(latest.at, style: .relative).font(.caption2).foregroundColor(.secondary)
                                    }
                                }
                                HStack {
                                    Text(messages ? (world.messages(person).last?.text ?? "") : person.subtitle)
                                        .font(.subheadline).foregroundColor(.secondary).lineLimit(2)
                                    Spacer(minLength: 3)
                                    if messages && world.countUnread(person) > 0 {
                                        Text("\(world.countUnread(person))").font(.caption.bold())
                                            .padding(6).background(Color.blue, in: Capsule()).foregroundColor(.white)
                                    }
                                }
                            }
                        }.padding(.vertical, 6)
                    }
                }
            }
        }.navigationTitle(messages ? "Messages" : "Contacts")
            .searchable(text: $search, prompt: messages ? "Search conversations" : "Search contacts")
    }
}

private struct LabPhoto: Identifiable {
    let id: String
    let title: String
    let asset: String
    let caption: String
}

private struct LabPhotosView: View {
    @State private var selection: LabPhoto?
    @AppStorage("lastseen.lab.favoritePhotos") private var favorites = ""
    @State private var onlyFavorites = false
    @State private var scale: CGFloat = 1
    private let photos = [
        LabPhoto(id: "owner", title: "Nora", asset: RestoredPhoneBackup.ownerPortrait, caption: "Portrait · saved last week"),
        LabPhoto(id: "maya", title: "Maya", asset: Neighbor.maya.portraitAssetName, caption: "Saved contact photograph"),
        LabPhoto(id: "denise", title: "Denise", asset: Neighbor.denise.portraitAssetName, caption: "Saved contact photograph")
    ]
    private var shown: [LabPhoto] { photos.filter { !onlyFavorites || isFavorite($0.id) } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Library", selection: $onlyFavorites) {
                    Text("Library").tag(false)
                    Text("Favorites").tag(true)
                }.pickerStyle(.segmented)
                HStack {
                    Text(onlyFavorites ? "Favorites" : "Camera roll").font(.title2.bold())
                    Spacer()
                    Text("\(shown.count) photos").font(.caption).foregroundColor(.secondary)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                    ForEach(shown) { photo in
                        Button {
                            scale = 1; selection = photo
                        } label: {
                            GeometryReader { geo in
                                Image(photo.asset).resizable().scaledToFill()
                                    .frame(width: geo.size.width, height: geo.size.height).clipped()
                                    .overlay(alignment: .bottomTrailing) {
                                        if isFavorite(photo.id) { Image(systemName: "heart.fill").font(.caption).padding(6).foregroundColor(.white).shadow(radius: 3) }
                                    }
                            }.aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }.buttonStyle(.plain).accessibilityLabel(photo.title)
                    }
                }
                if shown.isEmpty { Text("Favorite a photo to see it here.").foregroundColor(.secondary).padding(.vertical, 25) }
                Text("Albums").font(.title2.bold()).padding(.top, 10)
                NavigationLink { ProtectedAreaView(area: .photos) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "lock.rectangle.stack.fill").font(.title2).foregroundColor(.teal)
                            .frame(width: 52, height: 52).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private album").font(.headline)
                            Text("Authentication required").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }.padding(13).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
            }.padding()
        }.navigationTitle("Photos")
        .sheet(item: $selection) { photo in
            NavigationStack {
                VStack(spacing: 16) {
                    Spacer()
                    Image(photo.asset).resizable().scaledToFit()
                        .scaleEffect(scale).gesture(MagnificationGesture().onChanged { scale = min(3, max(1, $0)) })
                        .clipped().onTapGesture(count: 2) { withAnimation { scale = scale > 1 ? 1 : 2 } }
                    Spacer()
                    Text(photo.caption).font(.caption).foregroundColor(.secondary)
                    Button { toggle(photo.id) } label: {
                        Label(isFavorite(photo.id) ? "Remove favorite" : "Favorite", systemImage: isFavorite(photo.id) ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.bordered)
                }.padding().navigationTitle(photo.title).navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { selection = nil } } }
            }.preferredColorScheme(.dark)
        }
    }
    private func isFavorite(_ id: String) -> Bool { favorites.split(separator: "|").contains(Substring(id)) }
    private func toggle(_ id: String) {
        var ids = RelayCatalog.ids(favorites)
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        favorites = RelayCatalog.encoded(ids)
    }
}

private struct LabClockView: View {
    @State private var tab = 0
    @AppStorage("lastseen.lab.stopwatchStart") private var started = 0.0
    @AppStorage("lastseen.lab.stopwatchElapsed") private var elapsed = 0.0
    @AppStorage("lastseen.lab.timerEnd") private var timerEnd = 0.0
    @AppStorage("lastseen.lab.timerMinutes") private var minutes = 5
    var body: some View {
        VStack(spacing: 18) {
            Picker("Clock mode", selection: $tab) {
                Text("Clock").tag(0)
                Text("Stopwatch").tag(1)
                Text("Timer").tag(2)
            }.pickerStyle(.segmented)
            TimelineView(.periodic(from: .now, by: tab == 1 ? 0.1 : 1)) { context in
                let timestamp = context.date.timeIntervalSince1970
                VStack(spacing: 22) {
                    Spacer()
                    if tab == 0 {
                        Image(systemName: "clock").font(.system(size: 62, weight: .thin)).foregroundColor(.teal)
                        Text(context.date, style: .time).font(.system(size: 60, weight: .thin)).monospacedDigit()
                        Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                    } else if tab == 1 {
                        Text(String(format: "%.1f", elapsed + (started > 0 ? max(0, timestamp - started) : 0)))
                            .font(.system(size: 56, weight: .thin)).monospacedDigit()
                        Text("Seconds").font(.caption).foregroundColor(.secondary)
                        HStack {
                            Button("Reset") { started = 0; elapsed = 0 }.buttonStyle(.bordered)
                            Spacer()
                            Button(started > 0 ? "Stop" : "Start") {
                                let now = Date().timeIntervalSince1970
                                if started > 0 { elapsed += max(0, now - started); started = 0 }
                                else { started = now }
                            }.buttonStyle(.borderedProminent)
                        }
                    } else {
                        let remaining = timerEnd > 0 ? max(0, Int(ceil(timerEnd - timestamp))) : minutes * 60
                        ZStack {
                            Circle().stroke(.white.opacity(0.12), lineWidth: 7)
                            Circle().trim(from: 0, to: min(1, Double(remaining) / Double(max(1, minutes * 60))))
                                .stroke(Color.teal, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
                            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                                .font(.system(size: 47, weight: .light)).monospacedDigit()
                        }.frame(width: 210, height: 210)
                        if timerEnd == 0 {
                            Stepper("\(minutes) minutes", value: $minutes, in: 1...60)
                            Button("Start timer") { timerEnd = Date().timeIntervalSince1970 + Double(minutes * 60) }.buttonStyle(.borderedProminent)
                        } else {
                            if remaining == 0 { Text("Timer finished").font(.headline).foregroundColor(.teal) }
                            Button(remaining == 0 ? "Done" : "Cancel timer") { timerEnd = 0 }.buttonStyle(.bordered)
                        }
                        Text("In-phone timer • No real alarm is scheduled").font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.padding(20).navigationTitle("Clock")
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
                        Text(key).font(.system(size: 27, weight: .medium)).frame(maxWidth: .infinity).frame(height: 65)
                            .background(["÷","×","−","+","="].contains(key) ? Color.orange : Color.gray.opacity(0.24), in: Capsule())
                    }.buttonStyle(.plain)
                }
            }
        }.padding().background(Color.black.ignoresSafeArea()).navigationTitle("Calculator")
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

private struct PhoneCalendarRoute: Hashable { let day: Date }

private struct PhoneFileRoute: Hashable { let title: String }

private struct LabFilesView: View {
    let documents = PhonePublicFiles.documents
    @State private var search = ""
    var body: some View {
        List {
            NavigationLink { ProtectedAreaView(area: .files) } label: { Label("Protected files", systemImage: "lock.doc") }
            ForEach(documents.keys.sorted().filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) }, id: \.self) { name in
                NavigationLink(value: PhoneFileRoute(title: name)) {
                    HStack(spacing: 13) {
                        Image(systemName: "doc.text.fill").font(.title2).foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name).font(.headline)
                            Text("Restored document • On this phone").font(.caption).foregroundColor(.secondary)
                        }
                    }.padding(.vertical, 6)
                }
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
            Text(wifi ? "Saved pages • Offline browser" : "Saved pages • Wi-Fi off").font(.caption2).foregroundColor(.secondary).padding(.bottom, 4)
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
