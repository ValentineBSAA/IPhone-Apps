import SwiftUI

// Original, self-contained service exercises. They do not read real hardware,
// execute commands, unlock protected records, or assert narrative facts.
enum WorkbenchDiagnostic: String, CaseIterable, Codable, Identifiable {
    case signal, configuration, chronology
    var id: String { rawValue }
    var key: String { "b32-diagnostic-v1-" + rawValue }
    var title: String {
        switch self {
        case .signal: return "Signal alignment"
        case .configuration: return "Configuration diagnosis"
        case .chronology: return "Record sequencing"
        }
    }
    var symbol: String {
        switch self {
        case .signal: return "waveform.path"
        case .configuration: return "slider.horizontal.3"
        case .chronology: return "list.number"
        }
    }
    var instructions: String {
        switch self {
        case .signal: return "Adjust the three controls until the output matches the reference trace. Compare peak height, number of cycles and starting direction. No timing or sound is required."
        case .configuration: return "Read the service policy, then adjust the three settings to make a consistent read-only preview. Verify the configuration when ready."
        case .chronology: return "Use the local sample log to place four operations in a valid dependency order. Tap the arrow buttons to move operations. Independent operations may occur in either order."
        }
    }
    var initial: [Int] {
        switch self {
        case .signal: return [1,4,1]
        case .configuration: return [1,0,1]
        case .chronology: return [3,2,0,1]
        }
    }
    func accepts(_ values: [Int]) -> Bool {
        switch self {
        case .signal: return values.count == 3 && (1...4).contains(values[0]) && (1...4).contains(values[1]) && (0...1).contains(values[2])
        case .configuration: return values.count == 3 && values.allSatisfy { (0...1).contains($0) }
        case .chronology: return values.count == 4 && Set(values) == Set(0...3)
        }
    }
    func valid(_ values: [Int]) -> Bool {
        guard accepts(values) else { return false }
        switch self {
        case .signal: return values == [3,2,0]
        case .configuration: return values == [0,1,0]
        case .chronology:
            guard let a = values.firstIndex(of: 0), let b = values.firstIndex(of: 1),
                  let c = values.firstIndex(of: 2), let d = values.firstIndex(of: 3) else { return false }
            return a < b && a < c && b < d && c < d
        }
    }
    var hints: [String] {
        switch self {
        case .signal: return [
            "Compare one characteristic at a time instead of changing everything together.",
            "Count the complete cycles in the reference and compare the first movement away from the center.",
            "Peak height is independent of cycle count. Match both numeric reference descriptions before choosing a direction."
        ]
        case .configuration: return [
            "The goal is inspection, not modifying or publishing a record.",
            "The policy distinguishes a local preview from permission to edit its source.",
            "Compare each switch separately against the three policy statements."
        ]
        case .chronology: return [
            "Start with an operation that doesn't require any other operation to finish.",
            "Two checks share a prerequisite but don't depend on one another.",
            "The final operation requires both checks. Either ordering of those independent checks is acceptable."
        ]
        }
    }
}
struct WorkbenchDiagnosticProgress: Codable, Equatable {
    var values: [Int]
    var hintLevel = 0
    var verified = false
}
enum WorkbenchDiagnosticCatalog {
    static func available(_ world: PhoneWorld) -> [WorkbenchDiagnostic] {
        guard world.everydayArchiveRevision != nil,
              world.connectedWorld?.workbenchConnected == true else { return [] }
        return WorkbenchDiagnostic.allCases
    }
    static func progress(_ challenge: WorkbenchDiagnostic, in world: PhoneWorld) -> WorkbenchDiagnosticProgress {
        guard let p = world.connectedWorld?.diagnostics?[challenge.key],
              challenge.accepts(p.values) else { return .init(values: challenge.initial) }
        return .init(values: p.values, hintLevel: min(3,max(0,p.hintLevel)), verified: p.verified && challenge.valid(p.values))
    }
    static func verifiedCount(_ world: PhoneWorld) -> Int {
        guard world.everydayArchiveRevision != nil else { return 0 }
        return WorkbenchDiagnostic.allCases.filter { progress($0, in: world).verified }.count
    }
}
struct WorkbenchSignalTrace: View {
    let heightLevel: Int
    let cycles: Int
    let inverted: Bool
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline)
            Canvas { context, size in
                let middle = size.height / 2
                var line = Path()
                line.move(to: CGPoint(x: 0,y: middle))
                line.addLine(to: CGPoint(x: size.width,y: middle))
                context.stroke(line, with: .color(.secondary.opacity(0.5)), lineWidth: 1)
                var trace = Path()
                for i in 0...160 {
                    let fraction = Double(i) / 160
                    let wave = sin(fraction * Double(cycles) * 2 * Double.pi) * (inverted ? -1 : 1)
                    let point = CGPoint(x: CGFloat(fraction) * size.width, y: middle - CGFloat(wave) * size.height * 0.1 * CGFloat(heightLevel))
                    if i == 0 { trace.move(to: point) } else { trace.addLine(to: point) }
                }
                context.stroke(trace, with: .color(.teal), style: StrokeStyle(lineWidth: 2.5,lineCap: .round,lineJoin: .round))
            }.frame(height: 100).padding(8).background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10)).accessibilityHidden(true)
            Text("Peak level \(heightLevel) · \(cycles) cycles · starts \(inverted ? "down" : "up")")
                .font(.caption).foregroundColor(.secondary)
        }
    }
}
struct WorkbenchDiagnosticView: View {
    let challenge: WorkbenchDiagnostic
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var feedback = ""
    @Environment(\.scenePhase) private var phase
    private var progress: WorkbenchDiagnosticProgress { WorkbenchDiagnosticCatalog.progress(challenge,in: world.state) }
    private var available:Bool {phase == .active && WorkbenchDiagnosticCatalog.available(world.state).contains(challenge)}
    private func binding(_ index: Int) -> Binding<Int> {
        Binding(get: { progress.values[index] }, set: { value in
            var next = progress.values; next[index] = value
            world.updateDiagnostic(challenge, values: next); feedback = ""
        })
    }
    private func toggle(_ index: Int) -> Binding<Bool> {
        Binding(get: { progress.values[index] == 1 }, set: { binding(index).wrappedValue = $0 ? 1 : 0 })
    }
    private let operations = ["Read sample index","Validate sample header","Validate sample body","Assemble preview"]
    private func move(_ index: Int, by delta: Int) {
        var next = progress.values
        guard next.indices.contains(index), next.indices.contains(index + delta) else { return }
        next.swapAt(index,index + delta)
        world.updateDiagnostic(challenge,values: next); feedback = ""
    }
    var body: some View {
        List {
            if available {
                Section {
                    LumaHeader(title: challenge.title, detail: progress.verified ? "Verified" : "Local diagnostic", symbol: challenge.symbol)
                    Text(challenge.instructions).font(.subheadline)
                }
                Group {
                    switch challenge {
                    case .signal:
                        Section("Reference and output") {
                            WorkbenchSignalTrace(heightLevel: 3, cycles: 2, inverted: false, title: "Reference")
                            WorkbenchSignalTrace(heightLevel: progress.values[0], cycles: progress.values[1], inverted: progress.values[2] == 1, title: "Output")
                        }
                        Section("Controls") {
                            Stepper("Peak level: \(progress.values[0])",value: binding(0),in: 1...4)
                            Stepper("Cycles: \(progress.values[1])",value: binding(1),in: 1...4)
                            Toggle("Invert starting direction",isOn: toggle(2))
                        }
                    case .configuration:
                        Section("Local service policy") {
                            Label("Source records must remain read-only.",systemImage: "lock")
                            Label("Local preview rendering is permitted.",systemImage: "doc.text.magnifyingglass")
                            Label("Preview publication is not permitted.",systemImage: "eye.slash")
                        }
                        Section("Service switches") {
                            Toggle("Allow source editing",isOn: toggle(0))
                            Toggle("Enable local preview",isOn: toggle(1))
                            Toggle("Publish preview",isOn: toggle(2))
                        }
                    case .chronology:
                        Section("Sample log constraints") {
                            Text("The index is read before either validation. Header and body checks are independent. Assembly waits for both checks.")
                        }
                        Section("Operation order") {
                            ForEach(Array(progress.values.enumerated()),id: \.element) { item in
                                HStack {
                                    Text("\(item.offset + 1). " + operations[item.element]).font(.subheadline)
                                    Spacer()
                                    Button { move(item.offset,by: -1) } label: { Image(systemName: "arrow.up.circle").font(.title2).frame(minWidth: 44,minHeight: 44) }
                                        .buttonStyle(.borderless).disabled(item.offset == 0).accessibilityLabel("Move " + operations[item.element] + " up")
                                    Button { move(item.offset,by: 1) } label: { Image(systemName: "arrow.down.circle").font(.title2).frame(minWidth: 44,minHeight: 44) }
                                        .buttonStyle(.borderless).disabled(item.offset == progress.values.count - 1).accessibilityLabel("Move " + operations[item.element] + " down")
                                }
                            }
                        }
                    }
                }.disabled(progress.verified)
                Section("Verification") {
                    if progress.verified {
                        Label("Diagnostic verified",systemImage: "checkmark.seal.fill").foregroundColor(.teal)
                        Text("Completion is retained in this save.").font(.caption).foregroundColor(.secondary)
                    } else {
                        Button("Verify diagnostic") {
                            feedback = world.verifyDiagnostic(challenge) ? "Diagnostic verified." : "The output does not satisfy the reference. Your adjustments are retained."
                        }.accessibilityIdentifier("workbench.verify." + challenge.rawValue)
                        Button("Reset adjustments") { world.resetDiagnostic(challenge); feedback = "" }
                    }
                    if !feedback.isEmpty { Text(feedback).font(.subheadline).foregroundColor(.secondary) }
                }
                Section("Explain procedure") {
                    Text(challenge.instructions).font(.caption)
                    ForEach(Array(challenge.hints.prefix(progress.hintLevel).enumerated()),id: \.offset) { hint in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hint \(hint.offset + 1)").font(.caption.bold())
                            Text(hint.element).font(.subheadline)
                        }
                    }
                    if progress.hintLevel < challenge.hints.count && !progress.verified {
                        Button("Show next hint") { world.revealDiagnosticHint(challenge) }
                    }
                }
            } else {
                Label("Reconnect the simulated phone to continue.",systemImage: "cable.connector")
            }
        }.navigationTitle(challenge.title).navigationBarTitleDisplayMode(.inline)
        .onChange(of:available){if !$0 {feedback=""}}
    }
}
