import SwiftUI
import Charts

private struct PosiesTrackerDay: Identifiable {
    let day: Date
    let amount: Int
    var id: Date { day }
}

/// Friendly *recording* highlights, never adherence, clinical targets,
/// medication advice, or symptom-free assumptions on days without entries.
struct PosiesTrackerHighlightsView: View {
    let category: LogCategory
    let records: [RecordSnapshot]
    @AppStorage("posiesHydrationGoalMLV028") private var personalHydrationGoal = 0
    @AppStorage("posiesHydrationShowOuncesV028") private var showFluidOunces = false


    private var sevenDays: [RecordSnapshot] {
        let start = Calendar.current.date(byAdding: .day, value: -6,
            to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return records.filter { $0.recordedAt >= start && $0.recordedAt <= Date() }
    }

    private var today: [RecordSnapshot] {
        records.filter { Calendar.current.isDateInToday($0.recordedAt) }
    }

    private var daily: [PosiesTrackerDay] {
        let byDay = Dictionary(grouping: sevenDays) {
            Calendar.current.startOfDay(for: $0.recordedAt)
        }
        return byDay.map { day, items in
            let amount: Int
            switch category {
            case .hydration, .sleep:
                amount = items.reduce(0) { $0 + max(0, Int($1.firstValue)) }
            default:
                amount = items.count
            }
            return PosiesTrackerDay(day: day, amount: amount)
        }
        .sorted { $0.day < $1.day }
    }

    private var summary: String {
        switch category {
        case .hydration:
            let total = today.reduce(0) { $0 + max(0, Int($1.firstValue)) }
            return today.isEmpty ? "Not recorded today" :
                (showFluidOunces ? String(format: "%.1f US fl oz recorded today", Double(total) / 29.5735295625)
                                 : "\(total) mL recorded today")
        case .medications:
            return today.isEmpty ? "No medication entries today"
                : "\(today.count) medication \(today.count == 1 ? "entry" : "entries") today"
        case .sleep:
            let mins = sevenDays.reduce(0) { $0 + max(0, Int($1.firstValue)) }
            return sevenDays.isEmpty ? "No sleep/rest recorded this week" : "\(mins) minutes recorded this week"
        case .posture:
            return sevenDays.isEmpty ? "No observations recorded this week" : "\(sevenDays.count) observations this week"
        default: return "Your saved records"
        }
    }

    private var yAxisLabel: String {
        switch category {
        case .hydration: return "Recorded mL"
        case .sleep: return "Recorded minutes"
        default: return "Recorded entries"
        }
    }

    var body: some View {
        if category.isExtended {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 9) {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundStyle(Color.potsTeal)
                        Text("Your recent notes")
                            .font(.headline)
                    }
                    Text(summary)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.potsTeal)
                    if category == .hydration {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Show US fluid ounces in summary", isOn: $showFluidOunces)
                                .tint(.potsTeal)
                                .font(.subheadline)
                            Stepper(value: $personalHydrationGoal, in: 0...10000, step: 250) {
                                Text(personalHydrationGoal == 0
                                     ? "Personal daily goal: Off"
                                     : "My chosen daily goal: \(personalHydrationGoal) mL")
                                    .font(.subheadline.weight(.medium))
                            }
                            Text("A goal is optional and set only by you. Follow your clinician's advice about fluids and sodium.")
                                .font(.caption)
                                .foregroundStyle(Color.potsSecondary)
                            if personalHydrationGoal > 0 {
                                let actual = today.reduce(0) { $0 + max(0, Int($1.firstValue)) }
                                ProgressView(value: Double(min(actual, personalHydrationGoal)),
                                             total: Double(personalHydrationGoal))
                                    .tint(.potsTeal)
                                Text("\(actual) mL of your personal \(personalHydrationGoal) mL goal recorded")
                                    .font(.caption)
                                    .foregroundStyle(Color.potsSecondary)
                            }
                        }
                    }
                    if !daily.isEmpty {
                        Chart(daily) { item in
                            BarMark(
                                x: .value("Day", item.day, unit: .day),
                                y: .value(yAxisLabel, item.amount)
                            )
                            .foregroundStyle(Color.potsTeal)
                        }
                        .frame(height: 116)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .accessibilityLabel("Recorded activity chart, only days with saved entries")
                    }
                    Text("Only saved entries are shown. Blank days are unknown. No goals or health ratings are calculated.")
                        .font(.caption)
                        .foregroundStyle(Color.potsSecondary)
                }
            }
        }
    }
}
