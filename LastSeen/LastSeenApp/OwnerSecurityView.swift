import SwiftUI
import LocalAuthentication
import UIKit

/// Fictional puzzle only. Never compares against the actual device passcode.
enum OwnerSecurityPolicy {
    static let fixtureCode = "241607"
    static func accepts(_ candidate: String) -> Bool { candidate == fixtureCode }
    static func canDisplayProtected(session:Bool,passcodeSession:Bool,ownerVerified:Bool,appearanceEnrolled:Bool,active:Bool,sameCheckpoint:Bool)->Bool {
        session && ownerVerified && active && sameCheckpoint && (passcodeSession || appearanceEnrolled)
    }
    static func canUseBiometrics(ownerVerified: Bool, appearanceEnrolled: Bool) -> Bool {
        ownerVerified && appearanceEnrolled
    }
    // Face ID may report while the app is inactive. True background, an
    // invalidated request, or revoked eligibility must never grant access.
    static func acceptsCallback(currentRequest: Bool, eligible: Bool, background: Bool) -> Bool {
        currentRequest && eligible && !background
    }
}

enum ProtectedArea: String {
    case security = "Biometrics & Passcode"
    case photos = "Private album"
    case notes = "Locked notes"
    case files = "Protected files"
}

struct OwnerPasscodeView: View {
    let onSuccess: () -> Void
    var onCancel: (() -> Void)? = nil
    @Environment(\.scenePhase) private var phase
    @State private var digits = ""
    @State private var attempts = 0
    @State private var cooldownUntil = Date.distantPast
    @State private var notice = ""
    @State private var showHint = false
    @AppStorage("lastseen.lab.messageSound") private var sound = true
    @AppStorage("lastseen.lab.messageHaptics") private var haptics = true
    private let keys = ["1","2","3","4","5","6","7","8","9","","0","delete"]
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(ceil(cooldownUntil.timeIntervalSince(context.date))))
            VStack(spacing: 18) {
                Image("System_ProtectedStorage").resizable().scaledToFit().frame(width: 86, height: 86).clipShape(RoundedRectangle(cornerRadius: 22))
                Text("Enter owner passcode").font(.title2.bold())
                Text("Use the fictional six-digit code found in the restored phone. Never enter your actual device passcode.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                HStack(spacing: 13) {
                    ForEach(0..<6, id: \.self) { i in
                        Circle().strokeBorder(notice.isEmpty ? Color.white.opacity(0.65) : Color.red, lineWidth: 1.4)
                            .background(Circle().fill(i < digits.count ? Color.white : .clear))
                            .frame(width: 13, height: 13)
                    }
                }.accessibilityLabel("\(digits.count) of six digits entered")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(keys, id: \.self) { key in
                        if key.isEmpty { Color.clear.frame(height: 56) }
                        else {
                            Button { press(key) } label: {
                                Group {
                                    if key == "delete" { Image(systemName: "delete.left").font(.title2) }
                                    else { Text(key).font(.system(size: 27, weight: .light)) }
                                }.frame(maxWidth: .infinity).frame(height: 56)
                                    .lumaSurface(radius: 18)
                            }.buttonStyle(.plain).accessibilityLabel(key == "delete" ? "Delete digit" : key)
                                .disabled(remaining > 0 || phase != .active)
                        }
                    }
                }.frame(maxWidth: 310)
                if remaining > 0 { Text("Try again in \(remaining)s").font(.caption).foregroundColor(.orange) }
                else if !notice.isEmpty { Text(notice).font(.caption).foregroundColor(.orange) }
                Button(showHint ? "Hide hint" : "Need a hint?") { showHint.toggle() }.font(.subheadline).frame(minHeight: 44)
                if showHint { Text("Hint: check the restored Files and book reservation.").font(.caption).foregroundColor(.secondary) }
                if let onCancel { Button("Cancel", action: onCancel).font(.subheadline) }
            }.padding(20).frame(maxWidth: .infinity)
        }.onChange(of:phase){if $0 != .active {digits="";showHint=false}}
    }
    private func press(_ key: String) {
        guard phase == .active,Date() >= cooldownUntil else{return}
        if key == "delete" {
            if !digits.isEmpty { digits.removeLast() }
            return
        }
        guard digits.count < 6 else { return }
        notice = ""
        PhoneSensoryEngine.play(.passcodeKeypress, sound: sound, haptics: haptics, horrorEnabled: false)
        digits += key
        guard digits.count == 6 else { return }
        if OwnerSecurityPolicy.accepts(digits) {
            digits = ""; notice = ""; attempts = 0; onSuccess()
        } else {
            PhoneSensoryEngine.authentication(.authenticationFailed, sound: sound, haptics: haptics)
            digits = ""; attempts += 1; notice = "Incorrect owner passcode."
            if attempts % 3 == 0 { cooldownUntil = Date().addingTimeInterval(5) }
        }
    }
}

