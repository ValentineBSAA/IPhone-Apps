import SwiftUI

/// The full soundtrack lives in its own destination rather than under the
/// More Adventures menu. Roles and titles come from the 51-song source manifest.
struct BerryJukeboxView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audio = BerryAudio.shared
    @AppStorage("berryblockblast.music") private var musicOn = true

    private let sections: [(title: String, role: String, icon: String, subtitle: String)] = [
        ("🍓 Strawberry Village", "menu", "house.fill", "11 menu themes"),
        ("🧁 Relaxed Berry Garden", "gameplay", "leaf.fill", "22 calm and upbeat game tracks"),
        ("⚡ Berry Blitz", "blitz", "bolt.fill", "7 dedicated timed-race tracks"),
        ("🏆 Sweet Victories", "results", "crown.fill", "11 full-length results themes")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    BerryMusicSettingsView()
                    Text("🎼 51 Original Berry Songs")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("Every recording is bundled inside your iPhone. No Wi-Fi or streaming required.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                        .multilineTextAlignment(.center)
                    ForEach(sections, id: \.role) { section in
                        VStack(alignment: .leading, spacing: 9) {
                            Label(section.title, systemImage: section.icon)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(BerryStyle.strawberry)
                            Text(section.subtitle)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
                            ForEach(BerryAudio.tracks.filter { $0.role == section.role }) { track in
                                Button {
                                    if !musicOn { musicOn = true; audio.setMusic(true) }
                                    audio.selectTrack(track.id - 1)
                                    audio.play(.menuSelect)
                                } label: {
                                    HStack(spacing: 11) {
                                        Image(systemName: audio.currentTrackNumber == track.id
                                              ? "waveform" : "music.note")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 39, height: 39)
                                            .background(audio.currentTrackNumber == track.id
                                                ? BerryStyle.strawberry : BerryStyle.leaf,
                                                in: RoundedRectangle(cornerRadius: 11))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(track.title)
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .lineLimit(2)
                                            Text(String(format: "%02d", track.id) + " • " +
                                                (track.mood == "calm" ? "Cozy" : "Upbeat"))
                                                .font(.caption2)
                                                .foregroundStyle(BerryStyle.chocolate.opacity(0.62))
                                        }
                                        Spacer()
                                        if audio.currentTrackNumber == track.id {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .foregroundStyle(BerryStyle.strawberry)
                                        } else {
                                            Image(systemName: "play.fill")
                                                .foregroundStyle(BerryStyle.strawberry.opacity(0.75))
                                        }
                                    }
                                    .foregroundStyle(BerryStyle.chocolate)
                                    .padding(10)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(BerryStyle.strawberry.opacity(0.16), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .background(Color(red: 1, green: 0.91, blue: 0.93).opacity(0.75),
                                    in: RoundedRectangle(cornerRadius: 22))
                    }
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(BerryStyle.cream.ignoresSafeArea())
            .navigationTitle("🍓 Strawberry Jukebox")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { audio.play(.menuBack); dismiss() }
                        .fontWeight(.bold)
                        .tint(BerryStyle.strawberry)
                }
            }
        }
        .presentationDetents([.large])
    }
}
