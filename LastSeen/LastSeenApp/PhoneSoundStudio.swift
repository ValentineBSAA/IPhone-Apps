import SwiftUI
import AVFoundation

enum PhoneSoundPreview: Hashable {
    case phone(PhoneCue), restart(String)
    var title: String {
        switch self {
        case .phone(let cue): return cue.title
        case .restart(let name):
            switch name {
            case "RespringDown": return "Respring start"
            case "RespringUp": return "Respring finish"
            case "UserspaceDown": return "Userspace reboot start"
            case "UserspaceUp": return "Userspace reboot finish"
            default: return "Restart sound"
            }
        }
    }
    var isHorror: Bool {
        if case .phone(let cue) = self { return cue.isHorror }
        return false
    }
    var isRestart: Bool {
        if case .restart = self { return true }
        return false
    }
    var url: URL? {
        switch self {
        case .phone(let cue): return cue.audioURL()
        case .restart(let name): return Bundle.main.url(forResource: name, withExtension: "wav")
        }
    }
    var profile: PhoneHapticProfile? {
        if case .phone(let cue) = self { return .cue(cue) }
        return nil
    }
}

struct PhoneSoundStudio: View {
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var horrorEnabled: Bool
    @AppStorage("lastseen.recovery.effects") private var restartEffects = true
    @Environment(\.scenePhase) private var phase
    @State private var playing: PhoneSoundPreview?
    @State private var owner: UUID?
    @State private var previewTask: Task<Void, Never>?
    @State private var notice = ""
    var body: some View {
        List {
            Section {
                Toggle("Phone sounds", isOn: $sound)
                Toggle("Phone vibrations", isOn: $haptics)
                Toggle("Horror sensory effects", isOn: $horrorEnabled)
                Toggle("Restart sound effects", isOn: $restartEffects)
                Button(role: .destructive) { stop() } label: {
                    Label("Stop preview", systemImage: "stop.circle")
                }.disabled(playing == nil)
                if !notice.isEmpty { Text(notice).font(.caption).foregroundColor(.secondary) }
            } footer: {
                Text("19 original recordings. Each plays once. Genuine phone alerts take precedence. Restart previews do not restart the phone.")
            }
            Section("Everyday phone") {
                ForEach(PhoneCue.allCases.filter { !$0.isHorror }, id: \.self) { cue in row(.phone(cue)) }
            }
            Section("Horror & suspense") {
                ForEach(PhoneCue.allCases.filter { $0.isHorror }, id: \.self) { cue in row(.phone(cue)) }
            }
            Section("Restart & respring") {
                ForEach(RestartAudio.assetNames, id: \.self) { name in row(.restart(name)) }
            }
        }
        .navigationTitle("Sound Library")
        .onDisappear { stop() }
        .onChange(of: phase) { if $0 != .active { stop() } }
        .onChange(of: sound) { _ in stop() }
        .onChange(of: haptics) { _ in stop() }
        .onChange(of: restartEffects) { if !$0 && playing?.isRestart == true { stop() } }
        .onChange(of: horrorEnabled) { if !$0 && playing?.isHorror == true { stop() } }
    }
    private func row(_ item: PhoneSoundPreview) -> some View {
        Button {
            if playing == item { stop(); return }
            stop()
            let token = UUID()
            let started = PhoneSensoryEngine.preview(owner: token, url: item.url, profile: item.profile,
                sound: item.isRestart ? restartEffects : sound, haptics: !item.isRestart && haptics,
                horror: item.isHorror)
            guard started else {
                notice = "Preview unavailable while another sound is playing, or the recording could not be opened. Try again."
                return
            }
            owner = token
            playing = item
            notice = ""
            previewTask = Task { @MainActor in
                while !Task.isCancelled, PhoneSensoryEngine.previewIsActive(token) {
                    do { try await Task.sleep(nanoseconds: 100_000_000) } catch { return }
                }
                guard !Task.isCancelled, owner == token else { return }
                owner = nil; playing = nil; previewTask = nil
            }
        } label: {
            HStack {
                Image(systemName: playing == item ? "stop.circle.fill" : "play.circle").font(.title2)
                Text(item.title)
                Spacer()
                Text("Once").font(.caption).foregroundColor(.secondary)
            }.padding(.vertical, 4)
        }.disabled(item.isRestart ? !restartEffects : ((item.isHorror && !horrorEnabled) || (!sound && !haptics)))
    }
    private func stop() {
        previewTask?.cancel(); previewTask = nil
        if let owner { PhoneSensoryEngine.stopPreview(owner: owner) }
        owner = nil; playing = nil; notice = ""
    }
}
