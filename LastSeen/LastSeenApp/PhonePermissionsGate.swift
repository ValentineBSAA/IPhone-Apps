import SwiftUI
import LocalAuthentication
import UserNotifications

/// One consent review; Apple may still display separate native dialogs.
struct PhonePermissionsGate: View {
    @AppStorage("lastseen.permissions.reviewed.v1") private var reviewed = false
    @AppStorage("lastseen.permissions.reviewRevision") private var revision = 0
    @AppStorage("lastseen.permissions.biometricPrepared") private var biometrics = false
    @AppStorage("lastseen.lab.nativeAlerts") private var alerts = false
    @State private var wantsBiometrics = false
    @State private var wantsAlerts = false
    @State private var busy = false
    @State private var showQA = false
    @State private var status = ""
    private let accent = Color(red: 0.35, green: 0.86, blue: 0.77)

    var body: some View {
        Group {
            if reviewed && revision >= 2 {
                RecoveryPrologue()
            } else {
                ZStack {
                    Color(red: 0.035, green: 0.06, blue: 0.10).ignoresSafeArea()
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 22) {
                                OpeningArt(name: "Opening_Permissions", size: 108)
                                Text("Before you begin").font(.system(size: 32, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
                                Text("Last Seen is a fictional horror game. Choose the optional features you want to use.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                                VStack(spacing: 16) {
                                    permission("faceid", "Face ID / Touch ID", "Prepare authentication for later. Protected records still require the fictional owner passcode.", $wantsBiometrics)
                                    Divider()
                                    permission("bell.badge", "Game notifications", "Allow optional native alerts from Last Seen.", $wantsAlerts)
                                }.padding(18).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 23))
                                Label("No real personal records or system modifications", systemImage: "lock.shield")
                                    .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                                Text("iOS may show separate permission dialogs. Both choices are optional; camera, microphone and location are not requested.").font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                            }.padding(24)
                        }.scrollIndicators(.hidden)
                        if busy {
                            ProgressView(status).font(.caption).padding(8)
                        }
                        Button {
                            continueReview()
                        } label: {
                            Text("Continue with selected permissions").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                        }.buttonStyle(.borderedProminent).tint(accent).foregroundColor(.black).disabled(busy)
                        Button("Continue without permissions") {
                            wantsBiometrics = false; wantsAlerts = false; continueReview()
                        }.font(.subheadline).padding(.vertical, 13).disabled(busy)
                        Button("Developer Diagnostics") { showQA = true }.font(.caption).foregroundColor(.secondary).disabled(busy)
                    }.padding(.horizontal, 22).padding(.bottom, 14).frame(maxWidth: 540)
                }.onAppear { wantsBiometrics = biometrics; wantsAlerts = alerts }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showQA) { OpeningDiagnosticsView() }
    }

    private func permission(_ icon: String, _ title: String, _ detail: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon).font(.title2).foregroundColor(accent).frame(width: 30)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).foregroundColor(.secondary)
                }
            }
        }.tint(accent).disabled(busy)
    }
    private func continueReview() {
        guard !busy else { return }
        busy = true
        OpeningQA.record("Permission review submitted; biometric selected: \(wantsBiometrics), alerts selected: \(wantsAlerts)")
        guard wantsBiometrics else { biometrics = false; requestAlerts(); return }
        status = "Preparing biometrics"
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometrics = false
            OpeningQA.record("Biometric preparation unavailable")
            requestAlerts(); return
        }
        context.localizedFallbackTitle = ""
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Prepare optional biometric authentication for Last Seen.") { success, _ in
            DispatchQueue.main.async {
                biometrics = success
                OpeningQA.record(success ? "Biometric preparation succeeded" : "Biometric preparation not completed")
                requestAlerts()
            }
        }
    }
    private func requestAlerts() {
        guard wantsAlerts else {
            alerts = false
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["lastseen-lab-test"])
            finishReview(); return
        }
        status = "Reviewing notifications"
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                alerts = granted
                OpeningQA.record(granted ? "Notification permission granted" : "Notification permission not granted")
                finishReview()
            }
        }
    }
    private func finishReview() {
        OpeningQA.record("Permission review completed")
        revision = 2; reviewed = true; busy = false
    }
}

struct PhoneWallpaper: View {
    let selection: Int
    var body: some View {
        let colors: [Color] = selection == 2
            ? [Color(red: 0.10, green: 0.23, blue: 0.45), Color(red: 0.035, green: 0.055, blue: 0.15)]
            : selection == 1
            ? [Color(red: 0.34, green: 0.18, blue: 0.32), Color(red: 0.12, green: 0.12, blue: 0.22)]
            : [Color(red: 0.14, green: 0.34, blue: 0.41), Color(red: 0.07, green: 0.12, blue: 0.24)]
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                if LumaDesign.wallpaperAssets.indices.contains(selection),
                   !LumaDesign.wallpaperAssets[selection].isEmpty {
                    Image(LumaDesign.wallpaperAssets[selection]).resizable().scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height).clipped()
                }
                if selection == 2 { Circle().fill(.white.opacity(0.05)).frame(width: proxy.size.width * 0.88).offset(x: proxy.size.width * 0.38, y: proxy.size.height * 0.23)
                Circle().strokeBorder(.white.opacity(0.10), lineWidth: 1).frame(width: proxy.size.width * 0.77).offset(x: -proxy.size.width * 0.31, y: -proxy.size.height * 0.14) }
            }.frame(width: proxy.size.width, height: proxy.size.height).clipped()
        }
    }
}
