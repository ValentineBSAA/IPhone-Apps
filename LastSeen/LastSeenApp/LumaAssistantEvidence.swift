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

    static func search(_ query:String,in world:PhoneWorld)->[Record] {
        let term=query.trimmingCharacters(in:.whitespacesAndNewlines)
        return visible(world).filter{record in
            term.isEmpty || record.title.localizedCaseInsensitiveContains(term) ||
            record.excerpts.contains{$0.localizedCaseInsensitiveContains(term)}
        }
    }
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
        if HavenWatchEvents.openedFollowup(world) {
            result.append(.init(id:HavenWatchEvents.followupRecordID,title:"HavenWatch · retained archive label",kind:.document,
                excerpts:[HavenWatchEvents.retainedNote]))
        }
        if NoraFriendArchive.opened(world) {
            result.append(.init(id:NoraFriendArchive.recordID,title:NoraFriendArchive.title,kind:.correspondence,
                excerpts:NoraFriendArchive.lines.map{$0.speaker+": "+$0.text}))
        }
        if SocialArchiveReview.opened(world) {
            result.append(.init(id:SocialArchiveReview.recordID,title:SocialArchiveReview.title,kind:.document,
                excerpts:["Restored local draft attributed to Nora; not a published post.",SocialArchiveReview.text]))
        }
        for frame in HavenWatchArchive.opened(world) {
            result.append(.init(id:"haven:"+frame.id,title:"HavenWatch · "+frame.camera.rawValue+" · "+frame.label,
                kind:.document,excerpts:["Camera label: CAM "+frame.camera.number+". "+frame.camera.rawValue+".",
                    "Restored still: "+frame.label+". Original capture date unavailable. No live connection."]))
        }
        if HavenCrossArchiveReview.reviewed(world) {
            result.append(.init(id:"haven:cross-archive",title:"Home archive origins review",kind:.document,
                excerpts:[HavenCrossArchiveReview.note]))
        }
        if VeilArchive.authorized(world) {
            if VeilCommunity.reconstructionOpened(world) {
                result.append(.init(id:VeilCommunity.reconstructionID,title:VeilCommunity.reconstructionTitle,
                    kind:.document,excerpts:[VeilCommunity.reconstructionText]))
            }
            for thread in VeilCommunity.opened(world) {
                let passages = [thread.author+": "+thread.text] + thread.replies.map{$0.author+": "+$0.text}
                result.append(.init(id:"veil:thread:"+thread.id,title:thread.title,kind:.web,excerpts:passages))
            }
            if world.flags.contains("veil.home-index.opened"),
               let page = VeilArchive.pages(world).first(where:{$0.id == "home-index"}) {
                var excerpts=[page.text]
                if VeilCommunity.disputeReviewed(world) { excerpts.append(VeilCommunity.disputeNote) }
                result.append(.init(id:"veil:home-index",title:page.title,kind:.web,excerpts:excerpts))
            }
            let read = world.flags.contains("veil.correspondence.opened")
            let messages = VeilArchive.messages(world)
            for asset in VeilArchive.media(world) where world.flags.contains("veil.viewed."+asset) {
                var facts = ["The displayed image is a recovered reference copy. Its capture date and origin have not been authenticated."]
                if read, let message = messages.first(where:{$0.attachment == asset}) {
                    let date = VeilArchive.date(message,in:world).formatted(date:.abbreviated,time:.omitted)
                    facts.append("The historical conversation includes a copy of this attachment under the date "+date+". That is a message date, not a verified capture date.")
                }
                if let description=VeilArchive.mediaDescription(asset) { facts.append("Visible scene: "+description+" Visible similarities do not authenticate a common source.") }
                if let summary=RecoveredImageAnalysis.summary(asset,in:world){facts.append(summary)}
                if let light=RecoveredImageAnalysis.lightNote(asset,in:world){facts.append(light)}
                facts += ImageInterpretation.notes(asset,in:world)
                facts += PhotoFeatureMatch.notes(asset,in:world)
                result.append(.init(id:"image:"+asset,title:VeilArchive.mediaTitle(asset,in:world) ?? "Recovered photograph",kind:.image,excerpts:facts))
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
            if let light=RecoveredImageAnalysis.lightNote(item.id,in:world){facts.append(light)}
            if item.source == .browser,let description=LumaWebCatalog.referenceDescriptions[item.id] {facts.append("Visible scene: "+description)}
            if item.source == .cameraRoll,let description=NoraPhotoCatalog.everydayDescriptions[item.id] {facts.append("Visible scene: "+description)}
            facts += ImageInterpretation.notes(item.id,in:world)
            facts += PhotoFeatureMatch.notes(item.id,in:world)
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
    /// Find a specific opened record from meaningful terms, without assuming a vague match is proof.
    static func relevant(_ raw:String,in world:PhoneWorld) -> Record? {
        let stop:Set<String>=["the","a","an","i","me","you","it","what","where","who","is","was","were","are","can","could","would","please","tell","about","found","find","look","help","record","message","photo","image","think","nora","that","this","with","and","for","from","have","does","did","do","of","to","in"]
        let terms=LumaAssistantConversation.words(raw).subtracting(stop).filter{$0.count>=4}
        guard !terms.isEmpty else{return nil}
        var ranked:[(record:Record,score:Int)]=[]
        for item in visible(world) {
            let title=LumaAssistantConversation.words(item.title)
            let contents=LumaAssistantConversation.words(item.excerpts.joined(separator:" "))
            let titleScore=title.intersection(terms).count * 3
            let bodyScore=contents.intersection(terms).count
            let score=titleScore+bodyScore
            if score>=2 {ranked.append((item,score))}
        }
        ranked.sort { left,right in
            if left.score==right.score {return left.record.id<right.record.id}
            return left.score>right.score
        }
        guard let best=ranked.first else{return nil}
        if ranked.count>1 && best.score==ranked[1].score {return nil}
        return best.record
    }
    /// These categories describe saved observations, not new visual inference.
    static func imageResponse(_ words:Set<String>,record:Record,visual:LumaImageAnalysisReport?)->String {
        let reconstruction=record.excerpts.filter{$0.hasPrefix("Interpretive observation (uncertain):")}
        let matching=record.excerpts.filter{$0.hasPrefix("Recorded visible-detail comparison:")}
        let light=record.excerpts.filter{$0.hasPrefix("Original-image regional light scan completed.")}
        let source=record.excerpts.filter{$0.hasPrefix("Image analysis recorded.")}
        let scene=record.excerpts.filter{$0.hasPrefix("Visible scene:")}
        let provenance=record.excerpts.filter{$0.contains("message date")}
        if !words.isDisjoint(with:["shadow","shadows","figure","reflection","reflections","distortion","distortions","reconstruction","reconstructed","echo","scanline","scanlines","marker","synthetic","silhouette"]) {
            guard !reconstruction.isEmpty else {
                return "I haven't received a recorded reconstruction observation for this photograph. If something seems different in an adjusted view, compare it with the untouched original before deciding what it means."
            }
            return "I can understand why that detail caught your attention. "+reconstruction.joined(separator:" ")+" I would keep the reconstruction separate from what actually appears in the original."
        }
        if !words.isDisjoint(with:["match","matches","matching","matched","similar","similarity","recurring","furniture","furnishings","countertop","table","sofa"]) {
            guard !matching.isEmpty else {
                return "I don't have a recorded visible-detail match for this photograph yet. Similar-looking rooms or objects aren't enough to establish a shared source. Compare opened originals if you have another reference."
            }
            return matching.joined(separator:" ")+" That is an observation worth keeping, even if we can't establish who made the copies."
        }
        if !words.isDisjoint(with:["brightness","brightest","darkest","contrast","luminance","light"]) {
            let scan=visual.flatMap{$0.valid && record.id=="image:"+$0.asset ? $0.description:nil}
            let facts=light+(scan.map{[$0]} ?? [])
            return facts.isEmpty ? "I don't have a recorded light-scan result for this photograph. You can inspect the original's measured brightness without relying on the reconstruction." :
                facts.joined(separator:" ")+" A light reading doesn't establish what caused the lighting or what lies outside the frame."
        }
        if !words.isDisjoint(with:["date","dates","when","chronology","capture","captured","timestamp"]) {
            return (provenance.isEmpty ? "I don't have a verified capture date for this reference." : provenance.joined(separator:" "))+" A date attached to a recovered copy is not necessarily the date it was taken."
        }
        if !words.isDisjoint(with:["scared","scary","creepy","disturbing","unsettling","afraid","worried"]) {
            return "I can see why an unfamiliar photograph of Nora's life could be unsettling. " +
                (reconstruction.isEmpty ? "We don't need to assume what isn't established by the original." : "You've recorded an interpretive detail, not evidence of another person.") +
                " You can continue with the text records instead."
        }
        let scan=visual.flatMap{$0.valid && record.id=="image:"+$0.asset ? $0.description:nil}
        let wantsVisual = !words.isDisjoint(with:["analyze","analysis","see","showing","shows","scan","object","objects","scene","visible","picture","image","photo","photograph","detail","details","what"])
        var facts=Array(record.excerpts.prefix(1))+scene+provenance+source
        if wantsVisual,let scan {facts.insert(scan,at:0)}
        let completed=light.count+matching.count+reconstruction.count
        if completed>0 {
            facts.append("There are "+String(completed)+" additional recorded observations for this image. Ask me about the light scan, recurring details or reconstruction.")
        }
        return facts.joined(separator:" ")+" What detail would you like to examine?"
    }
    static func response(_ raw:String,record:Record,visual:LumaImageAnalysisReport? = nil) -> String {
        let words = LumaAssistantConversation.words(raw)
        let identity = !words.isDisjoint(with:["identity","sender","who","behind","whereabouts","location"])
        if record.kind == .image {
            if identity { return "I cannot identify the photographer or establish Nora's whereabouts from this reference. "+(record.excerpts.first ?? "") }
            return imageResponse(words,record:record,visual:visual)
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


/// Ephemeral record reference; never persisted with the world.
struct LumaImageHandoff:Equatable {
    let asset:String
    let epoch:UUID
    static func make(_ asset:String,epoch:UUID,in world:PhoneWorld)->Self? {
        guard RecoveredImageAnalysis.record(asset,in:world) != nil,
              LumaAssistantEvidence.selected("image:"+asset,in:world) != nil else{return nil}
        return .init(asset:asset,epoch:epoch)
    }
    func resolve(epoch current:UUID,in world:PhoneWorld)->String? {
        guard epoch==current,Self.make(asset,epoch:current,in:world) != nil else{return nil}
        return asset
    }
}
