import SwiftUI

/// Display the existing approved artwork throughout POTS & Posies. Rest
/// intentionally shares the original Sleep & Rest PNG; no new art generated.
enum PosiesFeatureVisuals {
    static let approvedIDs = [
        "heartRate", "bloodPressure", "symptom", "hydration", "medications",
        "sleep", "calendar", "reports", "journal", "posture", "reminders", "settings"
    ]
    static func canonicalID(_ value: String) -> String {
        switch value.lowercased() {
        case "rest", "sleep & rest", "sleep and rest": return "sleep"
        case "medication", "medicine": return "medications"
        default: return value
        }
    }
    static func artworkFile(for value: String) -> String? {
        TrackerFeature.all.first { $0.id == canonicalID(value) }?.file
    }
}

struct PosiesFeatureIcon: View {
    let featureID: String
    var width: CGFloat = 40
    var body: some View {
        Group {
            if let feature = TrackerFeature.all.first(where: {
                $0.id == PosiesFeatureVisuals.canonicalID(featureID)
            }) {
                FeatureArtwork(feature: feature, width: width)
            } else {
                Image(systemName: featureID == "checkIn" ? "heart.text.square.fill" :
                      "square.grid.2x2.fill")
                    .font(.system(size: width * 0.46, weight: .medium))
                    .foregroundStyle(Color.potsTeal)
                    .frame(width: width, height: width)
                    .background(Color.potsSurfaceMuted,
                                in: RoundedRectangle(cornerRadius: width * 0.22))
            }
        }.accessibilityHidden(true)
    }
}

struct PosiesFeatureHeading: View {
    let featureID: String
    let title: String
    let subtitle: String
    var artworkSize: CGFloat = 52
    var body: some View {
        HStack(spacing: 12) {
            PosiesFeatureIcon(featureID: featureID, width: artworkSize)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(Color.potsSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }.accessibilityElement(children: .combine)
    }
}

struct PosiesFeatureSectionTitle: View {
    let featureID: String
    let title: String
    var artworkSize: CGFloat = 33
    var body: some View {
        HStack(spacing: 9) {
            PosiesFeatureIcon(featureID: featureID, width: artworkSize)
            Text(title).font(.headline).foregroundStyle(Color.potsTeal)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }.accessibilityElement(children: .combine)
    }
}

/// All dropdown choices use the same original stored string fields and
/// existing reversible-selection behavior, never a new data model.
struct PosiesChoiceMenu: View {
    let title: String
    let options: [String]
    @Binding var selected: String
    var body: some View {
        Menu {
            Button("Clear selection") { selected = "" }
            ForEach(options, id: \.self) { value in
                Button {
                    selected = PosiesChoiceBehavior.toggle(selected, tapped: value)
                } label: {
                    if selected == value { Label(value, systemImage: "checkmark") }
                    else { Text(value) }
                }
            }
        } label: {
            HStack(spacing: 9) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.caption).foregroundStyle(Color.potsSecondary)
                    Text(selected.isEmpty ? "Choose an option" : selected)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary).lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption).foregroundStyle(Color.potsTeal)
            }
            .padding(.horizontal, 12).frame(minHeight: 53)
            .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
         .accessibilityLabel("\(title), \(selected.isEmpty ? "not selected" : selected)")
         .accessibilityHint("Choose or clear an option; selecting it again removes it.")
    }
}

/// Multi-select context menu instead of a tall row of chips.
struct PosiesTagsMenu: View {
    let title: String
    let options: [String]
    @Binding var selected: Set<String>
    var body: some View {
        Menu {
            Button("Clear all context") { selected.removeAll() }
            ForEach(options, id: \.self) { value in
                Button {
                    if selected.contains(value) { selected.remove(value) }
                    else { selected.insert(value) }
                } label: {
                    if selected.contains(value) { Label(value, systemImage: "checkmark") }
                    else { Text(value) }
                }
            }
        } label: {
            HStack(spacing: 9) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.caption).foregroundStyle(Color.potsSecondary)
                    Text(selected.isEmpty ? "None selected" :
                         selected.sorted().joined(separator: ", "))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary).lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption).foregroundStyle(Color.potsTeal)
            }
            .padding(.horizontal, 12).frame(minHeight: 53)
            .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
         .accessibilityLabel("\(title), \(selected.count) selected")
         .accessibilityHint("Choose optional contexts. Select one again to clear it.")
    }
}
