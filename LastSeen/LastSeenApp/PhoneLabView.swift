import SwiftUI
import UserNotifications
import LocalAuthentication

/// Neutral, offline phone prototype. No GameStore or story routing is constructed here.
struct PhoneLabView: View {
    @StateObject private var world: PhoneWorldStore
    @State private var path = NavigationPath()
    @StateObject private var saves: LumaSaveStore
    @AppStorage("lastseen.saves.interval") private var saveInterval = 5
    @State private var checkpointReboot = false
    @State private var circuitBanner = false
    @State private var utilityNotice: LumaUtility?
    @State private var observedUtilityFlags: Set<String> = []
    @AppStorage("lastseen.utility.small") private var utilitySmall = false
    @AppStorage("lastseen.utility.five") private var utilityFive = false
    @AppStorage("lastseen.utility.labels") private var utilityLabels = true
    @AppStorage("lastseen.utility.glass") private var utilityGlass = true
    @AppStorage("lastseen.utility.theme") private var utilityTheme = false
    @AppStorage("lastseen.utility.shortcuts") private var utilityShortcuts = true
    @State private var navigationGeneration = UUID()
    @AppStorage("lastseen.lab.lockWallpaper") private var lockWallpaper = -1
    @AppStorage("lastseen.lab.wallpaperBlur") private var wallpaperBlur = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var locked: Bool
    init(startUnlocked: Bool = false, uiFixture: Bool = false) {
        _locked = State(initialValue: !startUnlocked)
        #if DEBUG && targetEnvironment(simulator)
        if uiFixture {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("LumaUISmoke-" + UUID().uuidString)
            _world = StateObject(wrappedValue: PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(), persistToDisk: false))
            _saves = StateObject(wrappedValue: LumaSaveStore(root: root, defaults: UserDefaults(suiteName: "LumaUISmoke-" + UUID().uuidString) ?? .standard))
            return
        }
        #endif
        _world = StateObject(wrappedValue: PhoneWorldStore(storageURL: RestoredPhoneBackup.url))
        _saves = StateObject(wrappedValue: LumaSaveStore())
    }
    @State private var panel: LabPanel?
    @State private var homePage = 0
    @State private var homeFolder: LumaHomeFolder?
    @State private var recent: [LabApp] = []
    @State private var pendingThread: Neighbor?
    @State private var banner: PhoneAlert?
    @State private var observedIncoming: Set<String> = []
    @State private var observedOutgoing: Set<String> = []
    @State private var arrivalTask: Task<Void, Never>?
    private var outgoingIDs: Set<String> { PhoneMessageArrival.outgoingIDs(in: world.state) }
    private var messageIDs: Set<String> { Set(incomingIDs).union(outgoingIDs) }
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.lab.messageSound") private var messageSound = true
    @AppStorage("lastseen.lab.messageHaptics") private var messageHaptics = true
    @AppStorage("lastseen.lab.horrorEffects") private var horrorEffects = true
    @AppStorage("lastseen.lab.feedbackRevision") private var feedbackRevision = 0
    @State private var didConfigureFeedback = false
    @AppStorage("lastseen.lab.timerEnd") private var feedbackTimerEnd = 0.0
    @AppStorage("lastseen.lab.timerFeedbackDelivered") private var feedbackTimerDelivered = 0.0
    @State private var timerBaselineReady = false
    @State private var tutorialReplay = 0
    @State private var confirmTutorialReplay = false
    private var tutorialDeliveryID: String { "\(didConfigureFeedback)-\(phase == .active)-\(tutorialReplay)-\(checkpointReboot)" }
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
    private var fieldNotesAvailable: Bool { RecoveryCircuit.unlocked(world.state.flags) && tweak("fieldnotes") }
    private func utilityActive(_ tool: LumaUtility) -> Bool { tweak(tool.rawValue) && RelayCatalog.available(tool.rawValue, flags: world.state.flags) }
    private var fiveColumns: Bool { tweak("fivegrid") || (utilityActive(.lumaplus) && utilityFive) }
    private var smallIcons: Bool { (!safeMode && compactIcons) || fiveColumns || (utilityActive(.lumaplus) && utilitySmall) }
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
            .navigationDestination(for: WorldDocumentRoute.self) { route in
                WorldDocumentReader(id:route.id).safeAreaInset(edge:.bottom,spacing:0) { gameHomeHandle }
            }
            .navigationDestination(for: PhoneFileRoute.self) { route in
                PhoneDocumentView(title: route.title).safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
            }
            .navigationDestination(for: LumaCallRoute.self) { route in
                LumaCallView(neighbor: route.neighbor)
                    .safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
            }
            .navigationDestination(for: AppPage.self) { page in
                Group {
                    switch page {
                    case .worldThread(let neighbor): NeighborConversationView(neighbor: neighbor, reactive: true)
                    case .worldProfile(let neighbor): NeighborProfileView(neighbor: neighbor, phoneLab: true)
                    case .note(let id): PhoneNoteEditorView(noteID: id)
                    default: Text("Not available in Phone Lab")
                    }
                }.safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
            }
        }
        .id(navigationGeneration)
        .environmentObject(world)
        .defersSystemGestures(on: deferSystemEdges ? [.top, .bottom] : [])
        .tint(LumaDesign.accent)
        .preferredColorScheme(.dark)
        .overlay {
            Color.black.opacity(max(0, 1 - brightness) * 0.75)
                .ignoresSafeArea().allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            if let alert = banner, !locked, panel == nil, world.visibleThread != alert.neighbor {
                PhoneNotificationCard(alert: alert) {
                    banner = nil; openThread(alert.neighbor)
                }.padding(.horizontal, 14).padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            if circuitBanner && !locked && !checkpointReboot && panel == nil {
                Button { circuitBanner = false; open(.relay) } label: { CircuitNoticeCard() }
                    .buttonStyle(.plain).padding(.horizontal, 14).padding(.top, 4)
            }
        }
        .overlay(alignment: .top) {
            if let tool = utilityNotice, !locked && !checkpointReboot && panel == nil {
                Button { utilityNotice = nil; open(.relay) } label: { UtilityNoticeCard(tool: tool) }.buttonStyle(.plain).padding(.horizontal, 14).padding(.top, 4)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if utilityActive(.clipglass), !locked && !checkpointReboot && panel == nil,
               let id = world.state.pinnedSnippet,
               let snippet = LumaRecords.visibleSaved(world.state).first(where: { $0.id == id }) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text("ClipGlass").font(.caption.bold()); Spacer(); Button { world.pinSnippet(nil) } label: { Image(systemName: "xmark.circle.fill").accessibilityLabel("Close pinned clip") } }
                    Text(snippet.title).font(.caption.weight(.semibold))
                    Text(snippet.text).font(.caption).lineLimit(3)
                }.padding(12).frame(maxWidth: 210).lumaSurface(radius: 16).padding(.trailing, 12).padding(.bottom, 58)
            }
        }
        .onChange(of: world.state.flags) { flags in
            if checkpointReboot { utilityNotice = nil; return }
            let old = utilityNotice
            if let tool = LumaUtility.allCases.last(where: { flags.contains($0.flag) && !observedUtilityFlags.contains($0.flag) }) { utilityNotice = tool }
            observedUtilityFlags = flags
            if let old, !flags.contains(old.flag) { utilityNotice = nil }
        }
        .onAppear {
            observedUtilityFlags = world.state.flags
            if !timerBaselineReady {
                timerBaselineReady = true
                if feedbackTimerEnd > 0 && feedbackTimerEnd <= Date().timeIntervalSince1970 { feedbackTimerDelivered = feedbackTimerEnd }
            }
        }
        .task(id: utilityNotice) {
            guard let tool = utilityNotice else { return }
            do { try await Task.sleep(nanoseconds: 6_000_000_000) } catch { return }
            if utilityNotice == tool { utilityNotice = nil }
        }
        .onChange(of: RecoveryCircuit.unlocked(world.state.flags)) { earned in
            if earned && !checkpointReboot { circuitBanner = true }
            else { circuitBanner = false }
            if earned && !checkpointReboot && didConfigureFeedback && phase == .active { PhoneSensoryEngine.play(.general, sound: messageSound, haptics: messageHaptics, horrorEnabled: horrorEffects) }
        }
        .task(id: circuitBanner) {
            guard circuitBanner else { return }
            do { try await Task.sleep(nanoseconds: 6_000_000_000) } catch { return }
            circuitBanner = false
        }
        .task(id: banner?.id) {
            guard let id = banner?.id else { return }
            do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
            if banner?.id == id { withAnimation { banner = nil } }
        }
        .onChange(of: messageIDs) { _ in
            let previous = observedIncoming
            let sent = !outgoingIDs.subtracting(observedOutgoing).isEmpty
            observedIncoming = Set(incomingIDs)
            observedOutgoing = outgoingIDs
            guard didConfigureFeedback, phase == .active, !checkpointReboot else { return }
            let newest = PhoneMessageArrival.newest(in: world.state, previous: previous)
            guard sent || newest != nil else { return }
            arrivalTask?.cancel(); arrivalTask = nil
            // Commit incoming feedback immediately. The audio engine sequences
            // sounds; an outgoing tick must not suppress an arrival vibration.
            if sent {
                PhoneSensoryEngine.play(.outgoing, sound: messageSound, haptics: messageHaptics && newest == nil, horrorEnabled: horrorEffects)
            }
            if let newest {
                PhoneSensoryEngine.play(.message, sound: messageSound, haptics: messageHaptics, horrorEnabled: horrorEffects)
                if PhoneConversationPresentation.shouldShowBanner(for: newest.neighbor, visible: world.visibleThread, locked: locked, covered: panel != nil || showOwnerPasscode) {
                    withAnimation(.easeOut(duration: 0.25)) { banner = newest }
                } else if !locked && panel == nil && world.visibleThread == newest.neighbor {
                    world.markRead(newest.neighbor)
                    banner = nil
                }
            }
        }
        .onChange(of: world.visibleThread) { visible in
            if banner?.neighbor == visible { banner = nil }
        }
        .task(id: phase) {
            guard phase == .active else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
                guard !Task.isCancelled else { return }
                if !checkpointReboot { saves.tick(world: world.state, minutes: saveInterval) }
            }
        }
        .task(id: phase) {
            guard phase == .active else { return }
            while !Task.isCancelled {
                if !checkpointReboot {
                    let before = PhoneMailArrival.inboxIDs(in: world.state)
                    world.advancePendingReplies()
                    if didConfigureFeedback && !PhoneMailArrival.added(in: world.state, previous: before).isEmpty {
                        PhoneSensoryEngine.play(.general, sound: messageSound, haptics: messageHaptics, horrorEnabled: horrorEffects, hapticProfile: .mail)
                    }
                    if timerBaselineReady && feedbackTimerEnd > 0 && feedbackTimerEnd != feedbackTimerDelivered && feedbackTimerEnd <= Date().timeIntervalSince1970 {
                        feedbackTimerDelivered = feedbackTimerEnd
                        PhoneSensoryEngine.play(.timerCompleted, sound: messageSound, haptics: messageHaptics, horrorEnabled: horrorEffects)
                    }
                }
                do { try await Task.sleep(nanoseconds: 250_000_000) } catch { return }
            }
        }
        .onChange(of: locked) { value in
            guard value else { return }
            PhoneSensoryEngine.cancelAuthentication()
            guard didConfigureFeedback, phase == .active, !checkpointReboot else { return }
            PhoneSensoryEngine.play(.lock, sound: messageSound, haptics: messageHaptics, horrorEnabled: horrorEffects)
        }
        .onChange(of: phase) { value in
            observedIncoming = Set(incomingIDs)
            observedOutgoing = outgoingIDs
            if value != .active { saves.persistPlayTime() }
            if value != .active {
                arrivalTask?.cancel(); arrivalTask = nil
                if value == .background { PhoneSensoryEngine.stop() }
                else { PhoneSensoryEngine.stopSound(); PhoneSensoryEngine.stopHaptics() }
                banner = nil
            }
        }
        .onChange(of: messageSound) { if !$0 { PhoneSensoryEngine.stopSound() } }
        .onChange(of: messageHaptics) { if !$0 { PhoneSensoryEngine.stopHaptics() } }
        .onChange(of: horrorEffects) { if !$0 { PhoneSensoryEngine.stop() } }
        .onDisappear {
            arrivalTask?.cancel(); arrivalTask = nil
            PhoneSensoryEngine.stop()
        }
        .task(id: tutorialDeliveryID) {
            guard didConfigureFeedback, phase == .active, !checkpointReboot, !world.tutorialStarted else { return }
            do { try await Task.sleep(nanoseconds: 1_500_000_000) } catch { return }
            guard !Task.isCancelled, phase == .active, !checkpointReboot, !world.tutorialStarted else { return }
            world.startPhoneTutorial()
        }
        .fullScreenCover(isPresented: $checkpointReboot) {
            RelayUserspaceView {
                observedIncoming = Set(incomingIDs)
                observedOutgoing = outgoingIDs
                checkpointReboot = false
                tutorialReplay += 1
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
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(recent.filter { $0 != .fieldNotes || fieldNotesAvailable }) { app in
                                    Button { panel = nil; open(app) } label: {
                                        VStack(spacing: 18) {
                                            if let art = app.foundationIcon {
                                                Image(art).resizable().scaledToFit().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 18))
                                            } else { Image(systemName: app.symbol).font(.system(size: 44)).frame(height: 72) }
                                            Text(app.rawValue).font(.headline)
                                            Text("Open app").font(.caption).foregroundColor(.secondary)
                                        }.frame(maxWidth: .infinity).padding(18).lumaSurface()
                                    }.buttonStyle(.plain)
                                }
                            }.padding(18)
                            if recent.isEmpty { Text("No recent apps").foregroundColor(.secondary) }
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
            if !didConfigureFeedback {
                if feedbackRevision < 3 {
                    // One-time Build 21 migration so the owner can hear the new incoming alerts.
                    if world.tutorialStarted { world.resetPhoneTutorial() }
                    feedbackRevision = 3
                }
                observedIncoming = Set(incomingIDs)
                observedOutgoing = outgoingIDs
                didConfigureFeedback = true
            }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [NotificationRouter.storyNotificationID])
            center.removeDeliveredNotifications(withIdentifiers: [NotificationRouter.storyNotificationID])
        }
    }

    private var backdrop: some View {
        let chosen = locked && lockWallpaper >= 0 ? lockWallpaper : wallpaper
        return PhoneWallpaper(selection: LumaDesign.resolvedWallpaper(chosen, midnight: tweak("midnight")))
            .blur(radius: !locked && wallpaperBlur ? 18 : 0)
            .overlay(Color.black.opacity(locked ? 0.18 : 0.23))
            .ignoresSafeArea()
    }

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
            }.buttonStyle(.plain).disabled(authContext != nil).accessibilityIdentifier("luma.lock.unlock")
                .gesture(DragGesture(minimumDistance: 16).onEnded { value in
                    if value.translation.height < -20 { pendingThread = nil; requestUnlock() }
                })
        }.padding(.horizontal, 18).padding(.vertical, 10).foregroundColor(.white)
    }

    private func completeUnlock() {
        guard locked else { return }
        authNotice = ""
        PhoneSensoryEngine.authentication(.unlock, sound: messageSound, haptics: messageHaptics)
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
        PhoneSensoryEngine.cancelAuthentication()
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
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your fictional Last Seen phone.") { success, error in
            DispatchQueue.main.async {
                guard authContext === context else { return }
                authContext = nil
                if success {
                    completeUnlock()
                } else {
                    pendingThread = nil
                    if (error as? LAError)?.code == .authenticationFailed {
                        authNotice = "Authentication failed. Use the fictional owner passcode or open public apps."
                        PhoneSensoryEngine.authentication(.authenticationFailed, sound: messageSound, haptics: messageHaptics)
                    } else { authNotice = "Unlock cancelled or unavailable. Use the fictional owner passcode or open public apps." }
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

            }.frame(maxWidth: .infinity).frame(height: 44).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .background(.ultraThinMaterial)
            .accessibilityLabel("Return to in-game home").accessibilityIdentifier("luma.home")
            .gesture(DragGesture(minimumDistance: 16).onEnded { value in
                if value.translation.height < -20 { returnHome() }
                else if abs(value.translation.width) > 50 && abs(value.translation.height) < 35 {
                    returnHome(); panel = .recent
                    OpeningQA.record("In-game recent apps gesture")
                }
            })
    }

    private func returnHome() {
        homeFolder = nil
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { path = NavigationPath() }
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

    // The launcher is a fixed safe-area composition. Only the page grid changes
    // horizontally; the dock and system controls never cover its contents.
    private var launcher: some View {
        GeometryReader { geometry in
            let layout = LumaHomeLayout(width:geometry.size.width,height:geometry.size.height,
                                        fiveColumns:fiveColumns,smallIcons:smallIcons)
            let pages = LumaHomeLayout.pages(columns:layout.columns,rows:layout.rows,fieldNotes:fieldNotesAvailable)
            let selected = min(max(0,homePage),pages.count-1)
            ZStack {
                VStack(spacing:layout.spacing) {
                    homeTopBar.frame(height:44)
                    homeSearch.frame(height:42)
                    if layout.showWidgets { homeWidgets.frame(height:74) }
                    TabView(selection:Binding(get:{min(max(0,homePage),pages.count-1)},set:{homePage=$0})) {
                        ForEach(pages.indices,id:\.self) { index in
                            homeGrid(pages[index],layout:layout).tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode:.never))
                    .frame(height:layout.gridHeight)
                    .clipped()
                    HStack(spacing:0) {
                        ForEach(pages.indices,id:\.self) { index in
                            Button {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration:0.22)) { homePage=index }
                            } label:{
                                Circle().fill(.white.opacity(selected==index ? 0.98 : 0.36))
                                    .frame(width:selected==index ? 8 : 6,height:selected==index ? 8 : 6)
                                    .frame(width:38,height:32).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .accessibilityLabel("Home page \(index+1) of \(pages.count)")
                                .accessibilityIdentifier("luma.home.page.\(index)")
                                .accessibilityAddTraits(selected==index ? .isSelected : [])
                        }
                    }.frame(height:32)
                    homeActions.frame(height:44)
                    HStack(spacing:6) {
                        ForEach(LumaHomeLayout.dock) { app in
                            icon(app,size:layout.dockIconSize)
                                .frame(height:layout.dockHeight-12)
                        }
                    }.padding(.horizontal,9).padding(.vertical,6)
                        .frame(height:layout.dockHeight)
                        .background {
                            if !tweak("dockglass") && (!utilityActive(.lumaplus) || utilityGlass) {
                                RoundedRectangle(cornerRadius:27,style:.continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius:27).strokeBorder(.white.opacity(0.12),lineWidth:1))
                            }
                        }
                }
                .padding(.horizontal,14).padding(.vertical,8)
                .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.top)
                .accessibilityHidden(homeFolder != nil)
                .allowsHitTesting(homeFolder == nil)
                if let folder=homeFolder {
                    Color.black.opacity(0.34).ignoresSafeArea().onTapGesture { closeHomeFolder() }
                        .accessibilityHidden(true)
                    homeFolderView(folder,width:geometry.size.width)
                        .transition(reduceMotion ? .opacity : .scale(scale:0.94).combined(with:.opacity))
                }
            }.onChange(of:pages.count) { count in
                homePage=min(homePage,max(0,count-1))
            }
        }.buttonStyle(.plain).foregroundColor(.white)
    }

    private var homeTopBar: some View {
        HStack(spacing:8) {
            Button { panel = .notifications } label: {
                Image(systemName:"bell").font(.title3).frame(width:44,height:44).contentShape(Rectangle())
            }.accessibilityLabel("Notifications").simultaneousGesture(pullDown(.notifications))
            Spacer(minLength:0)
            if safeMode {
                Button { open(.relay) } label:{
                    Label("Safe Mode",systemImage:"exclamationmark.shield").font(.caption.weight(.medium)).foregroundColor(.orange)
                }.accessibilityLabel("Safe Mode, open Relay to exit")
            } else {
                Text("Nora’s phone").font(.caption.weight(.medium)).foregroundColor(.white.opacity(0.77))
                    .lineLimit(1)
            }
            Spacer(minLength:0)
            Button { panel = .controls } label:{
                Image(systemName:wifi ? "slider.horizontal.3" : "wifi.slash").font(.title3)
                    .frame(width:44,height:44).contentShape(Rectangle())
            }.accessibilityLabel("Quick settings").simultaneousGesture(pullDown(.controls))
        }
    }
    private var homeSearch: some View {
        Button { searchQuery=""; panel = .search } label:{
            HStack(spacing:10) {
                Image(systemName:"magnifyingglass")
                Text("Search phone").font(.subheadline)
                Spacer()
            }.foregroundColor(.white.opacity(0.88)).padding(.horizontal,13)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:16))
        }.accessibilityIdentifier("luma.launcher.search")
    }
    private var homeWidgets: some View {
        HStack(spacing:10) {
            TimelineView(.periodic(from:.now,by:60)) { context in
                VStack(alignment:.leading,spacing:4) {
                    Text(context.date,style:.time).font(.title2.weight(.light)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                    Text(context.date,format:.dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(.caption).lineLimit(1).minimumScaleFactor(0.75)
                }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading)
                    .padding(.horizontal,13)
                    .background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:21))
            }
            Button { open(.calendar) } label:{
                VStack(alignment:.leading,spacing:5) {
                    Label("Calendar",systemImage:"calendar").font(.caption.bold()).foregroundColor(.white.opacity(0.8))
                    Text(world.state.events.filter{$0.endsAt>=Date()}.sorted{$0.startsAt<$1.startsAt}.first?.title ?? "No upcoming events")
                        .font(.subheadline.weight(.medium)).lineLimit(2).minimumScaleFactor(0.8)
                }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading)
                    .padding(.horizontal,13)
                    .background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:21))
            }.accessibilityLabel("Upcoming calendar event, open Calendar")
        }
    }
    private var homeActions: some View {
        HStack(spacing:4) {
            Button { closeHomeFolder(); withAnimation(reduceMotion ? nil : .easeInOut(duration:0.2)) { locked=true } } label:{
                Label("Lock",systemImage:"lock").font(.caption).frame(maxWidth:.infinity,minHeight:44)
            }
            Button { open(.saves) } label:{
                Label("Saves",systemImage:"archivebox").font(.caption).frame(maxWidth:.infinity,minHeight:44)
            }
            Button { panel = .recent } label:{
                Label("Recent apps",systemImage:"square.on.square").font(.caption).lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth:.infinity,minHeight:44)
            }
        }.padding(.horizontal,3)
    }
    private func homeGrid(_ entries:[LumaHomeEntry],layout:LumaHomeLayout)->some View {
        VStack(spacing:0) {
            ForEach(0..<layout.rows,id:\.self) { row in
                HStack(spacing:4) {
                    ForEach(0..<layout.columns,id:\.self) { column in
                        let index=row*layout.columns+column
                        Group {
                            if entries.indices.contains(index) {
                                switch entries[index] {
                                case .app(let app):icon(app,size:layout.iconSize)
                                case .folder(let folder):folderIcon(folder,size:layout.iconSize)
                                }
                            } else { Color.clear.accessibilityHidden(true) }
                        }.frame(maxWidth:.infinity).frame(height:layout.rowHeight)
                    }
                }
            }
            Spacer(minLength:0)
        }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.top)
    }
    private func folderIcon(_ folder:LumaHomeFolder,size:CGFloat)->some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration:0.18)) { homeFolder=folder }
        } label:{
            VStack(spacing:5) {
                ZStack {
                    RoundedRectangle(cornerRadius:size*0.27,style:.continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius:size*0.27).fill(folder.tint.opacity(0.20))
                    RoundedRectangle(cornerRadius:size*0.27).strokeBorder(.white.opacity(0.22),lineWidth:1)
                    VStack(spacing:3) {
                        ForEach(0..<2,id:\.self) { row in
                            HStack(spacing:3) {
                                ForEach(0..<2,id:\.self) { column in
                                    let index=row*2+column
                                    if folder.apps.indices.contains(index) {
                                        appArtwork(folder.apps[index],size:size*0.32)
                                    } else { Color.clear.frame(width:size*0.32,height:size*0.32) }
                                }
                            }
                        }
                    }
                }.frame(width:size,height:size)
                if labelsVisible {
                    Text(folder.rawValue).font(.system(size:11,weight:.medium)).lineLimit(1).minimumScaleFactor(0.72)
                }
            }.frame(maxWidth:.infinity).contentShape(Rectangle())
        }.accessibilityLabel(folder.rawValue+" folder")
            .accessibilityIdentifier("luma.folder."+folder.id)
    }
    private var labelsVisible:Bool { !tweak("clearlabels") && (!utilityActive(.lumaplus) || utilityLabels) }
    private func closeHomeFolder() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration:0.18)) { homeFolder=nil }
    }
    private func homeFolderView(_ folder:LumaHomeFolder,width:CGFloat)->some View {
        VStack(alignment:.leading,spacing:20) {
            HStack {
                VStack(alignment:.leading,spacing:4) {
                    Text(folder.rawValue).font(.title.bold())
                    Text(folder.subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button { closeHomeFolder() } label:{
                    Image(systemName:"xmark.circle.fill").font(.title2).foregroundColor(.secondary)
                        .frame(width:44,height:44).contentShape(Rectangle())
                }.accessibilityLabel("Close folder").accessibilityIdentifier("luma.folder.close")
            }
            HStack(alignment:.top,spacing:8) {
                ForEach(folder.apps) { app in icon(app,size:min(61,max(38,(width-92)/3-10))) }
                if folder.apps.count<3 { Spacer(minLength:0) }
            }.padding(.vertical,8)
        }.padding(20)
            .frame(width:min(340,max(220,width-32)))
            .background(.regularMaterial,in:RoundedRectangle(cornerRadius:30,style:.continuous))
            .overlay(RoundedRectangle(cornerRadius:30).strokeBorder(folder.tint.opacity(0.45),lineWidth:1))
    }

    private func open(_ app: LabApp) {
        guard app != .fieldNotes || fieldNotesAvailable else { return }
        homeFolder = nil
        OpeningQA.record("Opened in-game app: \(app.rawValue)")
        locked = false
        recent.removeAll { $0 == app }
        recent.insert(app, at: 0)
        path = NavigationPath()
        path.append(app)
    }

    @ViewBuilder private func appArtwork(_ app:LabApp,size:CGFloat)->some View {
        Group {
            if app == .patchline || app == .relay {
                Image(app == .patchline ? "Jailbreak_Patchline" : "Jailbreak_Relay").resizable().scaledToFit()
            } else if !safeMode,(tealTheme || (utilityActive(.afterglowstudio) && utilityTheme)),let asset=ApprovedArt.themeName(for:app.rawValue) {
                Image(asset).resizable().scaledToFit()
            } else if let art=app.foundationIcon {
                Image(art).resizable().scaledToFit()
            } else {
                RoundedRectangle(cornerRadius:size*0.26)
                    .fill(LinearGradient(colors:[app.color,app.color.opacity(0.55)],startPoint:.topLeading,endPoint:.bottomTrailing))
                    .overlay { Image(systemName:app.symbol).font(.system(size:size*0.43,weight:.medium)) }
            }
        }.frame(width:size,height:size).clipShape(RoundedRectangle(cornerRadius:size*0.26,style:.continuous))
    }
    private func icon(_ app:LabApp,size:CGFloat)->some View {
        Button { open(app) } label:{
            VStack(spacing:5) {
                ZStack(alignment:.topTrailing) {
                    appArtwork(app,size:size)
                    if app == .messages && unread>0 && !tweak("quietbadges") {
                        Text("\(unread)").font(.caption2.bold()).padding(5)
                            .background(.red,in:Capsule()).offset(x:5,y:-5)
                    }
                }
                if labelsVisible {
                    Text(app.rawValue).font(.system(size:11,weight:.medium)).lineLimit(1).minimumScaleFactor(0.7)
                }
            }.frame(maxWidth:.infinity).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(app.rawValue).accessibilityIdentifier("luma.app."+app.rawValue)
    }

    private var controls: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image("Brand_LumaOS").resizable().scaledToFit().frame(width: 66, height: 66).clipShape(RoundedRectangle(cornerRadius: 17))
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LumaOS").font(.title2.bold())
                        Text(device).font(.subheadline).foregroundColor(.secondary)
                    }
                }.padding(.vertical, 8)
                NavigationLink { InvestigationProgressView(openBrowser: { open(.browser) }, openMessages: { open(.messages) }, openNotes: { open(.notes) }, openFiles: { open(.files) }) } label: { Label("Investigation progress", systemImage: "checklist") }
                NavigationLink { LumaGameplayStatisticsView(store:saves) } label: {
                    Label("Gameplay Statistics",systemImage:"chart.bar.xaxis")
                }
                NavigationLink { LumaSaveView(store: saves, onLoad: loadCheckpoint) } label: {
                    Label("Game Saves", systemImage: "archivebox")
                }
                NavigationLink { LumaWallpaperSettings(home: $wallpaper, lock: $lockWallpaper, blur: $wallpaperBlur, midnight: tweak("midnight")) } label: {
                    Label("Wallpaper & appearance", systemImage: "photo.on.rectangle")
                }
            }
            Section("Display & connectivity") {
                LabeledContent("Device name", value: device)
                Toggle(isOn: $wifi) { Label("Wi-Fi (in-game)", systemImage: "wifi") }
                VStack(alignment: .leading) {
                    Text("Display brightness")
                    Slider(value: $brightness, in: 0.35...1)
                }
            }
            Section("Security & privacy") {
                NavigationLink { ProtectedAreaView(area: .security) } label: {
                    Label("Biometrics & Passcode", systemImage: "lock.shield")
                }
                LabeledContent("Appearance", value: biometricUnlock ? "Registered" : "Locked")
            }
            Section("Jailbreak") {
                LabeledContent("Environment", value: safeMode ? "Safe Mode" : "Rootless")
                LabeledContent("Installed tweaks", value: String(RelayCatalog.ids(relayInstalled).count))
                NavigationLink { RelayPackagesView(earnedFlags: world.state.flags, onRestart: { panel = nil; returnHome(); locked = true }) } label: { Label("Manage packages in Relay", systemImage: "shippingbox.fill") }
            }
            Section("Gestures") {
                Toggle("Immersive screen-edge gestures", isOn: $deferSystemEdges)
                Text("Use the in-game gestures first. Repeat a system-edge swipe to access actual device controls. Turn this off for standard device gesture priority.").font(.footnote).foregroundColor(.secondary)
            }
            Section("Sounds & Haptics") {
                Toggle(isOn: $messageSound) { Label("Phone sounds", systemImage: "speaker.wave.2") }
                Toggle(isOn: $messageHaptics) { Label("Phone vibrations", systemImage: "waveform.path") }
                Toggle("Horror sensory effects", isOn: $horrorEffects)
                NavigationLink {
                    PhoneSoundStudio(sound: $messageSound, haptics: $messageHaptics, horrorEnabled: $horrorEffects)
                } label: { Label("Sound Library · 15 effects", systemImage: "waveform") }
                Button {
                    PhoneSensoryEngine.play(.message, sound: messageSound, haptics: messageHaptics, horrorEnabled: horrorEffects)
                } label: { Label("Preview message alert", systemImage: "bell.badge") }
                Button {
                    PhoneSensoryEngine.play(.general, sound: messageSound, haptics: messageHaptics, horrorEnabled: false, hapticProfile: .mail)
                } label: { Label("Preview mail alert", systemImage: "envelope.badge") }
                Button {
                    PhoneSensoryEngine.play(.message, sound: false, haptics: messageHaptics, horrorEnabled: false)
                } label: { Label("Test vibration only", systemImage: "waveform.path") }
                .disabled(!messageHaptics)
                Text("In-game effects only. Each recording plays once. Sounds respect your device's silent mode and volume. Haptics depend on device support and system settings. Horror cues are optional.")
                    .font(.footnote).foregroundColor(.secondary)
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
                LabeledContent("Software", value: "1.9.0 (32)")
                Button("Developer Diagnostics") { showOpeningQA = true }
                Button("Replay message tutorial") { confirmTutorialReplay = true }
                Button("Replay phone setup") { confirmSetupReplay = true }
            }
        }
        .scrollContentBackground(.hidden)
        .background(LumaDesign.background.ignoresSafeArea())
        .sheet(isPresented: $showOpeningQA) { OpeningDiagnosticsView() }
        .confirmationDialog("Replay message tutorial?", isPresented: $confirmTutorialReplay) {
            Button("Replay tutorial") {
                arrivalTask?.cancel(); arrivalTask = nil
                PhoneSensoryEngine.stop()
                banner = nil
                world.resetPhoneTutorial()
                observedIncoming = Set(incomingIDs)
                observedOutgoing = outgoingIDs
                panel = nil
                returnHome()
                locked = true
                tutorialReplay += 1
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Only the introductory messages and their tutorial progress restart. Packages, other conversations, settings, notes and owner security stay intact.")
        }
        .confirmationDialog("Replay phone setup?", isPresented: $confirmSetupReplay) {
            Button("Replay setup") { OpeningQA.record("Phone setup replay requested"); panel = nil; setupProgress = 0; setupStage = 0 }
            Button("Replay entire introduction") { OpeningQA.record("Introduction replay requested"); panel = nil; setupProgress = 0; setupStage = 0; recoveryProgress = 0; recoverySimulated = false; recoveryStage = 0 }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your restored phone records, Field Notes and story saves will not be erased.")
        }
    }

    private func loadCheckpoint(_ slot: String) {
        arrivalTask?.cancel(); arrivalTask = nil
        PhoneSensoryEngine.stop()
        guard !checkpointReboot else { return }
        checkpointReboot = true
        if saves.restore(slot, into: world) {
            observedIncoming = Set(incomingIDs)
            observedOutgoing = outgoingIDs
            banner = nil; pendingThread = nil; circuitBanner = false; utilityNotice = nil; observedUtilityFlags = world.state.flags
            authContext?.invalidate(); authContext = nil
            showOwnerPasscode = false
            panel = nil
            recent.removeAll()
            returnHome()
            locked = true
            navigationGeneration = UUID()
        } else {
            checkpointReboot = false
        }
    }

    private func scheduleTestAlert() {
        guard nativeAlerts else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                DispatchQueue.main.async { testNotice = "Notifications are disabled in device settings." }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Last Seen"
            content.body = "Game notification test. No story event has been triggered."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false)
            center.add(UNNotificationRequest(identifier: "lastseen-lab-test", content: content, trigger: trigger)) { error in
                DispatchQueue.main.async { testNotice = error == nil ? "Test scheduled. Leave the app to see the device alert." : "Unable to schedule the test." }
            }
        }
    }

    private var notifications: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                LumaHeader(title: "Notification Center", detail: "Recent activity", symbol: "bell.badge")
                if RecoveryCircuit.unlocked(world.state.flags) { CircuitNoticeCard() }
                ForEach(LumaUtility.allCases.filter { world.state.flags.contains($0.flag) }) { tool in UtilityNoticeCard(tool: tool) }
                Button { panel = nil; open(.settings) } label: { Label("Investigation progress · " + InvestigationProgress.summary(world.state.flags), systemImage: "checklist").frame(maxWidth: .infinity, alignment: .leading).padding(12).lumaSurface() }.buttonStyle(.plain)
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
                LumaHeader(title: "Control Center", detail: "Your phone, your controls", symbol: "slider.horizontal.3")
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
                }.padding(17).lumaSurface()
                if utilityActive(.quickpulse) && utilityShortcuts {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("QuickPulse", systemImage: "bolt.fill").font(.headline)
                        if fieldNotesAvailable { Button { panel = nil; open(.fieldNotes) } label: { Label("Field Notes", systemImage: "note.text") } }
                        Button { panel = nil; open(.patchline) } label: { Label("Patchline utilities", systemImage: "cpu") }
                        Button { panel = nil; open(.relay) } label: { Label("Relay", systemImage: "shippingbox") }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(14).lumaSurface()
                }
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
                let apps = LabApp.allCases.filter { ($0 != .fieldNotes || fieldNotesAvailable) && $0.rawValue.localizedCaseInsensitiveContains(q) }
                let results = PhonePublicSearch.results(query: q, world: world.state, documents: PhonePublicFiles.available(in: world.state))
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
            case .files:
                if detail.hasPrefix("WorldDoc_") { path.append(WorldDocumentRoute(id:detail)) }
                else { path.append(PhoneFileRoute(title: detail)) }
            case .calendar: if let event = world.state.events.first(where: { $0.id == detail }) { path.append(PhoneCalendarRoute(day: event.startsAt)) }
            default: break
            }
        }
    }

    @ViewBuilder private func destination(_ app: LabApp) -> some View {
        switch app {
        case .fieldNotes: if fieldNotesAvailable { FieldNotesView() } else { Text("Package unavailable") }
        case .saves: LumaSaveView(store: saves, onLoad: loadCheckpoint)
        case .messages: LumaMessagesDirectory()
        case .contacts: LumaContactsDirectory()
        case .phone: LumaPhoneDirectory()
        case .notes: PhoneNotesView(lab: true)
        case .calendar: PhoneCalendarView()
        case .mail: PhoneMailView(lab: true)
        case .afterframe: LumaSocialView(channel:.afterframe)
        case .connective: LumaSocialView(channel:.connective)
        case .commonGround: LumaSocialView(channel:.commonGround)
        case .workstation: LumaWorkbenchView(openRelay:{open(.relay)},openFiles:{open(.files)})
        case .photos: LabPhotosView()
        case .clock: LabClockView()
        case .calculator: LabCalculatorView()
        case .settings:
            controls.navigationTitle("Settings")
        case .files: LabFilesView()
        case .browser: LumaWebBrowser(wifi: wifi)
        case .relay: RelayPackagesView(earnedFlags: world.state.flags, onRestart: { returnHome(); recent.removeAll(); locked = true })
        case .patchline: PatchlineControlView(openRelay: { open(.relay) }, onRestart: { returnHome(); recent.removeAll(); locked = true })
        }
    }
}

