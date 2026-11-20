import SwiftUI
import CoreData
import Charts

private struct PosiesTrendBucket: Identifiable {
    var day: Date
    var count: Int
    var id: Date { day }
}

private struct PosiesPulsePlot: Identifiable {
    var id: UUID
    var time: Date
    var bpm: Int
}

struct PosiesReportsView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>
    @AppStorage("journalLockEnabled") private var journalLockEnabled = false
    @ObservedObject private var journalAccess = JournalAccess.shared
    @State private var range: PosiesDateRange = .thirty
    @State private var showTable = false

    private var calendar: Calendar { .current }
    private var records: [PosiesPortableRecord] {
        Array(entries).filter {
            !$0.isDeleted && range.includes($0.recordedAt) &&
                (!journalLockEnabled || journalAccess.unlocked || $0.category != LogCategory.journal.rawValue)
        }.map(PosiesPortableRecord.init)
    }
    private var recordedDays: Int {
        Set(records.map { calendar.startOfDay(for: $0.recordedAt) }).count
    }
    private var symptomRows: [(String, Int)] {
        let groups = Dictionary(grouping: records.filter { $0.category == LogCategory.symptom.rawValue },
                                by: \.title)
        return groups.map { ($0.key, $0.value.count) }
            .sorted { $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 > $1.1 }
    }
    private var heartRows: [PosiesPulsePlot] {
        records.filter { $0.category == LogCategory.heartRate.rawValue && (1...400).contains($0.firstValue) }
            .map { PosiesPulsePlot(id: $0.id, time: $0.recordedAt, bpm: Int($0.firstValue)) }
            .sorted { $0.time < $1.time }
    }
    private var groupedBuckets: [PosiesTrendBucket] {
        let weekly = range == .year || range == .all
        let counts = Dictionary(grouping: records) { row -> Date in
            let component: Calendar.Component = weekly ? .weekOfYear : .day
            return calendar.dateInterval(of: component, for: row.recordedAt)?.start ??
                calendar.startOfDay(for: row.recordedAt)
        }
        return counts.map { PosiesTrendBucket(day: $0.key, count: $0.value.count) }
            .sorted { $0.day < $1.day }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Your patterns over time", systemImage: "chart.bar.xaxis")
                            .font(.title3.bold())
                            .foregroundStyle(Color.potsTeal)
                        Picker("Report period", selection: $range) {
                            ForEach(PosiesDateRange.allCases) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.menu)
                        HStack {
                            statistic("\(records.count)", "Saved entries")
                            Spacer()
                            statistic("\(recordedDays)", "Days with entries")
                        }
                        Text("Counts reflect only days with recorded entries. No missing days are assumed symptom-free.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recording activity").font(.headline)
                        if groupedBuckets.isEmpty {
                            missing
                        } else {
                            Chart(groupedBuckets) { bucket in
                                BarMark(
                                    x: .value("Date", bucket.day, unit: .day),
                                    y: .value("Saved entries", bucket.count)
                                )
                                .foregroundStyle(Color.potsTeal)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 190)
                            Text(range == .year || range == .all ? "Entries grouped by week" : "Entries grouped by day")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manually recorded heart rates").font(.headline)
                        if heartRows.isEmpty {
                            missing
                        } else {
                            Chart(heartRows) { item in
                                PointMark(
                                    x: .value("When", item.time),
                                    y: .value("Heart rate (bpm)", item.bpm)
                                )
                                .foregroundStyle(Color.potsTeal)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 175)
                            Text("\(heartRows.count) recorded values, in bpm. Dots are measurements, not continuous monitoring.")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most recorded symptoms").font(.headline)
                        if symptomRows.isEmpty { missing }
                        else {
                            ForEach(Array(symptomRows.prefix(8).enumerated()), id: \.offset) { _, item in
                                HStack {
                                    Text(item.0).font(.subheadline)
                                    Spacer()
                                    Text("\(item.1)")
                                        .font(.subheadline.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(Color.potsTeal)
                                }
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recorded by tracker").font(.headline)
                            Spacer()
                            Button(showTable ? "Hide" : "Show table") { showTable.toggle() }
                                .font(.caption.weight(.semibold))
                        }
                        if showTable {
                            ForEach(LogCategory.allCases) { category in
                                HStack {
                                    Text(category.title).font(.subheadline)
                                    Spacer()
                                    Text("\(records.filter { $0.category == category.rawValue }.count)")
                                        .font(.subheadline.monospacedDigit())
                                }
                            }
                        }
                        NavigationLink {
                            PosiesDataManagementView()
                        } label: {
                            Label("Export PDF, CSV or backup", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, minHeight: 47)
                        }
                        .buttonStyle(.borderedProminent).tint(Color.potsButtonFill)
                    }
                }
                Text("All analyses describe your saved entries only. They cannot establish cause, diagnose POTS or substitute for medical care.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var missing: some View {
        Text("No entries recorded for this view.")
            .font(.subheadline).foregroundStyle(Color.potsSecondary)
    }
    private func statistic(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(Color.potsSecondary)
        }
    }
}
