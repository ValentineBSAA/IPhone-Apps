import SwiftUI
import LocalAuthentication
import UserNotifications

/// Out-of-fiction consent before the welcome screen; never requests unrelated permissions.
struct PhonePermissionsGate: View {
    @AppStorage("lastseen.permissions.reviewed.v1") private var reviewed = false
    @AppStorage("lastseen.lab.biometricUnlock") private var biometrics = false
    @AppStorage("lastseen.lab.nativeAlerts") private var alerts = false
    @State private var busy = false
    @State private var feedback = ""
    var body: some View {
        if reviewed {
            PhoneSetupRoot()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "hand.raised.circle").font(.system(size: 52)).foregroundColor(.teal)
                    Text("Before you begin").font(.largeTitle.bold())
                    Text("Last Seen is a fictional horror game. The phone, backup, messages and media are created for the game. Your real contacts, photos, messages and cloud account are never accessed.")
                        .foregroundColor(.secondary)
                    permission("faceid", "Biometric unlock", "Optional. Authenticate with your enrolled Face ID or Touch ID to unlock the in-game phone.", biometrics)
                    Button(biometrics ? "Turn off biometric unlock" : "Enable biometric unlock") {
                        if biometrics { biometrics = false; feedback = "" } else { authenticate() }
                    }.buttonStyle(.bordered).disabled(busy)
                    Divider()
                    permission("bell.badge", "Game notifications", "Optional. Allow Last Seen to display real iOS alerts for game events. Test alerts are available in Settings.", alerts)
                    Button(alerts ? "Turn off game alerts" : "Allow game notifications") {
                        if alerts {
                            alerts = false; feedback = ""
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["lastseen-lab-test"])
                        } else { authorizeAlerts() }
                    }.buttonStyle(.bordered).disabled(busy)
                    if !feedback.isEmpty { Text(feedback).font(.footnote).foregroundColor(.secondary) }
                    Button {
                        reviewed = true
                    } label: {
                        Text("Continue to phone setup").font(.headline).frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.borderedProminent).tint(.teal).disabled(busy)
                    Text("Both features are optional. You can change your choices later. No real biometrics are stored by the game.").font(.footnote).foregroundColor(.secondary)
                }.padding(25)
            }
            .background(Color(red: 0.07, green: 0.12, blue: 0.18).ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }
    private func permission(_ icon: String, _ title: String, _ detail: String, _ enabled: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundColor(.teal).frame(width: 34)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundColor(.secondary)
                Text(enabled ? "Enabled in game" : "Optional").font(.caption).foregroundColor(.teal)
            }
        }
    }
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            feedback = "Biometrics unavailable. You can continue without them."
            return
        }
        context.localizedFallbackTitle = ""
        busy = true
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable biometric unlock for your fictional Last Seen phone.") { success, _ in
            DispatchQueue.main.async {
                biometrics = success
                busy = false
                feedback = success ? "Biometric unlock enabled." : "Authentication was not completed. You can continue."
            }
        }
    }
    private func authorizeAlerts() {
        busy = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                alerts = granted
                busy = false
                feedback = granted ? "Game alerts enabled." : "Game alerts are off. You can continue."
            }
        }
    }
}
struct PhoneWallpaper: View {
    let selection: Int
    var body: some View {
        let colors: [Color] = selection == 1
            ? [Color(red: 0.34, green: 0.18, blue: 0.32), Color(red: 0.12, green: 0.12, blue: 0.22)]
            : [Color(red: 0.14, green: 0.34, blue: 0.41), Color(red: 0.07, green: 0.12, blue: 0.24)]
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(.white.opacity(0.05)).frame(width: proxy.size.width * 0.88).offset(x: proxy.size.width * 0.38, y: proxy.size.height * 0.23)
                Circle().strokeBorder(.white.opacity(0.10), lineWidth: 1).frame(width: proxy.size.width * 0.77).offset(x: -proxy.size.width * 0.31, y: -proxy.size.height * 0.14)
            }.frame(width: proxy.size.width, height: proxy.size.height).clipped()
        }
    }
}
