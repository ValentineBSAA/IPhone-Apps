import SwiftUI
import UserNotifications
import LocalAuthentication
import UIKit
import AVFoundation

/// Neutral, offline phone prototype. No GameStore or story routing is constructed here.
struct PhoneLabView: View {
    @StateObject private var world: PhoneWorldStore
    @State private var path = NavigationPath()
    @State private var pendingLumaImage:LumaImageHandoff?
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
    @State private var pendingActivityID: String?
    @State private var banner: PhoneAlert?
    @State private var activityBanner: LumaActivityNotice?
    @State private var activityQueue = LumaActivityBannerQueue()
    private var availableActivity:[LumaActivityNotice] {
        LumaActivityCatalog.available(world.state){ title in
            LabApp(rawValue:title).map(appAvailable) ?? false
        }
    }
    private var eligibleMessageBanner:PhoneAlert? {
        PhoneAlertCatalog.current(banner,in:world.state)
    }
    private var currentMessageBanner:PhoneAlert? {
        guard let banner=eligibleMessageBanner,phase == .active,!locked,!checkpointReboot,panel == nil,!showOwnerPasscode,
              world.visibleThread != banner.neighbor else{return nil}
        return banner
    }
    private var presentedActivityID: String? {
        guard let activityBanner,availableActivity.contains(where:{$0.id==activityBanner.id}) else{return nil}
        return LumaActivityCatalog.presentedID(activityBanner, in: world.state,
            unobstructed: phase == .active && currentMessageBanner == nil && !locked && !checkpointReboot && panel == nil && !showOwnerPasscode)
    }
    @State private var observedIncoming: Set<String> = []
    @State private var observedOutgoing: Set<String> = []
    @State private var arrivalTask: Task<Void, Never>?
    private var outgoingIDs: Set<String> { PhoneMessageArrival.outgoingIDs(in: world.state) }
    private var messageIDs: Set<String> { Set(incomingIDs).union(outgoingIDs) }
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.lab.messageSound") private var messageSound = true
    @AppStorage("lastseen.lab.messageHaptics") private var messageHaptics = true
    @AppStorage("lastseen.lab.horrorEffects") private var horrorEffects = true
    @AppStorage("lastseen.lab.atmosphereIntensity") private var atmosphereIntensity = LumaArchiveAtmosphere.Intensity.standard.rawValue
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
    private func tweak(_ id: String) -> Bool { RelayCatalog.tweakActive(id, installed: relayInstalled, safeMode: safeMode, flags: world.state.flags) }
    private var fieldNotesAvailable: Bool { RecoveryCircuit.unlocked(world.state.flags) && tweak("fieldnotes") }
    private var supportAvailable: Bool { RelaySupportAccess.available(installed: relayInstalled, flags: world.state.flags) }
    private var veilAvailable: Bool { VeilArchive.installed(world.state, packages: relayInstalled, safeMode: safeMode) }
    private func appAvailable(_ app: LabApp) -> Bool {
        (app != .fieldNotes || fieldNotesAvailable) && (app != .relaySupport || supportAvailable) && (app != .veil || veilAvailable)
    }
    private func utilityActive(_ tool: LumaUtility) -> Bool { tweak(tool.rawValue) && RelayCatalog.available(tool.rawValue, flags: world.state.flags) }
    private var fiveColumns: Bool { tweak("fivegrid") || (utilityActive(.lumaplus) && utilityFive) }
    private var smallIcons: Bool { tweak("compact") || fiveColumns || (utilityActive(.lumaplus) && utilitySmall) }
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
    @AppStorage("lastseen.recovery.effects") private var restartEffects = true
    @State private var testAlertGeneration=UUID()
    private var effectiveLockPreviewsHidden:Bool {
        LumaSettingsPolicy.hidesMessagePreviews(preference:hideLockPreviews,biometrics:biometricUnlock,shield:tweak("privatepreview"))
    }
    @AppStorage("lastseen.setup.stage") private var setupStage = 5
    @AppStorage("lastseen.setup.progress") private var setupProgress = 100
    @State private var testNotice = ""
    @State private var confirmSetupReplay = false
    @State private var showOpeningQA = false
    @AppStorage("lastseen.lab.deferSystemEdges") private var deferSystemEdges = true

