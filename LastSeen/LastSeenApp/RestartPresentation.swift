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
    private static var player: AVAudioPlayer?
    static func play(_ name: String, enabled: Bool) {
        guard enabled, let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.82
            player?.play()
            OpeningQA.record("Restart audio requested: " + name)
        } catch { OpeningQA.record("Restart audio unavailable") }
    }
    static func stop() { player?.stop(); player = nil }
}

enum RestartPhase: Equatable {
    case black, userspace, respring
    static func opening(at seconds: Int) -> Self {
        if seconds < 2 || (seconds >= 8 && seconds < 10) { return .black }
        return seconds < 8 ? .userspace : .respring
    }
}

/// Original cinematic restart. No actual process or device is restarted.
struct RestartArtwork: View {
    let phase: RestartPhase
    var respringDuration: Double = 5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var entered = Date()
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if phase != .black {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
                    let t = max(0, context.date.timeIntervalSince(entered))
                    let reveal = reduceMotion ? 1.0 : min(1, t / 0.65)
                    let spin = reduceMotion ? 0.0 : t * 165
                    if phase == .userspace {
                        VStack(spacing: 23) {
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.08), lineWidth: 1).frame(width: 148, height: 148)
                                Circle().trim(from: 0, to: 0.22)
                                    .stroke(AngularGradient(colors: [.clear, .teal, .white], center: .center), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .frame(width: 148, height: 148).rotationEffect(.degrees(spin))
                                OpeningArt(name: "Opening_Reboot", size: 104)
                                    .scaleEffect(reduceMotion ? 1 : 0.96 + reveal * 0.04)
                                    .shadow(color: .teal.opacity(0.22), radius: 22)
                            }
                            Text("PATCHLINE").font(.system(size: 12, weight: .medium, design: .monospaced))
                                .tracking(5).foregroundColor(.white.opacity(0.74))
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.12)).frame(width: 112, height: 3)
                                Capsule().fill(.white.opacity(0.88)).frame(width: 112 * (reduceMotion ? 0.6 : min(1, t / 5.5)), height: 3)
                            }.accessibilityHidden(true)
                        }.opacity(reveal)
                    } else {
                        ZStack {
                            Circle().stroke(.white.opacity(0.06), lineWidth: 1).frame(width: 66, height: 66)
                            ZStack {
                            ForEach(0..<12, id: \.self) { index in
                                Capsule()
                                    .fill(Color.white.opacity(Double(index + 1) / 12))
                                    .frame(width: 4, height: 13)
                                    .offset(y: -22)
                                    .rotationEffect(.degrees(Double(index) * 30))
                            }
                            }.rotationEffect(.degrees(reduceMotion ? 0 : t * 300))
                        }.frame(width: 68, height: 68)
                            .scaleEffect(reduceMotion ? 1 : 0.78 + reveal * 0.22)
                            .opacity(reduceMotion ? 1 : min(reveal, max(0, (respringDuration - t) / 0.65)))
                    }
                }.transition(.opacity)
            }
        }.onAppear { entered = Date() }
            .onChange(of: phase) { _ in entered = Date() }
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
        RestartArtwork(phase: seconds < 2 ? .black : .respring, respringDuration: 3)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.65), value: seconds < 2)
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
                guard started, !finished, UIApplication.shared.applicationState == .active else { return }
                seconds = min(5, seconds + 1)
                if seconds == 2 { RestartAudio.play("RespringUp", enabled: effects) }
                if seconds == 5 {
                    finished = true
                    OpeningQA.record("Theme respring completed")
                    onComplete()
                }
            }
            .onChange(of: scenePhase) { value in if value == .background { RestartAudio.stop() } }
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
        RestartArtwork(phase: RestartPhase.opening(at: seconds))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.65), value: RestartPhase.opening(at: seconds))
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
                guard started, !finished, UIApplication.shared.applicationState == .active else { return }
                seconds = min(15, seconds + 1)
                if seconds == 2 { RestartAudio.play("UserspaceUp", enabled: effects) }
                if seconds == 8 { RestartAudio.play("RespringDown", enabled: effects) }
                if seconds == 10 { RestartAudio.play("RespringUp", enabled: effects) }
                if seconds == 15 {
                    finished = true
                    OpeningQA.record("Relay userspace restart completed")
                    onComplete()
                }
            }
            .onChange(of: scenePhase) { value in if value == .background { RestartAudio.stop() } }
            .onDisappear { RestartAudio.stop() }
    }
}
