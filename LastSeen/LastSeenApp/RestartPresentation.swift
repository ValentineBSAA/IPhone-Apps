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
            player?.volume = 0.65
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

struct RestartArtwork: View {
    let phase: RestartPhase
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if phase != .black {
                VStack(spacing: 22) {
                    OpeningArt(name: phase == .userspace ? "Opening_Reboot" : "Opening_Respring", size: 142)
                    ProgressView().tint(.white.opacity(0.85))
                    Text(phase == .userspace ? "Userspace reboot" : "Respring").font(.footnote.weight(.medium)).foregroundColor(.white.opacity(0.72))
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
            .onDisappear { RestartAudio.stop() }
    }
}
