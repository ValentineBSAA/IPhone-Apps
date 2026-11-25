import SwiftUI

enum LumaDesign {
    static let accent = Color(red: 0.41, green: 0.80, blue: 0.84)
    static let iris = Color(red: 0.51, green: 0.46, blue: 0.87)
    static let background = Color(red: 0.043, green: 0.063, blue: 0.098)
    static let surface = Color(red: 0.09, green: 0.13, blue: 0.19)
    static let raised = Color(red: 0.14, green: 0.19, blue: 0.26)
    static let wallpaperNames = ["Coastal Dusk", "Velvet Plum", "Midnight Glass", "Blue Hour Glass", "Titanium Flow", "Neon Studio", "Pearl Mist", "City After Midnight", "Aurora Night", "Bookshop Morning", "Obsidian Wave"]
    static let wallpaperAssets = ["Wallpaper_CoastalDusk", "Wallpaper_VelvetPlum", "", "Wallpaper_BlueHourGlass", "Wallpaper_TitaniumFlow", "Wallpaper_NeonStudio", "Wallpaper_PearlMist", "Wallpaper_CityAfterMidnight", "Wallpaper_AuroraNight", "Wallpaper_BookshopMorning", "Wallpaper_ObsidianWave"]
    static func wallpaperChoices(midnight: Bool) -> [Int] {
        wallpaperNames.indices.filter { $0 != 2 || midnight }
    }
    static func resolvedWallpaper(_ value: Int, midnight: Bool) -> Int {
        wallpaperChoices(midnight: midnight).contains(value) ? value : 0
    }
    static let iconNames = ["Messages","Contacts","Photos","Notes","Calendar","Mail","Files","Browser","Clock","Calculator","Settings","Phone","Save"]
    static let assetNames = wallpaperAssets.filter { !$0.isEmpty } + iconNames.map { "Icon_" + $0 } + ["Brand_LumaOS","System_Recovery","System_ProtectedStorage"]
}

struct LumaSurface: ViewModifier {
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
    }
}
extension View {
    func lumaSurface(radius: CGFloat = 22) -> some View { modifier(LumaSurface(radius: radius)) }
}
struct LumaHeader: View {
    let title: String
    let detail: String
    var symbol: String = "sparkle"
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 26, weight: .medium))
                .foregroundColor(LumaDesign.accent).frame(width: 54, height: 54).lumaSurface(radius: 16)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.title2.weight(.semibold))
                Text(detail).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }.padding(16).lumaSurface()
    }
}
struct LumaWallpaperSettings: View {
    @Binding var home: Int
    @Binding var lock: Int
    @Binding var blur: Bool
    let midnight: Bool
    @State private var editingLock = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    preview("Home Screen", value: home, lockScreen: false)
                    preview("Lock Screen", value: lock < 0 ? home : lock, lockScreen: true)
                }
                Picker("Customize", selection: $editingLock) {
                    Text("Home").tag(false); Text("Lock Screen").tag(true)
                }.pickerStyle(.segmented)
                Toggle("Soften home wallpaper", isOn: $blur)
                if editingLock { Button("Match Home Screen") { lock = -1 }.frame(minHeight: 44) }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 14) {
                    ForEach(LumaDesign.wallpaperChoices(midnight: midnight), id: \.self) { index in
                        Button {
                            if editingLock { lock = index } else { home = index }
                        } label: {
                            VStack(spacing: 7) {
                                PhoneWallpaper(selection: index).aspectRatio(0.49, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .overlay(alignment: .bottomTrailing) {
                                        if index == (editingLock ? (lock < 0 ? home : lock) : home) {
                                            Image(systemName: "checkmark.circle.fill").font(.title2).foregroundColor(.white).padding(8)
                                        }
                                    }
                                Text(LumaDesign.wallpaperNames[index]).font(.caption).lineLimit(2)
                            }
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(18)
        }.navigationTitle("Wallpaper")
    }
    private func preview(_ title: String, value: Int, lockScreen: Bool) -> some View {
        VStack(spacing: 6) {
            PhoneWallpaper(selection: LumaDesign.resolvedWallpaper(value, midnight: midnight))
                .aspectRatio(0.49, contentMode: .fit)
                .overlay(alignment: .top) {
                    if lockScreen { Text("9:41").font(.system(size: 28, weight: .light)).foregroundColor(.white).padding(.top, 22) }
                    else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                            ForEach(["Messages","Photos","Notes","Files","Mail","Settings"], id: \.self) { name in
                                Image("Icon_" + name).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }.padding(10)
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 20))
            Text(title).font(.caption.weight(.medium))
        }
    }
}