    var body: some View {
        if world.recoveryRequired || world.settingsRecoveryRequired {
            ScrollView {
            VStack(alignment:.leading,spacing:16) {
                Label("Phone recovery required",systemImage:"externaldrive.badge.exclamationmark").font(.title2.bold())
                Text(world.recoveryRequired
                     ? "The live phone save could not be read. Its original file is preserved. Choose a readable checkpoint to recover your phone."
                     : "The checkpoint settings could not finish restoring. The current world and pending receipt are preserved. Retry or select a readable checkpoint.")
                if world.settingsRecoveryRequired {
                    Button("Retry settings recovery") {
                        guard phase == .active else{return}
                        if world.retrySettingsRecovery(){saves.refresh();locked=true;navigationGeneration=UUID()}
                    }.buttonStyle(.borderedProminent)
                }
                ForEach(LumaSaveStore.manual+LumaSaveStore.automatic,id:\.self) { slot in
                    if let saved=saves.slots[slot] {
                        Button {
                            guard phase == .active else{return}
                            recoverySlot=slot
                            recoveryDate=saved.date
                            confirmDamagedRestore=true
                        } label:{
                            HStack { Text(slot.hasPrefix("manual") ? "Manual save "+String(slot.suffix(1)) : "Automatic checkpoint "+String(slot.suffix(1))); Spacer(); Text(saved.date,format:.dateTime.month().day().hour().minute()).font(.caption) }
                        }.buttonStyle(.bordered)
                    }
                }
                if saves.slots.isEmpty {Text("No readable checkpoint is available. Existing recovery files have been preserved.").foregroundColor(.secondary)}
                Button("Refresh checkpoints"){saves.refresh()}
                Text(saves.notice).font(.caption)
            }.padding(24)
            }
                .confirmationDialog("Recover from selected checkpoint?",isPresented:$confirmDamagedRestore,titleVisibility:.visible) {
                    Button("Restore checkpoint",role:.destructive) {
                        guard phase == .active,let slot=recoverySlot else{return}
                        saves.refresh()
                        guard saves.slots[slot]?.date == recoveryDate,saves.slots[slot] != nil else {
                            recoverySlot=nil;return
                        }
                        if saves.restore(slot,into:world) {locked=true;navigationGeneration=UUID()}
                        recoverySlot=nil
                    }
                    Button("Cancel",role:.cancel){recoverySlot=nil}
                } message:{Text("Unreadable live data and unresolved settings receipts will be preserved before replacement. Later progress may not be present in this checkpoint.")}
                .onChange(of:phase){if $0 != .active {confirmDamagedRestore=false;recoverySlot=nil}}
        } else { phoneBody }
    }
    @State private var recoverySlot:String?
    @State private var recoveryDate:Date?
    @State private var confirmDamagedRestore=false
    private var phoneBody:some View {
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
                            Button { returnHome() } label: {
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
            .navigationDestination(for: LumaActivityRoute.self) { route in
                LumaActivityDetail(id: route.id)
            }
            .navigationDestination(for: LumaCallRoute.self) { route in
                LumaCallView(neighbor: route.neighbor)
                    .safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
            }
            .navigationDestination(for: AppPage.self) { page in
                Group {
                    switch page {
                    case .worldThread(let neighbor):
                        if !locked && !checkpointReboot && Neighbor.visible(in:world.state).contains(neighbor) {NeighborConversationView(neighbor:neighbor,reactive:true)}
                        else {Text("Conversation unavailable")}
                    case .worldProfile(let neighbor):
                        if !locked && !checkpointReboot && Neighbor.visible(in:world.state).contains(neighbor) {NeighborProfileView(neighbor:neighbor,phoneLab:true)}
                        else {Text("Contact unavailable")}
                    case .note(let id): PhoneNoteEditorView(noteID: id)
                    default: Text("Not available in Phone Lab")
                    }
                }.safeAreaInset(edge: .bottom, spacing: 0) { gameHomeHandle }
            }
        }
        .id(navigationGeneration)
        .environmentObject(world)
        .environment(\.sendImageToLuma,{ asset in
            guard phase == .active,appAvailable(.assistant),!locked,!checkpointReboot,
                  let handoff=LumaImageHandoff.make(asset,epoch:world.checkpointEpoch,in:world.state) else{return}
            open(.assistant)
            pendingLumaImage=handoff
        })
        .defersSystemGestures(on: deferSystemEdges ? [.top, .bottom] : [])
        .tint(LumaDesign.accent)
        .preferredColorScheme(.dark)
        .overlay {
            Color.black.opacity(LumaSettingsPolicy.displayDimming(brightness))
                .ignoresSafeArea().allowsHitTesting(false)
        }
        .overlay(alignment:.bottom) {
            if world.persistenceFailed {
                Label("Live save unavailable. Progress may not survive restart.",systemImage:"exclamationmark.triangle")
                    .font(.caption).padding(8).background(.regularMaterial,in:RoundedRectangle(cornerRadius:10))
                    .padding(.bottom,48).allowsHitTesting(false)
            }
        }
        .overlay(alignment: .top) {
            if let alert = currentMessageBanner {
                PhoneNotificationCard(alert: alert) {
                    banner = nil; openThread(alert.neighbor)
                }.padding(.horizontal, 14).padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            if let notice = activityBanner, presentedActivityID == notice.id {
                LumaActivityCard(notice: notice, hidePreview: notice.hidePreview(in: world.state)) { openActivity(notice) }
                    .padding(.horizontal, 14).padding(.top, 4)
            }
        }
        .overlay(alignment: .top) {
            if circuitBanner && currentMessageBanner == nil && presentedActivityID == nil && phase == .active && !locked && !checkpointReboot && panel == nil && !showOwnerPasscode {
                Button { circuitBanner = false; open(.relay) } label: { CircuitNoticeCard() }
                    .buttonStyle(.plain).padding(.horizontal, 14).padding(.top, 4)
            }
        }
        .overlay(alignment: .top) {
            if let tool = utilityNotice, currentMessageBanner == nil && presentedActivityID == nil && !circuitBanner && phase == .active && !locked && !checkpointReboot && panel == nil && !showOwnerPasscode {
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
                settleTimer(now: Date().timeIntervalSince1970, present: false)
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
        .task(id: currentMessageBanner?.id) {
            guard let id = currentMessageBanner?.id else { return }
            do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
            if !Task.isCancelled,currentMessageBanner?.id == id { withAnimation { banner = nil } }
        }
        // Count a continuous visible interval, not time spent behind another overlay.
        // SwiftUI cancels this task on preemption; resuming starts a fresh interval.
        .task(id: presentedActivityID) {
            guard let id = presentedActivityID else { return }
            do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
            guard !Task.isCancelled, presentedActivityID == id else { return }
            activityBanner = nil
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
                } else if !locked && panel == nil && !showOwnerPasscode && world.visibleThread == newest.neighbor {
                    world.markRead(newest.neighbor)
                    banner = nil
                }
            }
        }
        .onChange(of: world.visibleThread) { visible in
            if banner?.neighbor == visible { banner = nil }
        }
        .onChange(of:eligibleMessageBanner?.id) { value in
            if value == nil {banner=nil}
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
                    let before = LumaActivityCatalog.allIDs(world.state)
                    world.advancePendingReplies()
                    world.advanceRelaySupportActivity(installed: relayInstalled)
                    if timerBaselineReady { settleTimer(now: Date().timeIntervalSince1970, present: false) }
                    if didConfigureFeedback {
                        let arrived = availableActivity.filter{!before.contains($0.id)}.reversed()
                        playActivityFeedback(Array(arrived))
                        if !locked {
                            activityQueue.enqueue(Array(arrived), showing: activityBanner?.id)
                            if let current = activityBanner, !availableActivity.contains(where: { $0.id == current.id }) { activityBanner = nil }
                            if activityBanner == nil && currentMessageBanner == nil && panel == nil && !showOwnerPasscode {
                                while let next=activityQueue.next(in:world.state) {
                                    if availableActivity.contains(where:{$0.id==next.id}) {activityBanner=next;break}
                                }
                            }
                        }
                    }
                }
                do { try await Task.sleep(nanoseconds: 250_000_000) } catch { return }
            }
        }
        .onChange(of: locked) { value in
            guard value else { return }
            returnHome()
            panel=nil;banner=nil
            activityBanner=nil;activityQueue.clear()
            PhoneSensoryEngine.cancelAuthentication()
            guard didConfigureFeedback, phase == .active, !checkpointReboot else { return }
            PhoneSensoryEngine.play(.lock, sound: messageSound, haptics: messageHaptics, horrorEnabled: horrorEffects)
        }
        .onChange(of: phase) { value in
            observedIncoming = Set(incomingIDs)
            observedOutgoing = outgoingIDs
            if value != .active { pendingLumaImage=nil;saves.persistPlayTime() }
            if value != .active {
                arrivalTask?.cancel(); arrivalTask = nil
                if value == .background {
                    cancelLockAuthentication()
                    PhoneSensoryEngine.stop()
                }
                else { PhoneSensoryEngine.stopSound(); PhoneSensoryEngine.stopHaptics() }
                banner = nil; activityBanner = nil; activityQueue.clear()
            } else {routePendingUnlock()}
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
            if let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
               AVAudioSession.InterruptionType(rawValue: raw) == .began {
                PhoneSensoryEngine.stopSound()
                PhoneSensoryEngine.stopHaptics()
                RestartAudio.stop()
            }
        }
        .onChange(of: messageSound) { if !$0 { PhoneSensoryEngine.stopSound() } }
        .onChange(of: messageHaptics) { if !$0 { PhoneSensoryEngine.stopHaptics() } }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { notification in
            if let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
               AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable {
                // Do not spill an in-progress alert onto a newly selected speaker.
                PhoneSensoryEngine.stopSound()
                RestartAudio.stop()
            }
        }
        .onChange(of: horrorEffects) { if !$0 { PhoneSensoryEngine.stopHorrorEffects() } }
        .onChange(of: restartEffects){if !$0 {RestartAudio.stop()}}
        .onChange(of: nativeAlerts){if !$0 {cancelTestAlert()}}
        .onDisappear {
            arrivalTask?.cancel(); arrivalTask = nil
            cancelLockAuthentication()
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
                                ForEach(recent.filter { appAvailable($0) }) { app in
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
        .sheet(isPresented: $showOwnerPasscode, onDismiss: {
            if locked { pendingThread = nil; pendingActivityID = nil }
        }) {
            ScrollView {
                OwnerPasscodeView(onSuccess: {
                    guard phase == .active,locked,!checkpointReboot,showOwnerPasscode else{return}
                    ownerVerified=true;showOwnerPasscode=false;completeUnlock()
                }, onCancel: { showOwnerPasscode = false; pendingThread = nil; pendingActivityID = nil })
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

    private var unread: Int { Neighbor.visible(in:world.state).reduce(0) { $0 + world.countUnread($1) } }

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
                        if value.translation.height < -40 { pendingThread = nil; pendingActivityID = nil; requestUnlock() }
                    })
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !alerts.isEmpty || !availableActivity.isEmpty {
                        HStack {
                            Text("Notifications").font(.headline)
                            Spacer()
                            Text("\(unread) unread").font(.caption).foregroundColor(.white.opacity(0.72))
                        }.padding(.horizontal, 4)
                        ForEach(alerts) { alert in
                            PhoneNotificationCard(alert: alert, hidePreview: effectiveLockPreviewsHidden) {
                                guard phase == .active,authContext == nil,alerts.contains(where:{$0.id==alert.id}) else { return }
                                pendingActivityID = nil; pendingThread = alert.neighbor
                                requestUnlock()
                            }
                        }
                        ForEach(availableActivity) { notice in
                            LumaActivityCard(notice: notice, hidePreview: true) {
                                guard phase == .active,authContext == nil,availableActivity.contains(where:{$0.id==notice.id}) else { return }
                                pendingThread = nil; pendingActivityID = notice.id; requestUnlock()
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
                Button("Explore public apps") { pendingThread = nil; pendingActivityID = nil; authNotice = ""; locked = false }.font(.caption).disabled(authContext != nil)
            }
            Button {
                pendingThread = nil; pendingActivityID = nil; requestUnlock()
            } label: {
                VStack(spacing: 7) {
                    Image(systemName: "chevron.up").font(.headline)
                    Text(biometricUnlock ? "Authenticate to unlock" : "Swipe up to open").font(.subheadline.weight(.medium))
                    Capsule().fill(.white.opacity(0.8)).frame(width: 110, height: 5)
                }.frame(maxWidth: .infinity).padding(.vertical, 12).contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(authContext != nil).accessibilityIdentifier("luma.lock.unlock")
                .gesture(DragGesture(minimumDistance: 16).onEnded { value in
                    if value.translation.height < -20 && authContext == nil {
                        pendingThread = nil; pendingActivityID = nil; requestUnlock()
                    }
                })
        }.padding(.horizontal, 18).padding(.vertical, 10).foregroundColor(.white)
    }

    private func playActivityFeedback(_ notices: [LumaActivityNotice]) {
        guard didConfigureFeedback, phase == .active, !checkpointReboot else { return }
        for notice in notices {
            let cue = notice.cue.isHorror && !horrorEffects ? PhoneCue.general : notice.cue
            PhoneSensoryEngine.play(cue, sound: messageSound, haptics: messageHaptics, horrorEnabled: horrorEffects, hapticProfile: notice.profile)
        }
    }

    private func settleTimer(now: Double, present: Bool) {
        let end = feedbackTimerEnd
        guard LumaTimerCompletion.due(end: end, delivered: feedbackTimerDelivered, now: now) else { return }
        let before = LumaActivityCatalog.allIDs(world.state)
        world.recordTimerActivity(end: end)
        feedbackTimerDelivered = end
        if present {
            let arrived=Array(availableActivity.filter{!before.contains($0.id)}.reversed())
            playActivityFeedback(arrived)
            if didConfigureFeedback && phase == .active && !checkpointReboot && !locked {
                activityQueue.enqueue(arrived, showing: activityBanner?.id)
            }
        }
    }

    private func completeUnlock() {
        guard locked,!checkpointReboot,phase != .background else{return}
        authNotice = ""
        PhoneSensoryEngine.authentication(.unlock, sound: messageSound, haptics: messageHaptics)
        withAnimation(.easeInOut(duration: 0.25)) { locked = false }
        routePendingUnlock()
    }

    private func routePendingUnlock() {
        guard phase == .active,!locked,!checkpointReboot else{return}
        let activityID=pendingActivityID
        let neighbor=pendingThread
        pendingActivityID=nil;pendingThread=nil
        if let activityID {
            if let notice=availableActivity.first(where:{$0.id==activityID}) {openActivity(notice)}
        } else if let neighbor {openThread(neighbor)}
    }

    private func openActivity(_ snapshot:LumaActivityNotice) {
        guard phase == .active,!locked,!checkpointReboot,
              let notice=availableActivity.first(where:{$0.id==snapshot.id}),
              let app=LabApp(rawValue:notice.appTitle),appAvailable(app) else{return}
        panel=nil;activityBanner=nil
        open(app)
        if notice.kind != .timer && notice.kind != .support {
            path.append(LumaActivityRoute(id:notice.id))
        }
        world.dismissActivity(notice.id)
    }

    private func openThread(_ neighbor: Neighbor) {
        guard phase == .active,!locked,!checkpointReboot,Neighbor.visible(in:world.state).contains(neighbor) else{return}
        panel = nil
        banner = nil
        open(.messages)
        path.append(AppPage.worldThread(neighbor))
    }

    private func cancelLockAuthentication() {
        let previous = authContext
        authContext = nil
        previous?.invalidate()
        pendingThread = nil; pendingActivityID = nil
        showOwnerPasscode = false
        PhoneSensoryEngine.cancelAuthentication()
    }

    private func requestUnlock() {
        guard locked, authContext == nil, phase == .active,
              UIApplication.shared.applicationState != .background, !checkpointReboot else { return }
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
            pendingThread = nil; pendingActivityID = nil
            authNotice = "Biometrics unavailable. Use the fictional owner passcode or open public apps."
            return
        }
        authContext = context
        let requestEpoch=world.checkpointEpoch
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your fictional Last Seen phone.") { success, error in
            DispatchQueue.main.async {
                guard authContext === context else{return}
                guard requestEpoch==world.checkpointEpoch else{cancelLockAuthentication();return}
                guard OwnerSecurityPolicy.acceptsCallback(currentRequest: true, eligible: locked && biometricUnlock && !checkpointReboot,
                    background: phase == .background || UIApplication.shared.applicationState == .background) else {
                    cancelLockAuthentication()
                    return
                }
                authContext = nil
                if success {
                    completeUnlock()
                } else {
                    pendingThread = nil; pendingActivityID = nil
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
        pendingLumaImage=nil
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
                                        fiveColumns:fiveColumns,smallIcons:smallIcons,accessibleLayout:dynamicTypeSize.isAccessibilitySize)
            let pages = LumaHomeLayout.pages(columns:layout.columns,rows:layout.rows,fieldNotes:fieldNotesAvailable,support:supportAvailable,veil:veilAvailable)
            let selected = min(max(0,homePage),pages.count-1)
            ZStack {
                launcherScrollIfNeeded(layout.needsScroll) {
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
                                    .frame(width:38,height:44).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .accessibilityLabel("Home page \(index+1) of \(pages.count)")
                                .accessibilityIdentifier("luma.home.page.\(index)")
                                .accessibilityAddTraits(selected==index ? .isSelected : [])
                        }
                    }.frame(height:44)
                    homeActions.frame(height:44)
                    HStack(spacing:6) {
                        ForEach(LumaHomeLayout.dock) { app in
                            icon(app,size:layout.dockIconSize)
                                .frame(height:layout.dockHeight-12)
                        }
                    }.padding(.horizontal,9).padding(.vertical,6)
                        .frame(height:layout.dockHeight)
                        .background {
                            if tweak("dockcontrast") {
                                RoundedRectangle(cornerRadius: 27, style: .continuous)
                                    .fill(Color(red: 0.09, green: 0.13, blue: 0.20))
                                    .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(Color.white.opacity(0.42), lineWidth: 1))
                            } else if !tweak("dockglass") && (!utilityActive(.lumaplus) || utilityGlass) {
                                RoundedRectangle(cornerRadius:27,style:.continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius:27).strokeBorder(.white.opacity(0.12),lineWidth:1))
                            }
                        }
                }
                .padding(.horizontal,14).padding(.vertical,8)
                .frame(maxWidth:.infinity,alignment:.top)
                .frame(minHeight:layout.contentHeight,alignment:.top)
                }
                .accessibilityHidden(homeFolder != nil)
                .allowsHitTesting(homeFolder == nil)
                if let folder=homeFolder {
                    Color.black.opacity(0.34).ignoresSafeArea().onTapGesture { closeHomeFolder() }
                        .accessibilityHidden(true)
                    ScrollView {
                        homeFolderView(folder,width:geometry.size.width)
                            .frame(maxWidth:.infinity).padding(.vertical,12)
                    }.frame(maxHeight:geometry.size.height)
                        .transition(reduceMotion ? .opacity : .scale(scale:0.94).combined(with:.opacity))
                }
            }.onChange(of:pages.count) { count in
                homePage=min(homePage,max(0,count-1))
            }
        }.buttonStyle(.plain).foregroundColor(.white)
    }

    @ViewBuilder private func launcherScrollIfNeeded<Content:View>(_ needed:Bool,@ViewBuilder content:()->Content)->some View {
        if needed {ScrollView(.vertical){content()}}
        else {content()}
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
            }.frame(maxWidth:.infinity,minHeight:44).contentShape(Rectangle())
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: folder.apps.count > 3 ? 2 : 3), alignment: .leading, spacing: 16) {
                ForEach(folder.apps) { app in icon(app,size:min(61,max(38,(width-92)/3-10))) }
            }.padding(.vertical,8)
        }.padding(20)
            .frame(width:min(340,max(220,width-32)))
            .background(.regularMaterial,in:RoundedRectangle(cornerRadius:30,style:.continuous))
            .overlay(RoundedRectangle(cornerRadius:30).strokeBorder(folder.tint.opacity(0.45),lineWidth:1))
    }

    private func open(_ app: LabApp) {
        guard phase == .active,!locked,!checkpointReboot,appAvailable(app) else{return}
        pendingLumaImage=nil
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
            } else if (tweak("teal") || (utilityActive(.afterglowstudio) && utilityTheme)),let asset=ApprovedArt.themeName(for:app.rawValue) {
                Image(asset).resizable().scaledToFit()
            } else if let art=app.foundationIcon, UIImage(named: art) != nil {
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
                    let count = app == .messages ? unread : availableActivity.filter { $0.appTitle == app.rawValue }.count
                    if count > 0 && !tweak("quietbadges") {
                        Text("\(count)").font(.caption2.bold()).padding(5)
                            .background(.red,in:Capsule()).offset(x:5,y:-5)
                    }
                }
                if labelsVisible {
                    Text(app.rawValue).font(.system(size:11,weight:.medium)).lineLimit(1).minimumScaleFactor(0.7)
                }
            }.frame(maxWidth:.infinity,minHeight:44).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(app.rawValue)
            .accessibilityValue(tweak("quietbadges") ? "" : String(app == .messages ? unread : availableActivity.filter{$0.appTitle==app.rawValue}.count)+" notifications")
            .accessibilityIdentifier("luma.app."+app.rawValue)
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
                NavigationLink { InvestigationProgressView(openBrowser: { open(.browser) }, openMessages: { open(.messages) }, openNotes: { open(.notes) }, openFiles: { open(.files) }, openMail: { open(.mail) }) } label: { Label("Investigation progress", systemImage: "checklist") }
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
                    Text("Game display only · "+String(Int(LumaSettingsPolicy.clampedBrightness(brightness)*100))+"%").font(.caption).foregroundColor(.secondary)
                }
            }
            Section("Security & privacy") {
                NavigationLink { ProtectedAreaView(area: .security) } label: {
                    Label("Biometrics & Passcode", systemImage: "lock.shield")
                }
                LabeledContent("Biometric unlock", value: biometricUnlock ? "Registered" : "Not registered")
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
                Toggle("Restart sound effects",isOn:$restartEffects)
                Picker("Archive atmosphere", selection: $atmosphereIntensity) {
                    ForEach(LumaArchiveAtmosphere.Intensity.allCases) { intensity in
                        Text(intensity.title).tag(intensity.rawValue)
                    }
                }.disabled(!horrorEffects)
                Text("Atmosphere changes presentation only. Restrained uses a static edge tint; Off removes the additional effects. Neither changes the investigation.").font(.footnote).foregroundColor(.secondary)
                NavigationLink {
                    PhoneSoundStudio(sound: $messageSound, haptics: $messageHaptics, horrorEnabled: $horrorEffects)
                } label: { Label("Sound Library · 19 effects", systemImage: "waveform") }
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
                LabeledContent("Effective message previews",value:effectiveLockPreviewsHidden ? "Hidden":"Visible")
                if biometricUnlock || tweak("privatepreview") {
                    Text("Owner authentication or Preview Shield overrides the preview preference.").font(.caption).foregroundColor(.secondary)
                }
                Text("Other app activity is always redacted on the lock screen.").font(.caption).foregroundColor(.secondary)
                LabeledContent("Native game alerts", value: nativeAlerts ? "Enabled in game" : "Off")
                if nativeAlerts {
                    Button("Turn off native game alerts"){nativeAlerts=false;cancelTestAlert()}
                }
                Button("Review optional permissions") { panel = nil; permissionsReviewed = false }
                if nativeAlerts {
                    Button("Schedule test notification (7 seconds)") { scheduleTestAlert() }
                    Button("Cancel test notification"){cancelTestAlert()}
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
            cancelTestAlert()
            observedIncoming = Set(incomingIDs)
            observedOutgoing = outgoingIDs
            banner = nil; activityBanner = nil; activityQueue.clear(); pendingThread = nil; pendingActivityID = nil; circuitBanner = false; utilityNotice = nil; observedUtilityFlags = world.state.flags
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

    private func cancelTestAlert() {
        testAlertGeneration=UUID()
        let center=UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers:["lastseen-lab-test"])
        center.removeDeliveredNotifications(withIdentifiers:["lastseen-lab-test"])
        testNotice="Test notification canceled."
    }

    private func scheduleTestAlert() {
        guard nativeAlerts else{return}
        let token=UUID()
        testAlertGeneration=token
        let center=UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers:["lastseen-lab-test"])
        testNotice="Checking notification permission…"
        Task { @MainActor in
            let settings=await center.notificationSettings()
            guard token==testAlertGeneration,nativeAlerts else{return}
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                testNotice="Notifications are disabled in device settings.";return
            }
            let content=UNMutableNotificationContent()
            content.title="Last Seen"
            content.body="Game notification test. No story event has been triggered."
            content.sound=messageSound ? .default:nil
            let trigger=UNTimeIntervalNotificationTrigger(timeInterval:7,repeats:false)
            do {
                try await center.add(UNNotificationRequest(identifier:"lastseen-lab-test",content:content,trigger:trigger))
                guard token==testAlertGeneration,nativeAlerts else {
                    if !nativeAlerts {center.removePendingNotificationRequests(withIdentifiers:["lastseen-lab-test"])}
                    return
                }
                testNotice="Test scheduled. Leave the app to see the device alert."
            } catch {
                if token==testAlertGeneration {testNotice="Unable to schedule the test."}
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
                Text("Recent app activity").font(.subheadline).foregroundColor(.secondary)
                ForEach(availableActivity) { notice in
                    VStack(alignment: .trailing, spacing: 4) {
                        LumaActivityCard(notice: notice, hidePreview: notice.hidePreview(in: world.state)) { openActivity(notice) }
                        Button("Dismiss") { world.dismissActivity(notice.id) }.font(.caption)
                    }
                }
                Text("Recent messages").font(.subheadline).foregroundColor(.secondary)
                ForEach(PhoneAlertCatalog.alerts(in: world.state, unreadOnly: false)) { alert in
                    PhoneNotificationCard(alert: alert) { openThread(alert.neighbor) }
                }
                if PhoneAlertCatalog.alerts(in: world.state, unreadOnly: false).isEmpty && availableActivity.isEmpty {
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
                    }.buttonStyle(.plain).accessibilityLabel("Simulated Wi-Fi").accessibilityValue(wifi ? "On":"Off")
                    Button { hideLockPreviews.toggle() } label: {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: effectiveLockPreviewsHidden ? "lock.fill" : "bell.fill").font(.title)
                            Text("Previews").font(.headline)
                            Text(effectiveLockPreviewsHidden ? "Hidden" : "Visible").font(.caption)
                            if biometricUnlock || tweak("privatepreview") {Text("Protected").font(.caption2)}
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain)
                        .disabled(biometricUnlock || tweak("privatepreview"))
                        .accessibilityLabel("Lock screen previews")
                        .accessibilityValue(effectiveLockPreviewsHidden ? "Hidden":"Visible")
                        .accessibilityHint(biometricUnlock || tweak("privatepreview") ? "Protected by current security settings":"Toggle message previews")
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label("Brightness", systemImage: "sun.max").font(.headline)
                    Slider(value: $brightness, in: 0.35...1)
                        .accessibilityLabel("Simulated brightness")
                }.padding(17).lumaSurface()
                Button { panel = nil; open(.assistant) } label: { Label("Luma Assistant", systemImage: "waveform.circle.fill").frame(maxWidth: .infinity, alignment: .leading).padding(14).lumaSurface() }.buttonStyle(.plain)
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
                    .autocorrectionDisabled().submitLabel(.search)
            }
            let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty {
                Text("Search restored phone contents. Protected records are not indexed.").font(.subheadline).foregroundColor(.secondary)
            } else {
                let apps = LabApp.allCases.filter { appAvailable($0) && $0.rawValue.localizedCaseInsensitiveContains(q) }
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
        }.listStyle(.insetGrouped).scrollDismissesKeyboard(.interactively)
    }

    private func openSearchResult(_ result: PhoneSearchResult) {
        guard phase == .active,!locked,!checkpointReboot,
              let app=LabApp(rawValue:result.destination),appAvailable(app),
              PhonePublicSearch.results(query:searchQuery.trimmingCharacters(in:.whitespacesAndNewlines),world:world.state,documents:PhonePublicFiles.available(in:world.state)).contains(where:{$0.id==result.id}) else{return}
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
        case .veil: if veilAvailable { VeilBrowser() } else { Text("Package unavailable") }
        case .relaySupport: if supportAvailable { RelaySupportView() } else { Text("Package unavailable") }
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
        case .havenWatch: HavenWatchView()
        case .dayblink: DayblinkView()
        case .motionwell: MotionwellView()
        case .voiceMemos: LumaVoiceMemos()
        case .assistant: LumaAssistantView(context: { LumaAssistantContext(world: world.state, availableApps: Set(LabApp.allCases.filter { appAvailable($0) }), wifi: wifi, sound: messageSound, haptics: messageHaptics, safeMode: safeMode, installedCount: RelayCatalog.ids(relayInstalled).count, timerEnd: feedbackTimerEnd, now: Date()) }, openApp: { open($0) }, acknowledgeBoundaries: { world.acknowledgeLumaBoundaries() }, rememberSession: { world.rememberLumaSession($0) }, takeImageHandoff: {
            let handoff=pendingLumaImage;pendingLumaImage=nil
            return handoff?.resolve(epoch:world.checkpointEpoch,in:world.state)
        }, checkpointEpoch:{world.checkpointEpoch})
        case .workstation: LumaWorkbenchView(openRelay:{open(.relay)},openFiles:{open(.files)})
        case .photos: LabPhotosView()
        case .clock: LabClockView(onFinish: { settleTimer(now: $0, present: true) })
        case .calculator: LabCalculatorView()
        case .settings:
            controls.navigationTitle("Settings")
        case .files: LabFilesView()
        case .browser: LumaWebBrowser(wifi: wifi)
        case .relay: RelayPackagesView(earnedFlags: world.state.flags, onRestart: { returnHome(); recent.removeAll(); locked = true })
        case .patchline: PatchlineControlView(openRelay: { open(.relay) }, onRestart: { returnHome(); recent.removeAll(); locked = true }, earnedFlags: world.state.flags)
        }
    }
}

