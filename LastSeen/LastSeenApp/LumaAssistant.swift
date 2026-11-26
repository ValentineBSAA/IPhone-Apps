import SwiftUI
import AVFoundation
import Combine

struct LumaAssistantContext {
    let world: PhoneWorld
    let availableApps: Set<LabApp>
    let wifi: Bool
    let sound: Bool
    let haptics: Bool
    let safeMode: Bool
    let installedCount: Int
    let timerEnd: Double
    let now: Date
}
struct LumaAssistantAnswer {
    let text: String
    let clipID: String
    var app: LabApp? = nil
}
/// Fixed recordings may only speak the exact canonical approved script.
enum LumaAssistantVoicePolicy {
    static let scripts: [String: String] = [
        "help": "I can open apps, check unread messages, tell you the time, or explain the phone's current settings.",
        "denied": "I can help with visible records and ordinary phone controls, but I can't do that.",
        "unavailable": "That application isn't available in the current phone environment.",
        "hint": "Review the records you already have access to, and keep track of what you've actually verified.",
        "progress": "You can review your completed steps in Settings. I won't reveal undiscovered records or answers.",
        "clarify": "I'm not sure what you mean. Try asking me to open an app or check unread messages."
    ]
    static func recordingID(for answer: LumaAssistantAnswer) -> String? {
        guard let script = scripts[answer.clipID], script == answer.text else { return nil }
        return answer.clipID
    }
}

