import SwiftUI

@main
struct BerryBlockBlastApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            BerryHomeView()
                .overlay(alignment: .top) { BerryMilestoneBanner() }
                .onAppear { BerryAudio.shared.appSceneDidChange(scenePhase) }
                .onChange(of: scenePhase) { phase in
                    // Handles lock button, notification banners, home gesture
                    // and unlocking before any delayed app callbacks.
                    BerryAudio.shared.appSceneDidChange(phase)
                }
        }
    }
}


private struct BerryMilestoneBanner: View {
    @ObservedObject private var progress = BerryProgression.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        if let text = progress.celebrationText {
            HStack(spacing: 9) {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(.yellow)
                Text(text)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(BerryStyle.chocolate)
            .padding(13)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(BerryStyle.strawberry.opacity(0.5), lineWidth: 2))
            .padding(.horizontal, 18)
            .padding(.top, 55)
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            .allowsHitTesting(false)
            .zIndex(50)
        }
    }
}