private enum LabPanel: String, Identifiable {
    case controls = "Quick settings", notifications = "Notifications", recent = "Recent apps", search = "Search"
    var id: String { rawValue }
}

enum LabApp: String, CaseIterable, Identifiable {
    case veil = "VEIL", relaySupport = "Relay Support", fieldNotes = "Field Notes", phone = "Phone", messages = "Messages", contacts = "Contacts", photos = "Photos", notes = "Notes", calendar = "Calendar", mail = "Mail", clock = "Clock", calculator = "Calculator", settings = "Settings", files = "Files", browser = "Browser", relay = "Relay", patchline = "Patchline", saves = "Game Saves", afterframe = "Afterframe", connective = "Connective", commonGround = "CommonGround", workstation = "Workstation", havenWatch = "HavenWatch", dayblink = "Dayblink", motionwell = "Motionwell", voiceMemos = "Voice Memos", assistant = "Luma Assistant"
    var foundationIcon: String? {
        if self == .veil { return "Icon_Veil" }
        if self == .relaySupport { return "Icon_RelaySupport" }
        if self == .fieldNotes { return "Jailbreak_FieldNotes" }
        if self == .voiceMemos { return "Icon_VoiceMemos" }
        if self == .assistant { return nil }
        if self == .relay || self == .patchline || self == .workstation { return nil }
        return self == .saves ? "Icon_Save" : "Icon_" + rawValue
    }
    var id: String { rawValue }
    var inDock: Bool { [.phone, .messages, .browser, .settings].contains(self) }
    var symbol: String {
        switch self {
        case .veil: return "eye.slash"
        case .relaySupport: return "headset"
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
        case .havenWatch: return "video.fill"
        case .dayblink: return "camera.fill"
        case .motionwell: return "play.rectangle.fill"
        case .voiceMemos: return "waveform"
        case .assistant: return "waveform.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .veil: return .purple
        case .relaySupport: return .teal
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
        case .havenWatch: return .cyan
        case .dayblink: return .yellow
        case .motionwell: return .red
        case .voiceMemos: return .red
        case .assistant: return .indigo
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
    @Environment(\.sendImageToLuma) private var sendImageToLuma
    @State private var pendingModalHandoff:LumaImageHandoff?
    @State private var photoEpoch:UUID?
    @State private var selection: LabPhoto?
    @AppStorage("lastseen.lab.favoritePhotos") private var favorites = ""
    @Environment(\.scenePhase) private var photoPhase
    @State private var libraryFilter:NoraPhotoCatalog.LibraryFilter = .library
    @State private var scale: CGFloat = 1
    @State private var gridColumns=3
    private func makePhoto(_ record:NoraPhoto)->LabPhoto {
        LabPhoto(id:record.id,title:record.title,asset:record.id,caption:"Recovered photograph · Capture date unavailable",record:record)
    }
    private var photos: [LabPhoto] {
        NoraPhotoCatalog.library(world.state.flags,filter:.library).map(makePhoto)
    }
    private var favoriteIDs:Set<String> {RelayCatalog.ids(favorites)}
    private func adjacent(_ id:String,_ offset:Int)->LabPhoto? {
        NoraPhotoCatalog.adjacent(id,offset:offset,flags:world.state.flags,filter:libraryFilter,favorites:favoriteIDs).map(makePhoto)
    }
    private func openPhoto(_ photo:LabPhoto) {
        guard photoPhase == .active else{return}
        scale=1
        photoEpoch=world.checkpointEpoch
        selection=photo
        if available(photo){world.recordCameraAnalysisOpened(photo.asset)}
    }
    private func available(_ photo: LabPhoto) -> Bool {
        photo.record?.available(flags: NoraPhotoCatalog.discoveryFlags(from: world.state.flags)) ?? true
    }
    private var shown:[LabPhoto] {
        NoraPhotoCatalog.library(world.state.flags,filter:libraryFilter,favorites:favoriteIDs).map(makePhoto)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Library", selection:$libraryFilter) {
                    ForEach(NoraPhotoCatalog.LibraryFilter.allCases){filter in Text(filter.rawValue).tag(filter)}
                }.pickerStyle(.segmented)
                HStack {
                    Text(libraryFilter == .library ? "Camera roll":libraryFilter.rawValue).font(.title2.bold())
                    Spacer()
                    Text("\(shown.filter { available($0) }.count) recovered").font(.caption).foregroundColor(.secondary)
                    Menu {
                        Button("Larger thumbnails"){gridColumns=2}
                        Button("Standard thumbnails"){gridColumns=3}
                    } label: {Image(systemName:"square.grid.2x2").frame(minWidth:44,minHeight:44).accessibilityLabel("Thumbnail size")}
                }
                if libraryFilter == .library {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Photo recovery", systemImage: "photo.stack").font(.headline)
                        ProgressView(value: Double(photos.filter { available($0) }.count), total: Double(max(1, photos.count))).tint(LumaDesign.accent)
                        Text("Unrecovered photos appear as you investigate. Private access is separate.").font(.caption).foregroundColor(.secondary)
                    }.padding(14).lumaSurface()
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count:gridColumns), spacing: 4) {
                    ForEach(shown) { photo in
                        Button {
                            openPhoto(photo)
                        } label: {
                            GeometryReader { geo in
                                Group {
                                    if available(photo) && photoPhase == .active { Image(photo.asset).resizable().scaledToFill() }
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
                if shown.isEmpty { Text(libraryFilter == .favorites ? "Favorite a photo to see it here.":"No recovered photos available.").foregroundColor(.secondary).padding(.vertical, 25) }
                if !RecoveredImageAnalysis.visible(world.state).isEmpty {
                    NavigationLink { ImageReviewOverviewView() } label:{
                        Label("Image investigation",systemImage:"viewfinder").padding(12).lumaSurface()
                    }.buttonStyle(.plain)
                }
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
        .onChange(of:photoPhase){if $0 != .active {pendingModalHandoff=nil;selection=nil;scale=1;photoEpoch=nil}}
        .onChange(of:world.checkpointEpoch){_ in pendingModalHandoff=nil;selection=nil;photoEpoch=nil;scale=1}
        .sheet(item:$selection,onDismiss:{
            let handoff=pendingModalHandoff
            pendingModalHandoff=nil;photoEpoch=nil
            if photoPhase == .active,let asset=handoff?.resolve(epoch:world.checkpointEpoch,in:world.state) {sendImageToLuma?(asset)}
        }) { photo in
            NavigationStack {
                ScrollView {
                VStack(spacing: 16) {
                    if available(photo) && photoPhase == .active && photoEpoch == world.checkpointEpoch {
                    if let image=UIImage(named:photo.asset) {
                        LumaImageViewport(image:image,scale:$scale)
                            .frame(height:320).clipShape(RoundedRectangle(cornerRadius:12))
                            .id(photo.id)
                        if scale>1 {Text("Drag the enlarged image to inspect its edges.").font(.caption).foregroundColor(.secondary)}
                    } else {Label("Image unavailable",systemImage:"photo.badge.exclamationmark").foregroundColor(.secondary)}
                    HStack {
                        Button("Zoom out"){scale=max(1,scale-0.5)}.disabled(scale<=1)
                        Spacer()
                        Text("\(Int(scale*100))%").font(.caption).monospacedDigit()
                        Spacer()
                        Button("Zoom in"){scale=min(3,scale+0.5)}.disabled(scale>=3)
                    }.buttonStyle(.bordered)
                    Text(photo.caption).font(.caption).foregroundColor(.secondary)
                    if RecoveredImageAnalysis.record(photo.asset,in:world.state) != nil {
                        NavigationLink { RecoveredImageAnalysisView(asset:photo.asset) } label:{
                            Label("Analyze image",systemImage:"viewfinder")
                        }.buttonStyle(.bordered)
                    }
                    SendImageToLumaButton(asset:photo.asset)
                    Button { toggle(photo.id) } label: {
                        Label(isFavorite(photo.id) ? "Remove favorite" : "Favorite", systemImage: isFavorite(photo.id) ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.bordered)
                    } else {
                        LockedPhotoSurface(compact: false).aspectRatio(1, contentMode: .fit)
                        Text(photo.record?.lockedHint ?? "Discovery required").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                    }
                    HStack {
                        Button {if let previous=adjacent(photo.id,-1){openPhoto(previous)}} label:{
                            Label("Previous",systemImage:"chevron.left").frame(minHeight:44)
                        }.disabled(adjacent(photo.id,-1)==nil || photoPhase != .active)
                        Spacer()
                        if let index=shown.firstIndex(where:{$0.id==photo.id}) {
                            Text("\(index+1) of \(shown.count)").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {if let next=adjacent(photo.id,1){openPhoto(next)}} label:{
                            Label("Next",systemImage:"chevron.right").frame(minHeight:44)
                        }.disabled(adjacent(photo.id,1)==nil || photoPhase != .active)
                    }
                }.padding()
                }.navigationTitle(available(photo) && photoPhase == .active && photoEpoch==world.checkpointEpoch ? photo.title : "Locked photograph").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { selection = nil } } }
            }.environment(\.sendImageToLuma,{ asset in
                guard photoPhase == .active,photoEpoch == world.checkpointEpoch,
                      let handoff=LumaImageHandoff.make(asset,epoch:world.checkpointEpoch,in:world.state) else{return}
                pendingModalHandoff=handoff
                selection=nil
            }).preferredColorScheme(.dark)
        }
    }
    private func isFavorite(_ id: String) -> Bool { favorites.split(separator: "|").contains(Substring(id)) }
    private func toggle(_ id: String) {
        guard photoPhase == .active,NoraPhotoCatalog.library(world.state.flags,filter:.recovered).contains(where:{$0.id==id}) else{return}
        var ids = RelayCatalog.ids(favorites)
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        favorites = RelayCatalog.encoded(ids)
    }
}

enum LumaClockPolicy {
    static func duration(_ minutes:Int)->Int {min(60,max(1,minutes))*60}
    static func remaining(end:Double,now:Double,minutes:Int)->Int {
        guard end.isFinite,end>0,now.isFinite else{return duration(minutes)}
        return Int(ceil(min(3600,max(0,end-now))))
    }
    static func stopwatch(start:Double,elapsed:Double,now:Double)->Double {
        let base=elapsed.isFinite ? max(0,elapsed):0
        guard start.isFinite,start>0,now.isFinite else{return base}
        let total=base+max(0,now-start)
        return total.isFinite ? total:base
    }
}
private struct LabClockView: View {
    let onFinish: (Double) -> Void
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
                        Text(String(format: "%.1f", LumaClockPolicy.stopwatch(start:started,elapsed:elapsed,now:timestamp)))
                            .font(.system(size: 56, weight: .thin)).monospacedDigit()
                        Text("Seconds").font(.caption).foregroundColor(.secondary)
                        HStack {
                            Button("Reset") { started = 0; elapsed = 0 }.buttonStyle(.bordered)
                            Spacer()
                            Button(started > 0 ? "Stop" : "Start") {
                                let now = Date().timeIntervalSince1970
                                if started > 0 { elapsed = LumaClockPolicy.stopwatch(start:started,elapsed:elapsed,now:now); started = 0 }
                                else { started = now }
                            }.buttonStyle(.borderedProminent)
                        }
                    } else {
                        let remaining = LumaClockPolicy.remaining(end:timerEnd,now:timestamp,minutes:minutes)
                        ZStack {
                            Circle().stroke(.white.opacity(0.12), lineWidth: 7)
                            Circle().trim(from: 0, to: min(1, Double(remaining) / Double(LumaClockPolicy.duration(minutes))))
                                .stroke(Color.teal, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
                            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                                .font(.system(size: 47, weight: .light)).monospacedDigit()
                        }.frame(width: 210, height: 210)
                        if timerEnd == 0 {
                            Stepper("\(minutes) minutes", value: $minutes, in: 1...60)
                            Button("Start timer") { timerEnd = Date().timeIntervalSince1970 + Double(LumaClockPolicy.duration(minutes)) }.buttonStyle(.borderedProminent)
                        } else {
                            if remaining == 0 { Text("Timer finished").font(.headline).foregroundColor(.teal) }
                            Button(remaining == 0 ? "Done" : "Cancel timer") {
                                let now = Date().timeIntervalSince1970
                                if timerEnd <= now { onFinish(now) }
                                timerEnd = 0
                            }.buttonStyle(.bordered)
                        }
                        Text("In-phone timer • No real alarm is scheduled").font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.padding(20).background(Night.background.ignoresSafeArea()).navigationTitle("Clock")
        .onAppear {
            minutes=min(60,max(1,minutes))
            if !timerEnd.isFinite || timerEnd<0 {timerEnd=0}
            if !started.isFinite || started<0 {started=0}
            if !elapsed.isFinite || elapsed<0 {elapsed=0}
        }
    }
}

/// Immediate-execution pocket calculator.
struct LumaCalculator {
    private(set) var display="0"
    private(set) var first:Double?
    private(set) var operation:String?
    private var replace=true
    private var repeatedOperation:String?
    private var repeatedOperand:Double?
    private static let operators=["÷","×","−","+"]
    private static func format(_ value:Double)->String {
        value == 0 ? "0":String(format:"%.10g",value)
    }
    private mutating func clear() {self=LumaCalculator()}
    private mutating func calculate(_ left:Double,_ op:String,_ right:Double)->String? {
        let result:Double
        switch op {
        case "+":result=left+right
        case "−":result=left-right
        case "×":result=left*right
        case "÷":result=right==0 ? .nan:left/right
        default:return nil
        }
        display=result.isFinite ? Self.format(result):"Error"
        let record=Self.format(left)+" "+op+" "+Self.format(right)+" = "+display
        if !result.isFinite {first=nil;operation=nil;repeatedOperation=nil;repeatedOperand=nil}
        replace=true
        return record
    }
    @discardableResult mutating func press(_ key:String)->String? {
        if key=="C" {clear();return nil}
        if display=="Error" {
            guard key=="." || (key.count==1 && "0123456789".contains(key)) else{return nil}
            clear()
        }
        if Self.operators.contains(key) {
            var record:String?
            if let first,let operation,!replace,let right=Double(display) {
                record=calculate(first,operation,right)
            }
            guard let value=Double(display),value.isFinite else{return record}
            first=value;operation=key;replace=true;repeatedOperation=nil;repeatedOperand=nil
            return record
        }
        if key=="=" {
            if let first,let operation,let right=Double(display) {
                let record=calculate(first,operation,right)
                if display != "Error" {repeatedOperation=operation;repeatedOperand=right}
                self.first=nil;self.operation=nil
                return record
            }
            if let left=Double(display),let op=repeatedOperation,let right=repeatedOperand {
                return calculate(left,op,right)
            }
            return nil
        }
        if key=="±" || key=="%" {
            guard let value=Double(display) else{return nil}
            let adjusted:Double
            if key=="±" {adjusted = -value}
            else if let first,let operation,["+", "−"].contains(operation),!replace {adjusted=first*(value/100)}
            else {adjusted=value/100}
            guard adjusted.isFinite else {clear();display="Error";return nil}
            display=Self.format(adjusted);replace=false
            repeatedOperation=nil;repeatedOperand=nil
            return nil
        }
        if key=="⌫" {
            guard !replace else{return nil}
            if display.contains("e") || display.contains("E") {display="0"}
            else {display.removeLast();if display.isEmpty || display=="-" {display="0"}}
            return nil
        }
        guard key=="." || (key.count==1 && "0123456789".contains(key)) else{return nil}
        if replace || display.contains("e") || display.contains("E") {
            display=key=="." ? "0.":key;replace=false
        } else if key != "." || !display.contains(".") {
            if display.count<16 {display=display=="0" && key != "." ? key:display+key}
        }
        repeatedOperation=nil;repeatedOperand=nil
        return nil
    }
}
private struct LabCalculatorView: View {
    @State private var calculator=LumaCalculator()
    let keys=["C","±","%","÷","7","8","9","×","4","5","6","−","1","2","3","+","0",".","⌫","="]
    @AppStorage("lastseen.lab.calculatorHistory") private var storedHistory=""
    private var history:[String]{storedHistory.split(separator:"\n").map(String.init)}
    @State private var showHistory=false
    @State private var confirmClear=false
    var body:some View {
        GeometryReader { geometry in
            VStack(spacing:10) {
                Spacer(minLength:0)
                if let op=calculator.operation,let left=calculator.first {
                    Text(String(format:"%.10g",left)+" "+op).font(.title3).foregroundColor(.secondary)
                        .frame(maxWidth:.infinity,alignment:.trailing)
                }
                Text(calculator.display).font(.system(size:52,weight:.light)).lineLimit(1).minimumScaleFactor(0.3)
                    .frame(maxWidth:.infinity,alignment:.trailing).padding(8).accessibilityLabel("Result "+calculator.display)
                LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:8) {
                    ForEach(keys,id:\.self) {key in
                        Button {
                            if let record=calculator.press(key) {
                                storedHistory=([record]+history).prefix(30).joined(separator:"\n")
                            }
                        } label:{
                            Text(key).font(.system(size:27,weight:.medium)).frame(maxWidth:.infinity)
                                .frame(height:max(44,min(65,(geometry.size.height-105)/5-8)))
                                .background(["÷","×","−","+","="].contains(key) ? Color.orange:Color.gray.opacity(0.24),in:Capsule())
                        }.buttonStyle(.plain).accessibilityLabel(key=="⌫" ? "Delete digit":key)
                    }
                }
            }.padding()
        }.background(Night.background.ignoresSafeArea()).navigationTitle("Calculator")
        .toolbar {ToolbarItem(placement:.navigationBarTrailing){Button{showHistory=true}label:{Image(systemName:"clock.arrow.circlepath").accessibilityLabel("Calculation history")}}}
        .sheet(isPresented:$showHistory) {
            NavigationStack {
                List {
                    ForEach(Array(history.enumerated()),id:\.offset){item in Text(item.element).textSelection(.enabled)}
                    if history.isEmpty {Text("No calculations yet").foregroundColor(.secondary)}
                }.navigationTitle("History").toolbar {
                    ToolbarItem(placement:.cancellationAction){Button("Done"){showHistory=false}}
                    ToolbarItem(placement:.navigationBarTrailing){Button("Clear",role:.destructive){confirmClear=true}.disabled(history.isEmpty)}
                }.confirmationDialog("Clear calculation history?",isPresented:$confirmClear){
                    Button("Clear history",role:.destructive){storedHistory=""}
                }
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
    private var query:String {search.trimmingCharacters(in:.whitespacesAndNewlines)}
    var body: some View {
        List {
            LumaHeader(title: "On this phone", detail: "\(documents.count + WorldDocumentCatalog.visible(world.state).count) restored documents", symbol: "folder.fill").listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            NavigationLink { ProtectedAreaView(area: .files) } label: { Label("Protected files", systemImage: "lock.doc") }
            let references = VeilReferences.visible(world.state).filter { query.isEmpty || $0.filename.localizedCaseInsensitiveContains(query) }
            if !references.isEmpty {
                Section("Recovered bookmarks") {
                    ForEach(references) { ref in
                        NavigationLink { VeilReferenceReader(id:ref.id) } label: {
                            Label(ref.filename,systemImage:"doc.badge.ellipsis").font(.headline)
                        }
                    }
                }
            }
            let records = WorldDocumentCatalog.search(query,world:world.state)
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
            let publicNames=documents.keys.sorted().filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) || (documents[$0]?.localizedCaseInsensitiveContains(query) ?? false) }
            if references.isEmpty && records.isEmpty && publicNames.isEmpty {
                Text("No matching documents").foregroundColor(.secondary)
            }
            Section("Public files") {
            ForEach(publicNames, id: \.self) { name in
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
            }
        }.scrollContentBackground(.hidden).background(Night.background.ignoresSafeArea()).navigationTitle("Files").searchable(text: $search,prompt:"Search accessible files")
    }
}


enum LumaSettingsPolicy {
    static func hidesMessagePreviews(preference:Bool,biometrics:Bool,shield:Bool)->Bool {
        preference || biometrics || shield
    }
    static func clampedBrightness(_ value:Double)->Double {
        guard value.isFinite else{return 0.9}
        return min(1,max(0.35,value))
    }
    static func displayDimming(_ value:Double)->Double {
        (1-clampedBrightness(value))*0.75
    }
}
