import SwiftUI
import UniformTypeIdentifiers
import DaySixIntegration

/// Drop-in component for the existing DaySix dashboard.
/// The caller must inject a real SideStore-derived SigningInstalling implementation.
/// It intentionally never treats a Files import or a Share Sheet as an install.
@MainActor
struct DaySixImportPanel: View {
    let service: DaySixImportService

    @State private var isSelectingIPA = false
    @State private var stagedIPA: URL?
    @State private var selectedFileName: String?
    @State private var isInstalling = false
    @State private var status: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                isSelectingIPA = true
            } label: {
                Label("Import IPA", systemImage: "square.and.arrow.down.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isInstalling)

            if let stagedIPA {
                VStack(alignment: .leading, spacing: 9) {
                    Text(selectedFileName ?? stagedIPA.lastPathComponent)
                        .font(.headline)
                        .lineLimit(2)
                    Text("Ready to sign and install")
                        .foregroundStyle(.secondary)
                    Button {
                        startInstall(stagedIPA)
                    } label: {
                        Label("Sign & Install", systemImage: "checkmark.shield.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
            }

            if isInstalling { ProgressView("Signing and installing…") }
            if let status {
                Label(status, systemImage: "info.circle.fill")
                    .font(.subheadline)
            }
        }
        .fileImporter(
            isPresented: $isSelectingIPA,
            allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .data]
        ) { result in
            do {
                let selected = try result.get()
                stagedIPA = try copySecurityScopedImport(selected)
                selectedFileName = selected.lastPathComponent
                status = nil
            } catch {
                // The file picker can be cancelled without producing an error alert.
                let nsError = error as NSError
                if nsError.code != NSUserCancelledError { errorMessage = error.localizedDescription }
            }
        }
        .alert("DaySix", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func copySecurityScopedImport(_ source: URL) throws -> URL {
        let isScoped = source.startAccessingSecurityScopedResource()
        defer { if isScoped { source.stopAccessingSecurityScopedResource() } }
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImportedIPAs", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        // Unique destination prevents overwriting older IPAs or clobbering app data.
        let destination = folder.appendingPathComponent(UUID().uuidString + ".ipa")
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private func startInstall(_ ipa: URL) {
        guard !isInstalling else { return }
        isInstalling = true
        status = nil
        Task {
            defer { isInstalling = false }
            do {
                let result = try await service.signAndInstall(ipa: ipa)
                switch result.disposition {
                case .submittedForInstallation:
                    status = "Install request submitted. Check the iPhone installation prompt."
                case .installedAndVerified:
                    status = "Installation verified on this iPhone."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}