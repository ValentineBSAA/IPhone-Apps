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

    struct LibraryEntry: Identifiable {
        let guide: Guide
        let sections: [Guide.Section]
        let complete: Bool
        var id: String { guide.id }
        var title: String { guide.title }
    }

    /// Use the live catalog rather than trusting a guide's static availability.
    /// An unrecognized package-reference heading is never exposed.
    static func library(flags: Set<String>, sources: String, installed: String) -> [LibraryEntry] {
        guard RelaySupportAccess.available(installed: installed, flags: flags) else { return [] }
        let enabled = RelayCatalog.ids(RelayCatalog.recoveredSources(sources, flags: flags))
        let installedIDs = RelayCatalog.ids(installed)
        let visible = RelayCatalog.packages.filter {
            RelayCatalog.available($0.id, flags: flags) &&
            ($0.essential || enabled.contains($0.source) || installedIDs.contains($0.id))
        }
        let generalIDs = Set(generalGuides().map(\.id)).union(["service-tools","relay-support"])
        return guides.compactMap { guide in
            if generalIDs.contains(guide.id) {
                return LibraryEntry(guide: guide, sections: guide.sections, complete: true)
            }
            guard ["packages-07","packages-08","packages-09","packages-10","packages-11","packages-12"].contains(guide.id) else { return nil }
            let sections = guide.sections.filter { section in
                visible.contains { $0.title == section.heading }
            }
            guard !sections.isEmpty else { return nil }
            return LibraryEntry(guide: guide, sections: sections, complete: sections.count == guide.sections.count)
        }
    }

    static func libraryEntry(_ id: String, flags: Set<String>, sources: String, installed: String) -> LibraryEntry? {
        library(flags: flags, sources: sources, installed: installed).first { $0.id == id }
    }
}
