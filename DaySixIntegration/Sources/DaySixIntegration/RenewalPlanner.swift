import Foundation

public struct RenewalPlan: Sendable, Equatable {
    public let issuedAt: Date
    public let expiresAt: Date
    public let firstAttemptAt: Date

    public func shouldAttempt(at now: Date) -> Bool {
        now >= firstAttemptAt && now < expiresAt
    }
    public func isExpired(at now: Date) -> Bool { now >= expiresAt }
}

public enum RenewalPlanningError: Error {
    case invalidValidityPeriod
}

public enum RenewalPlanner {
    /// Day six from signing, or at least one day before an earlier profile expiry.
    /// The provided expiry MUST be read from actual app provisioning data, not assumed.
    public static func plan(issuedAt: Date, expiresAt: Date) throws -> RenewalPlan {
        guard expiresAt > issuedAt else { throw RenewalPlanningError.invalidValidityPeriod }
        let sixDays = issuedAt.addingTimeInterval(6 * 24 * 3600)
        let oneDayBeforeExpiry = expiresAt.addingTimeInterval(-24 * 3600)
        return RenewalPlan(issuedAt: issuedAt, expiresAt: expiresAt,
                           firstAttemptAt: min(sixDays, max(issuedAt, oneDayBeforeExpiry)))
    }
}