enum LumaAssistantPolicy {
    static func normalize(_ text: String) -> String {
        text.lowercased().split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
    }
    static func answer(_ raw: String, context c: LumaAssistantContext) -> LumaAssistantAnswer {
        let text = normalize(raw)
        let words = Set(text.split(separator: " ").map(String.init))
        let denied: Set<String> = ["passcode","password","pin","unlock","identity","secret","spoiler","ending","delete","erase","reset","install","uninstall","send","call","location","track","microphone","camera"]
        if !words.isDisjoint(with: denied) {
            return .init(text: "I can help with visible records and ordinary phone controls, but I can't do that.", clipID: "denied")
        }
        if text.hasPrefix("open ") || text.hasPrefix("show ") {
            let name = String(text.dropFirst(5))
            let aliases: [String: LabApp] = ["texts": .messages, "email": .mail, "emails": .mail, "pictures": .photos, "memos": .voiceMemos, "recordings": .voiceMemos, "videos": .motionwell, "security cameras": .havenWatch, "dark web": .veil, "anonymous browser": .veil, "tor browser": .veil]
            if let app = aliases[name] ?? LabApp.allCases.first(where: { normalize($0.rawValue) == name }) {
                guard c.availableApps.contains(app), app != .assistant else {
                    return .init(text: "That application isn't available in the current phone environment.", clipID: "unavailable")
                }
                return .init(text: "I can open " + app.rawValue + " for you.", clipID: "open", app: app)
            }
        }
        switch text {
        case "hello", "hi", "hey", "help", "what can you do":
            return .init(text: "I can open apps, check unread messages, tell you the time, or explain the phone's current settings.", clipID: "help")
        case "unread", "unread messages", "how many unread messages", "check messages":
            let count = Neighbor.visible(in: c.world).reduce(0) { total, neighbor in
                total + (c.world.threads[neighbor.id] ?? []).filter { !$0.fromPlayer && !$0.read }.count
            }
            return .init(text: "You have \(count) unread messages.", clipID: "unread")
        case "time", "what time is it", "current time":
            return .init(text: "The phone clock reads " + c.now.formatted(date: .omitted, time: .shortened) + ".", clipID: "time")
        case "calendar", "next event", "what is on my calendar", "upcoming event":
            let next = c.world.events.filter { $0.endsAt >= c.now }.sorted { $0.startsAt < $1.startsAt }.first
            return .init(text: next.map { "Next calendar item: " + $0.title + ", " + $0.startsAt.formatted(date: .abbreviated, time: .shortened) + "." } ?? "There are no upcoming calendar items.", clipID: "calendar")
        case "timer", "timer status", "how much time is left":
            let remaining = max(0, c.timerEnd - c.now.timeIntervalSince1970)
            if !remaining.isFinite || remaining <= 0 { return .init(text: "No timer is currently running.", clipID: "timer") }
            let seconds = Int(min(remaining.rounded(.up), 86400))
            return .init(text: "The timer has \(seconds / 60) minutes and \(seconds % 60) seconds remaining.", clipID: "timer")
        case "settings", "phone settings", "wifi", "wi fi", "sound", "haptics":
            return .init(text: "Simulated Wi-Fi is \(c.wifi ? "on" : "off"). Phone sounds are \(c.sound ? "on" : "off"), and haptics are \(c.haptics ? "on" : "off").", clipID: "settings")
        case "package status", "relay status", "patchline status", "safe mode":
            return .init(text: "The phone is in \(c.safeMode ? "Safe Mode" : "its simulated rootless environment"). There are \(c.installedCount) entries in the local installed-package list.", clipID: "packages")
        case "progress", "investigation progress":
            return .init(text: "You can review your completed steps in Settings. I won't reveal undiscovered records or answers.", clipID: "progress")
        case "hint", "help me investigate", "what should i do":
            return .init(text: "Review the records you already have access to, and keep track of what you've actually verified.", clipID: "hint")
        default:
            return .init(text: "I'm not sure what you mean. Try asking me to open an app or check unread messages.", clipID: "clarify")
        }
    }
}
struct LumaAssistantView: View {
    let context: () -> LumaAssistantContext
    let openApp: (LabApp) -> Void
    let acknowledgeBoundaries: () -> Void
    let rememberSession: (LumaAssistantSession?) -> Void
    var takeImageHandoff: () -> String? = {nil}
    @State private var previousMemoryID: String?
    @State private var recollectionCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.lab.messageSound") private var sound = true
    @State private var input = ""
    @State private var evidenceID: String?
    @State private var lastAccess: LumaAssistantAccessSnapshot?
    private var accessSnapshot: LumaAssistantAccessSnapshot { .init(context().world) }
    @State private var imageScan:Task<Void,Never>?
    @State private var imageScanID=UUID()
    @State private var imageReport:LumaImageAnalysisReport?
    @State private var imageScanNotice=""
    @AppStorage("lastseen.veil.security") private var imageSecurity="Standard"
    @State private var showEvidence = false
    @State private var evidenceSearch = ""
    @State private var conversationTopic: LumaConversationTopic?
    @State private var conversationTurns: [String] = []
    @State private var interpretation: Task<Void,Never>?
    @State private var requestID = UUID()
    @AppStorage("lastseen.assistant.interpretOnDevice") private var interpretOnDevice = true
    @State private var answer = LumaAssistantAnswer(text: "What can I help you with?", clipID: "greeting")
    @State private var player: AVAudioPlayer?
    @StateObject private var readAloud = LumaReadAloud()
    @State private var audioOwner = UUID()
    @State private var voiceSource: String?
    @AppStorage("lastseen.assistant.readAloud") private var spokenResponses = false
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    private func stopAudio() {
        player?.stop(); player = nil
        PhoneSensoryEngine.endMediaAudio(audioOwner)
        readAloud.stop()
        voiceSource = nil
    }
    private func speakCurrentAnswer() {
        stopAudio()
        guard sound, spokenResponses, phase == .active else { return }
        if let clipID = LumaAssistantVoicePolicy.recordingID(for: answer),
           let url = Bundle.main.url(forResource: "LumaAssistant_" + clipID, withExtension: "m4a"),
           let audio = try? AVAudioPlayer(contentsOf: url),
           audio.duration.isFinite, audio.duration > 0 {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default)
                try session.setActive(true)
                audio.numberOfLoops = 0
                audio.prepareToPlay()
                PhoneSensoryEngine.beginMediaAudio(audioOwner)
                if audio.play() {
                    player = audio
                    voiceSource = "Recorded Luma response"
                    return
                }
                PhoneSensoryEngine.endMediaAudio(audioOwner)
            } catch {
                PhoneSensoryEngine.endMediaAudio(audioOwner)
            }
        }
        readAloud.speak(answer.text)
        if readAloud.active { voiceSource = "iPhone system read-aloud" }
    }
    private func resumeSession() {
        let world = context().world
        let session = LumaAssistantSession.validated(world.connectedWorld?.assistantSession,in:world)
        conversationTopic = session?.topic
        previousMemoryID = session?.memoryID
        recollectionCount = session?.recollectionCount ?? 0
        answer = .init(text:LumaAssistantSession.resumePrompt(session,world:world),clipID:"conversation")
    }
    private func cancelImageScan() {
        imageScan?.cancel();imageScan=nil;imageScanID=UUID()
        imageReport=nil;imageScanNotice=""
    }
    private func startImageScan(_ recordID:String) {
        guard phase == .active,recordID==evidenceID,recordID.hasPrefix("image:") else{return}
        let asset=String(recordID.dropFirst(6))
        guard LumaImageAnalysis.permitted(asset,world:context().world,security:imageSecurity) else{return}
        cancelImageScan();stopAudio()
        interpretation?.cancel();interpretation=nil;requestID=UUID()
        let id=UUID();imageScanID=id
        imageScan=Task { @MainActor in
            let result=await LumaImageAnalysis.scan(asset,world:context().world,security:imageSecurity)
            guard !Task.isCancelled,imageScanID==id,phase == .active,evidenceID==recordID else{return}
            imageScan=nil
            guard let result=LumaImageAnalysis.verified(result,recordID:recordID,world:context().world,security:imageSecurity),
                  let record=LumaAssistantEvidence.selected(recordID,in:context().world) else {
                imageScanNotice="The original could not be analyzed, or is no longer available. You can still discuss the record."
                return
            }
            imageReport=result
            accept("Analyze the original image on this device.",.init(topic:.pictures,answer:.init(text:LumaAssistantEvidence.response("Analyze the original image",record:record,visual:result),clipID:"conversation")))
        }
    }
    private func receiveImageHandoff() {
        guard phase == .active,let asset=takeImageHandoff(),
              RecoveredImageAnalysis.record(asset,in:context().world) != nil,
              let record=LumaAssistantEvidence.selected("image:"+asset,in:context().world) else{return}
        stopAudio()
        cancelImageScan()
        interpretation?.cancel();interpretation=nil;requestID=UUID()
        evidenceID=record.id
        accept("Please analyze this image.",.init(topic:.pictures,answer:.init(text:LumaAssistantEvidence.response("Please analyze this image.",record:record),clipID:"conversation")))
    }
    /// Discard transient conversation and queued work without mutating the
    /// newly restored checkpoint or granting any new access.
    private func clearTransientContext() {
        stopAudio()
        cancelImageScan()
        interpretation?.cancel(); interpretation = nil; requestID = UUID()
        evidenceID = nil; conversationTurns = []; conversationTopic = nil
        previousMemoryID = nil; recollectionCount = 0
        input = ""; focused = false; showEvidence = false
        answer = .init(text: LumaAssistantTrust.greeting(context().world), clipID: "conversation")
    }
    private func clearSession() {
        stopAudio(); interpretation?.cancel(); interpretation = nil; requestID = UUID()
        cancelImageScan()
        rememberSession(nil); evidenceID = nil; conversationTurns = []; conversationTopic = nil
        input="";focused=false;showEvidence=false;evidenceSearch=""
        previousMemoryID = nil; recollectionCount = 0
        answer = .init(text:LumaAssistantTrust.greeting(context().world),clipID:"conversation")
    }
    @State private var glow = false
    @FocusState private var focused: Bool
    private func submit(_ text: String) {
        guard phase == .active,!text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,text.count<=600 else{return}
        let access = accessSnapshot
        if let lastAccess, access.revokes(lastAccess) { clearTransientContext() }
        lastAccess = access
        stopAudio()
        interpretation?.cancel(); interpretation = nil
        if LumaAssistantTrust.acknowledgesBoundaries(text) { acknowledgeBoundaries() }
        let id = UUID(); requestID = id
        if imageScan != nil {cancelImageScan()}
        let current = context()
        let previous = conversationTopic
        let known = LumaAssistantConversation.topic(text,previous:previous)
        let initial = LumaAssistantConversation.reply(text,context:current,previous:previous,previousMemoryID:previousMemoryID,recollectionCount:recollectionCount,evidenceID:evidenceID,visualReport:imageReport,imageSecurity:imageSecurity)
        input = ""; focused = false
        if known == nil, initial.topic == .general, initial.answer.clipID == "conversation", interpretOnDevice, LumaIntentInterpreter.available {
            interpretation = Task { @MainActor in
                let inferred = await LumaIntentInterpreter.interpret(text,previous:previous)
                guard !Task.isCancelled,requestID==id,phase == .active else{return}
                guard !accessSnapshot.revokes(access) else {clearTransientContext();lastAccess=accessSnapshot;return}
                accept(text,LumaAssistantConversation.reply(text,context:context(),previous:previous,interpreted:inferred,previousMemoryID:previousMemoryID,recollectionCount:recollectionCount,evidenceID:evidenceID,visualReport:imageReport,imageSecurity:imageSecurity))
                interpretation = nil
            }
        } else { accept(text,initial) }
    }
    private func accept(_ question:String,_ reply:LumaConversationReply) {
        guard phase == .active else{return}
        conversationTopic = reply.topic
        previousMemoryID = reply.memoryID
        recollectionCount = reply.recollectionCount
        if reply.answer.clipID == "conversation" && reply.topic != .general {
            rememberSession(LumaAssistantSession.from(reply,in:context().world))
        }
        conversationTurns.append("You: " + question)
        conversationTurns.append("Luma: " + reply.answer.text)
        conversationTurns = Array(conversationTurns.suffix(12))
        answer = reply.answer
        speakCurrentAnswer()
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(Color.teal.opacity(0.18)).frame(width: 146, height: 146).scaleEffect(glow && !reduceMotion ? 1.08 : 1)
                    Circle().fill(RadialGradient(colors: [.white, .cyan, .indigo, .black], center: .init(x: 0.35, y: 0.3), startRadius: 2, endRadius: 87)).frame(width: 114, height: 114)
                    Image(systemName: "waveform").font(.system(size: 35, weight: .light)).foregroundColor(.white)
                }.accessibilityHidden(true)
                Text("Luma Assistant").font(.title.bold())
                if !context().world.flags.contains(LumaAssistantTrust.acknowledgement) {
                    Button("I understand Nora's privacy matters") {
                        submit("I understand her privacy matters")
                    }.font(.footnote).buttonStyle(.bordered)
                }
                Text(answer.text).font(.title3).multilineTextAlignment(.center).accessibilityIdentifier("luma.assistant.answer")
                    .frame(maxWidth: .infinity).padding(18).lumaSurface()
                if conversationTurns.count > 2 {
                    DisclosureGroup("Recent conversation") {
                        ForEach(conversationTurns.indices.dropLast(2),id: \.self) { i in
                            Text(conversationTurns[i]).font(.subheadline).frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,4)
                        }
                    }
                }
                if interpretation != nil {
                    HStack {
                        ProgressView("Considering your question").font(.caption)
                        Button("Cancel"){interpretation?.cancel();interpretation=nil;requestID=UUID()}.font(.caption)
                    }
                }
                if let app = answer.app {
                    Button("Open " + app.rawValue) {
                        guard context().availableApps.contains(app) else { return }
                        stopAudio(); openApp(app)
                    }.buttonStyle(.borderedProminent).tint(.teal)
                }
                if let source = LumaAssistantEvidence.selected(evidenceID,in:context().world) {
                    HStack {
                        Label(source.title,systemImage:"doc.text.magnifyingglass").font(.caption).lineLimit(2)
                        Spacer()
                        Button {
                            stopAudio(); cancelImageScan()
                            interpretation?.cancel(); interpretation = nil; requestID = UUID()
                            evidenceID = nil
                        } label: { Image(systemName:"xmark.circle.fill").accessibilityLabel("Clear selected record") }
                    }.padding(10).lumaSurface(radius:12)
                    if source.kind == .image {
                        let asset=String(source.id.dropFirst(6))
                        if LumaImageAnalysis.permitted(asset,world:context().world,security:imageSecurity) {
                            if imageScan != nil {
                                ProgressView("Analyzing original locally")
                                Button("Cancel analysis"){cancelImageScan()}.font(.caption)
                            } else {
                                Button { startImageScan(source.id) } label: {
                                    Label("Analyze original on this device",systemImage:"viewfinder")
                                }.buttonStyle(.borderedProminent)
                            }
                            Text("Optional scan of original pixels only. No image leaves the device; reconstructed layers are excluded.").font(.caption).foregroundColor(.secondary)
                            if let report=LumaImageAnalysis.verified(imageReport,recordID:source.id,world:context().world,security:imageSecurity) {
                                DisclosureGroup("Original image scan"){Text(report.description).font(.subheadline)}
                            }
                        } else {Text("Image scanning is unavailable under the current security preference. Text discussion remains available.").font(.caption).foregroundColor(.secondary)}
                        if !imageScanNotice.isEmpty {Text(imageScanNotice).font(.caption)}
                    }
                }
                Button { evidenceSearch = ""; showEvidence = true } label: {
                    Label("Discuss an opened record",systemImage:"doc.text.magnifyingglass")
                }.buttonStyle(.bordered)
                if LumaAssistantEvidence.visible(context().world).count >= 2 {
                    NavigationLink { EvidenceComparisonView(initialRecordID:evidenceID) } label:{
                        Label("Compare two discoveries",systemImage:"arrow.left.arrow.right")
                    }.buttonStyle(.bordered)
                }
                HStack {
                    TextField("Ask Luma about what you found", text: $input).textFieldStyle(.roundedBorder).focused($focused)
                        .submitLabel(.go).onSubmit { submit(input) }
                    Button { submit(input) } label: { Image(systemName: "arrow.up.circle.fill").font(.title2) }
                        .accessibilityLabel("Ask").disabled(phase != .active || input.count>600 || input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                }
                if !input.isEmpty {Text("\(input.count) / 600").font(.caption2).foregroundColor(.secondary)}
                VStack(alignment: .leading, spacing: 10) {
                    Text("Try asking").font(.headline)
                    ForEach(["What was Nora like?", "What did she do for work?", "Open Messages", "Unread messages", "Next event", "Timer status", "Package status", "Hint"], id: \.self) { item in
                        Button { submit(item) } label: {
                            HStack { Text(item); Spacer(); Image(systemName: "chevron.right").font(.caption) }.padding(12).lumaSurface(radius: 12)
                        }.buttonStyle(.plain)
                    }
                }
                Button("Start a new conversation") { clearSession() }.font(.footnote)
                Toggle("Speak responses", isOn: $spokenResponses)
                if let voiceSource {
                    HStack {
                        Label(voiceSource, systemImage: "speaker.wave.2").font(.caption)
                        Spacer()
                        Button("Stop") { stopAudio() }.font(.caption)
                    }.padding(10).lumaSurface(radius: 12)
                }
                Toggle("On-device question interpretation",isOn:$interpretOnDevice)
                Text("When supported, the device model interprets unfamiliar wording. Answers remain limited to available records. No external AI requests.").font(.caption).foregroundColor(.secondary)
                Text("Optional iPhone system read-aloud or approved fixed recordings. No microphone listening.").font(.caption).foregroundColor(.secondary)
                if !readAloud.notice.isEmpty { Text(readAloud.notice).font(.caption).foregroundColor(.secondary) }
                Text("Local text commands · No microphone listening or real-device actions.").font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            }.padding(20)
        }.navigationTitle("Assistant").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented:$showEvidence) {
                NavigationStack {
                    List {
                        let records=LumaAssistantEvidence.search(evidenceSearch,in:context().world)
                        if records.isEmpty { Text("No matching opened records. Explore the phone first.").foregroundColor(.secondary) }
                        ForEach(records) { record in
                            Button {
                                guard phase == .active,LumaAssistantEvidence.selected(record.id,in:context().world) != nil else{return}
                                interpretation?.cancel(); interpretation = nil; requestID = UUID()
                                stopAudio(); cancelImageScan(); evidenceID = record.id; showEvidence = false
                            } label: { Text(record.title) }
                        }
                    }.navigationTitle("Opened records").searchable(text:$evidenceSearch)
                        .toolbar { ToolbarItem(placement:.cancellationAction) { Button("Cancel") { showEvidence = false } } }
                }
            }
            .onAppear { lastAccess = accessSnapshot; resumeSession(); receiveImageHandoff(); if !reduceMotion { withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { glow = true } } }
            .onChange(of:phase) {
                if $0 != .active {clearTransientContext()}
                else {lastAccess=accessSnapshot;resumeSession();receiveImageHandoff()}
            }
            .onChange(of:imageSecurity) { _ in
                // Earlier turns may contain scan results even when the player
                // subsequently cleared the selection or opened another record.
                clearTransientContext()
            }
            .onChange(of:interpretOnDevice) { enabled in
                if !enabled {interpretation?.cancel();interpretation=nil;requestID=UUID()}
            }
            .onChange(of:accessSnapshot) { current in
                if let lastAccess, current.revokes(lastAccess) { clearTransientContext() }
                lastAccess = current
            }
            .onChange(of: sound) { if !$0 { stopAudio() } }
            .onChange(of: spokenResponses) { if !$0 { stopAudio() } }
            .onReceive(timer) { now in
                readAloud.tick(now: now)
                if let player, !player.isPlaying { stopAudio() }
                else if player == nil, !readAloud.active { voiceSource = nil }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
                if let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                   AVAudioSession.InterruptionType(rawValue: raw) == .began { stopAudio() }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { notification in
                if let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                   AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable { stopAudio() }
            }
            .onDisappear {clearTransientContext()}
    }
}
