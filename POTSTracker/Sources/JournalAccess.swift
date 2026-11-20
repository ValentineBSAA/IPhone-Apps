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

/// Journal lock policy is testable without a device's Face ID implementation.
/// A transient inactive scene (including the system authentication UI) does NOT
/// mean Journal should be locked. Only a real background transition does.
enum JournalGatePolicy {
    static func shouldLockForScene(_ phase: ScenePhase) -> Bool {
        phase == .background
    }

    static func needsPrompt(enabled: Bool,
                            unlocked: Bool,
                            waitingForReply: Bool,
                            scene: ScenePhase) -> Bool {
        enabled && !unlocked && !waitingForReply && scene == .active
    }
}

/// The Journal destination requests Face ID automatically, but this gate does
/// not own the lifetime of the unlocked session. In particular, rebuilding
/// locked versus unlocked view content must never call lock() from onDisappear.
/// The navigation destination locks when it is actually left, and the app root
/// locks when the scene enters background. This eliminates the self-lock loop.
struct JournalProtected<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("journalLockEnabled") private var enabled = false
    @ObservedObject private var access = JournalAccess.shared
    @State private var pendingAttempt: UUID?
    @State private var lastError: String?
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
                    Image(systemName: "lock.shield")
                        .font(.largeTitle)
                        .foregroundStyle(Color.potsTeal)
                    if pendingAttempt != nil {
                        ProgressView()
                        Text("Unlocking private Journal…")
                            .font(.subheadline)
                            .foregroundStyle(Color.potsSecondary)
                    } else {
                        Text(lastError ?? "Your Journal is locked.")
                            .font(.subheadline)
                            .foregroundStyle(Color.potsSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // A system authentication callback can be interrupted or
                    // delayed. The user must always have a non-destructive exit.
                    Button(pendingAttempt == nil ? "Unlock Journal" : "Try Face ID again") {
                        if pendingAttempt != nil {
                            // Invalidate the obsolete attempt before retrying.
                            access.lock()
                            pendingAttempt = nil
                        }
                        authenticateIfNeeded()
                    }
                    .font(.subheadline.weight(.semibold))
                    Button("Back") {
                        pendingAttempt = nil
                        dismiss()
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain)
            }
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .onAppear { authenticateIfNeeded() }
        .onChange(of: scenePhase) { phase in
            // The root App is the ONLY owner of scene-background locking.
            // Reset a pending request when backgrounding, then re-prompt
            // after returning active. Ignore transient .inactive states.
            if JournalGatePolicy.shouldLockForScene(phase) {
                pendingAttempt = nil
                lastError = nil
            } else if phase == .active {
                authenticateIfNeeded()
            }
        }
        .onChange(of: enabled) { _ in
            lastError = nil
            authenticateIfNeeded()
        }
        // IMPORTANT: No .onDisappear { access.lock() } here.
        // The old handler could fire while the gate's unlocked content was
        // being substituted, immediately relocking a successful Face ID.
    }

    private func authenticateIfNeeded() {
        guard JournalGatePolicy.needsPrompt(
            enabled: enabled,
            unlocked: access.unlocked,
            waitingForReply: pendingAttempt != nil,
            scene: scenePhase
        ) else { return }

        lastError = nil
        let attempt = UUID()
        pendingAttempt = attempt
        access.authenticate(reason: "Open your private Journal") { success, error in
            guard pendingAttempt == attempt else { return }
            pendingAttempt = nil
            // Face ID can temporarily make SwiftUI scenePhase == .inactive.
            // Do not discard a successful device authorization on that basis.
            // Background transitions invalidate the request in JournalAccess.
            if !success {
                lastError = error ?? "Authentication was canceled."
                if scenePhase == .active { dismiss() }
            }
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
                            .foregroundStyle(Color.potsSecondary)
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
                        .tint(Color.potsButtonFill)
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
                    .foregroundStyle(Color.potsSecondary)
                }
                if !access.isAvailable {
                    Text("To enable Journal Lock, first enable a passcode in iPhone Settings.")
                        .font(.caption)
                        .foregroundStyle(Color.potsSecondary)
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
