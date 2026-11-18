import Foundation

/// User-confirmed prerequisites for on-device self-renewal.
/// These are user attestations, not access to SideStore's private data.
///
/// Stock iOS does not permit reading SideStore's managed app database,
/// Apple authentication state, or VPN pairing state across sandboxes.
enum SigningReadiness {
    static let managedKey = "daysix.readiness.enrolledInSideStore.v1"
    static let refreshTestedKey = "daysix.readiness.sideStoreRefreshTested.v1"

    static var userConfirmedEnrollment: Bool {
        get { UserDefaults.standard.bool(forKey: managedKey) }
        set { UserDefaults.standard.set(newValue, forKey: managedKey) }
    }

    static var userConfirmedRefreshTest: Bool {
        get { UserDefaults.standard.bool(forKey: refreshTestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshTestedKey) }
    }

    /// This deliberately does not claim a verified working signing engine.
    static var userReportedReady: Bool {
        userConfirmedEnrollment && userConfirmedRefreshTest
    }
}
