import SwiftUI
import AVFoundation

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
            let aliases: [String: LabApp] = ["texts": .messages, "email": .mail, "emails": .mail, "pictures": .photos, "memos": .voiceMemos, "recordings": .voiceMemos, "videos": .motionwell, "security cameras": .havenWatch]
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.lab.messageSound") private var sound = true
    @State private var input = ""
    @State private var answer = LumaAssistantAnswer(text: "What can I help you with?", clipID: "greeting")
    @State private var player: AVAudioPlayer?
    @State private var glow = false
    @FocusState private var focused: Bool
    private func submit(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, text.count <= 300 else { return }
        player?.stop(); player = nil
        answer = LumaAssistantPolicy.answer(text, context: context())
        input = ""; focused = false
        // Fixed clips are optional. Dynamic values remain text, never substitute
        // an invented spoken value or a different transcript.
        if sound, ["help","denied","unavailable","hint","progress","clarify"].contains(answer.clipID),
           let url = Bundle.main.url(forResource: "LumaAssistant_" + answer.clipID, withExtension: "m4a"),
           let audio = try? AVAudioPlayer(contentsOf: url) {
            PhoneSensoryEngine.stopSound()
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            player = audio; audio.play()
        }
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
                Text(answer.text).font(.title3).multilineTextAlignment(.center).accessibilityIdentifier("luma.assistant.answer")
                    .frame(maxWidth: .infinity).padding(18).lumaSurface()
                if let app = answer.app {
                    Button("Open " + app.rawValue) {
                        guard context().availableApps.contains(app) else { return }
                        player?.stop(); openApp(app)
                    }.buttonStyle(.borderedProminent).tint(.teal)
                }
                HStack {
                    TextField("Ask Luma", text: $input).textFieldStyle(.roundedBorder).focused($focused)
                        .submitLabel(.go).onSubmit { submit(input) }
                    Button { submit(input) } label: { Image(systemName: "arrow.up.circle.fill").font(.title2) }
                        .accessibilityLabel("Ask").disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Try asking").font(.headline)
                    ForEach(["Open Messages", "Unread messages", "Next event", "Timer status", "Package status", "Hint"], id: \.self) { item in
                        Button { submit(item) } label: {
                            HStack { Text(item); Spacer(); Image(systemName: "chevron.right").font(.caption) }.padding(12).lumaSurface(radius: 12)
                        }.buttonStyle(.plain)
                    }
                }
                Text("Local text commands · No microphone listening or real-device actions.").font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            }.padding(20)
        }.navigationTitle("Assistant").navigationBarTitleDisplayMode(.inline)
            .onAppear { if !reduceMotion { withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { glow = true } } }
            .onChange(of: phase) { if $0 != .active { player?.stop(); player = nil } }
            .onChange(of: sound) { if !$0 { player?.stop(); player = nil } }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in player?.stop(); player = nil }
            .onDisappear { player?.stop(); player = nil; focused = false }
    }
}
