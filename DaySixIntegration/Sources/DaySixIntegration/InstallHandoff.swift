import Foundation

// Installation is never declared successful just because a sign/install request was sent.
public enum InstallationDisposition: Sendable, Equatable {
    case submittedForInstallation
    case installedAndVerified
}

public protocol SigningInstalling: Sendable {
    /// The adapter MUST use a real signing/installation backend and return
    /// `installedAndVerified` only after device-level confirmation.
    func signAndInstall(ipa: URL) async throws -> InstallationDisposition
}

public struct ImportInstallationResult: Sendable, Equatable {
    public let inspection: IPAInspection
    public let disposition: InstallationDisposition
}

public struct DaySixImportService: Sendable {
    private let backend: any SigningInstalling

    public init(backend: any SigningInstalling) { self.backend = backend }

    /// Call from an explicit Sign & Install button AFTER the Files import succeeds.
    /// The caller must copy a security-scoped file into its sandbox before this step.
    public func signAndInstall(ipa: URL) async throws -> ImportInstallationResult {
        let inspection = try IPAInspector.inspect(ipa)
        let disposition = try await backend.signAndInstall(ipa: ipa)
        return ImportInstallationResult(inspection: inspection, disposition: disposition)
    }
}

public struct UnconfiguredSigningBackend: SigningInstalling {
    public init() {}
    public func signAndInstall(ipa: URL) async throws -> InstallationDisposition {
        throw SigningSetupError.backendNotConnected
    }
}

public enum SigningSetupError: Error, LocalizedError {
    case backendNotConnected

    public var errorDescription: String? {
        switch self {
        case .backendNotConnected:
            return "Signing isn't configured. Connect a real on-device signer before installing this IPA."
        }
    }
}