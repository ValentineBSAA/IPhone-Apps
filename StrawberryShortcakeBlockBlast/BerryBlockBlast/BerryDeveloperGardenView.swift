import SwiftUI
import UIKit

/// Safe, read-only on-device QA dashboard. PIN is a convenience, not security.
struct BerryDeveloperGardenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var unlocked = false
    @State private var pinError = false
    @State private var selectedTool: Tool?
    @State private var previewMilestone: Int?
    @AppStorage("berryblockblast.touchDiagnostics") private var touchDiagnostics = false

    private let columns = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]

    private enum Tool: String, CaseIterable, Identifiable {
        case diagnostics = "Diagnostics"
        case saves = "Save Inspector"
        case clock = "Timers & Clocks"
        case notifications = "Notification Test"
        case economy = "Economy Inspector"
        case build = "Build Information"
        case experimental = "Experimental Features"
        case combo = "Combo Preview"

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
            case .combo: return "sparkles.rectangle.stack.fill"
            }
        }
        // Individually approved PNGs are packaged as nine native assets.
        // Existing branded art is kept as a fallback if an asset goes missing.
        var packagedArt: String {
            switch self {
            case .diagnostics: return "BBBIconTools"
            case .saves: return "BBBIconInventory"
            case .clock: return "BBBIconSeasonal"
            case .notifications: return "BBBIconHelp"
            case .economy: return "Strawberry_Currency"
            case .build: return "BBBIconSettings"
            case .experimental: return "Night_Developer_Mode_Strawberry_Lock"
            case .combo: return "Milestone"
            }
        }
        var approvedCandidate: String {
            switch self {
            case .diagnostics: return "Dev_Diagnostics_Strawberry_Pulse"
            case .saves: return "Dev_Save_Inspector_Berry_Drive"
            case .clock: return "Dev_Timers_Moon_Clock"
            case .notifications: return "Dev_Notification_Test_Berry_Bell"
            case .economy: return "Dev_Economy_Inspector_Two_Currencies"
            case .build: return "Dev_Build_Information_Berry_Blueprint"
            case .experimental: return "Dev_Experimental_Features_Moon_Potion"
            case .combo: return "Dev_Combo_Preview_Fireworks"
            }
        }
        var blurb: String {
            switch self {
            case .diagnostics: return "Read input and placement status"
            case .saves: return "Check saved Endless gardens"
            case .clock: return "Live local device time"
            case .notifications: return "Future notice preview"
            case .economy: return "Strawberry and future Moonberry status"
            case .build: return "Which app build is installed?"
            case .experimental: return "Which themes are enabled?"
            case .combo: return "Test celebrations without rewards"
            }
        }
        var isPlanned: Bool { self == .notifications }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    Image("Developer_Mode_Strawberry_Lock")
                        .resizable().scaledToFit()
                        .frame(width: 70, height: 70)
                        .accessibilityHidden(true)
                    Text("Developer Garden")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    if !unlocked {
                        Text("Safe tools for development and physical iPhone testing.")
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
                        Text("READ-ONLY QA • No berries, scores or saves are changed")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate)
                            .multilineTextAlignment(.center)
                        Text(BerryBuildIdentity.revisionName)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(BerryStyle.leaf)
                        LazyVGrid(columns: columns, spacing: 11) {
                            ForEach(Tool.allCases) { tool in
                                Button { selectedTool = tool } label: {
                                    VStack(spacing: 6) {
                                        Group {
                                            if UIImage(named: tool.approvedCandidate) != nil {
                                                Image(tool.approvedCandidate)
                                                    .resizable().scaledToFit()
                                            } else {
                                                BerryApprovedArtwork(name: tool.packagedArt,
                                                                     fallback: tool.icon,
                                                                     size: 49)
                                            }
                                        }
                                        .frame(width: 49, height: 49)
                                        Text(tool.rawValue)
                                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        Text(tool.blurb)
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundStyle(BerryStyle.chocolate.opacity(0.78))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(3)
                                        Text(tool.isPlanned ? "COMING LATER" : "OPEN")
                                            .font(.system(size: 9, weight: .black, design: .rounded))
                                            .foregroundStyle(tool.isPlanned ? BerryStyle.chocolate : BerryStyle.leaf)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 151)
                                    .padding(8)
                                    .foregroundStyle(BerryStyle.strawberry)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18)
                                            .strokeBorder(BerryStyle.strawberry.opacity(0.28), lineWidth: 1)
                                    }
                                }
                                .buttonStyle(BerryPolishPressStyle())
                            }
                        }
                    }
                }
                .frame(maxWidth: 480)
                .padding(18)
                .frame(maxWidth: .infinity)
            }
            .background(BerryStyle.softPink.ignoresSafeArea())
            .navigationTitle("Berry Garden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedTool) { tool in
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 13) {
                            Group {
                                if UIImage(named: tool.approvedCandidate) != nil {
                                    Image(tool.approvedCandidate)
                                        .resizable().scaledToFit()
                                } else {
                                    BerryApprovedArtwork(name: tool.packagedArt,
                                                         fallback: tool.icon,
                                                         size: 64)
                                }
                            }
                            .frame(width: 64, height: 64)
                            Text(tool.rawValue)
                                .font(.title2.bold())
                                .foregroundStyle(BerryStyle.strawberry)
                            Text(tool.blurb)
                                .font(.subheadline)
                                .foregroundStyle(BerryStyle.chocolate)
                                .multilineTextAlignment(.center)
                            toolDetails(tool)
                        }
                        .frame(maxWidth: 480)
                        .padding(20)
                        .frame(maxWidth: .infinity)
                    }
                    .background(BerryStyle.softPink.ignoresSafeArea())
                    .navigationTitle(tool.rawValue)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                previewMilestone = nil
                                selectedTool = nil
                            }
                        }
                    }
                    .overlay(alignment: .center) {
                        if let milestone = previewMilestone {
                            BerryComboMilestoneBanner(milestone: milestone)
                                .frame(maxWidth: 300)
                                .padding(.horizontal, 18)
                                .allowsHitTesting(false)
                                .accessibilityLabel("Visual-only combo preview")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func toolDetails(_ tool: Tool) -> some View {
        switch tool {
        case .diagnostics:
            Toggle("Show touch diagnostics during gameplay", isOn: $touchDiagnostics)
                .padding(13)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
            Text("The small QA TOUCH readout appears directly below the gameplay tools bar. Pick up, move and release a piece to see finger events and board cell coordinates, including legal or blocked placement. Return here to switch it off. It never changes the game.")
                .font(.caption)
                .multilineTextAlignment(.center)
        case .saves:
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach([8, 12, 24], id: \.self) { side in
                    let saved = BerryGameSession.hasResumableEndless(side: side)
                    VStack(spacing: 7) {
                        Image(systemName: saved ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(saved ? BerryStyle.leaf : BerryStyle.chocolate)
                        Text("\(side)×\(side) Endless")
                            .font(.caption.bold())
                        Text(saved ? "Saved run" : "No saved run")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, minHeight: 102)
                    .background(.white, in: RoundedRectangle(cornerRadius: 15))
                }
            }
            Text("Read-only: this view cannot restart a game or spend strawberries.")
                .font(.caption)
        case .clock:
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date.formatted(date: .abbreviated, time: .standard))
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
            }
            Text("This is the phone's current local clock. Automatic 6 AM/6 PM storefront switching is not active in Build 4.1.")
                .font(.caption)
                .multilineTextAlignment(.center)
        case .notifications:
            Text("COMING LATER • Build 5")
                .font(.headline)
                .foregroundStyle(BerryStyle.strawberry)
            Text("In-app notice presentation tests are planned. No native iPhone alert is generated here.")
                .font(.caption)
                .multilineTextAlignment(.center)
        case .economy:
            Text("Strawberry balances and purchases continue to use the existing saved ledger. This panel does not grant, deduct or simulate rewards.")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("Moonberries and the Night Market are planned for Build 6, not active here.")
                .font(.caption.bold())
        case .build:
            Text(BerryBuildIdentity.settingsLabel)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
            Text(BerryBuildIdentity.sourceBranch)
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
            Text("Minimum iOS 16.0 • This test candidate is not the earlier Build 4 IPA.")
                .font(.caption)
        case .experimental:
            Text("ACTIVE: Strawberry Blossom Glass can be selected in Settings → Block Appearance. Select Original Strawberry Jam to roll it back.")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("PLANNED: automatic Night Edition artwork switching and the Moonberry economy. These controls are not implemented in this test build.")
                .font(.caption)
                .multilineTextAlignment(.center)
        case .combo:
            Text("Show the center celebration for testing. These are strictly visual previews: no points, streak changes, achievements, strawberries or saved data are awarded.")
                .font(.caption)
                .multilineTextAlignment(.center)
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach([10, 20, 30, 50], id: \.self) { number in
                    Button("✨ Combo ×\(number)") {
                        previewMilestone = number
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            if previewMilestone == number { previewMilestone = nil }
                        }
                    }
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(.white, in: RoundedRectangle(cornerRadius: 15))
                    .buttonStyle(BerryPolishPressStyle())
                }
            }
        }
    }
}
