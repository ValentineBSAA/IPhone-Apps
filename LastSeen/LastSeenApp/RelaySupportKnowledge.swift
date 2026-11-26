import Foundation

/// Imported creator-approved metadata. Runtime RelayCatalog remains the
/// authority for visibility, compatibility, versions, dependencies and status.
enum RelaySupportKnowledge {
    struct PackageHelp: Decodable {
        let id: String
        let summary: String
        let use: String
        let limits: String
        let restart: String
        let status: String
    }
    struct Guide: Decodable, Identifiable {
        struct Section: Decodable {
            let heading: String
            let text: String
        }
        let id: String
        let title: String
        let filename: String
        let sections: [Section]
    }
    private static func load<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: "RelaySupport_" + name, withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: bytes)
    }
    private static let packages = load("packages", as: [PackageHelp].self) ?? []
    private static let guides = load("guides", as: [Guide].self) ?? []

    static func packageHelp(_ id: String, flags: Set<String>) -> PackageHelp? {
        guard RelayCatalog.available(id, flags: flags) else { return nil }
        return packages.first { $0.id == id && $0.status == "existing_catalog" }
    }
    // Start with general guides only. Full package reference docs may name
    // unrecovered packages and must remain inaccessible until filtered.
    static func generalGuides() -> [Guide] {
        guides.filter { ["relay-basics","patchline-recovery","protected-storage","checkpoints","attachments"].contains($0.id) }
    }
    static func generalGuide(_ id: String) -> Guide? {
        generalGuides().first { $0.id == id }
    }
}
