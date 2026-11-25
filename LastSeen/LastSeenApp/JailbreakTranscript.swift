import Foundation

/// Fixed theatrical messages. Never derived from the actual device, its kernel,
/// filesystem, exploit capabilities, identifiers or security state.
enum JailbreakTranscript {
    static let recognition: [String] = [
        "Opening Patchline session",
        "Waiting for device",
        "Connection established",
        "Negotiating service channel",
        "Device handshake complete",
        "Loading device profile",
        "Reading firmware manifest",
        "Checking build compatibility",
        "Recovery channel ready",
        "Session token accepted",
        "Profile checksum verified",
        "Loading compatibility database",
        "Bootstrap type: rootless",
        "Device manifest matched",
        "Transport ready",
        "Handshake complete",
        "Starting diagnostics",
        "Session integrity verified"
    ]
    static let diagnostics: [String] = [
        "Checking kernel profile",
        "Checking compatibility",
        "kfd compatibility: available",
        "Kernel profile accepted",
        "Checking system protection status",
        "Rootless layout verified",
        "Locating backup index",
        "Preserve user data: enabled",
        "Checking package compatibility",
        "Loading compatibility table",
        "Diagnostics initialized",
        "Checking service availability",
        "Kernel configuration accepted",
        "Backup manifest verified",
        "Resource catalog available",
        "Validating package catalog",
        "Owner access policy retained",
        "Diagnostics complete",
        "All checks passed",
        "Diagnostic report: PASS"
    ]
    static let preparation: [String] = [
        "Opening jailbreak session",
        "Loading Patchline modules",
        "kfd module ready",
        "Preparing kernel session",
        "Kernel access: pending",
        "Checking memory profile",
        "Preparing rootless bootstrap",
        "Loading package manifest",
        "Saving recovery checkpoint",
        "Bootstrap manifest verified",
        "Starting install worker",
        "Preparing bootstrap resources",
        "Checking archive entries",
        "Package index verified",
        "Preparing trust cache",
        "Rootless staging ready",
        "Checking service manifest",
        "Recovery checkpoint saved",
        "Ready to install",
        "Environment preparation: OK"
    ]
    static let installation: [String] = [
        "Starting jailbreak",
        "Initializing kernel session",
        "Kernel session active",
        "Kernel access: acquired",
        "Kernel checkpoint verified",
        "Security policy loaded",
        "Trust cache: preparing",
        "Trust cache: registered",
        "Bootstrap: staging",
        "Bootstrap: ready",
        "Verifying bootstrap archive",
        "Unpacking bootstrap archive",
        "Bootstrap manifest verified",
        "Initializing package database",
        "Package database ready",
        "Loading service definitions",
        "Registering userspace services",
        "Preparing tweak loader",
        "Tweak loader registered",
        "Preparing SpringBoard services",
        "SpringBoard services ready",
        "Installing Relay",
        "Loading Relay package index",
        "Local sources registered",
        "Theme catalog available",
        "Refreshing icon cache",
        "Application registry refreshed",
        "Checking backup integrity",
        "User data preserved",
        "Owner records remain locked",
        "Install worker online",
        "Loading service catalog",
        "Kernel profile synchronized",
        "Compatibility check: OK",
        "Kernel session established",
        "Checkpoint saved",
        "Resource table verified",
        "Bootstrap entries verified",
        "Staging worker ready",
        "Archive entries indexed",
        "Resource validation complete",
        "Rootless manifest accepted",
        "Importing package metadata",
        "Package registry synchronized",
        "Repository index verified",
        "Relay registered",
        "Relay resources verified",
        "Tweak preferences initialized",
        "Theme manifest registered",
        "Stock icon set retained",
        "SpringBoard configuration loaded",
        "Launcher resources verified",
        "Services ready",
        "Service queue drained",
        "Backup reference retained",
        "Owner security policy unchanged",
        "Package checksum verified",
        "Bootstrap complete",
        "Restart plan ready",
        "Closing install session",
        "Final integrity check: PASS",
        "Rootless environment ready",
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
