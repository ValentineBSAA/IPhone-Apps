import SwiftUI

/// Personal shortcuts fill an editable draft only; no treatment target or record is inferred.
enum PosiesQuickPresets {
    static func values(_ stored: String, fallback: [Int], range: ClosedRange<Int>) -> [Int] {
        guard !stored.isEmpty else { return fallback }
        let fields = stored.split(separator: ",", omittingEmptySubsequences: false)
        guard fields.count == 4 else { return fallback }
        let values = fields.compactMap { Int(String($0).trimmingCharacters(in: .whitespaces)) }
        guard values.count == 4, Set(values).count == 4,
              values.allSatisfy({ range.contains($0) }) else { return fallback }
        return values
    }

    static func encode(_ amounts: [Int], range: ClosedRange<Int>) -> String? {
        guard amounts.count == 4, Set(amounts).count == 4,
              amounts.allSatisfy({ range.contains($0) }) else { return nil }
        return amounts.map(String.init).joined(separator: ",")
    }
}

struct PosiesQuickPresetsEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var stored: String
    let title: String
    let unit: String
    let fallback: [Int]
    let range: ClosedRange<Int>
    @State private var amounts: [String]

    init(stored: Binding<String>, title: String, unit: String,
         fallback: [Int], range: ClosedRange<Int>) {
        _stored = stored
        self.title = title
        self.unit = unit
        self.fallback = fallback
        self.range = range
        _amounts = State(initialValue: PosiesQuickPresets.values(
            stored.wrappedValue, fallback: fallback, range: range).map(String.init))
    }

    private var encoded: String? {
        guard amounts.count == 4 else { return nil }
        return PosiesQuickPresets.encode(amounts.compactMap(Int.init), range: range)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("My quick-entry buttons", systemImage: "slider.horizontal.3")
                            .font(.headline).foregroundStyle(Color.potsTeal)
                        Text("Choose four different amounts. These shortcuts fill a draft only; you still choose when to save.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        ForEach(0..<4, id: \.self) { index in
                            HStack(spacing: 10) {
                                Text("Button \(index + 1)").font(.subheadline)
                                Spacer()
                                TextField("Amount", text: $amounts[index])
                                    .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 110)
                                    .accessibilityLabel("Quick amount \(index + 1), \(unit)")
                                Text(unit).foregroundStyle(Color.potsSecondary)
                            }
                        }
                        if encoded == nil {
                            Text("Enter four different whole numbers between \(range.lowerBound) and \(range.upperBound).")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                        Button("Restore original buttons") {
                            amounts = fallback.map(String.init)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Tap Save to apply the restored values.")
                        Text("Previous entries, medication records and personal goals will not change.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }
                .padding(18)
            }
            .background(Color.potsBackground.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let encoded else { return }
                        stored = encoded
                        dismiss()
                    }
                    .disabled(encoded == nil)
                }
            }
        }
    }
}
