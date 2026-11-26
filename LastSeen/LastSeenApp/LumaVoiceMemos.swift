import SwiftUI
import AVFoundation
import Combine

struct LumaMemo: Identifiable, Equatable {
    let id: String
    let title: String
    let speaker: String
    let date: Date
    let transcript: String
    var file: String { "LumaMemo_" + id }
    var url: URL? { Bundle.main.url(forResource: file, withExtension: "m4a") }
}
enum LumaMemoCatalog {
    static func search(_ world:PhoneWorld,query:String="")->[LumaMemo] {
        let q=query.trimmingCharacters(in:.whitespacesAndNewlines)
        return visible(world).filter{q.isEmpty || [$0.title,$0.speaker,$0.transcript].contains{$0.localizedCaseInsensitiveContains(q)}}
    }
    static func visible(_ world: PhoneWorld) -> [LumaMemo] {
        guard world.everydayArchiveRevision != nil else { return [] }
        let anchor = world.createdAt
        return [
            .init(id: "personal", title: "Weekend reminder", speaker: "Nora Bennett", date: anchor.addingTimeInterval(-192000), transcript: "Remember the book, the jacket, and an evening without work. I don't need to fill every hour with something."),
            .init(id: "qa", title: "Friday review checklist", speaker: "Nora Bennett", date: anchor.addingTimeInterval(-148000), transcript: "For Friday, check large text, interruptions and save persistence. Compare the palettes on the phone itself. Make a note of anything that feels awkward."),
            .init(id: "lunch", title: "Sunday lunch", speaker: "Nora Bennett", date: anchor.addingTimeInterval(-110000), transcript: "Check whether Mum needs dessert. Ask about a lift if necessary. Leave the laptop at home."),
            .init(id: "palette", title: "Palette review", speaker: "Tessa Reed", date: anchor.addingTimeInterval(-92000), transcript: "For the visual review, compare lilac, pearl and midnight at the same brightness. Read the labels before deciding which palette is best.")
        ].sorted { $0.date > $1.date }
    }
}
struct LumaVoiceMemos: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var query = ""
    private var memos: [LumaMemo] {
        LumaMemoCatalog.search(world.state,query:query)
    }
    var body: some View {
        List {
            Section {
                LumaHeader(title: "Voice Memos", detail: "Restored local recordings", symbol: "waveform")
            }
            if memos.isEmpty {
                Text("No matching recordings.").foregroundColor(.secondary)
            }
            ForEach(memos) { memo in
                NavigationLink { LumaMemoDetail(id: memo.id) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "waveform").font(.title2).foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memo.title).font(.headline)
                            Text(memo.speaker).font(.caption).foregroundColor(.secondary)
                            Text(memo.date, style: .date).font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(memo.url == nil ? "Transcript only" : "Audio + transcript").font(.caption).foregroundColor(.secondary)
                    }.padding(.vertical, 4)
                }
            }
            Section {
                Text("Only the fictional restored archive is shown. No real recordings or microphone access.").font(.caption).foregroundColor(.secondary)
            }
        }.navigationTitle("Voice Memos").searchable(text: $query)
    }
}
struct LumaMemoDetail: View {
    let id: String
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var player: AVAudioPlayer?
    @State private var elapsed = 0.0
    @State private var duration = 0.0
    @State private var playing = false
    @State private var error = ""
    @State private var audioOwner = UUID()
    @StateObject private var readAloud = LumaReadAloud()
    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    private var memo: LumaMemo? { LumaMemoCatalog.visible(world.state).first { $0.id == id } }
    private func stop() {
        player?.pause()
        playing = false
        elapsed = player?.currentTime ?? elapsed
        PhoneSensoryEngine.endMediaAudio(audioOwner)
    }
    private func resetPlayback() {
        stop();readAloud.stop();player=nil;elapsed=0;duration=0;error=""
    }
    private func seek(_ seconds:Double) {
        guard phase == .active,memo != nil,let player else{return}
        let position=LumaMemoPlayback.position(seconds,duration:duration)
        player.currentTime=position;elapsed=position
    }
    private func load() {
        guard phase == .active,let url = memo?.url, player == nil else { return }
        do {
            let audio = try AVAudioPlayer(contentsOf: url)
            guard audio.duration.isFinite, audio.duration > 0 else {
                error = "Recording duration is unavailable."
                return
            }
            audio.prepareToPlay()
            player = audio; duration = audio.duration
        } catch { self.error = "Recording could not be decoded." }
    }
    private func clock(_ seconds: Double) -> String {
        let total = Int(LumaMemoPlayback.position(seconds,duration:86400))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
    var body: some View {
        ScrollView {
            if phase == .active,let memo {
                VStack(alignment: .leading, spacing: 16) {
                    Text(memo.title).font(.title2.bold())
                    Text(memo.speaker).font(.headline)
                    Text(memo.date, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundColor(.secondary)
                    if let player {
                        VStack(spacing: 12) {
                            Image(systemName: playing ? "waveform.circle.fill" : "waveform.circle").font(.system(size: 72)).foregroundColor(.red)
                            Slider(value: Binding(get: { LumaMemoPlayback.position(elapsed,duration:duration) }, set: { seek($0) }), in: 0...max(0.01, duration))
                                .accessibilityLabel("Playback position")
                            HStack { Text(clock(elapsed)); Spacer(); Text(clock(duration)) }.font(.caption.monospacedDigit())
                            HStack(spacing: 30) {
                                Button { seek(elapsed-10) } label: { Image(systemName: "gobackward.10") }.accessibilityLabel("Back ten seconds")
                                Button {
                                    if playing { stop() }
                                    else {
                                        if elapsed >= duration - 0.1 { seek(0) }
                                        guard phase == .active, self.memo != nil else { return }
                                        readAloud.stop()
                                        PhoneSensoryEngine.beginMediaAudio(audioOwner)
                                        do {
                                            let session = AVAudioSession.sharedInstance()
                                            try session.setCategory(.ambient, mode: .default)
                                            try session.setActive(true)
                                            playing = player.play()
                                        } catch { playing = false }
                                        elapsed = player.currentTime
                                        error = playing ? "" : "Playback unavailable."
                                        if !playing { PhoneSensoryEngine.endMediaAudio(audioOwner) }
                                    }
                                } label: { Image(systemName: playing ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 50)) }
                                    .accessibilityLabel(playing ? "Pause" : "Play")
                                Button { seek(elapsed+10) } label: { Image(systemName: "goforward.10") }.accessibilityLabel("Forward ten seconds")
                            }.font(.title2).buttonStyle(.plain)
                        }.padding(16).lumaSurface()
                    } else {
                        Label("Audio unavailable · transcript retained", systemImage: "waveform.slash")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    if !error.isEmpty { Text(error).font(.caption).foregroundColor(.secondary) }
                    Text("Transcript").font(.headline)
                    Text(memo.transcript).textSelection(.enabled)
                    Button {
                        if readAloud.active { readAloud.stop() }
                        else if phase == .active { stop(); readAloud.speak(memo.transcript) }
                    } label: {
                        Label(readAloud.active ? "Stop read-aloud" : "Read transcript aloud", systemImage: readAloud.active ? "stop.circle" : "speaker.wave.2")
                    }.buttonStyle(.bordered)
                    Text("Uses the iPhone's system voice. This is not the original character recording.").font(.caption).foregroundColor(.secondary)
                    if !readAloud.notice.isEmpty { Text(readAloud.notice).font(.caption).foregroundColor(.secondary) }
                    Text("Restored local record").font(.caption).foregroundColor(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            } else { Text("Recording unavailable").padding() }
        }.navigationTitle("Recording").navigationBarTitleDisplayMode(.inline)
            .onAppear { load() }
            .onReceive(timer) { now in
                readAloud.tick(now: now)
                guard let player else { return }
                if playing && !player.isPlaying {
                    // AVAudioPlayer may reset its clock when it ends. A halt
                    // well before the end must not be reported as completion.
                    if max(elapsed, player.currentTime) >= duration - 0.5 {
                        elapsed = duration; player.currentTime = 0
                    } else {
                        player.currentTime = min(duration, max(elapsed, player.currentTime))
                        elapsed = player.currentTime
                    }
                    playing = false
                    PhoneSensoryEngine.endMediaAudio(audioOwner)
                } else if playing { elapsed = player.currentTime }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
                if let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                   AVAudioSession.InterruptionType(rawValue: raw) == .began { stop(); readAloud.stop() }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { notification in
                if let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                   AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable { stop(); readAloud.stop() }
            }
            .onChange(of: memo?.id) { value in
                if value == nil { resetPlayback() }
                else { load() }
            }
            .onChange(of: phase) { if $0 != .active { stop(); readAloud.stop() } else {load()} }
            .onDisappear { resetPlayback() }
    }
}


enum LumaMemoPlayback {
    static func position(_ seconds:Double,duration:Double)->Double {
        guard seconds.isFinite,duration.isFinite,duration>0 else{return 0}
        return min(duration,max(0,seconds))
    }
}
