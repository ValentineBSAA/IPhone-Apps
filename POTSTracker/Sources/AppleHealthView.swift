import SwiftUI
import HealthKit

/// Read-only iPhone Health data. No Apple Watch requirement or background sync.
/// Data is queried on demand and is never copied to our local Core Data journal.
@MainActor
final class AppleHealthReader: ObservableObject {
    static let shared = AppleHealthReader()

    @Published private(set) var steps: String = "—"
    @Published private(set) var distance: String = "—"
    @Published private(set) var flights: String = "—"
    @Published private(set) var updatedAt: Date?
    @Published private(set) var loading = false
    @Published var errorText: String?

    private let healthStore = HKHealthStore()
    private var pendingQueries = 0
    private init() {}

    var supported: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount, .distanceWalkingRunning, .flightsClimbed
        ]
        return Set<HKObjectType>(
            identifiers.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
                .map { $0 as HKObjectType }
        )
    }

    func requestReadAccess() {
        guard supported else {
            errorText = "Apple Health data isn't available on this device."
            return
        }
        loading = true
        healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: readTypes) { success, error in
            DispatchQueue.main.async {
                self.loading = false
                if let error {
                    let entitlementMissing = error.localizedDescription.localizedCaseInsensitiveContains("entitlement")
                    self.errorText = entitlementMissing
                        ? "This AltStore installation was signed without the HealthKit permission Apple requires. POTS & Posies cannot grant it itself. Apple Health remains optional; manual tracking and the experimental camera pulse tool work independently. To enable Apple Health, use an Apple provisioning profile that authorizes HealthKit."
                        : "Apple Health couldn't connect. Check iPhone permissions and your signing profile, or continue using manual tracking. Technical detail: \(error.localizedDescription)"
                } else if success {
                    // Apple doesn't disclose whether the user denied individual
                    // read permissions. Never claim access was granted from
                    // requestAuthorization's success boolean.
                    UserDefaults.standard.set(true, forKey: "appleHealthReadRequested")
                    self.refresh()
                }
            }
        }
    }

    func refresh() {
        guard supported, UserDefaults.standard.bool(forKey: "appleHealthReadRequested") else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let now = Date()
        loading = true
        pendingQueries = 3

        query(.stepCount, start: start, end: now, unit: .count()) { value in
            self.steps = value.map { Int($0.rounded()).formatted() } ?? "—"
            self.finishedQuery()
        }
        let isUS = Locale.current.usesMetricSystem == false
        query(.distanceWalkingRunning, start: start, end: now,
              unit: isUS ? .mile() : .meterUnit(with: .kilo)) { value in
            self.distance = value.map { String(format: "%.2f %@", $0, isUS ? "mi" : "km") } ?? "—"
            self.finishedQuery()
        }
        query(.flightsClimbed, start: start, end: now, unit: .count()) { value in
            self.flights = value.map { Int($0.rounded()).formatted() } ?? "—"
            self.finishedQuery()
        }
    }

    private func finishedQuery() {
        pendingQueries = max(0, pendingQueries - 1)
        if pendingQueries == 0 {
            updatedAt = Date()
            loading = false
        }
    }

    private func query(_ identifier: HKQuantityTypeIdentifier, start: Date, end: Date,
                       unit: HKUnit, completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, error in
            let value = error == nil ? result?.sumQuantity()?.doubleValue(for: unit) : nil
            DispatchQueue.main.async {
                completion(value)
            }
        }
        healthStore.execute(query)
    }
}

struct AppleHealthView: View {
    @ObservedObject private var reader = AppleHealthReader.shared
    @AppStorage("appleHealthReadRequested") private var requested = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 11) {
                        Label("From Apple Health", systemImage: "heart.text.square.fill")
                            .font(.title3.bold())
                            .foregroundStyle(Color.potsTeal)
                        Text("Choose whether to let POTS & Posies read activity already saved in your iPhone's Health app.")
                            .font(.subheadline)
                        Text("Read-only. No Apple Watch, account, paid service or automatic upload. Nothing is imported into your saved journal.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !reader.supported {
                            Text("Apple Health isn't available on this iPhone.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Button {
                                reader.requestReadAccess()
                            } label: {
                                Label(requested ? "Review Health access" : "Connect Apple Health",
                                      systemImage: "hand.raised.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 51)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(reader.loading)
                        }
                    }
                }

                if requested && reader.supported {
                    HStack {
                        Text("Today")
                            .font(.headline)
                        Spacer()
                        Button {
                            reader.refresh()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .font(.subheadline)
                        .disabled(reader.loading)
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        metric("Steps", value: reader.steps, symbol: "figure.walk")
                        metric("Walking distance", value: reader.distance, symbol: "figure.walk.motion")
                        metric("Flights climbed", value: reader.flights, symbol: "stairs")
                    }
                    if reader.loading {
                        ProgressView("Reading Health data…")
                    }
                    Text("A dash means no accessible samples, which may mean no data was recorded or sharing wasn't allowed. It never means zero activity.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let updated = reader.updatedAt {
                        Text("Last checked \(updated.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your choice")
                            .font(.headline)
                        Text("Apple controls exactly which Health categories you share. You can change permission any time in the iPhone's Health app under Sharing / Apps.")
                        Text("Steps, distance and flights depend on the data sources available on this iPhone. The app never pretends to measure something itself.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(17)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if requested { reader.refresh() } }
        .alert("Apple Health unavailable", isPresented: Binding(
            get: { reader.errorText != nil },
            set: { if !$0 { reader.errorText = nil } }
        )) {
            Button("OK") { reader.errorText = nil }
        } message: {
            Text(reader.errorText ?? "Try again.")
        }
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.potsTeal)
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(12)
        .background(Color.potsSurface, in: RoundedRectangle(cornerRadius: 18))
    }
}
