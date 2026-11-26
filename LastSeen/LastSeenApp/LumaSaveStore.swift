import Foundation
import SwiftUI

struct LumaCheckpoint: Codable {
    let version: Int
    let date: Date
    let playSeconds: Int
    var world: PhoneWorld
    let preferences: Data
}
@MainActor
final class LumaSaveStore: ObservableObject {
    static let keys = [
        "lastseen.lab.wallpaper","lastseen.lab.lockWallpaper","lastseen.lab.wallpaperBlur","lastseen.lab.lightAppearance",
        "lastseen.lab.messageSound","lastseen.lab.messageHaptics","lastseen.lab.horrorEffects","lastseen.lab.atmosphereIntensity","lastseen.recovery.effects",
        "lastseen.lab.hideLockPreviews","lastseen.lab.brightness","lastseen.lab.wifi","lastseen.lab.deferSystemEdges",
        "lastseen.lab.favoritePhotos","lastseen.lab.stopwatchStart","lastseen.lab.stopwatchElapsed","lastseen.lab.timerEnd",
        "lastseen.lab.timerMinutes","lastseen.lab.timerFeedbackDelivered","lastseen.lab.history","lastseen.lab.browserVisitLog","lastseen.lab.bookmarks","lastseen.lab.browserSeeded",
        "lastseen.lab.calculatorHistory","lastseen.lab.browserPage","lastseen.lab.browserForward","lastseen.lab.browserBackStack","lastseen.lab.browserForwardStack",
        "lastseen.restored.mail.read","lastseen.setup.device","lastseen.relay.installed","lastseen.relay.versions",
        "lastseen.relay.sources","lastseen.relay.history","lastseen.relay.wishlist","lastseen.relay.lastRefresh","lastseen.relay.safeMode","lastseen.relay.compactIcons","lastseen.relay.tealTheme",
        "lastseen.support.useOnDeviceAI","lastseen.assistant.readAloud","lastseen.assistant.interpretOnDevice","lastseen.veil.security",
        "lastseen.utility.small","lastseen.utility.five","lastseen.utility.labels","lastseen.utility.glass","lastseen.utility.theme","lastseen.utility.shortcuts"
    ]
    static let manual = (1...3).map { "manual-\($0)" }
    static let automatic = (1...3).map { "auto-\($0)" }
    let root: URL
    let defaults: UserDefaults
    @Published private(set) var slots: [String: LumaCheckpoint] = [:]
    @Published private(set) var invalid: Set<String> = []
    @Published private(set) var notice = ""
    @Published private(set) var playSeconds = 0
    @Published private(set) var lifetimeSeconds = 0
    @Published private(set) var sessionSeconds = 0
    @Published private(set) var lastSuccessfulAutomatic: Date?
    @Published private(set) var automaticFailed = false
    private var lastAutomatic: Date = .distantPast
    private var lastAutoAttempt: Date = .distantPast
    private var sinceAutomatic = 0
    private var previousInterval: Int?
    static let manualCooldown: TimeInterval = 60
    private var lastManual: Date { defaults.object(forKey: "lastseen.saves.lastManual") as? Date ?? .distantPast }
    func canSaveManually(now: Date = Date()) -> Bool { now.timeIntervalSince(lastManual) >= Self.manualCooldown }
    func manualRemaining(now: Date = Date()) -> Int { max(0, min(Int(Self.manualCooldown), Int(ceil(Self.manualCooldown - now.timeIntervalSince(lastManual))))) }
    func persistPlayTime() {
        defaults.set(playSeconds, forKey: "lastseen.saves.playSeconds")
        defaults.set(lifetimeSeconds, forKey: "lastseen.saves.lifetimeSeconds")
    }
    func nextAutomaticSeconds(interval: Int) -> Int? {
        guard [1,3,5,10].contains(interval) else { return nil }
        return max(0, interval * 60 - (previousInterval == interval ? sinceAutomatic : 0))
    }
    static func duration(_ seconds: Int) -> String {
        let s = max(0,seconds)
        return String(format:"%02d:%02d:%02d",s/3600,(s/60)%60,s%60)
    }
    @discardableResult
    func writeManual(_ slot: String, world: PhoneWorld, now: Date = Date()) -> Bool {
        guard Self.manual.contains(slot), canSaveManually(now: now) else { notice = "Manual save is cooling down."; return false }
        guard write(slot, world: world, now: now) else { return false }
        defaults.set(now, forKey: "lastseen.saves.lastManual")
        return true
    }
    init(root: URL? = nil, defaults: UserDefaults = .standard) {
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LastSeenCheckpoints", isDirectory: true)
        self.defaults = defaults
        playSeconds = max(0, defaults.integer(forKey: "lastseen.saves.playSeconds"))
        lifetimeSeconds = max(playSeconds, defaults.integer(forKey:"lastseen.saves.lifetimeSeconds"))
        refresh()
        lastSuccessfulAutomatic = defaults.object(forKey:"lastseen.saves.lastSuccessfulAutomatic") as? Date
        if let latest = Self.automatic.compactMap({ slots[$0]?.date }).max(),
           lastSuccessfulAutomatic == nil || latest > lastSuccessfulAutomatic! { lastSuccessfulAutomatic = latest }
        if let last = lastSuccessfulAutomatic { lastAutomatic = last }
        persistPlayTime()
    }
    private func url(_ slot: String) -> URL { root.appendingPathComponent(slot + ".json") }
    private func validSlot(_ slot: String) -> Bool { (Self.manual + Self.automatic).contains(slot) }
    func read(_ slot: String) throws -> LumaCheckpoint {
        guard validSlot(slot) else { throw CocoaError(.fileReadCorruptFile) }
        let value = try JSONDecoder().decode(LumaCheckpoint.self, from: Data(contentsOf: url(slot)))
        guard value.version == 1, value.world.version == 1, value.playSeconds >= 0 else { throw CocoaError(.fileReadCorruptFile) }
        _ = try preferences(value)
        return value
    }
    private func preferences(_ value: LumaCheckpoint) throws -> [String: Any] {
        guard let result = try PropertyListSerialization.propertyList(from: value.preferences, format: nil) as? [String: Any],
              Set(result.keys).isSubset(of: Set(Self.keys)),
              result.values.allSatisfy({ value in
                  if let number=value as? NSNumber {return number.doubleValue.isFinite}
                  return value is String
              }) else { throw CocoaError(.fileReadCorruptFile) }
        return result
    }
    func refresh() {
        var found: [String: LumaCheckpoint] = [:]; var damaged: Set<String> = []
        for slot in Self.manual + Self.automatic where FileManager.default.fileExists(atPath: url(slot).path) {
            do { found[slot] = try read(slot) } catch { damaged.insert(slot) }
        }
        slots = found; invalid = damaged
    }
    @discardableResult
    func write(_ slot: String, world: PhoneWorld, now: Date = Date(), quiet: Bool = false) -> Bool {
        guard validSlot(slot) else { return false }
        do {
            let prefs = Dictionary(uniqueKeysWithValues: Self.keys.compactMap { key in defaults.object(forKey: key).map { (key, $0) } })
            let bytes = try PropertyListSerialization.data(fromPropertyList: prefs, format: .binary, options: 0)
            let value = LumaCheckpoint(version: 1, date: now, playSeconds: playSeconds, world: world, preferences: bytes)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            try JSONEncoder().encode(value).write(to: url(slot), options: .atomic)
            refresh()
            persistPlayTime()
            if !quiet { notice = "Game saved." }
            return true
        } catch { notice = "Could not save. Existing checkpoints were preserved."; return false }
    }
    func automatic(world: PhoneWorld, now: Date = Date(), force: Bool = false) {
        guard force || (now.timeIntervalSince(lastAutomatic) >= 30 && now.timeIntervalSince(lastAutoAttempt) >= 5) else { return }
        lastAutoAttempt = now
        let slot = Self.automatic.first(where: { slots[$0] == nil }) ??
            Self.automatic.min(by: { (slots[$0]?.date ?? .distantPast) < (slots[$1]?.date ?? .distantPast) })!
        if write(slot, world: world, now: now, quiet: true) {
            lastAutomatic = now; sinceAutomatic = 0
            lastSuccessfulAutomatic = now
            defaults.set(now,forKey:"lastseen.saves.lastSuccessfulAutomatic")
            automaticFailed = false
        } else { automaticFailed = true }
    }
    func tick(world: PhoneWorld, minutes: Int, now: Date = Date()) {
        playSeconds += 1
        lifetimeSeconds += 1
        sessionSeconds += 1
        persistPlayTime()
        if previousInterval != minutes { sinceAutomatic = 0; previousInterval = minutes; automaticFailed = false }
        guard [1,3,5,10].contains(minutes) else { return }
        sinceAutomatic += 1
        if sinceAutomatic >= minutes * 60 { automatic(world: world, now:now) }
    }
    static func rebasedEvent(_ event:HavenWatchEvent?,by delta:TimeInterval)->HavenWatchEvent? {
        guard let event,!event.delivered,delta.isFinite else{return event}
        return HavenWatchEvent(id:event.id,due:event.due.addingTimeInterval(delta),delivered:false)
    }
    func restore(_ slot: String, into world: PhoneWorldStore, now: Date = Date()) -> Bool {
        do {
            var value = try read(slot)
            var prefs = try preferences(value)
            // Preserve time remaining in fictional timers and pending conversations.
            let delta = now.timeIntervalSince(value.date)
            guard delta.isFinite else{throw CocoaError(.fileReadCorruptFile)}
            value.world.pendingReplies = value.world.pendingReplies?.map {
                PhonePendingReply(id: $0.id, outgoingID: $0.outgoingID, neighbor: $0.neighbor, text: $0.text,
                    readAt: $0.readAt.addingTimeInterval(delta), dueAt: $0.dueAt.addingTimeInterval(delta), startsTutorial: $0.startsTutorial, typingAt: $0.typingAt?.addingTimeInterval(delta))
            }
            if var connected=value.world.connectedWorld {
                connected.characterCheckIns=CharacterCheckIns.rebase(connected.characterCheckIns,by:delta)
                connected.havenEvent=Self.rebasedEvent(connected.havenEvent,by:delta)
                connected.havenFollowupEvent=Self.rebasedEvent(connected.havenFollowupEvent,by:delta)
                connected.pendingMail=connected.pendingMail.map { pending in
                    let r=pending.record
                    let date=pending.dueAt.addingTimeInterval(delta)
                    return LumaPendingMail(record:LumaMailRecord(id:r.id,peer:r.peer,sender:r.sender,subject:r.subject,body:r.body,date:date,kind:r.kind,attachments:r.attachments),dueAt:date)
                }
                if var d = connected.dayblink {
                    d.pending = d.pending.map { event in
                        let r = event.record
                        let date = event.due.addingTimeInterval(delta)
                        return DayblinkPending(record: .init(id: r.id, friend: r.friend, sender: r.sender, text: r.text, date: date, image: r.image, temporary: r.temporary, alreadyExpired: r.alreadyExpired), due: date)
                    }
                    if let start = d.storyStart { d.storyStart = start.addingTimeInterval(delta) }
                    d.stories = d.stories?.map { story in
                        .init(id: story.id, friend: story.friend, caption: story.caption, image: story.image,
                              published: story.published.addingTimeInterval(delta), expires: story.expires.addingTimeInterval(delta), expired: story.expired || story.expires <= value.date)
                    }
                    connected.dayblink = d
                }
                if var community = connected.communityActivity {
                    community.start = community.start.addingTimeInterval(delta)
                    connected.communityActivity = community
                }
                connected.pendingSocialReplies = connected.pendingSocialReplies?.map { pending in
                    let r = pending.reply
                    let due = pending.dueAt.addingTimeInterval(delta)
                    return .init(channel: pending.channel, reply: .init(id: r.id, postID: r.postID, author: r.author, body: r.body, date: due), dueAt: due)
                }
                if let start = connected.motionwell?.publicationStart {
                    connected.motionwell?.publicationStart = start.addingTimeInterval(delta)
                }
                value.world.connectedWorld=connected
            }
            let timerKey = "lastseen.lab.timerEnd"
            let deliveredKey = "lastseen.lab.timerFeedbackDelivered"
            if let old = prefs[timerKey] as? NSNumber {
                let end = old.doubleValue
                prefs[timerKey] = LumaTimerCompletion.restoredDeadline(end, savedAt: value.date.timeIntervalSince1970, now: now.timeIntervalSince1970)
                if end > value.date.timeIntervalSince1970 {
                    // This timer was running in the snapshot, regardless of later live state.
                    prefs.removeValue(forKey: deliveredKey)
                } else if end > 0, (value.world.connectedWorld?.activityJournal ?? []).contains(where: { $0.id == "timer-" + String(end) }) {
                    // Includes dismissed history and checkpoints predating the marker.
                    prefs[deliveredKey] = end
                }
            } else {
                prefs.removeValue(forKey: deliveredKey)
            }
            if let old = prefs["lastseen.lab.stopwatchStart"] as? NSNumber, old.doubleValue > 0 {
                prefs["lastseen.lab.stopwatchStart"] = old.doubleValue + delta
            }
            // Validate before touching the active world. Security enrollment is not restored.
            try world.restoreCheckpoint(value.world)
            for key in Self.keys {
                if let object = prefs[key] { defaults.set(object, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
            defaults.set(false, forKey: "lastseen.security.ownerVerified")
            defaults.set(false, forKey: "lastseen.security.appearanceEnrolled")
            playSeconds = value.playSeconds; sinceAutomatic = 0
            persistPlayTime()
            automaticFailed = false
            lastAutomatic = now
            notice = "Checkpoint restored."
            return true
        } catch { notice = "Checkpoint could not be loaded. Current game was kept."; return false }
    }
    func remove(_ slot: String) {
        guard validSlot(slot) else { return }
        do { try FileManager.default.removeItem(at: url(slot)); refresh(); notice = "Checkpoint removed." }
        catch { notice = "Could not remove checkpoint." }
    }
}

struct LumaSaveView: View {
    @ObservedObject var store: LumaSaveStore
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.saves.interval") private var interval = 5
    let onLoad: (String) -> Void
    @State private var action: String?
    @State private var slot = ""
    @State private var confirm = false
    @State private var selectedDate:Date?
    @State private var selectedInvalid=false
    @State private var selectionNotice=""
    @Environment(\.scenePhase) private var phase
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 15) {
                    Image("Icon_Save").resizable().scaledToFit().frame(width: 74, height: 74).clipShape(RoundedRectangle(cornerRadius: 19))
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Game Saves").font(.largeTitle.bold())
                        Text("Your investigation, preserved.").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                NavigationLink { LumaGameplayStatisticsView(store:store) } label: {
                    LumaHeader(title:"Gameplay Statistics",detail:"Live playtime and checkpoints",symbol:"chart.bar.xaxis")
                }.buttonStyle(.plain)
                Text("Manual checkpoints").font(.title2.bold())
                if !store.canSaveManually() { Text("Next manual save in \(store.manualRemaining()) seconds").font(.caption).foregroundColor(.secondary).monospacedDigit() }
                ForEach(LumaSaveStore.manual, id: \.self) { row($0, manual: true) }
                Text("Automatic checkpoints").font(.title2.bold())
                Picker("Autosave interval", selection: $interval) {
                    Text("Off").tag(0); Text("1 min").tag(1); Text("3 min").tag(3); Text("5 min").tag(5); Text("10 min").tag(10)
                }.pickerStyle(.segmented)
                Text("Automatic checkpoints are created only at the chosen active-play interval. Off creates none. Your live progress is still preserved. Manual saves share a one-minute cooldown.").font(.caption).foregroundColor(.secondary)
                ForEach(LumaSaveStore.automatic, id: \.self) { row($0, manual: false) }
                if !selectionNotice.isEmpty {Text(selectionNotice).font(.caption).foregroundColor(.secondary)}
                if !store.notice.isEmpty { Text(store.notice).font(.subheadline).foregroundColor(LumaDesign.accent).accessibilityAddTraits(.updatesFrequently) }
            }.padding(18)
        }.navigationTitle("Game Saves").navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Confirm \(action ?? "action")", isPresented: $confirm, titleVisibility: .visible) {
            Button(action ?? "Continue", role: action == "Delete" ? .destructive : nil) {
                guard phase == .active else{return}
                store.refresh()
                guard store.slots[slot]?.date == selectedDate,store.invalid.contains(slot)==selectedInvalid else {
                    selectionNotice="This checkpoint changed. Review the updated slot and try again."
                    return
                }
                selectionNotice=""
                switch action {
                case "Save": _ = store.writeManual(slot, world: world.state)
                case "Load": onLoad(slot)
                case "Delete": store.remove(slot)
                default: break
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(action == "Load" ? "Return to this checkpoint? Later discoveries may be lost from the active game. Manual saves and personal Field Notes are kept." : "Only the selected checkpoint is affected.")
        }
        .onAppear { store.refresh() }
        .onChange(of:phase){if $0 != .active {confirm=false;action=nil;slot=""} else {store.refresh()}}
    }
    private func choose(_ operation:String,_ id:String) {
        guard phase == .active else{return}
        action=operation;slot=id;selectedDate=store.slots[id]?.date;selectedInvalid=store.invalid.contains(id)
        selectionNotice="";confirm=true
    }
    private func row(_ id: String, manual: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: manual ? "archivebox" : "clock.arrow.circlepath").foregroundColor(LumaDesign.accent)
                Text((manual ? "Save " : "Checkpoint ") + String(id.suffix(1))).font(.headline)
                Spacer()
                if let saved = store.slots[id] {
                    Text(saved.date, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundColor(.secondary)
                } else { Text(store.invalid.contains(id) ? "Unreadable" : "Empty").font(.caption).foregroundColor(.secondary) }
            }
            if let saved = store.slots[id] { Text("\(saved.playSeconds / 60) minutes played").font(.caption).foregroundColor(.secondary) }
            HStack {
                if manual {
                    Button("Save Now") {
                        guard phase == .active else{return}
                        if store.slots[id] != nil || store.invalid.contains(id) { choose("Save", id) }
                        else { _ = store.writeManual(id, world: world.state) }
                    }.buttonStyle(.borderedProminent).frame(minHeight: 44)
                    .disabled(!store.canSaveManually()).accessibilityIdentifier("luma.save." + id)
                }
                if store.slots[id] != nil { Button("Load") { choose("Load", id) }.buttonStyle(.bordered).frame(minHeight: 44).accessibilityIdentifier("luma.load." + id) }
                Spacer()
                if store.slots[id] != nil || store.invalid.contains(id) {
                    Button(role: .destructive) { choose("Delete", id) } label: { Image(systemName: "trash").frame(width: 44, height: 44) }.accessibilityLabel("Delete checkpoint")
                }
            }
        }.padding(15).lumaSurface()
    }
}