private enum LabPanel: String, Identifiable {
    case controls = "Quick settings", notifications = "Notifications", recent = "Recent apps", search = "Search"
    var id: String { rawValue }
}

enum LabApp: String, CaseIterable, Identifiable {
    case fieldNotes = "Field Notes", phone = "Phone", messages = "Messages", contacts = "Contacts", photos = "Photos", notes = "Notes", calendar = "Calendar", mail = "Mail", clock = "Clock", calculator = "Calculator", settings = "Settings", files = "Files", browser = "Browser", relay = "Relay", patchline = "Patchline", saves = "Game Saves", afterframe = "Afterframe", connective = "Connective", commonGround = "CommonGround", workstation = "Workstation"
    var foundationIcon: String? {
        if self == .fieldNotes { return "Jailbreak_FieldNotes" }
        if self == .relay || self == .patchline || self == .workstation { return nil }
        return self == .saves ? "Icon_Save" : "Icon_" + rawValue
    }
    var id: String { rawValue }
    var inDock: Bool { [.phone, .messages, .browser, .settings].contains(self) }
    var symbol: String {
        switch self {
        case .fieldNotes: return "note.text"
        case .phone: return "phone.fill"
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
        case .saves: return "archivebox"
        case .afterframe: return "photo.on.rectangle"
        case .connective: return "person.2.fill"
        case .commonGround: return "bubble.left.and.bubble.right.fill"
        case .workstation: return "desktopcomputer"
        }
    }
    var color: Color {
        switch self {
        case .fieldNotes: return .teal
        case .phone: return .green
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
        case .saves: return .indigo
        case .afterframe: return .purple
        case .connective: return .blue
        case .commonGround: return .teal
        case .workstation: return .gray
        }
    }
}

