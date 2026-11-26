import Foundation

struct RelaySupportAnswer {
    let text: String
    var guideID: String? = nil
    var packageID: String? = nil
}

protocol RelaySupportReplyProvider {
    func reply(question: String, recent: [RelaySupportMessage], flags: Set<String>, sources: String, installed: String) -> RelaySupportAnswer
}

/// Deterministic, offline retrieval. Never executes an action, and never
/// exposes undiscovered package metadata or the owner's message archive.
enum RelaySupportScope {
    static func personalQuestion(_ text:String)->Bool {
        let words=Set(text.lowercased().split{!$0.isLetter && !$0.isNumber}.map(String.init))
        guard words.contains("nora") else{return false}
        let personal:Set<String>=["whereabouts","missing","disappeared","stalking","stalker","family","friends","childhood","hobbies","relationship","boyfriend","girlfriend","favorite","favourite","identity","personal","life","music"]
        if !words.isDisjoint(with:personal) {return true}
        let ambiguous:Set<String>=["where","who","like","likes","liked","know"]
        let technical:Set<String>=["backup","restore","checkpoint","package","packages","relay","patchline","settings","diagnostic","diagnostics","respring","reboot","crash","error","files","storage","device","battery","wifi","bluetooth"]
        return !words.isDisjoint(with:ambiguous) && words.isDisjoint(with:technical)
    }
    static let personalReply="I handle technical support for the phone. Luma is the better assistant for questions about Nora and the records you've recovered. I don't have access to her private history."
}
struct RelaySupportLocalProvider: RelaySupportReplyProvider {
    private static let stop: Set<String> = ["a","an","the","to","of","and","or","is","it","i","my","me","you","can","could","would","how","what","where","why","do","does","did","with","for","this","that","please","about","tell","help","use","using"]
    private static let expansions: [String: Set<String>] = [
        "crash": ["recovery","safe","mode"], "crashing": ["recovery","safe","mode"],
        "restart": ["respring","reboot"], "restarts": ["respring","reboot"],
        "dependency": ["requirements","package"], "dependencies": ["requirements","package"],
        "repo": ["repository","sources"], "repos": ["repository","sources"],
        "backup": ["checkpoint","restore"], "save": ["checkpoint","saving"],
        "picture": ["photo","attachment"], "pictures": ["photo","attachment"],
        "locked": ["protected","authentication"], "faceid": ["biometrics","authentication"]
    ]
    private func words(_ text: String) -> Set<String> {
        Set(text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
    }
    private func normalized(_ text: String) -> String {
        text.lowercased().split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
    }
    func reply(question: String, recent: [RelaySupportMessage], flags: Set<String>, sources: String, installed: String) -> RelaySupportAnswer {
        let raw = words(question)
        if !raw.isDisjoint(with: ["password","passcode","pin","spoiler","ending","exploit","bypass","credentials","secret","secrets","solution"]) {
            return .init(text: "I can explain recovery and authentication, but I can't provide private credentials, hidden records or puzzle answers. What problem are you seeing in the interface?")
        }
        if RelaySupportScope.personalQuestion(question) {return .init(text:RelaySupportScope.personalReply)}
        if ["hi","hello","hey"].contains(normalized(question)) {
            return .init(text: "Hey! What are you working on? Tell me the package name or what you're seeing on the phone.")
        }
        if ["thanks","thank you","got it"].contains(normalized(question)) {
            return .init(text: "You're welcome. If anything else gets in your way, tell me what happened.")
        }
        let enabled = RelayCatalog.ids(RelayCatalog.recoveredSources(sources, flags: flags))
        let installedIDs = RelayCatalog.ids(installed)
        let accessible = RelayCatalog.packages.filter {
            RelayCatalog.available($0.id, flags: flags) && ($0.essential || enabled.contains($0.source) || installedIDs.contains($0.id))
        }
        let q = " " + normalized(question) + " "
        let mentioned = accessible.filter { q.contains(" " + normalized($0.title) + " ") || (normalized($0.id).count >= 5 && q.contains(" " + normalized($0.id) + " ")) }
        var tokens = raw.subtracting(Self.stop)
        for token in raw { tokens.formUnion(Self.expansions[token] ?? []) }
        let followup = !raw.isDisjoint(with: ["it","that","this","more","again","why"]) && tokens.count <= 6
        let previous = recent.last(where: { !$0.outgoing })
        let matched = mentioned.count == 1 ? mentioned.first : (mentioned.isEmpty && followup ? accessible.first { $0.id == previous?.packageID } : nil)
        if mentioned.count > 1 {
            return .init(text: "Which of those packages would you like to troubleshoot first?")
        }
        if let package = matched,
           let report = recent.reversed().compactMap(\.diagnostic).first(where: { $0.packageID == package.id }),
           !raw.isDisjoint(with: ["report","status","paused","conflict","fix","working","why","now","still","diagnostic"]) {
            return .init(text: "From the report you shared earlier (not a live check): " + report.advice +
                "\n\nIf you have changed anything since then, please share a fresh report from Diagnostics.",
                guideID: RelaySupportKnowledge.generalGuide("patchline-recovery")?.id, packageID: package.id)
        }
        if let package = matched, let help = RelaySupportKnowledge.packageHelp(package.id, flags: flags) {
            let instructions = !raw.isDisjoint(with: ["restart","reboot","respring"]) ? help.restart : help.use + "\n\n" + help.limits
            return .init(text: package.title + ": " + instructions, packageID: package.id)
        }
        let guides = RelaySupportKnowledge.generalGuides()
        var ranked: [(score: Int, guide: RelaySupportKnowledge.Guide, section: RelaySupportKnowledge.Guide.Section)] = []
        for guide in guides {
            for section in guide.sections {
                let titleScore = tokens.intersection(words(guide.title)).count
                let headingScore = tokens.intersection(words(section.heading)).count
                let contentScore = tokens.intersection(words(section.text)).count
                let context = followup && previous?.guideID == guide.id ? 2 : 0
                ranked.append((titleScore * 3 + headingScore * 4 + contentScore + context, guide, section))
            }
        }
        ranked.sort {
            if $0.score != $1.score {return $0.score > $1.score}
            if $0.guide.id != $1.guide.id {return $0.guide.id < $1.guide.id}
            return $0.section.heading < $1.section.heading
        }
        guard let best = ranked.first, best.score >= 3, !tokens.isEmpty else {
            return .init(text: "I'm not certain what you're referring to. Which app or package are you using, and what did you expect to happen?")
        }
        return .init(text: best.section.text + "\n\nI've included the relevant guide if you want the full instructions.", guideID: best.guide.id)
    }
}
