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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 9) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(BerryStyle.strawberry, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("🍓 Strawberry Sound Studio")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text("15 original songs · available offline")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate.opacity(0.65))
                }
            }
            Toggle("Original Berry soundtrack", isOn: $music)
                .onChange(of: music) { _, value in audio.setMusic(value) }
            VStack(alignment: .leading, spacing: 7) {
                Text("YOUR BERRY MIX").font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1).foregroundStyle(BerryStyle.strawberry)
                Picker("Berry music mode", selection: $musicMode) {
                    ForEach(BerryMusicMode.allCases) { mode in
                        Text(mode.shortLabel).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: musicMode) { _, value in
                    audio.setMusicMode(BerryMusicMode(rawValue: value) ?? .balanced)
                }
                Text((BerryMusicMode(rawValue: musicMode) ?? .balanced).description)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.70))
            }
            HStack(spacing: 10) {
                Image(systemName: "music.note")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(BerryStyle.strawberry)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 3) {
                    Text("NOW PLAYING")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1).foregroundStyle(BerryStyle.chocolate.opacity(0.65))
                    Text(audio.currentTrackName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(2)
                        .foregroundStyle(BerryStyle.chocolate)
                    Text(audio.currentTrackNumber > 0
                         ? "Track \(audio.currentTrackNumber) of 15"
                         : "The strawberry playlist is ready")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BerryStyle.chocolate.opacity(0.65))
                }
                Spacer(minLength: 4)
                Button {
                    audio.previousTrack()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 35, height: 43)
                }
                .buttonStyle(.bordered)
                .tint(BerryStyle.strawberry)
                .disabled(!music)
                .accessibilityLabel("Previous Berry song")
                Button {
                    audio.nextTrack()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 47, height: 43)
                }
                .buttonStyle(.borderedProminent)
                .tint(BerryStyle.strawberry)
                .disabled(!music)
                .accessibilityLabel("Play next Berry song")
            }
            .padding(12)
            .background(Color(red: 1, green: 0.92, blue: 0.94),
                        in: RoundedRectangle(cornerRadius: 16))

            Toggle("Shuffle without repeating songs", isOn: $shuffle)
                .onChange(of: shuffle) { _, value in audio.setShuffle(value) }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("🎶 Music Volume").font(.subheadline.bold())
                    Spacer()
                    Text("\(Int(musicVolume * 100))%")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Slider(value: $musicVolume, in: 0...1)
                    .onChange(of: musicVolume) { _, value in audio.setMusicVolume(Float(value)) }
                    .accessibilityLabel("Music volume")
            }
            Toggle("Berry sound effects", isOn: $sound)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("🍰 Sound Effects Volume").font(.subheadline.bold())
                    Spacer()
                    Text("\(Int(effectsVolume * 100))%")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Slider(value: $effectsVolume, in: 0...1)
                    .onChange(of: effectsVolume) { _, value in audio.setEffectVolume(Float(value)) }
                    .accessibilityLabel("Sound effects volume")
            }
            if let error = audio.playbackError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(BerryStyle.strawberry)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(BerryStyle.strawberry)
        .foregroundStyle(BerryStyle.chocolate)
        .padding(18)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23)
            .strokeBorder(BerryStyle.strawberry.opacity(0.18), lineWidth: 1.5))
        .onAppear {
            audio.setMusicMode(BerryMusicMode(rawValue: musicMode) ?? .balanced)
            audio.setShuffle(shuffle)
            audio.setMusicVolume(Float(musicVolume))
            audio.setEffectVolume(Float(effectsVolume))
        }
    }
}
