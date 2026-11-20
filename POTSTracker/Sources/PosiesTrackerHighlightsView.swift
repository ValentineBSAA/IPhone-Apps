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
            return today.isEmpty ? "Not recorded today" : "\(total) mL recorded today"
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
