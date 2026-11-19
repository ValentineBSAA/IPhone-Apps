import SwiftUI

/// Convenience gate for QA controls. This local PIN is not a security boundary.
/// Destructive debug operations must never be exposed in production releases.
struct BerryDeveloperGardenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var unlocked = false
    @State private var pinError = false
    @State private var selectedTool: Tool?
    @AppStorage("berryblockblast.touchDiagnostics") private var touchDiagnostics = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private enum Tool: String, CaseIterable, Identifiable {
        case diagnostics = "Diagnostics"
        case saves = "Save Inspector"
        case clock = "Timers & Clocks"
        case notifications = "Notification Test"
        case economy = "Economy Inspector"
        case build = "Build Information"
        case experimental = "Experimental Features"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .diagnostics: return "waveform.path.ecg"
            case .saves: return "externaldrive.fill"
            case .clock: return "clock.fill"
            case .notifications: return "bell.badge.fill"
            case .economy: return "creditcard.fill"
            case .build: return "hammer.fill"
            case .experimental: return "flask.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 43, weight: .bold))
                        .foregroundStyle(BerryStyle.strawberry)
                    if !unlocked {
                        Text("Developer Garden")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                        Text("For development and physical-device testing only.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        SecureField("Developer PIN", text: $pin)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .multilineTextAlignment(.center)
                            .font(.title2.monospacedDigit())
                            .padding(14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .onChange(of: pin) { value in
                                pin = String(value.filter(\.isNumber).prefix(4))
                                pinError = false
                            }
                            .accessibilityLabel("Four digit developer PIN")
                        if pinError {
                            Text("That code does not unlock the Developer Garden.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        Button("Unlock") {
                            if pin == "1476" {
                                unlocked = true
                                pin = ""
                            } else {
                                pinError = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BerryStyle.strawberry)
                        .disabled(pin.count != 4)
                    } else {
                        Text("Developer Garden")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                        Text("QA only • No save or currency mutations")
                            .font(.caption.bold())
                            .foregroundStyle(BerryStyle.chocolate)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Tool.allCases) { tool in
                                Button { selectedTool = tool } label: {
                                    VStack(spacing: 10) {
                                        Image(systemName: tool.icon)
                                            .font(.system(size: 28, weight: .bold))
                                        Text(tool.rawValue)
                                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 114)
                                    .foregroundStyle(BerryStyle.strawberry)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18)
                                        .strokeBorder(BerryStyle.strawberry.opacity(0.3)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: 480)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .background(BerryStyle.softPink.ignoresSafeArea())
            .navigationTitle("Berry Garden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            } }
            .sheet(item: $selectedTool) { tool in
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 14) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(BerryStyle.strawberry)
                            Text(tool.rawValue).font(.title2.bold())
                            toolDetails(tool)
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity)
                    }
                    .background(BerryStyle.softPink.ignoresSafeArea())
                    .navigationTitle(tool.rawValue)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { selectedTool = nil }
                    } }
                }
            }
        }
    }

    @ViewBuilder
    private func toolDetails(_ tool: Tool) -> some View {
        switch tool {
        case .diagnostics:
            Toggle("Show touch diagnostics in gameplay", isOn: $touchDiagnostics)
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            Text("When enabled, the placement coordinate readout appears during gameplay.")
        case .saves:
            ForEach([8, 12, 24], id: \.self) { side in
                let found = BerryGameSession.hasResumableEndless(side: side)
                Label("\(side)×\(side) Sweet Endless: \(found ? "Saved" : "No saved run")",
                      systemImage: found ? "checkmark.circle.fill" : "circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("This inspector is read-only and will never reset a garden.")
        case .clock:
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date.formatted(date: .abbreviated, time: .standard))
                    .font(.title3.monospacedDigit())
            }
            Text("Live device-local time. Future shop cycle QA will use absolute dates and calendar boundaries.")
        case .notifications:
            Text("Notification presentation tests are scheduled for the next development stage. No test reward is granted here.")
        case .economy:
            Text("The strawberry ledger is unchanged. Moonberries and Night Market purchasing are not enabled in this build.")
        case .build:
            Text(BerryBuildIdentity.settingsLabel)
            Text("iOS deployment target: 16.0")
        case .experimental:
            Text("Strawberry Blossom Glass remains disabled until its approved PNG assets pass the repository and hardware acceptance checks.")
        }
    }
}
