import SwiftUI

/// Original, entirely fictional onboarding. No cloud client, credentials or device permissions.
struct PhoneSetupRoot: View {
    @AppStorage("lastseen.setup.stage") private var stage = 0
    @AppStorage("lastseen.setup.progress") private var progress = 0
    @AppStorage("lastseen.setup.device") private var device = "My phone"
    @AppStorage("lastseen.lab.wallpaper") private var wallpaper = 0
    @AppStorage("lastseen.lab.biometricUnlock") private var biometricUnlock = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let restoreLabels = ["Preparing your phone", "Restoring contacts", "Restoring messages", "Restoring photos", "Preparing applications", "Finishing setup"]
    @State private var didHandleReplay = false
    @State private var justRestored = false
    @State private var restoreFailed = false
    private let replay = ProcessInfo.processInfo.arguments.contains("--replay-setup")

    var body: some View {
        Group {
            if stage >= 5 {
                PhoneLabView(startUnlocked: justRestored && !biometricUnlock)
            } else {
                setup
            }
        }
        .preferredColorScheme(.dark)
        .alert("Unable to finish restore", isPresented: $restoreFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The local backup could not be saved. Your existing data has not been erased. Try again.")
        }
        .onAppear {
            if replay && !didHandleReplay { didHandleReplay = true; stage = 0; progress = 0 }
        }
    }

    private var setup: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.13, green: 0.29, blue: 0.35), Color(red: 0.07, green: 0.10, blue: 0.17)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Text("PHONE SETUP").font(.caption.weight(.semibold)).tracking(3)
                    Spacer()
                    Text("\(min(stage + 1, 5)) / 5").font(.caption.monospacedDigit())
                }.foregroundColor(.white.opacity(0.6))
                ScrollView {
                    VStack(spacing: 22) {
                        switch stage {
                        case 0:
                            hero("sparkles", title: "Hello.", detail: "A new phone. A fresh start.")
                            Text("Set up your device in a few simple steps.").foregroundColor(.secondary)
                        case 1:
                            hero("iphone", title: "Make it yours", detail: "Choose a name for your new device.")
                            ForEach(["My phone", "Personal phone", "Everyday phone"], id: \.self) { name in
                                option(name, selected: device == name) { device = name }
                            }
                        case 2:
                            hero("paintpalette", title: "Your style", detail: "Choose your first wallpaper.")
                            option("Coastal", selected: wallpaper == 0) { wallpaper = 0 }
                            option("Dusk", selected: wallpaper == 1) { wallpaper = 1 }
                            Toggle("Use real Face ID / Touch ID", isOn: $biometricUnlock)
                                .tint(.teal)
                            Text("Optional. Your iPhone handles authentication when you unlock the fictional phone. No facial data is collected. You can play without biometrics.")
                                .font(.caption).foregroundColor(.secondary)
                        case 3:
                            hero("cloud", title: "Transfer your data", detail: "A saved device backup is available for this phone.")
                            VStack(alignment: .leading, spacing: 9) {
                                Label("Recommended backup", systemImage: "checkmark.seal")
                                    .font(.headline)
                                Text("Contacts, messages, photos and app data").font(.subheadline)
                                Text("Ready to restore").font(.caption).foregroundColor(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding()
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                            Text("No account sign-in is required. This is a simulated transfer inside the game.").font(.caption).foregroundColor(.secondary)
                        default:
                            hero("arrow.down.circle", title: "Restoring your phone", detail: "Getting everything ready for you.")
                            ProgressView(value: Double(progress), total: 100)
                                .tint(.teal)
                            Text("\(progress)%").font(.system(size: 36, weight: .light, design: .rounded)).monospacedDigit()
                            Text(progress >= 100 ? "Ready to use" : restoreLabels[min(progress * restoreLabels.count / 100, restoreLabels.count - 1)])
                                .foregroundColor(.secondary)
                            if progress < 100 {
                                Button("Skip animation") { progress = 100 }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }.frame(maxWidth: .infinity).padding(.vertical, 24)
                }.scrollIndicators(.hidden)
                if stage < 4 || progress >= 100 {
                    Button {
                        if stage == 4 {
                            do { try RestoredPhoneBackup.restore(); justRestored = true }
                            catch { restoreFailed = true; return }
                        }
                        if stage == 3 { progress = 0 }
                        if reduceMotion { stage += 1 }
                        else { withAnimation(.easeInOut(duration: 0.22)) { stage += 1 } }
                    } label: {
                        Text(stage == 0 ? "Get started" : stage == 3 ? "Restore backup" : stage == 4 ? "Welcome to your phone" : "Continue")
                            .font(.headline).frame(maxWidth: .infinity).padding(15)
                    }.buttonStyle(.borderedProminent).tint(.teal)
                }
                if stage > 0 && stage < 4 {
                    Button("Back") { stage -= 1 }.font(.subheadline)
                }
                Text("LAST SEEN · Fictional device setup").font(.caption2).foregroundColor(.white.opacity(0.5))
            }.padding(24)
        }
        .task(id: stage) {
            guard stage == 4 else { return }
            if reduceMotion { progress = 100; return }
            while progress < 100 && !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 75_000_000) } catch { return }
                guard !Task.isCancelled else { return }
                progress = min(100, progress + 2)
            }
        }
    }

    private func hero(_ symbol: String, title: String, detail: String) -> some View {
        VStack(spacing: 13) {
            Image(systemName: symbol).font(.system(size: 64, weight: .light))
                .foregroundColor(.teal).padding(.bottom, 10)
            Text(title).font(.system(size: 34, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(detail).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding(.vertical, 14)
    }

    private func option(_ name: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(name)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected ? .teal : .secondary)
            }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

