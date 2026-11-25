import SwiftUI
import AVFoundation

struct PhoneSoundStudio: View {
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var horrorEnabled: Bool
    @Environment(\.scenePhase) private var phase
    @State private var playing: PhoneCue?
    @State private var previewTask: Task<Void, Never>?
    var body: some View {
        List {
            Section {
                Toggle("Phone sounds", isOn: $sound)
                Toggle("Phone vibrations", isOn: $haptics)
                Toggle("Horror sensory effects", isOn: $horrorEnabled)
                Button(role: .destructive) { stop() } label: {
                    Label("Stop preview", systemImage: "stop.circle")
                }.disabled(playing == nil)
            } footer: {
                Text("Original creator-supplied recordings. Each plays once. Physical vibration is independent of the recording.")
            }
            Section("Everyday phone") {
                ForEach(PhoneCue.allCases.filter { !$0.isHorror }, id: \.self) { cue in row(cue) }
            }
            Section("Horror & suspense") {
                ForEach(PhoneCue.allCases.filter { $0.isHorror }, id: \.self) { cue in row(cue) }
            }
        }
        .navigationTitle("Sound Library")
        .onDisappear { stop() }
        .onChange(of: phase) { if $0 != .active { stop() } }
        .onChange(of: sound) { if !$0 { PhoneSensoryEngine.stopSound() } }
        .onChange(of: haptics) { if !$0 { PhoneSensoryEngine.stopHaptics() } }
        .onChange(of: horrorEnabled) { if !$0 && playing?.isHorror == true { stop() } }
    }
    private func row(_ cue: PhoneCue) -> some View {
        Button {
            if playing == cue { stop(); return }
            stop()
            let duration = PhoneSensoryEngine.play(cue, sound: sound, haptics: haptics, horrorEnabled: horrorEnabled)
            playing = cue
            previewTask = Task { @MainActor in
                do { try await Task.sleep(nanoseconds: UInt64(max(cue.duration, duration) * 1_000_000_000)) }
                catch { return }
                if !Task.isCancelled { playing = nil }
            }
        } label: {
            HStack {
                Image(systemName: playing == cue ? "stop.circle.fill" : "play.circle")
                    .font(.title2)
                Text(cue.title)
                Spacer()
                Text("Once").font(.caption).foregroundColor(.secondary)
            }.padding(.vertical, 4)
        }.disabled((cue.isHorror && !horrorEnabled) || (!sound && !haptics))
    }
    private func stop() {
        previewTask?.cancel(); previewTask = nil
        PhoneSensoryEngine.stop()
        playing = nil
    }
}
