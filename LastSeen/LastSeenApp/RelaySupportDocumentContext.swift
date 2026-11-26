import Foundation

/// Only the explicitly selected, already shareable fictional documents enter
/// support context. Never traverse Files or the owner's archive for the model.
struct RelaySupportDocumentExcerpt: Equatable {
    let recordID: String
    let title: String
    let excerpt: String
}
enum RelaySupportDocumentContext {
    private static let stop: Set<String> = ["a","an","the","to","of","and","or","is","it","i","my","me","you","can","could","would","how","what","where","why","do","does","did","with","for","this","that","please","about","tell","help","document","file","read","explain","summarize","summary"]
    private static func words(_ text: String) -> Set<String> {
        Set(text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)).subtracting(stop)
    }
    static func excerpts(items: [LumaMessageAttachment], question: String, world: PhoneWorld) -> [RelaySupportDocumentExcerpt] {
        guard RelaySupportAttachmentPolicy.canSend(items, world: world) else { return [] }
        let tokens = words(question)
        return items.compactMap { item in
            guard item.kind == .document,
                  let doc = WorldDocumentCatalog.document(item.recordID, world: world) else { return nil }
            let blocks = doc.blocks.compactMap { block -> String? in
                let value = block.text ?? block.rows?.map { $0.joined(separator: " | ") }.joined(separator: "\n") ?? ""
                let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return clean.isEmpty ? nil : clean
            }
            let ranked = blocks.enumerated().sorted {
                let a = words($0.element).intersection(tokens).count
                let b = words($1.element).intersection(tokens).count
                return a == b ? $0.offset < $1.offset : a > b
            }
            let selected = ranked.prefix(3).map(\.element).joined(separator: "\n")
            guard !selected.isEmpty else { return nil }
            return .init(recordID: doc.id, title: doc.title, excerpt: String(selected.prefix(900)))
        }
    }

    static func localAnswer(items: [LumaMessageAttachment], question: String, world: PhoneWorld) -> RelaySupportAnswer {
        let documents = excerpts(items: items, question: question, world: world)
        if documents.isEmpty {
            return .init(text: "I've received your selected attachments. I can see their file labels, but I can't inspect the image or document contents in this mode. Tell me which technical problem you'd like help with.",
                         guideID: RelaySupportKnowledge.generalGuide("attachments")?.id)
        }
        let summary = documents.map {
            "From " + $0.title + ":\n" + String($0.excerpt.prefix(420))
        }.joined(separator: "\n\n")
        let imageNote = items.contains { $0.kind == .photo } ? "\n\nI can see that you attached a photo too, but I can't analyze its visual contents." : ""
        return .init(text: "Here are relevant excerpts from the documents you shared. These are the document's own words, not a diagnosis.\n\n" + summary + imageNote + "\n\nWhich part would you like help interpreting?",
                     guideID: RelaySupportKnowledge.generalGuide("attachments")?.id)
    }
}
