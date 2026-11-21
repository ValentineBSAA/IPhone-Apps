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
    @State private var showAdvanced = false
    @State private var qaAmountText = ""
    @State private var qaBalance = 0
    @State private var qaPendingAmount = 0
    @State private var qaGrantConfirmation = false
    @State private var qaError: String?
    @AppStorage("berryblockblast.touchDiagnostics") private var touchDiagnostics = false
    @ObservedObject private var economyLedger = BerryEconomyLedger.shared

    private let columns = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]

    private enum Tool: String, CaseIterable, Identifiable {
        case qaWallet = "Test Strawberries"
        case diagnostics = "Diagnostics"
        case saves = "Save Inspector"
        case clock = "Timers & Clocks"
        case notifications = "Notification Test"
        case economy = "Economy Inspector"
        case build = "Build Information"
        case experimental = "Experimental Features"
        case combo = "Combo Preview"
        #if BERRY_INTERNAL_QA
        case sandbox = "Scenario Sandbox"
        case stateLab = "State & Timer Lab"
        case commerce = "Commerce Lab"
        #endif

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .qaWallet: return "wallet.pass.fill"
            case .diagnostics: return "waveform.path.ecg"
            case .saves: return "externaldrive.fill"
            case .clock: return "clock.fill"
            case .notifications: return "bell.badge.fill"
            case .economy: return "creditcard.fill"
            case .build: return "hammer.fill"
            case .experimental: return "flask.fill"
            case .combo: return "sparkles.rectangle.stack.fill"
            #if BERRY_INTERNAL_QA
            case .sandbox: return "square.grid.2x2.fill"
            case .stateLab: return "timer.circle.fill"
            case .commerce: return "basket.fill"
            #endif
            }
        }
        // Individually approved PNGs are packaged as nine native assets.
        // Existing branded art is kept as a fallback if an asset goes missing.
        var packagedArt: String {
            switch self {
            case .qaWallet: return "Strawberry_Currency"
            case .diagnostics: return "BBBIconTools"
            case .saves: return "BBBIconInventory"
            case .clock: return "BBBIconSeasonal"
            case .notifications: return "BBBIconHelp"
            case .economy: return "Strawberry_Currency"
            case .build: return "BBBIconSettings"
            case .experimental: return "Night_Developer_Mode_Strawberry_Lock"
            case .combo: return "Milestone"
            #if BERRY_INTERNAL_QA
            case .sandbox: return "BBBIconTools"
            case .stateLab: return "BBBIconTools"
            case .commerce: return "BBBIconInventory"
            #endif
            }
        }
        var approvedCandidate: String {
            switch self {
            case .qaWallet: return "Dev_Economy_Inspector_Two_Currencies"
            case .diagnostics: return "Dev_Diagnostics_Strawberry_Pulse"
            case .saves: return "Dev_Save_Inspector_Berry_Drive"
            case .clock: return "Dev_Timers_Moon_Clock"
            case .notifications: return "Dev_Notification_Test_Berry_Bell"
            case .economy: return "Dev_Economy_Inspector_Two_Currencies"
            case .build: return "Dev_Build_Information_Berry_Blueprint"
            case .experimental: return "Dev_Experimental_Features_Moon_Potion"
            case .combo: return "Dev_Combo_Preview_Fireworks"
            #if BERRY_INTERNAL_QA
            case .sandbox: return "Dev_Diagnostics_Strawberry_Pulse"
            case .stateLab: return "Dev_Timers_Moon_Clock"
            case .commerce: return "Dev_Economy_Inspector_Two_Currencies"
            #endif
            }
        }
        var blurb: String {
            switch self {
            case .qaWallet: return "Type any QA-only berry amount"
            case .diagnostics: return "Read input and placement status"
            case .saves: return "Check saved Endless gardens"
            case .clock: return "Live local device time"
            case .notifications: return "Future notice preview"
            case .economy: return "Strawberry and future Moonberry status"
            case .build: return "Which app build is installed?"
            case .experimental: return "Which themes are enabled?"
            case .combo: return "Test celebrations without rewards"
            #if BERRY_INTERNAL_QA
            case .sandbox: return "Run isolated board fixtures without saves"
            case .stateLab: return "Mock wallets, charges, saves and time"
            case .commerce: return "One-tap real checkout in disposable test store"
            #endif
            }
        }
        var isPlanned: Bool { self == .notifications }
    }
    private var quickTools: [Tool] {
        [.qaWallet, .diagnostics, .saves, .combo]
    }
    private var advancedTools: [Tool] {
        #if BERRY_INTERNAL_QA
        return [.sandbox, .stateLab, .commerce, .economy, .build, .clock, .experimental, .notifications]
        #else
        return [.economy, .build, .clock, .experimental, .notifications]
        #endif
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
                        Text("INTERNAL QA • Only confirmed test-wallet grants can change your berries")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate)
                            .multilineTextAlignment(.center)
                        Text(BerryBuildIdentity.revisionName)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(BerryStyle.leaf)
                        Text("QUICK TEST TOOLS")
                            .font(.caption.bold())
                            .foregroundStyle(BerryStyle.chocolate)
                        LazyVGrid(columns: columns, spacing: 11) {
                            ForEach(quickTools + (showAdvanced ? advancedTools : [])) { tool in
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
                        Button(showAdvanced ? "Hide extra diagnostics" : "More diagnostics and build information") {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showAdvanced.toggle()
                            }
                        }
                        .font(.subheadline.bold())
                        .tint(BerryStyle.strawberry)
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
                            // Native sheet title is already visible; avoid a second
                            // heading beneath it (also helps compact safe-area layout).
                            Text(tool.blurb)
                                .font(.subheadline)
                                .foregroundStyle(BerryStyle.chocolate)
                                .multilineTextAlignment(.center)
                            toolDetails(tool)
                        }
                        .frame(maxWidth: 480)
                        .padding(20)
                        .padding(.top, 14)
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
                    #if BERRY_INTERNAL_QA
                    .alert("Add test strawberries?", isPresented: $qaGrantConfirmation) {
                        Button("Add \(qaPendingAmount.formatted()) QA berries") {
                            if let balance = BerryGameSession.grantQAStrawberries(qaPendingAmount) {
                                qaBalance = balance
                                qaError = nil
                                qaAmountText = ""
                            } else {
                                qaError = "Unable to add this amount. Check the saved wallet and number size."
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Adds \(qaPendingAmount.formatted()) clearly marked QA strawberries to the saved wallet for testing. They are not counted as earned rewards or line income. This can be spent in the shop.")
                    }
                    #endif
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
        #if BERRY_INTERNAL_QA
        case .sandbox:
            BerryDeveloperSandboxPanel()
        case .stateLab:
            BerryDeveloperStateLabPanel()
        case .commerce:
            BerryDeveloperCommerceLabPanel()
        #endif
        case .qaWallet:
            #if BERRY_INTERNAL_QA
            VStack(spacing: 12) {
                Text("TEST CURRENCY • NOT GAMEPLAY REWARDS")
                    .font(.caption.bold())
                    .foregroundStyle(BerryStyle.strawberry)
                Text("Current saved wallet: 🍓 \(qaBalance.formatted())")
                    .font(.headline)
                TextField("Type amount, e.g. 1200", text: $qaAmountText)
                    .keyboardType(.numberPad)
                    .textContentType(.none)
                    .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                    .multilineTextAlignment(.center)
                    .padding(13)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    .onChange(of: qaAmountText) { value in
                        qaAmountText = String(value.filter(\.isNumber).prefix(19))
                        qaError = nil
                    }
                if let amount = Int(qaAmountText), amount > 0,
                   amount <= Int.max - qaBalance {
                    Text("Preview: 🍓 \(qaBalance.formatted()) → \((qaBalance + amount).formatted())")
                        .font(.subheadline.bold())
                        .foregroundStyle(BerryStyle.leaf)
                }
                Button("Review strawberry grant") {
                    guard let value = Int(qaAmountText), value > 0,
                          qaBalance >= 0, value <= Int.max - qaBalance else {
                        qaError = "Enter a positive whole number within the wallet's safe numeric range."
                        return
                    }
                    qaPendingAmount = value
                    qaGrantConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .tint(BerryStyle.strawberry)
                if let qaError {
                    Text(qaError).font(.caption).foregroundStyle(.red)
                }
                Text("Enter any positive amount once. Confirmation is required. Grants are recorded separately as developer QA credits, not earned strawberries, and remain in your wallet after relaunch. Never use the debug grant in a public build.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                let audit = BerryGameSession.qaGrantHistory()
                if !audit.isEmpty {
                    Text("Recent QA grants")
                        .font(.caption.bold())
                    ForEach(audit.prefix(4), id: \.self) { item in
                        Text(item)
                            .font(.system(size: 10, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .onAppear {
                qaBalance = BerryGameSession.qaWalletBalance()
            }
            #else
            Text("Test-currency grants are not present in distribution builds.")
                .font(.caption)
            #endif
        case .diagnostics:
            Toggle("Show touch diagnostics during gameplay", isOn: $touchDiagnostics)
                .padding(13)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
            Text("The small QA TOUCH readout appears directly below the gameplay tools bar. Pick up, move and release a piece to see finger events and board cell coordinates, including legal or blocked placement. Return here to switch it off. It never changes the game.")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("FAIR PLAY • EXISTING MODE RULES")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(BerryMode.allCases) { mode in
                    VStack(spacing: 7) {
                        Text(mode.rawValue)
                            .font(.caption.bold())
                            .multilineTextAlignment(.center)
                        Text(fairPlayRule(for: mode))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(BerryStyle.chocolate)
                    }
                    .frame(maxWidth: .infinity, minHeight: 108)
                    .padding(8)
                    .background(.white, in: RoundedRectangle(cornerRadius: 15))
                }
            }
            Text("Read-only mode rules. Seeded gameplay measurements run in GitHub CI, not on this phone.")
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
            Text("This is the phone's current local clock. Automatic 6 AM/6 PM storefront switching is planned for Build 4.6.")
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
            Text("FAIR PLAY • RECORDED STRAWBERRY ECONOMY")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            Text("Read-only data from the existing economy ledger. This is NOT the authoritative wallet. Quest, Story and other non-line rewards are not assigned to a mode.")
                .font(.caption)
                .multilineTextAlignment(.center)
            LazyVGrid(columns: columns, spacing: 11) {
                economyMetric("Recorded spending", "\(economyLedger.spent) 🍓")
                economyMetric("Recorded line earnings", "\(economyLedger.earnedByMode.values.reduce(0, +)) 🍓")
            }
            Text("LINE EARNINGS BY MODE")
                .font(.caption.bold())
                .foregroundStyle(BerryStyle.strawberry)
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(Array(economyLedger.earnedByMode.keys).sorted(), id: \.self) { key in
                    economyMetric(key, "\(economyLedger.earnedByMode[key, default: 0]) 🍓")
                }
            }
            Text("RECORDED PURCHASE SPENDING")
                .font(.caption.bold())
                .foregroundStyle(BerryStyle.strawberry)
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(Array(economyLedger.spentByItem.keys).sorted(), id: \.self) { key in
                    economyMetric(key, "\(economyLedger.spentByItem[key, default: 0]) 🍓")
                }
            }
            Text("Undo 40 • Shuffle 50 • Hint 35. Prices are unchanged. Viewing this screen cannot grant, spend or reset anything.")
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

    private func fairPlayRule(for mode: BerryMode) -> String {
        switch mode {
        case .classic:
            return "8×8 • No Undo, Shuffle, Hint or premium tools"
        case .endless:
            return "8×8 / 12×12 / 24×24 • Saved seasons • Adaptive first tray slot"
        case .story:
            return "Chapter objectives • Progressive first tray slot"
        case .daily:
            return "One attempt per day • No adaptive hand"
        case .cozy:
            return "Gentle first tray slot • No timed pressure"
        case .challenge:
            return "Timed score chase • No adaptive hand"
        case .superHard:
            return "12×12 • Three-minute hard challenge • No adaptive hand"
        }
    }

    private func economyMetric(_ title: String, _ amount: String) -> some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)
            Text(amount)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 15))
    }
}
