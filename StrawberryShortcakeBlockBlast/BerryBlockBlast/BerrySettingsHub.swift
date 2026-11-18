import SwiftUI

/// One shared two-column settings destination for Home and all game modes.
/// Values use the original AppStorage keys; merely opening a card cannot
/// reset gameplay, audio or a purchased cosmetic.
struct BerrySettingsHubView: View {
    var onRestart: (() -> Void)? = nil

    @State private var selected: Section?
    @State private var confirmAllAppearance = false


    @AppStorage("berryblockblast.shop.equippedBlockSkin.v056b2") private var blockSkin = "default"
    @AppStorage("berryblockblast.shop.equippedBorder.v056b2") private var borderSkin = "default"
    @AppStorage("berryblockblast.shop.equippedSparkle.v056b2") private var sparkleSkin = "default"
    @AppStorage("berryberryblast.board.surface.v059") private var boardSurface = "original"
    @AppStorage("berryberryblast.frame.overlay.v0511") private var frameID = "original"
    @AppStorage("berryblockblast.previewStyle") private var previewStyle = "ghost"

    @AppStorage("berryblockblast.haptics") private var haptics = true
    @AppStorage("berryblockblast.touchDiagnostics") private var touchDiagnostics = false
    @AppStorage("berryblockblast.music") private var music = true
    @AppStorage("berryblockblast.sound") private var sound = true
    @AppStorage("berryblockblast.musicVolume") private var musicVolume = 0.22
    @AppStorage("berryblockblast.musicMode.v056") private var musicMode = BerryMusicMode.balanced.rawValue
    @AppStorage("berryblockblast.shuffleEnabled.v056") private var shuffleSongs = true
    @AppStorage("berryblockblast.effectVolume") private var effectVolume = 0.65
    @AppStorage("berryberryblast.birthday.month.v0511") private var birthdayMonth = 0
    @AppStorage("berryberryblast.birthday.day.v0511") private var birthdayDay = 0

