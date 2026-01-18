import Foundation

/// Metadata about campground data availability and freshness.
///
/// Indicates what types of data are available for this campground.
public struct CampgroundMetadata: Codable, Sendable {
    /// Whether availability alert subscriptions are supported.
    public let hasAvailabilityAlerts: Bool?
    /// Whether real-time availability data is available.
    public let hasAvailabilityData: Bool?
    /// Whether individual campsite details are available.
    public let hasCampsiteLevelData: Bool?
    /// ISO 8601 timestamp of the last data update.
    public let lastUpdated: String?

    /// Creates a new metadata instance.
    ///
    /// - Parameters:
    ///   - hasAvailabilityAlerts: Whether alerts are supported.
    ///   - hasAvailabilityData: Whether availability data exists.
    ///   - hasCampsiteLevelData: Whether campsite-level data exists.
    ///   - lastUpdated: Last update timestamp.
    public init(
        hasAvailabilityAlerts: Bool? = nil,
        hasAvailabilityData: Bool? = nil,
        hasCampsiteLevelData: Bool? = nil,
        lastUpdated: String? = nil
    ) {
        self.hasAvailabilityAlerts = hasAvailabilityAlerts
        self.hasAvailabilityData = hasAvailabilityData
        self.hasCampsiteLevelData = hasCampsiteLevelData
        self.lastUpdated = lastUpdated
    }
}
