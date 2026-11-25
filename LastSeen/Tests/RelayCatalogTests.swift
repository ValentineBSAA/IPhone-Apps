import XCTest
@testable import LastSeen

final class RelayCatalogTests: XCTestCase {
    func testCatalogAndSources() {
        XCTAssertEqual(Set(RelayCatalog.packages.map(\.id)).count, RelayCatalog.packages.count)
        XCTAssertEqual(Set(RelayCatalog.sources.map(\.id)).count, RelayCatalog.sources.count)
        XCTAssertEqual(RelayCatalog.packages.filter(\.essential).count, 3)
        XCTAssertEqual(RelayCatalog.packages.filter { !$0.essential }.count, 23)
        for p in RelayCatalog.packages {
            XCTAssertNotNil(RelayCatalog.source(p.source))
            XCTAssertFalse(p.version.isEmpty)
        }
        XCTAssertTrue(RelayCatalog.source("core")?.essential == true)
        XCTAssertEqual(RelayCatalog.ids(RelayCatalog.defaultSources), Set(["core", "studio", "utilities"]))
    }

    func testSourceRecovery() {
        for raw in ["", "core", "studio", "core|utilities", "unknown", "core|studio|utilities"] {
            XCTAssertEqual(RelayCatalog.ids(RelayCatalog.recoveredSources(raw)), RelayCatalog.requiredSourceIDs)
        }
    }

    func testOptionalSourcesRequireDiscoveryAndExplicitAdd() throws {
        let optional=RelayCatalog.sources.filter{!RelayCatalog.requiredSourceIDs.contains($0.id)}
        XCTAssertEqual(optional.count,5)
        for source in optional {
            let gate=try XCTUnwrap(source.gate)
            let flags:Set<String>=[gate]
            let pkg=try XCTUnwrap(RelayCatalog.packages.first{$0.source==source.id})
            let add=RelayChange(package:pkg,action:.install)
            XCTAssertNil(RelayCatalog.sourceForAddress(source.address,flags:[]))
            XCTAssertNotNil(RelayCatalog.sourceForAddress(source.address,flags:flags))
            XCTAssertFalse(RelayPlan.valid([add],sources:[source.id],installed:[],flags:[]))
            XCTAssertFalse(RelayPlan.valid([add],sources:RelayCatalog.requiredSourceIDs,installed:[],flags:flags))
            XCTAssertTrue(RelayPlan.valid([add],sources:[source.id],installed:[],flags:flags))
            XCTAssertFalse(RelayCatalog.ids(RelayCatalog.recoveredSources("",flags:flags)).contains(source.id))
            XCTAssertTrue(RelayCatalog.ids(RelayCatalog.recoveredSources(source.id,flags:flags)).contains(source.id))
            XCTAssertFalse(RelayCatalog.ids(RelayCatalog.recoveredSources(source.id,flags:[])).contains(source.id))
            XCTAssertTrue(RelayPlan.valid([RelayChange(package:pkg,action:.remove)],sources:[],installed:[pkg.id],flags:[]))
            XCTAssertFalse(RelayCatalog.tweakActive(pkg.id,installed:pkg.id,safeMode:true,flags:flags))
        }
    }

    func testQueueAndProtectedCore() throws {
        let core = try XCTUnwrap(RelayCatalog.package("bootstrap"))
        let theme = try XCTUnwrap(RelayCatalog.package("teal"))
        let seconds = try XCTUnwrap(RelayCatalog.package("seconds"))
        let install = RelayChange(package: theme, action: .install)
        XCTAssertTrue(RelayPlan.queue(RelayChange(package: core, action: .remove), into: []).isEmpty)
        XCTAssertEqual(RelayPlan.queue(install, into: [install]).count, 1)
        XCTAssertTrue(RelayPlan.valid([install], sources: ["core", "studio"], installed: []))
        XCTAssertFalse(RelayPlan.valid([install, install], sources: ["core", "studio"], installed: []))
        XCTAssertFalse(RelayPlan.valid([install], sources: ["core"], installed: []))
        XCTAssertFalse(RelayPlan.valid([install], sources: ["core", "studio"], installed: ["teal"]))
        XCTAssertFalse(RelayPlan.valid([RelayChange(package: core, action: .remove)], sources: ["core"], installed: ["bootstrap"]))
        XCTAssertFalse(RelayPlan.valid([RelayChange(package: seconds, action: .install)], sources: ["core", "studio"], installed: []))
        XCTAssertTrue(RelayPlan.valid([RelayChange(package: seconds, action: .install)], sources: ["core", "utilities"], installed: []))
        XCTAssertTrue(RelayCatalog.visible(seconds, sources: ["core"], installed: ["seconds"]))
        XCTAssertFalse(RelayCatalog.visible(seconds, sources: ["core"], installed: []))
    }