private struct LabPhoto: Identifiable {
    let id: String
    let title: String
    let asset: String
    let caption: String
    var record: NoraPhoto? = nil
}

private struct LabPhotosView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var selection: LabPhoto?
    @AppStorage("lastseen.lab.favoritePhotos") private var favorites = ""
    @State private var onlyFavorites = false
    @State private var scale: CGFloat = 1
    private var photos: [LabPhoto] {
        NoraPhotoCatalog.photos.filter { !$0.privateAlbum }.map {
            LabPhoto(id: $0.id, title: $0.title, asset: $0.id, caption: "Recovered photograph", record: $0)
        }
    }
    private func available(_ photo: LabPhoto) -> Bool {
        photo.record?.available(flags: NoraPhotoCatalog.discoveryFlags(from: world.state.flags)) ?? true
    }
    private var shown: [LabPhoto] { photos.filter { !onlyFavorites || (available($0) && isFavorite($0.id)) } }
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
                    Text("\(shown.filter { available($0) }.count) recovered").font(.caption).foregroundColor(.secondary)
                }
                if !onlyFavorites {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Photo recovery", systemImage: "photo.stack").font(.headline)
                        ProgressView(value: Double(photos.filter { available($0) }.count), total: Double(max(1, photos.count))).tint(LumaDesign.accent)
                        Text("Unrecovered photos appear as you investigate. Private access is separate.").font(.caption).foregroundColor(.secondary)
                    }.padding(14).lumaSurface()
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                    ForEach(shown) { photo in
                        Button {
                            scale = 1; selection = photo
                        } label: {
                            GeometryReader { geo in
                                Group {
                                    if available(photo) { Image(photo.asset).resizable().scaledToFill() }
                                    else { LockedPhotoSurface() }
                                }.frame(width: geo.size.width, height: geo.size.height).clipped()
                                    .overlay(alignment: .bottomTrailing) {
                                        if available(photo) && isFavorite(photo.id) { Image(systemName: "heart.fill").font(.caption).padding(6).foregroundColor(.white).shadow(radius: 3) }
                                    }
                            }.aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }.buttonStyle(.plain).accessibilityLabel(available(photo) ? photo.title : "Locked photograph")
                    }
                }
                if shown.isEmpty { Text("Favorite a photo to see it here.").foregroundColor(.secondary).padding(.vertical, 25) }
                Text("Albums").font(.title2.bold()).padding(.top, 10)
                NavigationLink { ProtectedAreaView(area: .photos) } label: {
                    HStack(spacing: 14) {
                        Image("System_ProtectedStorage").resizable().scaledToFit()
                            .frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private album").font(.headline)
                            Text("Protected access · discoveries required").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }.padding(13).lumaSurface(radius: 16)
                }.buttonStyle(.plain)
            }.padding()
        }.navigationTitle("Photos")
        .onAppear { world.recoverPhotoDiscovery() }
        .sheet(item: $selection) { photo in
            NavigationStack {
                VStack(spacing: 16) {
                    Spacer()
                    if available(photo) {
                    Image(photo.asset).resizable().scaledToFit()
                        .scaleEffect(scale).gesture(MagnificationGesture().onChanged { scale = min(3, max(1, $0)) })
                        .clipped().onTapGesture(count: 2) { withAnimation { scale = scale > 1 ? 1 : 2 } }
                    Spacer()
                    Text(photo.caption).font(.caption).foregroundColor(.secondary)
                    Button { toggle(photo.id) } label: {
                        Label(isFavorite(photo.id) ? "Remove favorite" : "Favorite", systemImage: isFavorite(photo.id) ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.bordered)
                    } else {
                        LockedPhotoSurface(compact: false).aspectRatio(1, contentMode: .fit)
                        Text(photo.record?.lockedHint ?? "Discovery required").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                    }
                }.padding().navigationTitle(available(photo) ? photo.title : "Locked photograph").navigationBarTitleDisplayMode(.inline)
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
                        Image("Icon_Clock").resizable().scaledToFit().frame(width: 116, height: 116).clipShape(RoundedRectangle(cornerRadius: 26))
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
        }.padding(20).background(Night.background.ignoresSafeArea()).navigationTitle("Clock")
    }
}

