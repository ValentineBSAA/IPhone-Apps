import SwiftUI

@main
struct BerryBlockBlastApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            BerryHomeView()
                .onAppear { BerryAudio.shared.appSceneDidChange(scenePhase) }
                .onChange(of: scenePhase) { phase in
                    // Handles lock button, notification banners, home gesture
                    // and unlocking before any delayed app callbacks.
                    BerryAudio.shared.appSceneDidChange(phase)
                }
        }
    }
}
