import SwiftUI

@main
struct CrispCompanionApp: App {
    @StateObject private var kitchen = KitchenStore()

    var body: some Scene {
        WindowGroup {
            KitchenRootView()
                .environmentObject(kitchen)
                .preferredColorScheme(.dark)
                .tint(CrispPalette.gold)
        }
    }
}

enum CrispPalette {
    static let background = Color(red: 0.075, green: 0.086, blue: 0.108)
    static let panel = Color(red: 0.135, green: 0.151, blue: 0.177)
    static let panelRaised = Color(red: 0.178, green: 0.191, blue: 0.214)
    static let gold = Color(red: 1.00, green: 0.73, blue: 0.41)
    static let peach = Color(red: 1.00, green: 0.49, blue: 0.35)
    static let cream = Color(red: 0.99, green: 0.95, blue: 0.88)
    static let muted = Color(red: 0.65, green: 0.68, blue: 0.72)
    static let green = Color(red: 0.45, green: 0.85, blue: 0.66)
}

struct CrispCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(CrispPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.065), lineWidth: 1)
                    )
            )
    }
}

struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2.4)
                .foregroundColor(CrispPalette.gold)
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(CrispPalette.cream)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(CrispPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct KitchenRootView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Kitchen", systemImage: "flame.fill") }
            NavigationStack { RecipeLibraryView() }
                .tabItem { Label("Recipes", systemImage: "book.closed.fill") }
            NavigationStack { KitchenTimerView() }
                .tabItem { Label("Timer", systemImage: "timer") }
            NavigationStack { KitchenSettingsView() }
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .background(CrispPalette.background.ignoresSafeArea())
    }
}