private struct LabCalculatorView: View {
    @State private var display = "0"
    @State private var first: Double?
    @State private var operation: String?
    @State private var replace = true
    let keys = ["C","±","%","÷","7","8","9","×","4","5","6","−","1","2","3","+","0",".","="]
    @AppStorage("lastseen.lab.calculatorHistory") private var storedHistory = ""
    private var history: [String] { storedHistory.split(separator: "\n").map(String.init) }
    @State private var showHistory = false
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            if let op = operation, let left = first { Text("\(String(format: "%.10g", left)) \(op)").font(.title3).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing) }
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
        }.padding().background(Night.background.ignoresSafeArea()).navigationTitle("Calculator")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showHistory = true } label: { Image(systemName: "clock.arrow.circlepath").accessibilityLabel("Calculation history") } } }
        .sheet(isPresented: $showHistory) { NavigationStack { List { ForEach(Array(history.enumerated()), id: \.offset) { item in Text(item.element) }; if history.isEmpty { Text("No calculations yet").foregroundColor(.secondary) } }.navigationTitle("History").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showHistory = false } } } } }
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
                let record = "\(String(format: "%.10g", left)) \(op) \(String(format: "%.10g", right)) = \(display)"
                storedHistory = ([record] + history).prefix(30).joined(separator: "\n")
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
    @EnvironmentObject private var world: PhoneWorldStore
    private var documents: [String: String] { PhonePublicFiles.available(in: world.state) }
    @State private var search = ""
    var body: some View {
        List {
            LumaHeader(title: "On this phone", detail: "\(documents.count + WorldDocumentCatalog.visible(world.state).count) restored documents", symbol: "folder.fill").listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            NavigationLink { ProtectedAreaView(area: .files) } label: { Label("Protected files", systemImage: "lock.doc") }
            let records = WorldDocumentCatalog.search(search,world:world.state)
            if !records.isEmpty {
                Section("Restored records") {
                    ForEach(records) { document in
                        NavigationLink(value:WorldDocumentRoute(id:document.id)) {
                            VStack(alignment:.leading,spacing:5) {
                                Label(document.title,systemImage:"doc.richtext").font(.headline)
                                Text(document.author + " · " + document.revision).font(.caption).foregroundColor(.secondary)
                            }.padding(.vertical,5)
                        }
                    }
                }
            }
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
        }.scrollContentBackground(.hidden).background(Night.background.ignoresSafeArea()).navigationTitle("Files").searchable(text: $search)
    }
}
