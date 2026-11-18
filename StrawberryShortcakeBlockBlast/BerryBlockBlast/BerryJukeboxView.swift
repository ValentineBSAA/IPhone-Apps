import SwiftUI

/// The full soundtrack lives in its own destination rather than under the
/// More Adventures menu. Roles and titles come from the 51-song source manifest.
struct BerryJukeboxView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audio = BerryAudio.shared
    @AppStorage("berryblockblast.music") private var musicOn = true
    @State private var selectedRole: String? = nil

    private let sections: [(title: String, role: String, icon: String, subtitle: String)] = [
        ("🍓 Strawberry Village", "menu", "house.fill", "11 menu themes"),
        ("🧁 Relaxed Berry Garden", "gameplay", "leaf.fill", "22 calm and upbeat game tracks"),
        ("⚡ Berry Blitz", "blitz", "bolt.fill", "7 dedicated timed-race tracks"),
        ("🏆 Sweet Victories", "results", "crown.fill", "11 full-length results themes")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BerryMusicSettingsView()
                    Text("🎼 51 Original Berry Songs")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("Your entire soundtrack is stored on the iPhone, ready to play offline.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                        .multilineTextAlignment(.center)
                    if let role = selectedRole {
                        HStack {
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    selectedRole = nil
                                }
                            } label: {
                                Label("All Playlists", systemImage: "chevron.left")
                            }
                            .buttonStyle(.bordered)
                            .tint(BerryStyle.strawberry)
                            Spacer()
                            Text(sections.first(where: { $0.role == role })?.title ?? "Berry Songs")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(BerryStyle.chocolate)
                                .lineLimit(1)
                        }
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                            GridItem(.flexible(), spacing: 11)], spacing: 11) {
                            ForEach(BerryAudio.tracks.filter { $0.role == role }) { track in
                                Button {
                                    if !musicOn {
                                        musicOn = true
                                        audio.setMusic(true)
                                    }
                                    audio.selectTrack(track.id - 1)
                                    audio.play(.menuSelect)
                                } label: {
                                    VStack(spacing: 7) {
                                        Image(systemName: audio.currentTrackNumber == track.id ?
                                              "waveform" : "music.note")
                                            .font(.system(size: 29, weight: .bold))
                                            .foregroundStyle(BerryStyle.strawberry)
                                            .frame(width: 66, height: 66)
                                            .background(BerryStyle.softPink,
                                                        in: RoundedRectangle(cornerRadius: 18))
                                        Text(track.title)
                                            .font(.system(size: 13, weight: .black, design: .rounded))
                                            .foregroundStyle(BerryStyle.chocolate)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(3)
                                        Text(String(format: "Track %02d", track.id))
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
                                        Text(audio.currentTrackNumber == track.id ?
                                             "♫ Now Playing" : "▶ Play Track")
                                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                                            .foregroundStyle(audio.currentTrackNumber == track.id ?
                                                BerryStyle.leaf : BerryStyle.strawberry)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 165)
                                    .padding(10)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 19))
                                    .overlay(RoundedRectangle(cornerRadius: 19)
                                        .strokeBorder(BerryStyle.strawberry.opacity(
                                            audio.currentTrackNumber == track.id ? 0.72 : 0.25),
                                            lineWidth: audio.currentTrackNumber == track.id ? 2 : 1))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Play " + track.title)
                            }
                        }
                    } else {
                        Text("CHOOSE A BERRY PLAYLIST")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                            GridItem(.flexible(), spacing: 11)], spacing: 11) {
                            ForEach(sections, id: \.role) { section in
                                BerryGridNavigationTile(
                                    title: section.title,
                                    detail: section.subtitle,
                                    art: section.role == "menu" ? "StrawberryJukebox" :
                                         section.role == "gameplay" ? "SweetEndless" :
                                         section.role == "blitz" ? "Milestone" : "Champion",
                                    caption: "\(BerryAudio.tracks.filter { $0.role == section.role }.count) Tracks") {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        selectedRole = section.role
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
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