    private let cols = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]
    private enum Section: String, CaseIterable, Identifiable {
        case gameplay, appearance, audio, celebration, accessibility, restore
        var id: String { rawValue }
        var title: String {
            switch self {
            case .gameplay: return "Gameplay"
            case .appearance: return "Board & Appearance"
            case .audio: return "Audio"
            case .celebration: return "Celebrations"
            case .accessibility: return "Accessibility"
            case .restore: return "Data & Restore"
            }
        }
        var detail: String {
            switch self {
            case .gameplay: return "Preview and controls"
            case .appearance: return "Surfaces, frames, pieces"
            case .audio: return "Music and sound effects"
            case .celebration: return "Your birthday and seasons"
            case .accessibility: return "Readability and feedback"
            case .restore: return "Original looks and saves"
            }
        }
        var image: String {
            switch self {
            case .gameplay: return "BBBIconTools"
            case .appearance: return "BBBIconBoard"
            case .audio: return "BBBIconShop"
            case .celebration: return "BBBIconBirthday"
            case .accessibility: return "BBBIconHelp"
            case .restore: return "BBBIconSettings"
            }
        }
        var fallback: String {
            switch self {
            case .gameplay: return "gamecontroller.fill"
            case .appearance: return "square.grid.3x3.fill"
            case .audio: return "music.note"
            case .celebration: return "gift.fill"
            case .accessibility: return "hand.tap.fill"
            case .restore: return "arrow.uturn.backward.circle.fill"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 13) {
                Text(selected?.title ?? "🍓 Berry Settings")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                    .multilineTextAlignment(.center)

                if let selected {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { self.selected = nil }
                    } label: {
                        Label("All Settings", systemImage: "chevron.left")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .buttonStyle(.bordered)
                    .tint(BerryStyle.strawberry)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    destination(selected)
                } else {
                    Text("Every setting has its own berry card. Your game progress is never reset by appearance changes.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(BerryStyle.chocolate.opacity(0.76))
                    LazyVGrid(columns: cols, spacing: 11) {
                        ForEach(Section.allCases) { category in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    selected = category
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    BerryApprovedArtwork(name: category.image,
                                                         fallback: category.fallback,
                                                         size: 67)
                                    Text(category.title)
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                    Text(category.detail)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundStyle(BerryStyle.chocolate.opacity(0.73))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .frame(maxWidth: .infinity, minHeight: 153)
                                .padding(8)
                                .background(.white, in: RoundedRectangle(cornerRadius: 19))
                                .overlay(RoundedRectangle(cornerRadius: 19)
                                    .strokeBorder(BerryStyle.strawberry.opacity(0.24), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Text("Berry Berry Blast 0.5.11 • Build 1")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.67))
            }
            .padding(17)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(LinearGradient(colors: [BerryStyle.cream, BerryStyle.softPink],
                                   startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea())
        .confirmationDialog("Restore all original cosmetics?",
                            isPresented: $confirmAllAppearance,
                            titleVisibility: .visible) {
            Button("Restore All Cosmetic Defaults") {
                boardSurface = "original"
                frameID = "original"
                blockSkin = "default"
                borderSkin = "default"
                sparkleSkin = "default"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your purchases, strawberries, score, Daily Harvest and saved gardens remain untouched.")
        }
    }

    @ViewBuilder
    private func destination(_ section: Section) -> some View {
        switch section {
        case .gameplay:
            Text("PLACEMENT PREVIEW")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            LazyVGrid(columns: cols, spacing: 11) {
                choice("Sweet Assist", detail: "Colored placement preview",
                       icon: "checkmark.square.fill", selected: previewStyle == "ghost") { previewStyle = "ghost" }
                choice("Outline Only", detail: "Precise shape boundaries",
                       icon: "square.dashed", selected: previewStyle == "outline") { previewStyle = "outline" }
                choice("Mystery Garden", detail: "No preview assistance",
                       icon: "questionmark.square", selected: previewStyle == "mystery") { previewStyle = "mystery" }
                if let onRestart {
                    choice("Fresh Garden", detail: "Restart the current run",
                           icon: "arrow.clockwise", selected: false, action: onRestart)
                }
            }
        case .appearance:
            Text("EMPTY BOARD SQUARES")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            LazyVGrid(columns: cols, spacing: 11) {
                ForEach(["original", "cream", "glass", "picnic", "garden", "seed"], id: \.self) { id in
                    choice(surfaceName(id),
                           detail: id == "original" ? "Default clear squares" : "Optional cell treatment",
                           icon: "square.grid.3x3.fill",
                           selected: boardSurface == id) { boardSurface = id }
                }
            }
            Text("DECORATIVE FRAMES · FREE & OPTIONAL")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            BerryBoardFrameGrid()
            BerryBoardConceptGrid()
            Text("Blocks remain independent. Pick any frame without changing your squares or puzzle pieces.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
        case .audio:
            LazyVGrid(columns: cols, spacing: 11) {
                toggleCard("Music", detail: "Original soundtrack", icon: "music.note",
                           value: $music)
                toggleCard("Sound Effects", detail: "Berry chimes and pops", icon: "speaker.wave.2.fill",
                           value: $sound)
                toggleCard("Shuffle Songs", detail: "Avoid repeating the same berry track",
                           icon: "shuffle", value: $shuffleSongs)
                ForEach(BerryMusicMode.allCases) { mode in
                    choice(mode.shortLabel, detail: mode.description,
                           icon: "music.note.list", selected: musicMode == mode.rawValue) {
                        musicMode = mode.rawValue
                        BerryAudio.shared.setMusicMode(mode)
                    }
                }
                sliderCard("Music Volume", value: $musicVolume, icon: "music.note.list")
                sliderCard("Effect Volume", value: $effectVolume, icon: "speaker.wave.3.fill")
                choice("Test Berry Chimes", detail: "Hear the current effect volume",
                       icon: "bell.fill", selected: false) {
                    if sound { BerryAudio.shared.play(.clear) }
                }
            }
            .onChange(of: music) { BerryAudio.shared.setMusic($0) }
            .onChange(of: shuffleSongs) { BerryAudio.shared.setShuffle($0) }
            .onChange(of: musicVolume) { BerryAudio.shared.setMusicVolume(Float($0)) }
            .onChange(of: effectVolume) { BerryAudio.shared.setEffectVolume(Float($0)) }
        case .celebration:
            Text("Your birthday stays on this iPhone. Only month and day are saved, not your birth year.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)
            LazyVGrid(columns: cols, spacing: 11) {
                VStack(spacing: 9) {
                    Image(systemName: "calendar")
                        .font(.system(size: 23, weight: .bold))
                    Text("Birthday Month").bold()
                    Picker("Month", selection: $birthdayMonth) {
                        Text("Not Set").tag(0)
                        ForEach(1...12, id: \.self) { n in
                            Text(DateFormatter().monthSymbols[n - 1]).tag(n)
                        }
                    }
                    .pickerStyle(.menu)
                }.settingCard()
                VStack(spacing: 9) {
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 23, weight: .bold))
                    Text("Birthday Day").bold()
                    Picker("Day", selection: $birthdayDay) {
                        Text("Not Set").tag(0)
                        ForEach(1...31, id: \.self) { n in Text("\(n)").tag(n) }
                    }
                    .pickerStyle(.menu)
                }.settingCard()
                ForEach(BerryFrameCatalog.choices.filter { $0.id != "original" }) { theme in
                    choice(theme.title, detail: theme.detail, icon: theme.symbol,
                           selected: frameID == theme.id) { frameID = theme.id }
                }
            }
            if birthdayToday {
                Text("🎂 Happy Birthday! Your Berry Birthday frame is ready to equip.")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
            }
        case .accessibility:
            LazyVGrid(columns: cols, spacing: 11) {
                toggleCard("Haptics", detail: "Feel valid and invalid placement",
                           icon: "hand.tap.fill", value: $haptics)
                toggleCard("Touch Diagnostics", detail: "Show gesture debugging details",
                           icon: "hand.point.up.left.fill", value: $touchDiagnostics)
                choice("Sweet Assist", detail: "Most readable placement feedback",
                       icon: "checkmark.shield.fill",
                       selected: previewStyle == "ghost") { previewStyle = "ghost" }
                choice("High Contrast Board", detail: "Return to original clear squares",
                       icon: "square.grid.3x3.fill",
                       selected: boardSurface == "original") { boardSurface = "original" }
            }
        case .restore:
            LazyVGrid(columns: cols, spacing: 11) {
                choice("Restore Board Only", detail: "Keeps current block skin",
                       icon: "square.grid.3x3.fill", selected: boardSurface == "original" && frameID == "original") {
                    boardSurface = "original"
                    frameID = "original"
                    borderSkin = "default"
                }
                choice("Restore All Cosmetics", detail: "Requires confirmation",
                       icon: "arrow.uturn.backward.circle.fill", selected: false) {
                    confirmAllAppearance = true
                }
                BerryGridInfoTile(title: "Saved Games",
                                 detail: "Your saves and wallet remain local and untouched",
                                 art: "BerryCollection", value: "Protected")
                BerryGridInfoTile(title: "App Version",
                                 detail: "iOS 16 compatible",
                                 art: "Milestone", value: "0.5.11 • 1")
            }
        }
    }

    private var birthdayToday: Bool {
        let today = Date()
        let calendar = Calendar.current
        return birthdayMonth > 0 && birthdayDay > 0 &&
            calendar.component(.month, from: today) == birthdayMonth &&
            calendar.component(.day, from: today) == birthdayDay
    }
    private func surfaceName(_ id: String) -> String {
        switch id {
        case "original": return "Original Board"
        case "cream": return "Strawberry Cream"
        case "glass": return "Frosted Candy Glass"
        case "picnic": return "Berry Picnic"
        case "garden": return "Garden Patch"
        default: return "Seed Mosaic"
        }
    }
    private func choice(_ name: String, detail: String, icon: String,
                        selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(selected ? BerryStyle.leaf : BerryStyle.strawberry)
                Text(name)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .lineLimit(2).multilineTextAlignment(.center)
                Text(detail)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.76))
                    .lineLimit(3).multilineTextAlignment(.center)
                if selected {
                    Text("✓ SELECTED").font(.system(size: 10, weight: .black))
                        .foregroundStyle(BerryStyle.leaf)
                }
            }
            .foregroundStyle(BerryStyle.chocolate)
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(9)
            .background(.white, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17)
                .strokeBorder(selected ? BerryStyle.leaf : BerryStyle.strawberry.opacity(0.22),
                              lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
    private func toggleCard(_ title: String, detail: String, icon: String,
                            value: Binding<Bool>) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 25))
                .foregroundStyle(BerryStyle.strawberry)
            Text(title).font(.system(size: 13, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
            Text(detail).font(.system(size: 10))
                .multilineTextAlignment(.center)
            Toggle(title, isOn: value).labelsHidden().tint(BerryStyle.leaf)
        }
        .settingCard()
    }
    private func sliderCard(_ title: String, value: Binding<Double>,
                            icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 24))
                .foregroundStyle(BerryStyle.strawberry)
            Text(title).font(.system(size: 12, weight: .black, design: .rounded))
            Slider(value: value, in: 0...1).tint(BerryStyle.strawberry)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(BerryStyle.leaf)
        }
        .settingCard()
    }
}

private extension View {
    func settingCard() -> some View {
        self
            .foregroundStyle(BerryStyle.chocolate)
            .frame(maxWidth: .infinity, minHeight: 137)
            .padding(10)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(BerryStyle.strawberry.opacity(0.22), lineWidth: 1))
    }
}
