import SwiftUI
import LocalAuthentication

/// Access gate for Journal UI. Uses iPhone Face ID / Touch ID with device
/// passcode fallback. This is NOT separately encrypted journal storage.
@MainActor
final class JournalAccess: ObservableObject {
    static let shared = JournalAccess()
    @Published private(set) var unlocked = false
    private var authGeneration = 0
    private init() {}

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    func lock() {
        authGeneration += 1
        unlocked = false
    }

    func authenticate(reason: String, completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        let requestGeneration = authGeneration
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(false, "Set up an iPhone passcode in Settings to use Journal Lock.")
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, failure in
            DispatchQueue.main.async {
                guard self.authGeneration == requestGeneration else {
                    completion(false, "Authentication was interrupted. Please try again.")
                    return
                }
                if success { self.unlocked = true }
                completion(success, success ? nil : (failure?.localizedDescription ?? "Authentication was canceled."))
            }
        }
    }
}

/// Journal content is guarded by the iPhone's native authentication sheet.
/// There is no intermediate "Unlock Journal" page or second tap. If the person
/// cancels Face ID / passcode, return to the previous screen with no private UI.
struct JournalProtected<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("journalLockEnabled") private var enabled = false
    @ObservedObject private var access = JournalAccess.shared
    @State private var pendingAttempt: UUID?
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if !enabled || access.unlocked {
                content
            } else {
                VStack(spacing: 14) {
                    ProgressView()
                    Text("Unlocking private Journal…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Back") {
                        pendingAttempt = nil
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Journal locked. Authentication required.")
            }
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .onAppear { authenticateIfNeeded() }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                pendingAttempt = nil
                access.lock()
            } else if phase == .active {
                authenticateIfNeeded()
            }
        }
        .onChange(of: enabled) { _ in authenticateIfNeeded() }
        .onDisappear {
            pendingAttempt = nil
            access.lock()
        }
    }

    private func authenticateIfNeeded() {
        guard enabled && !access.unlocked && pendingAttempt == nil && scenePhase == .active else { return }
        let request = UUID()
        pendingAttempt = request
        access.authenticate(reason: "Open your private Journal") { success, _ in
            // Ignore obsolete replies from a Face ID prompt interrupted while backgrounding.
            guard pendingAttempt == request else { return }
            pendingAttempt = nil
            guard scenePhase == .active else { return }
            if !success { dismiss() }
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
