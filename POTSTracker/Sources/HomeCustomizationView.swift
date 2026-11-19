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
        case .today: return "Today"
        case .checkIn: return "Daily check-in"
        case .favorites: return "Pinned trackers"
        case .recent: return "Recent activity"
        }
    }

    var subtitle: String {
        switch self {
        case .today: return "Today's summary and quick log"
        case .checkIn: return "Optional one-tap check-in"
        case .favorites: return "Your shortcuts"
        case .recent: return "Your last three entries"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .checkIn: return "heart.text.square"
        case .favorites: return "square.grid.2x2"
        case .recent: return "clock.arrow.circlepath"
        }
    }
}

enum HomeLayout {
    static let moduleDefault = "today,checkIn,favorites,recent"
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
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var modules: [HomeModule] { HomeLayout.orderedModules(from: moduleOrder) }
    private var pinned: [TrackerFeature] { HomeLayout.pinned(from: pinnedIDs) }
    private var hidden: Set<String> { Set(HomeLayout.ids(from: hiddenModules)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Make Home yours")
                        .font(.title2.bold())
                    Text("Start with a calm layout. Show only the sections and shortcuts you find useful.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Home spacing").font(.headline)
                        Picker("Home spacing", selection: $density) {
                            Text("Compact").tag("compact")
                            Text("Comfortable").tag("comfortable")
                        }
                        .pickerStyle(.segmented)
                        Text("The low-energy setting in More makes tap targets larger, independently of this choice.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                sectionHeader("Home sections", caption: "Reorder or hide any section. Today stays available for quick access.")

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
                                    .foregroundStyle(.secondary)
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
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Text("Add or remove shortcuts")
                    .font(.headline)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(TrackerFeature.all) { feature in
                        let isPinned = pinned.contains(where: { $0.id == feature.id })
                        Button {
                            togglePin(feature.id)
                        } label: {
                            HStack(spacing: 9) {
                                FeatureArtwork(feature: feature, width: 37)
                                Text(feature.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                Spacer(minLength: 2)
                                Image(systemName: isPinned ? "checkmark.circle.fill" : "plus.circle")
                                    .foregroundStyle(Color.potsTeal)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, minHeight: 62)
                            .background(Color(uiColor: .secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(isPinned ? "Unpin" : "Pin") \(feature.name)")
                    }
                }
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
            Text(caption).font(.caption).foregroundStyle(.secondary)
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