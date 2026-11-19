import SwiftUI
import UIKit

/// Player-facing inventory. Technical touch/debug instructions belong in Developer Garden.
struct BerrySpecialToolsSheet: View {
    enum Tool: String, CaseIterable, Identifiable {
        case trowel, seed, twister, pantry, golden
        var id: String { rawValue }
        var name: String {
            switch self {
            case .trowel: return "Golden Trowel"
            case .seed: return "Starberry Seed"
            case .twister: return "Ribbon Twister"
            case .pantry: return "Picnic Pantry"
            case .golden: return "Golden Strawberry"
            }
        }
        var detail: String {
            switch self {
            case .trowel: return "Remove one block to make room."
            case .seed: return "Plant a block in an empty space."
            case .twister: return "Rotate the piece you selected."
            case .pantry: return "Save a selected piece for later."
            case .golden: return "Rescue your garden when no moves fit."
            }
        }
        var artwork: String {
            switch self {
            case .trowel: return "Flower"
            case .seed: return "Seed"
            case .twister: return "Rotate"
            case .pantry: return "Storage"
            case .golden: return "Strawberry_Currency"
            }
        }
        var fallback: String {
            switch self {
            case .trowel: return "hand.draw.fill"
            case .seed: return "leaf.fill"
            case .twister: return "arrow.triangle.2.circlepath"
            case .pantry: return "basket.fill"
            case .golden: return "heart.fill"
            }
        }
        var chargeKey: String {
            switch self {
            case .trowel: return "trowel"
            case .seed: return "seed"
            case .twister: return "twister"
            case .pantry: return "pantry"
            case .golden: return "golden-strawberry"
            }
        }
        var needsPiece: Bool { self == .twister || self == .pantry }
    }

    @Environment(\.dismiss) private var dismiss
    let charges: [String: Int]
    let pantryOwned: Bool
    let selectedPiece: Bool
    let canContinue: Bool
    let onChoose: (Tool) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("🍓 Special Tools")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Text("A little help for your growing garden!")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate)
                    if !selectedPiece {
                        Text("To rotate or store a piece, choose one of your three pieces before opening Tools.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(BerryStyle.chocolate)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 13))
                    }
                    LazyVGrid(columns: columns, spacing: 11) {
                        ForEach(Tool.allCases) { tool in
                            Button {
                                dismiss()
                                onChoose(tool)
                            } label: {
                                VStack(spacing: 8) {
                                    if let art = UIImage(named: tool.artwork) {
                                        Image(uiImage: art)
                                            .resizable().scaledToFit()
                                            .frame(width: 54, height: 54)
                                    } else {
                                        Image(systemName: tool.fallback)
                                            .font(.system(size: 31, weight: .bold))
                                            .frame(height: 54)
                                    }
                                    Text(tool.name)
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .lineLimit(2)
                                    Text(tool.detail)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .frame(minHeight: 39)
                                    Text(tool == .pantry ? (pantryOwned ? "Ready" : "Locked") :
                                         "\(charges[tool.chargeKey, default: 0]) left")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .background(BerryStyle.softPink, in: Capsule())
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .frame(maxWidth: .infinity, minHeight: 191)
                                .padding(9)
                                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(BerryStyle.strawberry.opacity(0.25)))
                            }
                            .buttonStyle(.plain)
                            .disabled(!canUse(tool))
                            .opacity(canUse(tool) ? 1 : 0.52)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
            }
            .background(BerryStyle.softPink.ignoresSafeArea())
            .navigationTitle("Special Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            } }
        }
    }

    private func canUse(_ tool: Tool) -> Bool {
        if tool == .pantry { return pantryOwned && selectedPiece }
        if tool == .golden {
            return canContinue && charges[tool.chargeKey, default: 0] > 0
        }
        if tool.needsPiece && !selectedPiece { return false }
        return charges[tool.chargeKey, default: 0] > 0
    }
}
