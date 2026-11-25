import SwiftUI
import UIKit
import AVFoundation

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

/// A minimal full-screen restart cutscene with no real system operations.
struct RestartArtwork: View {
    let phase: RestartPhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if phase == .userspace {
                VStack(spacing: 26) {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let pulse = reduceMotion ? 0.0 : (sin(t * 2.4) + 1) / 2
                        OpeningArt(name: "Opening_Reboot", size: 128)
                            .scaleEffect(1 + pulse * 0.035)
                            .shadow(color: .cyan.opacity(0.08 + pulse * 0.20), radius: 22)
                    }
                    Text("PATCHLINE").font(.system(size: 12, weight: .medium, design: .monospaced))
                        .tracking(5).foregroundColor(.white.opacity(0.75))
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let travel = reduceMotion ? 0.5 : (sin(t * 2) + 1) / 2
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.12)).frame(width: 110, height: 3)
                            Capsule().fill(.white.opacity(0.9)).frame(width: 30, height: 3).offset(x: 80 * travel)
                        }
                    }.accessibilityHidden(true)
                }.transition(.opacity)
            } else if phase == .respring {
                VStack(spacing: 16) {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                        let step = reduceMotion ? 0 : Int(context.date.timeIntervalSinceReferenceDate * 12) % 12
                        ZStack {
                            ForEach(0..<12, id: \.self) { index in
                                Capsule().fill(Color.white.opacity(Double((index - step + 12) % 12 + 1) / 12))
                                    .frame(width: 3, height: 10)
                                    .offset(y: -15)
                                    .rotationEffect(.degrees(Double(index) * 30))
                            }
                        }.frame(width: 44, height: 44)
                    }
                    Text("Respring").font(.caption2).foregroundColor(.white.opacity(0.45))
                }.transition(.opacity)
            }
        }
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
    var body: some View {
        RestartArtwork(phase: seconds < 2 ? .black : .respring)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.65), value: seconds < 2)
            .statusBar(hidden: true)
            .interactiveDismissDisabled()
            .accessibilityLabel("Simulated respring")
            .task {
                OpeningQA.record("Theme respring started")
                RestartAudio.play("RespringDown", enabled: effects)
                while seconds < 5 && !Task.isCancelled {
                    do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
                    guard scenePhase == .active else { continue }
                    seconds += 1
                    if seconds == 2 { RestartAudio.play("RespringUp", enabled: effects) }
                }
                guard !Task.isCancelled, !finished else { return }
                finished = true
                OpeningQA.record("Theme respring completed")
                onComplete()
            }
            .onChange(of: scenePhase) { value in if value == .background { RestartAudio.stop() } }
            .onDisappear { RestartAudio.stop() }
    }
}
