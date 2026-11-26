import SwiftUI
import UIKit
import AVFoundation
import Combine

enum ApprovedArt {
    static let opening = ["Computer","Phone","USB","Permissions","Diagnostics","Install","Unlock","Terminal","Reboot","Respring"].map { "Opening_" + $0 }
    static let theme = ["Messages","Contacts","Photos","Notes","Calendar","Mail","Browser","Files","Clock","Settings"].map { "Theme_" + $0 }
    static func themeName(for title: String) -> String? {
        let name = "Theme_" + title
        return theme.contains(name) ? name : nil
    }
}

struct OpeningArt: View {
    let name: String
    var size: CGFloat = 160
    var body: some View {
        Image(name).resizable().scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Original short, bundled effects. Ambient mode respects the silent switch and other audio.
@MainActor enum RestartAudio {
    static let assetNames = ["RespringDown", "RespringUp", "UserspaceDown", "UserspaceUp"]
    private static var player: AVAudioPlayer?
    private static var owner: UUID?
    private static var completion: Task<Void, Never>?
    static func play(_ name: String, enabled: Bool) {
        PhoneSensoryEngine.stopPreview()
        stop()
        guard enabled, UIApplication.shared.applicationState == .active,
              assetNames.contains(name) else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            OpeningQA.record("Missing restart audio: " + name); return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
            let candidate = try AVAudioPlayer(contentsOf: url)
            candidate.volume = 0.82
            candidate.numberOfLoops = 0
            candidate.prepareToPlay()
            let token = UUID()
            PhoneSensoryEngine.beginMediaAudio(token)
            owner = token
            guard candidate.play() else {
                stop()
                OpeningQA.record("Restart audio failed to start: " + name); return
            }
            player = candidate
            completion = Task { @MainActor in
                while !Task.isCancelled, owner == token, candidate.isPlaying,
                      UIApplication.shared.applicationState == .active {
                    do { try await Task.sleep(nanoseconds: 50_000_000) } catch { return }
                }
                guard !Task.isCancelled, owner == token else { return }
                stop()
            }
            OpeningQA.record("Restart audio started: " + name)
        } catch { OpeningQA.record("Restart audio unavailable: " + name) }
    }
    static func stop() {
        completion?.cancel(); completion = nil
        player?.stop(); player = nil
        if let owner { PhoneSensoryEngine.endMediaAudio(owner) }
        owner = nil
    }
}

/// Distinguish the initial install's two-step handoff from ordinary
/// maintenance. All durations are theatrical and do not measure real boot.
enum RestartPhase: Equatable {
    case black, userspace, respring
    static func opening(at seconds: Int) -> Self {
        if (2..<8).contains(seconds) {return .userspace}
        if (10..<14).contains(seconds) {return .respring}
        return .black
    }
    static func userspaceRestart(at seconds:Int)->Self {
        (2..<12).contains(seconds) ? .userspace:.black
    }
    static func shellRestart(at seconds:Int)->Self {
        (1..<4).contains(seconds) ? .respring:.black
    }
}

/// An original monochrome Patchline glyph, not an Apple or jailbreak logo.
/// No app icon tile, promotional text, progress bar or decorative ring.
struct PatchlineBootGlyph:View {
    var body:some View {
        Path { path in
            path.move(to:CGPoint(x:15,y:56))
            path.addLine(to:CGPoint(x:15,y:8))
            path.addLine(to:CGPoint(x:43,y:8))
            path.addQuadCurve(to:CGPoint(x:49,y:29),control:CGPoint(x:58,y:9))
            path.addLine(to:CGPoint(x:32,y:43))
            path.move(to:CGPoint(x:32,y:26))
            path.addLine(to:CGPoint(x:44,y:14))
            path.move(to:CGPoint(x:32,y:43))
            path.addLine(to:CGPoint(x:49,y:56))
        }.stroke(Color.white,style:StrokeStyle(lineWidth:5,lineCap:.round,lineJoin:.round))
        .frame(width:64,height:64)
        .accessibilityHidden(true)
    }
}

/// A brief black framebuffer, static original boot mark or small segmented
/// shell-reload spinner. Reduce Motion keeps the spinner stationary.
struct RestartArtwork: View {
    let phase: RestartPhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch phase {
            case .black: EmptyView()
            case .userspace:
                PatchlineBootGlyph()
            case .respring:
                TimelineView(.animation(minimumInterval:0.1,paused:reduceMotion)) { context in
                    let tick=reduceMotion ? 0 : Int(context.date.timeIntervalSinceReferenceDate*10)%12
                    ZStack {
                        ForEach(0..<12,id:\.self) { index in
                            Capsule().fill(Color.white.opacity(Double((index+tick)%12+1)/12))
                                .frame(width:2.5,height:8)
                                .offset(y:-13)
                                .rotationEffect(.degrees(Double(index)*30))
                        }
                    }.frame(width:36,height:36).accessibilityHidden(true)
                }
            }
        }.frame(maxWidth:.infinity,maxHeight:.infinity)
    }
}

