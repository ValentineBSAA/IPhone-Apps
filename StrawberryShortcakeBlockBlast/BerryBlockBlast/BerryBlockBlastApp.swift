import SwiftUI

@main
struct BerryBlockBlastApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            BerryHomeView()
                .onChange(of: scenePhase) { phase in
                    BerryAudio.shared.setAppActive(phase == .active)
                }
        }
    }
}
