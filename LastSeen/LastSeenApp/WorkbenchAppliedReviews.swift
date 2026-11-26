import SwiftUI

/// Optional applications of service exercises to already visited records.
/// These observations do not certify the original image, create evidence,
/// or grant any investigation flags.
enum WorkbenchAppliedReview: String, CaseIterable, Identifiable {
    case preview, configuration, sequence
    var id: String { rawValue }
    var diagnostic: WorkbenchDiagnostic {
        switch self {
        case .preview: return .signal
        case .configuration: return .configuration
        case .sequence: return .chronology
        }
    }
    var sourceID: String {
        switch self {
        case .preview: return "archive-records"
        case .configuration: return "studio-news"
        case .sequence: return "archive-ledger"
        }
    }
    var title: String {
        switch self {
        case .preview: return "Preview verification limits"
        case .configuration: return "Read-only review policy"
        case .sequence: return "Record sequence and provenance"
        }
    }
    var question: String {
        switch self {
        case .preview: return "What does a successful preview alignment establish about the recovered attachments?"
        case .configuration: return "Which service policy preserves the public reference while reviewing local records?"
        case .sequence: return "How should the two time labels be treated when the original source is disputed?"
        }
    }
    var options: [String] {
        switch self {
        case .preview: return ["The preview can be rendered consistently; the original capture still needs independent verification.", "The preview proves the original image depicts a verified event.", "A failed preview proves the source was deliberately altered."]
        case .configuration: return ["Rewrite the source to match the local preview.", "Keep the reference unchanged and inspect the local copy separately.", "Publish every recovered record to confirm the source."]
        case .sequence: return ["Treat the import label as the original capture time.", "Remove the disputed entry from the reference.", "Retain both labels separately; the import label does not establish the original capture."]
        }
    }
    func accepts(_ choice: Int) -> Bool {
        switch self {
        case .preview: return choice == 0
        case .configuration: return choice == 1
        case .sequence: return choice == 2
        }
    }
    var observation: String {
        switch self {
        case .preview: return "A stable preview is a presentation check, not a provenance certificate."
        case .configuration: return "A read-only copy can be compared without changing its reference."
        case .sequence: return "Dependency order and source provenance are separate questions."
        }
    }
    func source(in world: PhoneWorld) -> LumaWebPage? {
        guard world.everydayArchiveRevision != nil,
              world.flags.contains("web.visited." + sourceID),
              let page = LumaWebCatalog.page(sourceID), page.available(world.flags) else { return nil }
        return page
    }
    func available(in world: PhoneWorld) -> Bool {
        world.connectedWorld?.workbenchConnected == true &&
        source(in: world) != nil &&
        WorkbenchDiagnosticCatalog.progress(diagnostic, in: world).verified
    }
    func completed(in world: PhoneWorld) -> Bool {
        source(in: world) != nil &&
        WorkbenchDiagnosticCatalog.progress(diagnostic, in: world).verified &&
        world.connectedWorld?.workbenchAppliedReviews?.contains(rawValue) == true
    }
    static func visible(_ world: PhoneWorld) -> [Self] {
        allCases.filter { $0.available(in: world) }
    }
}

struct WorkbenchAppliedReviewView: View {
    let review: WorkbenchAppliedReview
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var selected: Int?
    private var available:Bool {phase == .active && review.available(in:world.state)}
    @State private var feedback = ""
    var body: some View {
        List {
            if available, let source = review.source(in: world.state) {
                Section {
                    LumaHeader(title: review.title, detail: "Optional applied diagnostic", symbol: "doc.text.magnifyingglass")
                    Text("Apply a verified practice procedure to a record you have already reviewed. This exercise is not required to finish the investigation.").font(.subheadline)
                }
                Section("Previously reviewed source") {
                    Text(source.title).font(.headline)
                    Text(source.address).font(.caption.monospaced()).foregroundColor(.secondary)
                    ForEach(source.sections.indices, id: \.self) { index in
                        Text(source.sections[index]).font(.subheadline).textSelection(.enabled)
                    }
                }
                if review.completed(in: world.state) {
                    Section("Applied observation") {
                        Label("Review recorded", systemImage: "checkmark.seal.fill").foregroundColor(.teal)
                        Text(review.observation).font(.subheadline)
                        Text("A local review note, not a new verified fact about the original record.").font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    Section("Apply the procedure") {
                        Text(review.question).font(.headline)
                        ForEach(review.options.indices, id: \.self) { index in
                            Button {
                                selected = index
                                feedback = ""
                            } label: {
                                HStack(alignment: .top) {
                                    Image(systemName: selected == index ? "largecircle.fill.circle" : "circle")
                                    Text(review.options[index]).multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                }
                            }.buttonStyle(.plain).accessibilityAddTraits(selected == index ? .isSelected : [])
                        }
                        Button("Record observation") {
                            guard available,let selected else{return}
                            feedback = world.completeAppliedReview(review, choice: selected) ? "Review recorded." : "Consider the limits of the source and try again."
                        }.disabled(selected == nil)
                        if !feedback.isEmpty { Text(feedback).font(.caption).foregroundColor(.secondary) }
                    }
                }
            } else {
                Label("This review is not available in the current environment.", systemImage: "lock")
            }
        }.navigationTitle("Applied review").navigationBarTitleDisplayMode(.inline)
        .onChange(of:available){if !$0 {selected=nil;feedback=""}}
    }
}