    func testTransactionsAndMigration() throws {
        let theme = try XCTUnwrap(RelayCatalog.package("teal"))
        let compact = try XCTUnwrap(RelayCatalog.package("compact"))
        XCTAssertEqual(RelayCatalog.installedVersion(theme, versions: [:]), "1.0.0")
        let plan = [RelayChange(package: theme, action: .upgrade), RelayChange(package: compact, action: .install)]
        XCTAssertTrue(RelayPlan.valid(plan, sources: ["core", "studio"], installed: ["teal"]))
        let (ids, versions) = RelayPlan.applying(plan, to: ["teal"], versions: [:])
        XCTAssertEqual(ids, Set(["compact", "teal"]))
        XCTAssertEqual(versions["teal"], theme.version)
        XCTAssertEqual(RelayCatalog.versions(RelayCatalog.encodedVersions(versions)), versions)
        let remove = RelayChange(package: theme, action: .remove)
        XCTAssertTrue(RelayPlan.valid([remove], sources: ["core"], installed: ids))
        let (remaining, v) = RelayPlan.applying([remove], to: ids, versions: versions)
        XCTAssertEqual(remaining, ["compact"])
        XCTAssertNil(v["teal"])
        XCTAssertEqual(v["compact"], compact.version)
        XCTAssertEqual(RelayCatalog.ids(RelayCatalog.encoded(remaining)), remaining)
    }

    func testConsoleWordingAndCompletion() {
        let lines = JailbreakTranscript.lines(stage: 3, elapsed: 0)
        XCTAssertEqual(lines.count, 123)
        XCTAssertTrue(lines.contains("Installing Relay"))
        XCTAssertEqual(lines.last, "LumaShell respring queued")
        XCTAssertFalse(lines.contains { $0.localizedCaseInsensitiveContains("virtual") || $0.localizedCaseInsensitiveContains("fictional") || $0.localizedCaseInsensitiveContains("simulat") })
    }
}

// Exercise every gated package's plan, install and removal independently.
extension RelayCatalogTests {
    func testAllEarnedUtilitiesInstallAndRemoveWithoutLosingOtherPackages() throws {
        let flags = Set(LumaUtility.allCases.map(\.flag)).union([RecoveryCircuit.completion])
        let packageIDs = ["fieldnotes"] + LumaUtility.allCases.map(\.rawValue)
        let sources = RelayCatalog.requiredSourceIDs
        var installed: Set<String> = ["seconds"]
        var versions = ["seconds": "1.0.0"]
        for id in packageIDs {
            let p = try XCTUnwrap(RelayCatalog.package(id))
            let install = RelayChange(package:p,action:.install)
            XCTAssertFalse(RelayPlan.valid([install],sources:sources,installed:installed,flags:[]))
            XCTAssertTrue(RelayPlan.valid([install],sources:sources,installed:installed,flags:flags))
            (installed,versions) = RelayPlan.applying([install],to:installed,versions:versions)
            XCTAssertTrue(installed.contains(id)); XCTAssertEqual(versions[id],p.version)
        }
        for id in packageIDs {
            let p = try XCTUnwrap(RelayCatalog.package(id))
            let remove = RelayChange(package:p,action:.remove)
            XCTAssertTrue(RelayPlan.valid([remove],sources:sources,installed:installed,flags:flags))
            (installed,versions) = RelayPlan.applying([remove],to:installed,versions:versions)
            XCTAssertFalse(installed.contains(id)); XCTAssertNil(versions[id])
        }
        XCTAssertEqual(installed,["seconds"]); XCTAssertEqual(versions,["seconds":"1.0.0"])
    }
}
