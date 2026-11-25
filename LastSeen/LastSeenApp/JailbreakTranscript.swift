import Foundation

/// Fixed theatrical messages. Never derived from the actual device, its kernel,
/// filesystem, exploit capabilities, identifiers or security state.
enum JailbreakTranscript {
    static let recognition: [String] = [
        "Patchline session opened", "Waiting for virtual transport acknowledgement",
        "Device handshake accepted", "Recovery session synchronized",
        "Device profile loaded (fictional)", "Rootless environment selected",
        "Virtual firmware manifest recognized", "Session integrity verified"
    ]
    static let diagnostics: [String] = [
        "Inspecting fictional kernel profile", "Checking simulated exploit compatibility",
        "KFD-inspired module: virtual profile available", "Kernel diagnostics complete",
        "System protection model loaded", "Rootless layout verified",
        "Archived data index located", "Preserve user records: enabled",
        "Package compatibility checked", "Diagnostic report: PASS"
    ]
    static let preparation: [String] = [
        "Opening jailbreak session", "Loading fictional kernel exploit module",
        "KFD-inspired simulation initialized", "Preparing virtual kernel environment",
        "Kernel access simulation: pending", "Checking virtual memory model",
        "Preparing rootless bootstrap", "Creating local package manifest",
        "Preparing recovery checkpoint", "Environment preparation: OK"
    ]
    static let installation: [String] = [
        "Jailbreaking fictional device", "Exploiting virtual kernel (simulation)",
        "Kernel simulation active", "Virtual kernel access: acquired",
        "Kernel integrity checkpoint: OK", "Sandbox state: simulated",
        "Trust cache simulation: pending", "Trust cache simulation: OK",
        "Rootless environment: staging", "Rootless environment: ready",
        "Bootstrap archive: validating", "Bootstrap archive: unpacking",
        "Bootstrap manifest: verified", "Package database: initializing",
        "Package database: ready", "Loading local service definitions",
        "Userspace services: registered", "Tweak loader: staging",
        "Tweak loader: registered", "SpringBoard customization: staging",
        "SpringBoard customization: ready", "Relay package manager: installing",
        "Relay package index: loaded", "Local repositories: available",
        "Afterglow Glass theme: available, not applied",
        "Icon cache: refreshing", "Application registrations: refreshed",
        "Checking restored data preservation", "Archived records: preserved",
        "Protected owner records: remain locked", "Final integrity check: PASS",
        "Rootless environment: complete", "Jailbreak complete",
        "Userspace reboot queued", "SpringBoard respring queued"
    ]

    static func prefix(_ lines: [String], seconds: Int, duration: Int) -> [String] {
        let count = max(0, min(lines.count, max(0, seconds) * lines.count / max(1, duration)))
        return Array(lines.prefix(count))
    }

    static func lines(stage: Int, elapsed: Int) -> [String] {
        guard stage >= 1 else { return [] }
        var result = prefix(recognition, seconds: stage > 1 ? 10 : elapsed, duration: 10)
        result += prefix(diagnostics, seconds: stage > 1 ? 15 : elapsed - 10, duration: 15)
        if stage >= 2 {
            result += prefix(preparation, seconds: stage > 2 ? 20 : elapsed, duration: 20)
            result += prefix(installation, seconds: stage > 2 ? 65 : elapsed - 20, duration: 65)
        }
        return result
    }
}
