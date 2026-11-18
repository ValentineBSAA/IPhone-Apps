import SwiftUI

/// Shared music controls used on the home screen, in More Adventures,
/// and in-game. All preferences are stored across updates via AppStorage.
struct BerryMusicSettingsView: View {
    @ObservedObject private var audio = BerryAudio.shared
    @AppStorage("berryblockblast.music") private var music = true
    @AppStorage("berryblockblast.sound") private var sound = true
    @AppStorage("berryblockblast.musicVolume") private var musicVolume = 0.22
    @AppStorage("berryblockblast.effectVolume") private var effectsVolume = 0.65
    @AppStorage("berryblockblast.musicMode.v056") private var musicMode = BerryMusicMode.balanced.rawValue
    @AppStorage("berryblockblast.shuffleEnabled.v056") private var shuffle = true

    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 12) {
            Text("🍓 Strawberry Sound Studio")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            Text("51 original tracks · all on your iPhone")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
            LazyVGrid(columns: columns, spacing: 10) {
                audioCard("Music", icon: "music.note") {
                    Toggle("Soundtrack", isOn: $music)
                        .labelsHidden().tint(BerryStyle.leaf)
                        .onChange(of: music) { audio.setMusic($0) }
                }
                audioCard("Sound Effects", icon: "speaker.wave.2.fill") {
                    Toggle("Effects", isOn: $sound)
                        .labelsHidden().tint(BerryStyle.leaf)
                }
                audioCard("Shuffle Songs", icon: "shuffle") {
                    Toggle("Shuffle", isOn: $shuffle)
                        .labelsHidden().tint(BerryStyle.leaf)
                        .onChange(of: shuffle) { audio.setShuffle($0) }
                }
                audioCard("Berry Music Mix", icon: "music.note.list") {
                    Picker("Mix", selection: $musicMode) {
                        ForEach(BerryMusicMode.allCases) { mode in
                            Text(mode.shortLabel).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: musicMode) {
                        audio.setMusicMode(BerryMusicMode(rawValue: $0) ?? .balanced)
                    }
                }
                audioCard("Music Volume", icon: "music.note") {
                    Slider(value: $musicVolume, in: 0...1)
                        .onChange(of: musicVolume) { audio.setMusicVolume(Float($0)) }
                    Text("\(Int(musicVolume * 100))%")
                        .font(.caption.bold())
                }
                audioCard("Effects Volume", icon: "speaker.wave.3.fill") {
                    Slider(value: $effectsVolume, in: 0...1)
                        .onChange(of: effectsVolume) { audio.setEffectVolume(Float($0)) }
                    Text("\(Int(effectsVolume * 100))%")
                        .font(.caption.bold())
                }
            }
            HStack(spacing: 9) {
                Image(systemName: "music.note")
                    .foregroundStyle(BerryStyle.strawberry)
                VStack(alignment: .leading, spacing: 3) {
                    Text("NOW PLAYING")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                    Text(audio.currentTrackName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .lineLimit(2)
                    Text(audio.currentTrackNumber > 0 ?
                         "Track \(audio.currentTrackNumber) of \(BerryAudio.tracks.count)" :
                         "Berry playlist is ready")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                Spacer(minLength: 0)
                Button { audio.previousTrack() } label: {
                    Image(systemName: "backward.end.fill")
                }
                .disabled(!music)
                Button { audio.nextTrack() } label: {
                    Image(systemName: "forward.end.fill")
                }
                .disabled(!music)
            }
            .padding(13)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(BerryStyle.strawberry.opacity(0.22), lineWidth: 1))
            if let error = audio.playbackError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(BerryStyle.strawberry)
            }
        }
        .foregroundStyle(BerryStyle.chocolate)
        .tint(BerryStyle.strawberry)
        .onAppear {
            audio.setMusicMode(BerryMusicMode(rawValue: musicMode) ?? .balanced)
            audio.setShuffle(shuffle)
            audio.setMusicVolume(Float(musicVolume))
            audio.setEffectVolume(Float(effectsVolume))
        }
    }

    private func audioCard<Content: View>(_ title: String, icon: String,
                 @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(BerryStyle.strawberry)
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
            content()
        }
        .frame(maxWidth: .infinity, minHeight: 113)
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17)
            .strokeBorder(BerryStyle.strawberry.opacity(0.22), lineWidth: 1))
    }
}
