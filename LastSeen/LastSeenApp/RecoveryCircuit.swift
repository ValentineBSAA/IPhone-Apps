import SwiftUI
import Foundation

// An invented dependency-repair puzzle, never a real shell or exploit.
enum RecoveryCircuit {
    static let completion = "patchline.circuit.verified.v1"
    static let stages: [[String]] = [
        ["Index", "Verify", "Mount"],
        ["Scan", "Repair", "Reload"],
        ["Prepare", "Link", "Activate"]
    ]
    static let instructions = [
        "Build the index before verification. Mount only a verified index.",
        "Scan the fictional service before repairing it. Reload only after repair.",
        "Prepare a local module before linking. Activate only after linking."
    ]
    static let choices = [
        ["Mount", "Index", "Verify"], ["Reload", "Repair", "Scan"], ["Link", "Activate", "Prepare"]
    ]
    static func valid(_ candidate: [String], stage: Int) -> Bool {
        stages.indices.contains(stage) && candidate == stages[stage]
    }
    static func unlocked(_ flags: Set<String>) -> Bool { flags.contains(completion) }
    static let reward = "Field Notes is available in Relay."
}

struct RecoveryCircuitView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var stage = 0
    @State private var selection: [String] = []
    @State private var feedback = ""
    @State private var finished = false
    private func resetSession() {stage=0;selection=[];feedback="";finished=false}
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 15) {
                    Image("Jailbreak_PulseTerminal").resizable().scaledToFit().frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading) {
                        Text("Recovery Circuit").font(.title2.bold())
                        Text("Patchline • Local service repair").font(.caption).foregroundColor(.secondary)
                    }
                }
                if finished {
                    Label("Service verified", systemImage: "checkmark.seal.fill").font(.title2.bold()).foregroundColor(LumaDesign.accent)
                    Text(RecoveryCircuit.reward)
                    Button("Run again") { stage = 0; selection = []; feedback = ""; finished = false }.buttonStyle(.bordered)
                } else {
                    ProgressView(value: Double(stage), total: Double(RecoveryCircuit.stages.count)).tint(LumaDesign.accent)
                    Text("Service \(stage + 1) of \(RecoveryCircuit.stages.count)").font(.headline)
                    Text(RecoveryCircuit.instructions[stage]).foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Execution order").font(.caption.bold()).foregroundColor(LumaDesign.accent)
                        ForEach(0..<3, id: \.self) { i in
                            HStack {
                                Text(String(i + 1)).monospacedDigit().foregroundColor(.secondary)
                                Text(i < selection.count ? selection[i] : "Select a module")
                                Spacer()
                            }.padding(12).background(LumaDesign.raised, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }.padding(14).lumaSurface()
                    ForEach(RecoveryCircuit.choices[stage], id: \.self) { choice in
                        Button { guard phase == .active,selection.count<3,!selection.contains(choice) else{return};selection.append(choice); feedback = "" } label: {
                            Label(choice, systemImage: "cpu").frame(maxWidth: .infinity, minHeight: 44)
                        }.buttonStyle(.bordered).disabled(selection.contains(choice)).accessibilityIdentifier("circuit.choice." + choice)
                    }
                    HStack {
                        Button("Clear") { selection = []; feedback = "" }.buttonStyle(.bordered)
                        Button("Verify sequence") {
                            guard phase == .active else{return}
                            guard RecoveryCircuit.valid(selection, stage: stage) else { feedback = "Dependency conflict. Try again; no records were changed."; selection = []; return }
                            if stage + 1 == RecoveryCircuit.stages.count {
                                _ = world.completeRecoveryCircuit(verified: RecoveryCircuit.stages)
                                finished = RecoveryCircuit.unlocked(world.state.flags)
                                if !finished {feedback="Service could not be verified. Try again."}
                            } else { stage += 1 }
                            selection = []; feedback = ""
                        }.buttonStyle(.borderedProminent).disabled(selection.count != 3)
                    }.frame(minHeight: 44)
                    if !feedback.isEmpty { Text(feedback).foregroundColor(.secondary).accessibilityAddTraits(.updatesFrequently) }
                }
            }.padding(18)
        }.background(LumaDesign.background.ignoresSafeArea())
            .navigationTitle("Recovery Circuit").navigationBarTitleDisplayMode(.inline)
            .onChange(of:world.checkpointEpoch){_ in resetSession()}
            .onChange(of:phase){if $0 != .active {selection=[];feedback=""}}
            .onChange(of:RecoveryCircuit.unlocked(world.state.flags)){if !$0 {resetSession()}}
    }
}

struct CircuitNoticeCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("Jailbreak_FieldNotes").resizable().scaledToFit().frame(width: 45, height: 45).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text("RELAY • PACKAGE ACCESS").font(.caption2.bold()).foregroundColor(LumaDesign.accent)
                Text("Service verified").font(.headline)
                Text(RecoveryCircuit.reward).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }.padding(14).lumaSurface(radius: 18)
    }
}
