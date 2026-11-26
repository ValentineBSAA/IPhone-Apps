import SwiftUI

struct RelaySupportDiagnostic: Codable, Equatable, Identifiable {
    let packageID: String
    let title: String
    let version: String
    let status: String
    let sourceEnabled: Bool
    var id: String { packageID }

    static func availablePackages(installed: String, flags: Set<String>) -> [RelayPackage] {
        let ids = RelayCatalog.ids(installed)
        return RelayCatalog.packages.filter {
            RelayCatalog.installed($0.id, userIDs: ids) && RelayCatalog.available($0.id, flags: flags)
        }
    }

    static func capture(packageID: String, installed: String, versions: String, sources: String, safeMode: Bool, flags: Set<String>) -> Self? {
        guard let package = availablePackages(installed: installed, flags: flags).first(where: { $0.id == packageID }) else { return nil }
        let ids = RelayCatalog.ids(installed)
        let enabled = RelayCatalog.ids(RelayCatalog.recoveredSources(sources, flags: flags))
        return .init(packageID: package.id, title: package.title,
                     version: RelayCatalog.installedVersion(package, versions: RelayCatalog.versions(versions)),
                     status: PatchlinePackageHealth.status(package, installed: ids, flags: flags, safeMode: safeMode).rawValue,
                     sourceEnabled: enabled.contains(package.source))
    }

    var advice: String {
        let intro = "Your shared report shows \(title) \(version) · \(status). "
        let source = sourceEnabled ? "" : "Its source is not enabled; check Sources before attempting an update. "
        switch status {
        case PatchlinePackageHealth.safeMode.rawValue:
            return intro + source + "Safe Mode pauses optional tweaks without removing them. Review any troublesome packages in Relay before leaving Safe Mode."
        case PatchlinePackageHealth.conflict.rawValue:
            return intro + source + "Open the package details and review its conflicts. Queue an intentional replacement or removal and review the transaction before confirming."
        case PatchlinePackageHealth.missingRequirement.rawValue:
            return intro + source + "Review the requirements in Relay and the loader diagnostics in Patchline. Do not remove essential components."
        case PatchlinePackageHealth.active.rawValue:
            return intro + source + "The loader reports this package as active. Where did you expect its feature to appear?"
        case PatchlinePackageHealth.essential.rawValue:
            return intro + source + "This is a protected system component. It isn't a user tweak and should remain installed."
        default:
            return intro + source + "The current report doesn't establish a cause. Check the package details in Relay."
        }
    }
}

enum RelaySupportAttachmentPolicy {
    static func canSend(_ items: [LumaMessageAttachment], world: PhoneWorld) -> Bool {
        items.count <= 3 && Set(items).count == items.count &&
        Set(items).isSubset(of: Set(LumaMessageAttachmentCatalog.shareable(world)))
    }
    static func canRead(_ item: LumaMessageAttachment, world: PhoneWorld) -> Bool {
        (world.relaySupport?.messages ?? []).contains { $0.outgoing && ($0.attachments ?? []).contains(item) } &&
        LumaMessageAttachmentCatalog.shareable(world).contains(item)
    }
}

struct RelaySupportDiagnosticCard: View {
    let report: RelaySupportDiagnostic
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Package report", systemImage: "waveform.path.ecg").font(.headline)
            Text(report.title).font(.subheadline.bold())
            LabeledContent("Installed version", value: report.version)
            LabeledContent("Loader status", value: report.status)
            LabeledContent("Source", value: report.sourceEnabled ? "Enabled" : "Not enabled")
        }.font(.caption).padding(12).lumaSurface(radius: 14)
    }
}

struct RelaySupportAttachmentPreview: View {
    let item: LumaMessageAttachment
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var installed = ""
    private var eligible: Bool {
        RelaySupportAccess.available(installed: installed, flags: world.state.flags) &&
        RelaySupportAttachmentPolicy.canRead(item, world: world.state)
    }
    var body: some View {
        if eligible {
            NavigationLink {
                if eligible {
                    switch item.kind {
                    case .photo:
                        RelaySupportPhotoDetail(item: item)
                    case .document:
                        WorldDocumentReader(id: item.recordID)
                    case .supportGuide:
                        Text("Attachment unavailable")
                    }
                } else { Text("Attachment unavailable") }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    if item.kind == .photo {
                        Image(item.recordID).resizable().scaledToFit().frame(maxHeight: 140).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Label(LumaMessageAttachmentCatalog.title(item, world: world.state) ?? "Attachment",
                          systemImage: item.kind == .photo ? "photo" : "doc.text").font(.caption)
                }.padding(10).lumaSurface(radius: 12)
            }.buttonStyle(.plain)
        } else { Label("Attachment unavailable", systemImage: "lock.doc").font(.caption) }
    }
}
