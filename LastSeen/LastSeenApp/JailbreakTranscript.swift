import Foundation

/// Fixed theatrical messages. Never derived from the actual device, its kernel,
/// filesystem, exploit capabilities, identifiers or security state.
enum JailbreakTranscript {
    static let recognition: [String] = [
        "Patchline session opened",
        "Waiting for virtual transport acknowledgement",
        "Device handshake accepted",
        "Recovery session synchronized",
        "Device profile loaded (fictional)",
        "Rootless environment selected",
        "Virtual firmware manifest recognized",
        "Service channel initialized",
        "Virtual connection state: stable",
        "Recovery session token: ready",
        "Device profile checksum: OK",
        "Local recovery capabilities loaded",
        "Session mode: rootless",
        "Fictional device manifest matched",
        "Transport queue drained",
        "Recovery handshake: complete",
        "Ready for diagnostic pass",
        "Session integrity verified"
    ]
    static let diagnostics: [String] = [
        "Inspecting fictional kernel profile",
        "Checking simulated exploit compatibility",
        "KFD-inspired module: virtual profile available",
        "Kernel diagnostics complete",
        "System protection model loaded",
        "Rootless layout verified",
        "Archived data index located",
        "Preserve user records: enabled",
        "Package compatibility checked",
        "Virtual compatibility table loaded",
        "Diagnostic worker online",
        "Checking simulated service availability",
        "Fictional kernel profile: accepted",
        "Recovery archive metadata: validated",
        "Local resources: accessible",
        "Checking package catalog integrity",
        "Owner access policy: preserved",
        "Diagnostic worker: complete",
        "All virtual checks passed",
        "Diagnostic report: PASS"
    ]
    static let preparation: [String] = [
        "Opening jailbreak session",
        "Loading fictional kernel exploit module",
        "KFD-inspired simulation initialized",
        "Preparing virtual kernel environment",
        "Kernel access simulation: pending",
        "Checking virtual memory model",
        "Preparing rootless bootstrap",
        "Creating local package manifest",
        "Preparing recovery checkpoint",
        "Patchline bootstrap manifest loaded",
        "Virtual worker queue initialized",
        "Preparing local recovery resources",
        "Checking package archive entries",
        "Package index integrity: OK",
        "Preparing simulated trust state",
        "Rootless staging area: ready",
        "Service registration plan: verified",
        "Virtual environment checkpoint saved",
        "Ready for installation",
        "Environment preparation: OK"
    ]
    static let installation: [String] = [
        "Jailbreaking fictional device",
        "Exploiting virtual kernel (simulation)",
        "Kernel simulation active",
        "Virtual kernel access: acquired",
        "Kernel integrity checkpoint: OK",
        "Sandbox state: simulated",
        "Trust cache simulation: pending",
        "Trust cache simulation: OK",
        "Rootless environment: staging",
        "Rootless environment: ready",
        "Bootstrap archive: validating",
        "Bootstrap archive: unpacking",
        "Bootstrap manifest: verified",
        "Package database: initializing",
        "Package database: ready",
        "Loading local service definitions",
        "Userspace services: registered",
        "Tweak loader: staging",
        "Tweak loader: registered",
        "SpringBoard customization: staging",
        "SpringBoard customization: ready",
        "Relay package manager: installing",
        "Relay package index: loaded",
        "Local repositories: available",
        "Afterglow Glass theme: available, not applied",
        "Icon cache: refreshing",
        "Application registrations: refreshed",
        "Checking restored data preservation",
        "Archived records: preserved",
        "Protected owner records: remain locked",
        "Virtual install worker online",
        "Local service map loaded",
        "Fictional kernel profile: synchronized",
        "Simulated compatibility result: OK",
        "Virtual kernel session: established",
        "Kernel model checkpoint saved",
        "Virtual resource table: verified",
        "Local bootstrap entry: validated",
        "Package staging worker ready",
        "Package archive entries indexed",
        "Local resource verification complete",
        "Rootless manifest: accepted",
        "Package metadata: imported",
        "Package registry: synchronized",
        "Local repository catalog: verified",
        "Relay interface: registered",
        "Relay assets: verified",
        "Tweak preferences: initialized",
        "Theme catalog: registered",
        "Original icon theme: retained",
        "SpringBoard scene model: loaded",
        "Launcher resources: verified",
        "Local services: ready",
        "Virtual service queue drained",
        "Recovery archive reference: retained",
        "Owner security policy: unchanged",
        "Package manifest final checksum: OK",
        "Bootstrap status: complete",
        "Virtual restart plan: validated",
        "Patchline session: ready to close",
        "Final integrity check: PASS",
        "Rootless environment: complete",
        "Jailbreak complete",
        "Userspace reboot queued",
        "SpringBoard respring queued"
    ]

    static func prefix(_ lines: [String], seconds: Int, quarter: Int = 0, duration: Int) -> [String] {
        let ticks = max(0, seconds * 4 + min(3, max(0, quarter)))
        let count = max(0, min(lines.count, ticks * lines.count / max(1, duration * 4)))
        return Array(lines.prefix(count))
    }

    static func lines(stage: Int, elapsed: Int, quarter: Int = 0) -> [String] {
        guard stage >= 1 else { return [] }
        let q = stage <= 2 ? quarter : 0
        var result = prefix(recognition, seconds: stage > 1 ? OpeningPace.recognition : elapsed, quarter: stage == 1 ? q : 0, duration: OpeningPace.recognition)
        if stage > 1 || elapsed >= OpeningPace.recognition {
            result += prefix(diagnostics, seconds: stage > 1 ? OpeningPace.diagnostics : elapsed - OpeningPace.recognition, quarter: stage == 1 ? q : 0, duration: OpeningPace.diagnostics)
        }
        if stage >= 2 {
            result += prefix(preparation, seconds: stage > 2 ? OpeningPace.preparation : elapsed, quarter: stage == 2 ? q : 0, duration: OpeningPace.preparation)
            if stage > 2 || elapsed >= OpeningPace.preparation {
                result += prefix(installation, seconds: stage > 2 ? OpeningPace.installation : elapsed - OpeningPace.preparation, quarter: stage == 2 ? q : 0, duration: OpeningPace.installation)
            }
        }
        return result
    }
}
