import SwiftUI

// Persisted preferences use stable IDs rather than array indices.
// Old builds have no Home settings, so the defaults below are safe on upgrade.
enum HomeModule: String, CaseIterable, Identifiable {
    case today
    case checkIn
    case favorites
    case recent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Home carousel"
        case .checkIn: return "Daily check-in"
        case .favorites: return "Pinned trackers"
        case .recent: return "Today's dots"
        }
    }

    var subtitle: String {
        switch self {
        case .today: return "Swipe through Today, Week, Wellbeing and Reminders"
        case .checkIn: return "Open an optional titled check-in note"
        case .favorites: return "Your shortcuts"
        case .recent: return "Simple indicators for what was logged today"
        }
    }

    var icon: String {
        switch self {
        case .today: return "rectangle.on.rectangle.angled"
        case .checkIn: return "heart.text.square"
        case .favorites: return "square.grid.2x2"
        case .recent: return "circle.grid.2x2"
        }
    }
}

enum HomeLayout {
    static let moduleDefault = "today,recent,checkIn,favorites"
    static let pinDefault = "symptom,heartRate,bloodPressure,journal"

    static func ids(from raw: String) -> [String] {
        var seen = Set<String>()
        return raw.split(separator: ",").map(String.init).filter { seen.insert($0).inserted }
    }

    static func orderedModules(from raw: String) -> [HomeModule] {
        let known = Set(HomeModule.allCases.map(\.rawValue))
        let normalized = ids(from: raw).filter { known.contains($0) }
        let final = normalized + HomeModule.allCases.map(\.rawValue).filter { !normalized.contains($0) }
        return final.compactMap(HomeModule.init(rawValue:))
    }

    static func pinned(from raw: String) -> [TrackerFeature] {
        let valid = ids(from: raw)
        return valid.compactMap { id in
            TrackerFeature.all.first(where: { $0.id == id })
        }
    }

    static func move(_ id: String, in ids: [String], by direction: Int) -> String {
        var values = ids
        guard let source = values.firstIndex(of: id) else { return values.joined(separator: ",") }
        let target = source + direction
        guard values.indices.contains(target) else { return values.joined(separator: ",") }
        values.swapAt(source, target)
        return values.joined(separator: ",")
    }
}

struct HomeCustomizationView: View {
    @AppStorage("homeModuleOrder") private var moduleOrder = HomeLayout.moduleDefault
    @AppStorage("homeHiddenModules") private var hiddenModules = ""
    @AppStorage("homePinnedFeatureIDs") private var pinnedIDs = HomeLayout.pinDefault
    @AppStorage("homeLayoutDensity") private var density = "compact"

