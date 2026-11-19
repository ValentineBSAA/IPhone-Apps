import SwiftUI
import LocalAuthentication

/// Access gate for Journal UI. Uses iPhone Face ID / Touch ID with device
/// passcode fallback. This is NOT separately encrypted journal storage.
@MainActor
final class JournalAccess: ObservableObject {
    static let shared = JournalAccess()
    @Published private(set) var unlocked = false
    private init() {}

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    func lock() { unlocked = false }

    func authenticate(reason: String, completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(false, "Set up an iPhone passcode in Settings to use Journal Lock.")
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, failure in
            DispatchQueue.main.async {
                if success { self.unlocked = true }
                completion(success, success ? nil : (failure?.localizedDescription ?? "Authentication was canceled."))
            }
        }
    }
}

/// The journal destination never constructs or renders private entries while
/// locked. Moving away from this destination locks it again.
struct JournalProtected<Content: View>: View {
    @AppStorage("journalLockEnabled") private var enabled = false
    @ObservedObject private var access = JournalAccess.shared
    @State private var errorText: String?
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if !enabled || access.unlocked {
                content
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(Color.potsTeal)
                        Text("Journal locked")
                            .font(.title3.bold())
                        Text("Unlock using Face ID or your iPhone passcode. Journal entries stay hidden until then.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            access.authenticate(reason: "Unlock your private POTS Journal") { success, error in
                                if !success { errorText = error }
                            }
                        } label: {
                            Label("Unlock Journal", systemImage: "faceid")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 54)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .onDisappear { access.lock() }
        .alert("Journal couldn't be unlocked", isPresented: Binding(
            get: { errorText != nil },
            set: { if !$0 { errorText = nil } }
        )) {
            Button("OK") { errorText = nil }
        } message: {
            Text(errorText ?? "Please try again.")
        }
    }
}

/// Turning the lock on or off always requires successful device authentication.
/// Never disable it after a failed or canceled authentication.
struct JournalLockSettings: View {
    @AppStorage("journalLockEnabled") private var enabled = false
    @ObservedObject private var access = JournalAccess.shared
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Private Journal", systemImage: enabled ? "lock.shield.fill" : "lock.open")
                            .font(.title3.bold())
                            .foregroundStyle(Color.potsTeal)
                        Text(enabled ? "Journal Lock is on" : "Journal Lock is off")
                            .font(.headline)
                        Text("When enabled, Journal entries require Face ID or the iPhone passcode. The lock returns when you leave the Journal or the app goes into the background.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            access.authenticate(reason: enabled ? "Turn off private Journal Lock" : "Turn on private Journal Lock") { success, error in
                                if success {
                                    enabled.toggle()
                                    access.lock()
                                } else {
                                    errorText = error
                                }
                            }
                        } label: {
                            Label(enabled ? "Turn off Journal Lock" : "Enable Journal Lock",
                                  systemImage: enabled ? "lock.open" : "faceid")
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("About this protection")
                            .font(.headline)
                        Text("Face ID is optional. iOS can use your existing device passcode as a fallback. Your face data and passcode are never given to this app.")
                        Text("This is an on-screen access lock, not separate encryption for individual Journal records. iPhone storage protection still applies. Journal information is hidden from Home and History while locked.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                if !access.isAvailable {
                    Text("To enable Journal Lock, first enable a passcode in iPhone Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Journal Lock")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Authentication unsuccessful", isPresented: Binding(
            get: { errorText != nil },
            set: { if !$0 { errorText = nil } }
        )) {
            Button("OK") { errorText = nil }
        } message: {
            Text(errorText ?? "Try again.")
        }
    }
}