/// Every protected destination authenticates independently. The permission preflight is not an owner grant.
struct ProtectedAreaView: View {
    let area: ProtectedArea
    var onOpened: () -> Void = {}
    @EnvironmentObject private var world:PhoneWorldStore
    @State private var sessionEpoch:UUID?
    @State private var openingRecorded=false
    @AppStorage("lastseen.security.ownerVerified") private var ownerVerified = false
    @AppStorage("lastseen.security.appearanceEnrolled") private var appearanceEnrolled = false
    @Environment(\.scenePhase) private var phase
    @State private var session = false
    @State private var passcodeSession = false
    @State private var context: LAContext?
    @State private var notice = ""
    @State private var enrollment = false
    @AppStorage("lastseen.lab.messageSound") private var sound = true
    @AppStorage("lastseen.lab.messageHaptics") private var haptics = true
    private var canUseBiometrics: Bool {
        OwnerSecurityPolicy.canUseBiometrics(ownerVerified: ownerVerified, appearanceEnrolled: appearanceEnrolled)
    }

    private var displayAllowed:Bool {
        OwnerSecurityPolicy.canDisplayProtected(session:session,passcodeSession:passcodeSession,ownerVerified:ownerVerified,appearanceEnrolled:appearanceEnrolled,active:phase == .active,sameCheckpoint:sessionEpoch == world.checkpointEpoch)
    }
    private func recordOpening() {
        guard displayAllowed,!openingRecorded else{return}
        openingRecorded=true;onOpened()
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if displayAllowed {
                    content
                    Button("Lock this area") { clearSession() }.buttonStyle(.bordered)
                } else if phase == .active {
                    if canUseBiometrics {
                        Button { authenticate(forEnrollment: false) } label: {
                            Label("Authenticate with Device biometrics", systemImage: "faceid").frame(maxWidth: .infinity)
                        }.buttonStyle(.borderedProminent).disabled(context != nil)
                        Text("Or use the owner passcode").font(.caption).foregroundColor(.secondary)
                    }
                    OwnerPasscodeView(onSuccess: {
                        guard phase == .active,context == nil else{return}
                        ownerVerified=true;sessionEpoch=world.checkpointEpoch;passcodeSession=true;session=true
                        PhoneSensoryEngine.authentication(.unlock, sound: sound, haptics: haptics)
                    }).disabled(context != nil)
                } else {Label("Protected content hidden",systemImage:"lock.shield")}
                if !notice.isEmpty { Text(notice).font(.footnote).foregroundColor(.secondary) }
            }.padding()
        }
        .navigationTitle(area.rawValue).navigationBarTitleDisplayMode(.inline)
        .onChange(of:displayAllowed){if $0 {recordOpening()}}
        .onDisappear {clearSession()}
        .onChange(of:phase){if $0 == .background {clearSession()} else if $0 == .active {recordOpening()}}
        .onChange(of:world.checkpointEpoch){_ in clearSession()}
        .onChange(of:ownerVerified){if !$0 {clearSession()}}
        .onChange(of:appearanceEnrolled){if !$0 && !passcodeSession {clearSession()}}
        .sheet(isPresented: $enrollment) {
            VStack(spacing: 20) {
                Image(systemName: "faceid").font(.system(size: 75, weight: .light)).foregroundColor(.teal)
                Text("Add your appearance").font(.title2.bold())
                Text("Register an appearance for this fictional phone. Your device will authenticate its already enrolled owner; no face is recorded or added to iOS.").multilineTextAlignment(.center).foregroundColor(.secondary)
                Button("Authenticate and register") { authenticate(forEnrollment: true) }
                    .buttonStyle(.borderedProminent).disabled(context != nil)
                if !notice.isEmpty { Text(notice).font(.footnote) }
                Button("Not now") { context?.invalidate(); context = nil; enrollment = false }.disabled(context != nil)
            }.padding(25).presentationDetents([.medium, .large])
        }
    }
    @ViewBuilder private var content: some View {
        switch area {
        case .security:
            Image(systemName: "lock.open.fill").font(.largeTitle).foregroundColor(.teal)
            Text("Owner security").font(.title2.bold())
            LabeledContent("Passcode", value: "Verified")
            LabeledContent("Appearance", value: canUseBiometrics ? "Registered" : "Not registered")
            if canUseBiometrics {
                Button("Remove registered appearance", role: .destructive) { appearanceEnrolled = false; notice = "Appearance removed. Owner passcode remains valid." }
                    .buttonStyle(.bordered)
            } else if passcodeSession {
                Button { notice = ""; enrollment = true } label: {
                    Label("Add appearance", systemImage: "faceid")
                }.buttonStyle(.borderedProminent)
            } else {
                Text("Verify the owner passcode to register an appearance.").font(.caption)
                Button("Verify passcode") { clearSession() }
            }
            Text("Biometrics are optional. The discovered fictional passcode always works.").font(.footnote).foregroundColor(.secondary)
        case .photos:
            LumaHeader(title: "Private album", detail: "Owner access verified. Individual photographs still require recovery.", symbol: "lock.open")
            NoraPrivateAlbum()
        case .notes:
            Text("Personal journal").font(.title2.bold())
            Text("I should make more time for myself. Finish the book, call Mum, and put the good photographs somewhere safe.\n\nMaya was right. I need to stop cancelling our plans. Coffee after the bookshop, if everything goes well.").frame(maxWidth: .infinity, alignment: .leading)
            Text("— Nora").font(.caption).foregroundColor(.secondary)
        case .files:
            Text("Personal archive").font(.title2.bold())
            Label("Book receipts and personal records", systemImage: "doc.text")
            Text("Reserved book collected. Personal copy retained.").frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    private func clearSession() {
        let previous = context
        context = nil
        previous?.invalidate()
        PhoneSensoryEngine.cancelAuthentication()
        session=false;passcodeSession=false;enrollment=false;notice=""
        sessionEpoch=nil;openingRecorded=false
    }
    private func authenticate(forEnrollment: Bool) {
        guard context == nil, phase == .active, UIApplication.shared.applicationState != .background,
              forEnrollment ? (ownerVerified && session && passcodeSession && enrollment) : canUseBiometrics else { return }
        let candidate = LAContext()
        candidate.localizedFallbackTitle = ""
        var error: NSError?
        guard candidate.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            notice = "Biometrics unavailable. Use the fictional owner passcode instead."
            return
        }
        context = candidate
        let requestEpoch=world.checkpointEpoch
        candidate.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: forEnrollment ? "Register your appearance in Last Seen." : "Unlock protected fictional records in Last Seen.") { success, error in
            DispatchQueue.main.async {
                guard context === candidate else{return}
                guard requestEpoch==world.checkpointEpoch else{clearSession();return}
                let eligible = forEnrollment ? (ownerVerified && session && passcodeSession && enrollment) : canUseBiometrics
                guard OwnerSecurityPolicy.acceptsCallback(currentRequest: true, eligible: eligible,
                    background: phase == .background || UIApplication.shared.applicationState == .background) else {
                    clearSession()
                    return
                }
                context = nil
                guard success else {
                    if (error as? LAError)?.code == .authenticationFailed {
                        notice = "Authentication failed. The owner passcode still works."
                        PhoneSensoryEngine.authentication(.authenticationFailed, sound: sound, haptics: haptics)
                    } else { notice = "Authentication cancelled or unavailable. The owner passcode still works." }
                    return
                }
                if forEnrollment {
                    guard ownerVerified && session && passcodeSession && enrollment else { return }
                    appearanceEnrolled = true; enrollment = false
                    notice = "Appearance registered."
                    PhoneSensoryEngine.authentication(.unlock, sound: sound, haptics: haptics)
                } else if canUseBiometrics {
                    sessionEpoch=requestEpoch;passcodeSession=false;session=true;notice=""
                    PhoneSensoryEngine.authentication(.unlock, sound: sound, haptics: haptics)
                }
            }
        }
    }
}