    @State private var showReset = false
    @State private var showPinPicker = false
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var modules: [HomeModule] { HomeLayout.orderedModules(from: moduleOrder) }
    private var pinned: [TrackerFeature] { HomeLayout.pinned(from: pinnedIDs) }
    private var hidden: Set<String> { Set(HomeLayout.ids(from: hiddenModules)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Only show what you want on Home.")
                        .font(.subheadline)
                        .foregroundStyle(Color.potsSecondary)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Home spacing").font(.headline)
                        HStack(spacing: 9) {
                            ForEach(["compact", "comfortable"], id: \.self) { option in
                                let active = density == option
                                Button {
                                    density = PosiesChoiceBehavior.toggle(density, tapped: option)
                                } label: {
                                    Text(option == "compact" ? "Compact" : "Comfortable")
                                        .font(.subheadline.weight(active ? .semibold : .regular))
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .foregroundStyle(active ? Color.white : Color.primary)
                                        .background(active ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                                    in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(active ? [.isSelected] : [])
                                .accessibilityHint(active ? "Selected. Tap again to clear." : "Tap to select.")
                            }
                        }
                        Text("Tap a selected spacing again to clear it. With nothing selected, Home uses compact spacing.")
                            .font(.caption)
                            .foregroundStyle(Color.potsSecondary)
                        Text("The low-energy setting in More makes tap targets larger, independently of this choice.")
                            .font(.caption)
                            .foregroundStyle(Color.potsSecondary)
                    }
                }

                sectionHeader("Home sections", caption: "Reorder or hide sections. Restore the original layout whenever you like.")

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(modules) { module in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: module.icon)
                                    .foregroundStyle(Color.potsTeal)
                                    .font(.headline)
                                Text(module.title)
                                    .font(.subheadline.bold())
                                Text(module.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(Color.potsSecondary)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack(spacing: 7) {
                                    Button {
                                        setHidden(module.id, shouldHide: !hidden.contains(module.id))
                                    } label: {
                                        Image(systemName: hidden.contains(module.id) ? "eye.slash" : "eye")
                                            .frame(maxWidth: .infinity, minHeight: 38)
                                    }
                                    .accessibilityLabel(hidden.contains(module.id) ? "Show \(module.title)" : "Hide \(module.title)")
                                    Button {
                                        moduleOrder = HomeLayout.move(module.id, in: modules.map(\.id), by: -1)
                                    } label: {
                                        Image(systemName: "arrow.up")
                                            .frame(maxWidth: .infinity, minHeight: 38)
                                    }
                                    .disabled(modules.first?.id == module.id)
                                    .accessibilityLabel("Move \(module.title) up")
                                    Button {
                                        moduleOrder = HomeLayout.move(module.id, in: modules.map(\.id), by: 1)
                                    } label: {
                                        Image(systemName: "arrow.down")
                                            .frame(maxWidth: .infinity, minHeight: 38)
                                    }
                                    .disabled(modules.last?.id == module.id)
                                    .accessibilityLabel("Move \(module.title) down")
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        }
                        .opacity(hidden.contains(module.id) ? 0.58 : 1)
                    }
                }

                sectionHeader("Pinned trackers", caption: "Only pinned features show on Home. All 12 remain accessible in Log.")
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(pinned) { feature in
                        GlassCard {
                            VStack(spacing: 10) {
                                FeatureArtwork(feature: feature, width: 53)
                                Text(feature.name)
                                    .font(.subheadline.bold())
                                    .lineLimit(2)
                                HStack(spacing: 8) {
                                    Button {
                                        pinnedIDs = HomeLayout.move(feature.id, in: pinned.map(\.id), by: -1)
                                    } label: { Image(systemName: "arrow.left").frame(maxWidth: .infinity, minHeight: 38) }
                                        .disabled(pinned.first?.id == feature.id)
                                        .accessibilityLabel("Move \(feature.name) earlier")
                                    Button {
                                        pinnedIDs = HomeLayout.move(feature.id, in: pinned.map(\.id), by: 1)
                                    } label: { Image(systemName: "arrow.right").frame(maxWidth: .infinity, minHeight: 38) }
                                        .disabled(pinned.last?.id == feature.id)
                                        .accessibilityLabel("Move \(feature.name) later")
                                    Button {
                                        togglePin(feature.id)
                                    } label: { Image(systemName: "minus.circle").frame(maxWidth: .infinity, minHeight: 38) }
                                        .accessibilityLabel("Unpin \(feature.name)")
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                if pinned.isEmpty {
                    Text("No trackers pinned. Your Log tab still contains every category.")
                        .font(.footnote).foregroundStyle(Color.potsSecondary)
                }

                Button {
                    showPinPicker = true
                } label: {
                    HStack {
                        Label("Choose pinned trackers", systemImage: "square.grid.2x2")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                Button("Restore original Home layout") { showReset = true }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Customize Home")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPinPicker) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select the trackers you want on Home. All categories stay available in Log and More.")
                            .font(.subheadline)
                            .foregroundStyle(Color.potsSecondary)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(TrackerFeature.all) { feature in
                                let isPinned = pinned.contains(where: { $0.id == feature.id })
                                Button {
                                    togglePin(feature.id)
                                } label: {
                                    HStack(spacing: 9) {
                                        FeatureArtwork(feature: feature, width: 39)
                                        Text(feature.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                        Spacer(minLength: 0)
                                        Image(systemName: isPinned ? "checkmark.circle.fill" : "plus.circle")
                                            .foregroundStyle(Color.potsTeal)
                                    }
                                    .padding(9)
                                    .frame(maxWidth: .infinity, minHeight: 64)
                                    .background(Color.potsSurface,
                                                in: RoundedRectangle(cornerRadius: 15))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(isPinned ? "Unpin" : "Pin") \(feature.name)")
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color.potsBackground.ignoresSafeArea())
                .navigationTitle("Pinned trackers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showPinPicker = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Restore the original Home layout?", isPresented: $showReset) {
            Button("Restore layout") {
                moduleOrder = HomeLayout.moduleDefault
                hiddenModules = ""
                pinnedIDs = HomeLayout.pinDefault
                density = "compact"
            }
        } message: {
            Text("This changes only Home appearance. Your saved entries will not be deleted.")
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.bold())
            Text(caption).font(.caption).foregroundStyle(Color.potsSecondary)
        }
    }

    private func setHidden(_ id: String, shouldHide: Bool) {
        var values = Set(HomeLayout.ids(from: hiddenModules))
        if shouldHide { values.insert(id) } else { values.remove(id) }
        hiddenModules = values.sorted().joined(separator: ",")
    }

    private func togglePin(_ id: String) {
        var values = HomeLayout.pinned(from: pinnedIDs).map(\.id)
        if let index = values.firstIndex(of: id) {
            values.remove(at: index)
        } else {
            values.append(id)
        }
        pinnedIDs = values.joined(separator: ",")
    }
}