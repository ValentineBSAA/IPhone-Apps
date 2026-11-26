import XCTest
@testable import LastSeen

final class RelayCatalogTests: XCTestCase {
    @MainActor
    func testMalformedReceiptQuarantinePreservesBytesAndPausesTweaks() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite="relay-quarantine-"+UUID().uuidString
        let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
        defer {defaults.removePersistentDomain(forName:suite);try? FileManager.default.removeItem(at:root)}
        let bytes=Data("unreadable fixture".utf8)
        defaults.set(bytes,forKey:RelayTransactionReceipt.key)
        defaults.set("compact",forKey:"lastseen.relay.installed")
        XCTAssertTrue(RelayTransactionReceipt.malformed(defaults:defaults))
        try RelayTransactionReceipt.quarantineMalformed(defaults:defaults,root:root)
        XCTAssertNil(defaults.object(forKey:RelayTransactionReceipt.key))
        XCTAssertTrue(defaults.bool(forKey:"lastseen.relay.safeMode"))
        XCTAssertEqual(defaults.string(forKey:"lastseen.relay.installed"),"compact")
        let archived=try XCTUnwrap(FileManager.default.contentsOfDirectory(at:root,includingPropertiesForKeys:nil).first)
        let plist=try PropertyListSerialization.propertyList(from:Data(contentsOf:archived),format:nil) as? [String:Any]
        XCTAssertEqual(plist?["receipt"] as? Data,bytes)
        XCTAssertThrowsError(try RelayTransactionReceipt.quarantineMalformed(defaults:defaults,root:root))
    }

    @MainActor
    func testPackageCommitReceiptRecoversPartialFieldsWithoutDuplicateHistory() throws {
        let suite="relay-receipt-"+UUID().uuidString
        let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
        defer{defaults.removePersistentDomain(forName:suite)}
        let package=try XCTUnwrap(RelayCatalog.package("compact"))
        let changes=[RelayChange(package:package,action:.install)]
        let target=RelayTransactionReceipt.Snapshot.planned(changes:changes,installed:[],versions:[:],
            wallpaper:1,history:"Previous transaction")
        try RelayTransactionReceipt.stage(target,defaults:defaults)
        // Simulate interruption after the installed ID was written.
        defaults.set(target.installed,forKey:"lastseen.relay.installed")
        defaults.set(true,forKey:"lastseen.relay.safeMode")
        XCTAssertTrue(RelayTransactionReceipt.recover(defaults:defaults))
        XCTAssertEqual(defaults.string(forKey:"lastseen.relay.versions"),target.versions)
        XCTAssertTrue(defaults.bool(forKey:"lastseen.relay.compactIcons"))
        XCTAssertEqual(defaults.integer(forKey:"lastseen.lab.wallpaper"),1)
        XCTAssertTrue(defaults.bool(forKey:"lastseen.relay.safeMode"))
        XCTAssertEqual(defaults.string(forKey:"lastseen.relay.history"),target.history)
        XCTAssertNil(defaults.object(forKey:RelayTransactionReceipt.key))
        XCTAssertTrue(RelayTransactionReceipt.recover(defaults:defaults))
        XCTAssertEqual(defaults.string(forKey:"lastseen.relay.history"),target.history)
        defaults.set(Data("bad receipt".utf8),forKey:RelayTransactionReceipt.key)
        XCTAssertFalse(RelayTransactionReceipt.recover(defaults:defaults))
        XCTAssertFalse(RelayTransactionReceipt.commit(target,defaults:defaults))
        XCTAssertEqual(defaults.string(forKey:"lastseen.relay.history"),target.history)
    }

    func testCatalogAndSources() {
        XCTAssertEqual(Set(RelayCatalog.packages.map(\.id)).count, RelayCatalog.packages.count)
        XCTAssertEqual(Set(RelayCatalog.sources.map(\.id)).count, RelayCatalog.sources.count)
        XCTAssertEqual(RelayCatalog.packages.filter(\.essential).count, 3)
        XCTAssertEqual(RelayCatalog.packages.filter { !$0.essential }.count, 27)
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
        XCTAssertTrue(lines.contains("Checking simulated firmware profile"))
        XCTAssertTrue(lines.contains("Checking fictional owner access policy"))
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

extension RelayCatalogTests {
    func testConflictReplacementAndLoaderStatus() throws {
        let ghost = try XCTUnwrap(RelayCatalog.package("dockglass"))
        let slate = try XCTUnwrap(RelayCatalog.package("dockcontrast"))
        let add = RelayChange(package: slate, action: .install)
        XCTAssertFalse(RelayPlan.valid([add], sources: ["studio"], installed: [ghost.id]))
        XCTAssertFalse(RelayPlan.problems([add], sources: ["studio"], installed: [ghost.id]).isEmpty)
        let replace = [RelayChange(package: ghost, action: .remove), add]
        XCTAssertTrue(RelayPlan.valid(replace, sources: ["studio"], installed: [ghost.id]))
        let (next, _) = RelayPlan.applying(replace, to: [ghost.id], versions: [:])
        XCTAssertEqual(next, [slate.id])
        XCTAssertTrue(RelayCatalog.tweakActive(slate.id, installed: slate.id, safeMode: false, flags: []))
        XCTAssertFalse(RelayCatalog.tweakActive(slate.id, installed: slate.id, safeMode: true, flags: []))
        XCTAssertFalse(RelayCatalog.tweakActive(slate.id, installed: "dockglass|dockcontrast", safeMode: false, flags: []))
        XCTAssertEqual(PatchlinePackageHealth.status(slate, installed: next, flags: [], safeMode: true), .safeMode)
        XCTAssertEqual(PatchlinePackageHealth.status(slate, installed: [ghost.id,slate.id], flags: [], safeMode: false), .conflict)
    }
    func testPackageHealthMatchesLauncherAndSupportException() throws {
        for p in RelayCatalog.packages where !p.essential {
            XCTAssertEqual(PatchlinePackageHealth.status(p,installed:[],flags:[],safeMode:false),.notInstalled)
            for safe in [false,true] {
                let installed:Set<String>=[p.id]
                let active = p.id == "relay-support"
                    ? RelaySupportAccess.available(installed:p.id,flags:[])
                    : RelayCatalog.tweakActive(p.id,installed:p.id,safeMode:safe,flags:[])
                XCTAssertEqual(PatchlinePackageHealth.status(p,installed:installed,flags:[],safeMode:safe) == .active,active,p.id)
            }
        }
        let support=try XCTUnwrap(RelayCatalog.package("relay-support"))
        XCTAssertEqual(PatchlinePackageHealth.status(support,installed:[support.id],flags:[],safeMode:true),.active)
        let teal=try XCTUnwrap(RelayCatalog.package("teal"))
        let plan=[RelayChange(package:teal,action:.install)]
        XCTAssertTrue(RelayPlan.valid(plan,sources:["studio"],installed:[]))
        XCTAssertFalse(RelayPlan.valid(plan,sources:["core"],installed:[]))
        XCTAssertFalse(RelayPlan.valid(plan,sources:["studio"],installed:["teal"]))
    }

    func testStaleUpgradeAndGatedRuntime() throws {
        let p = try XCTUnwrap(RelayCatalog.package("teal"))
        let upgrade = RelayChange(package: p, action: .upgrade)
        XCTAssertFalse(RelayPlan.valid([upgrade], sources: ["studio"], installed: [p.id], versions: [p.id:p.version]))
        XCTAssertTrue(RelayPlan.valid([upgrade], sources: ["studio"], installed: [p.id], versions: [p.id:"1.0.0"]))
        XCTAssertFalse(RelayCatalog.tweakActive("fieldnotes", installed: "fieldnotes", safeMode: false, flags: []))
        XCTAssertTrue(RelayCatalog.tweakActive("privatepreview", installed: "privatepreview", safeMode: false, flags: []))
        XCTAssertFalse(RelayCatalog.tweakActive("privatepreview", installed: "privatepreview", safeMode: true, flags: []))
    }
}