/// Local theme reload. No system process is restarted.
struct ThemeRespringView: View {
    let onComplete: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("lastseen.recovery.effects") private var effects = true
    @State private var seconds = 0
    @State private var finished = false
    @State private var started = false
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        RestartArtwork(phase: RestartPhase.shellRestart(at:seconds))
            .animation(reduceMotion ? nil : .easeInOut(duration:0.22),value:RestartPhase.shellRestart(at:seconds))
            .statusBar(hidden: true)
            .interactiveDismissDisabled()
            .accessibilityLabel("Simulated respring")
            .onAppear {
                guard !started else { return }
                started = true
                OpeningQA.record("Theme respring started")
                RestartAudio.play("RespringDown", enabled: effects)
            }
            .onReceive(clock) { _ in
                guard started,!finished,scenePhase == .active,UIApplication.shared.applicationState == .active else{return}
                seconds = min(5, seconds + 1)
                if seconds == 4 { RestartAudio.play("RespringUp", enabled: effects) }
                if seconds == 5 {
                    finished = true
                    OpeningQA.record("Theme respring completed")
                    onComplete()
                }
            }
            .onChange(of: scenePhase) { value in if value != .active { RestartAudio.stop() } }
            .onChange(of: effects) { if !$0 { RestartAudio.stop() } }
            .onDisappear { RestartAudio.stop() }
    }
}


/// Same cinematic userspace sequence, available from Relay after installation.
struct RelayUserspaceView: View {
    let onComplete: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("lastseen.recovery.effects") private var effects = true
    @State private var seconds = 0
    @State private var started = false
    @State private var finished = false
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        RestartArtwork(phase: RestartPhase.userspaceRestart(at:seconds))
            .animation(reduceMotion ? nil : .easeInOut(duration:0.22),value:RestartPhase.userspaceRestart(at:seconds))
            .statusBar(hidden: true)
            .interactiveDismissDisabled()
            .accessibilityLabel("Userspace reboot")
            .onAppear {
                guard !started else { return }
                started = true
                OpeningQA.record("Relay userspace restart started")
                RestartAudio.play("UserspaceDown", enabled: effects)
            }
            .onReceive(clock) { _ in
                guard started,!finished,scenePhase == .active,UIApplication.shared.applicationState == .active else{return}
                seconds = min(15, seconds + 1)
                if seconds == 12 { RestartAudio.play("UserspaceUp", enabled: effects) }
                if seconds == 15 {
                    finished = true
                    OpeningQA.record("Relay userspace restart completed")
                    onComplete()
                }
            }
            .onChange(of: scenePhase) { value in if value != .active { RestartAudio.stop() } }
            .onChange(of: effects) { if !$0 { RestartAudio.stop() } }
            .onDisappear { RestartAudio.stop() }
    }
}
