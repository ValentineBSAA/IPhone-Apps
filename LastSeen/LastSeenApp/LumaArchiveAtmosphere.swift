import SwiftUI

/// Bounded, authored presentation only. No new clues, notifications, records,
/// timers, access changes, or changes to the real device.
enum LumaArchiveAtmosphere {
    enum Intensity: String, CaseIterable, Identifiable {
        case off, restrained, standard
        var id: String { rawValue }
        var title: String {
            switch self {
            case .off: return "Off"
            case .restrained: return "Restrained"
            case .standard: return "Standard"
            }
        }
    }

    struct Treatment: Equatable {
        let edgeOpacity: Double
        let cue: PhoneCue?
    }

    static func treatment(pageID: String, flags: Set<String>, intensity: Intensity,
                          enabled: Bool, reduceMotion: Bool) -> Treatment? {
        guard enabled, intensity != .off, flags.contains("phone-tutorial-finished"),
              let page = LumaWebCatalog.page(pageID), page.id == pageID, page.available(flags),
              flags.contains("web.visited." + pageID),
              !flags.contains(InvestigationResolution.completed) else { return nil }
        let weight: Double
        switch pageID {
        case "archive": weight = 0.35
        case "archive-records": weight = 0.65
        case "archive-review", "archive-ledger": weight = 1
        default: return nil
        }
        // Static peripheral tint, never moving/flickering over a record.
        let opacity = weight * (intensity == .standard ? 0.19 : 0.08)
        return .init(edgeOpacity: opacity, cue: intensity == .standard && !reduceMotion && pageID == "archive-records" ? .suspense : nil)
    }

    /// VEIL is a separate local presentation surface. Its directory and
    /// ordinary session chrome stay neutral; only authorized records gain a
    /// static peripheral tint. No synthetic evidence or audio is generated.
    static func veilTreatment(pageID: String, world: PhoneWorld,
                              installed: String, safeMode: Bool,
                              connected: Bool, active: Bool, wifi: Bool,
                              security: String, intensity: Intensity,
                              enabled: Bool, reduceMotion: Bool) -> Treatment? {
        guard enabled, intensity != .off, !reduceMotion, active, connected, wifi,
              VeilArchive.installed(world, packages: installed, safeMode: safeMode),
              VeilArchive.pages(world).contains(where: { $0.id == pageID }),
              !world.flags.contains(InvestigationResolution.completed),
              VeilArchive.allowsImages(security) else { return nil }
        let weight: Double
        switch pageID {
        case "records": weight = 0.55
        case "media": weight = 0.8
        case "fragment-04": weight = 1
        case "home-index": weight = 1
        default: return nil
        }
        let securityWeight = security == "Safer" ? 0.5 : 1.0
        let opacity = weight * securityWeight * (intensity == .standard ? 0.19 : 0.08)
        return .init(edgeOpacity: opacity, cue: nil)
    }

    /// Deliberate first recording only. The existing optional audio channel
    /// drops the cue if busy; there is no replay or progression dependency.
    static func indexRecordingCue(previouslyRecorded:Bool,recorded:Bool,
                                  treatment:Treatment?,intensity:Intensity,
                                  security:String)->PhoneCue? {
        guard !previouslyRecorded,recorded,treatment != nil,
              intensity == .standard,security == "Standard" else { return nil }
        return .suspense
    }

    /// A quiet emotional beat, not a fake message or modified record.
    static func friendTreatment(world:PhoneWorld,active:Bool,enabled:Bool,
                                intensity:Intensity,reduceMotion:Bool,security:String)->Treatment? {
        guard active,enabled,!reduceMotion,intensity != .off,
              VeilArchive.allowsImages(security),NoraFriendArchive.opened(world),
              !world.flags.contains(InvestigationResolution.completed) else { return nil }
        let weight = security == "Safer" ? 0.5 : 1.0
        return .init(edgeOpacity:weight * (intensity == .standard ? 0.12 : 0.05),cue:nil)
    }

    static func entryCue(pageID: String, previouslyVisited: Bool, active: Bool,
                         treatment: Treatment?) -> PhoneCue? {
        guard active, !previouslyVisited else { return nil }
        return treatment?.cue
    }
}

/// The decoration occupies only a narrow noninteractive perimeter. No
/// fake messages, flashing, blur, reduced text contrast, or layout shifts.
struct LumaArchiveEdgeTreatment: View {
    let opacity: Double
    var body: some View {
        GeometryReader { proxy in
            let inset = min(12, proxy.size.width * 0.035)
            ZStack {
                HStack(spacing: 0) {
                    LinearGradient(colors: [Color.purple.opacity(opacity), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: inset)
                    Spacer(minLength: 0)
                    LinearGradient(colors: [.clear, Color.purple.opacity(opacity)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: inset)
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
