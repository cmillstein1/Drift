import Foundation

/// Check-in and check-out schedule for a campsite.
///
/// Defines the standard times for guest arrival and departure.
public struct CampsiteSchedule: Codable, Sendable {
    /// Standard check-in time (e.g., "14:00").
    public let checkInTime: String?
    /// Standard check-out time (e.g., "11:00").
    public let checkOutTime: String?
    /// Whether the schedule is uniform across all sites.
    public let uniform: Bool?

    /// Creates a new campsite schedule.
    ///
    /// - Parameters:
    ///   - checkInTime: Standard check-in time.
    ///   - checkOutTime: Standard check-out time.
    ///   - uniform: Whether the schedule applies uniformly.
    public init(
        checkInTime: String? = nil,
        checkOutTime: String? = nil,
        uniform: Bool? = nil
    ) {
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.uniform = uniform
    }
}
