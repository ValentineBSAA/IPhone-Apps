import SwiftUI

@main
struct BerryBlockBlastApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var playtime = BerryPlaytimeTracker.shared

    var body: some Scene {
        WindowGroup {
            BerryHomeView()
                .overlay(alignment: .top) { BerryMilestoneBanner() }
                .onAppear {
                    // 0.5.9 silently changed 'default' into fruit blocks and
                    // a decorated pink cell. Restore the familiar 0.5.8
                    // appearance once without discarding intentionally chosen
                    // alternative board surfaces or old cosmetic purchases.
                    let defaults = UserDefaults.standard
                    let migration = "berryberryblast.originalBoardRestored.v0510"
                    if !defaults.bool(forKey: migration) {
                        let surfaceKey = "berryberryblast.board.surface.v059"
                        if defaults.string(forKey: surfaceKey) == nil ||
                           defaults.string(forKey: surfaceKey) == "cream" {
                            defaults.set("original", forKey: surfaceKey)
                        }
                        defaults.set(true, forKey: migration)
                    }
                    BerryAudio.shared.appSceneDidChange(scenePhase)
                    playtime.scenePhaseDidChange(scenePhase)
                    BerryDayNightAppearance.update()
                }
                .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { now in
                    BerryDayNightAppearance.update(now: now)
                }
                .onChange(of: scenePhase) { phase in
                    // Handles lock button, notification banners, home gesture
                    // and unlocking before any delayed app callbacks.
                    BerryAudio.shared.appSceneDidChange(phase)
                    playtime.scenePhaseDidChange(phase)
                    if phase == .active { BerryDayNightAppearance.update() }
                }
        }
    }
}


private struct BerryMilestoneBanner: View {
    @ObservedObject private var progress = BerryProgression.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        if let text = progress.celebrationText {
            BerryNoticeBanner(message: text, kind: .success)
            .padding(.horizontal, 18)
            .padding(.top, 55)
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            .allowsHitTesting(false)
            .zIndex(50)
        }
    }
}
