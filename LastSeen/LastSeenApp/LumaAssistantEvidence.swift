import Foundation

/// References to actually opened fictional records. Catalog availability is
/// checked again on every request. No source is opened by assistant inference.
/// Transient access snapshot, not a saved permission or conversation record.
/// A rollback can revoke a source discussed by name even without a selection.
struct LumaAssistantAccessSnapshot: Equatable {
    let hasArchive: Bool
    let flags: Set<String>
    let recordIDs: Set<String>
    init(_ world: PhoneWorld) {
        hasArchive = world.everydayArchiveRevision != nil
        flags = world.flags
        recordIDs = Set(LumaAssistantEvidence.visible(world).map(\.id))
    }
    func revokes(_ previous: Self) -> Bool {
        (previous.hasArchive && !hasArchive) ||
        !previous.flags.isSubset(of: flags) ||
        !previous.recordIDs.isSubset(of: recordIDs)
    }
}

enum LumaAssistantEvidence {
    struct Record: Identifiable {
        let id:String
        let title:String
        let kind:Kind
        let excerpts:[String]
        var topic:LumaConversationTopic {
            switch kind {
            case .image: return .pictures
            case .correspondence: return .correspondence
            default: return .provenance
            }
        }
    }
    enum Kind { case document, web, social, image, correspondence }

    static func documentMarker(_ id:String) -> String { "luma.opened.document."+id }
    static func socialMarker(_ channel:LumaSocialChannel,_ id:String) -> String { "luma.opened.social."+channel.rawValue+"."+id }

    static func visible(_ world:PhoneWorld) -> [Record] {
        guard world.everydayArchiveRevision != nil else { return [] }
        var result:[Record] = []
        for doc in WorldDocumentCatalog.visible(world) where world.flags.contains(documentMarker(doc.id)) {
            let excerpts = doc.blocks.compactMap { block -> String? in
                if let text = block.text { return text }
                if let rows = block.rows { return rows.map{$0.joined(separator:" | ")}.joined(separator:"\n") }
                return nil
            }
            result.append(.init(id:"doc:"+doc.id,title:doc.title,kind:.document,excerpts:excerpts))
        }
        for page in LumaWebCatalog.pages where page.available(world.flags) && world.flags.contains("web.visited."+page.id) {
            result.append(.init(id:"web:"+page.id,title:page.title,kind:.web,excerpts:page.sections))
        }
        for channel in LumaSocialChannel.allCases {
            for post in LumaSocialCatalog.visible(channel,world:world) where world.flags.contains(socialMarker(channel,post.id)) {
                result.append(.init(id:"social:"+channel.rawValue+":"+post.id,title:post.author+" · "+String(post.body.prefix(48)),kind:.social,excerpts:[post.body]))
            }
        }
        if VeilArchive.authorized(world) {
            for thread in VeilCommunity.opened(world) {
                let passages = [thread.author+": "+thread.text] + thread.replies.map{$0.author+": "+$0.text}
                result.append(.init(id:"veil:thread:"+thread.id,title:thread.title,kind:.web,excerpts:passages))
            }
            let read = world.flags.contains("veil.correspondence.opened")
            let messages = VeilArchive.messages(world)
            for (i,asset) in VeilArchive.media(world).enumerated() where world.flags.contains("veil.viewed."+asset) {
                var facts = ["The displayed image is a recovered reference copy. Its capture date and origin have not been authenticated."]
                if read, let message = messages.first(where:{$0.attachment == asset}) {
                    let date = VeilArchive.date(message,in:world).formatted(date:.abbreviated,time:.omitted)
                    facts.append("The historical conversation includes a copy of this attachment under the date "+date+". That is a message date, not a verified capture date.")
                }
                if let summary=RecoveredImageAnalysis.summary(asset,in:world){facts.append(summary)}
                facts += ImageInterpretation.notes(asset,in:world)
                result.append(.init(id:"image:"+asset,title:"Recovered photograph "+String(i+1),kind:.image,excerpts:facts))
            }
            if read {
                // The player's open action exposed this correspondence already.
                // Preserve sender labels as labels, not verified identities.
                let excerpts = messages.map { ($0.fromNora ? "Nora: " : "Unknown Number: ")+$0.text }
                result.append(.init(id:"veil:conversation",title:"Recovered unknown-number conversation",kind:.correspondence,excerpts:excerpts))
            }
        }
        for item in RecoveredImageAnalysis.visible(world) where item.source != .veil {
            var facts=["This is a recovered local reference in the "+item.source.title+". Original capture and photographer are not independently established."]
            if let summary=RecoveredImageAnalysis.summary(item.id,in:world){facts.append(summary)}
            facts += ImageInterpretation.notes(item.id,in:world)
            result.append(.init(id:"image:"+item.id,title:item.title,kind:.image,excerpts:facts))
        }
        return result
    }

    static func selected(_ id:String?,in world:PhoneWorld) -> Record? {
        guard let id else { return nil }
        return visible(world).first{$0.id == id}
    }
    static func mentions(_ raw:String,in world:PhoneWorld) -> Record? {
        let normalized = " "+LumaAssistantPolicy.normalize(raw)+" "
        let matches = visible(world).filter {
            let title = LumaAssistantPolicy.normalize($0.title)
            return title.count >= 5 && normalized.contains(" "+title+" ")
        }
        return matches.count == 1 ? matches[0] : nil
    }
    static func response(_ raw:String,record:Record,visual:LumaImageAnalysisReport? = nil) -> String {
        let words = LumaAssistantConversation.words(raw)
        let identity = !words.isDisjoint(with:["identity","sender","who","behind","whereabouts","location"])
        if record.kind == .image {
            if identity { return "I cannot identify the photographer or establish Nora's whereabouts from this reference. "+record.excerpts.joined(separator:" ") }
            let scan=visual.flatMap { $0.valid && record.id=="image:"+$0.asset ? $0.description:nil }
            let wantsVisual = !words.isDisjoint(with:["analyze","analysis","see","showing","shows","brightness","dark","light","scan","object","objects","scene","visible","picture","image","photo","photograph","detail","details","what"])
            if wantsVisual,let scan {return scan+" "+record.excerpts.joined(separator:" ")+" What would you like to compare?"}
            return record.excerpts.joined(separator:" ")+" What detail in the image would you like to compare?"
        }
        if identity {
            return "The selected record is “"+record.title+"”. Its existence does not establish a person's identity or current whereabouts. I can compare its wording, but I cannot confirm who is responsible."
        }
        let ignored:Set<String> = ["the","a","an","it","this","that","i","me","you","what","does","did","is","are","was","were","about","tell","can","could","please","record","document","post","message","mean","think","say","said","in","of","to","and"]
        let query = words.subtracting(ignored)
        let excerpts = record.excerpts.map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty}
        guard !excerpts.isEmpty else { return "There is no readable text in this selected record." }
        let ranked = excerpts.enumerated().sorted { a,b in
            let x = LumaAssistantConversation.words(a.element).intersection(query).count
            let y = LumaAssistantConversation.words(b.element).intersection(query).count
            return x == y ? a.offset < b.offset : x > y
        }
        let best = ranked[0].element
        let relevant = !LumaAssistantConversation.words(best).isDisjoint(with:query)
        let excerpt = String(best.prefix(420))+(best.count > 420 ? "…" : "")
        let intro = relevant ? "This passage may be relevant" : "Here is a passage from the selected record"
        return intro+" (“"+record.title+"”):\n“"+excerpt+"”\nThat is what the record says, not independent confirmation. Which part would you like to examine?"
    }
}
