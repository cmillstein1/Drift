import Foundation

/// Campground availability for a specific date.
///
/// Indicates whether any campsites are available and which ones.
public struct Availability: Codable, Sendable {
    /// Date in ISO 8601 format (YYYY-MM-DD).
    public let date: String
    /// Whether any campsites are available on this date.
    public let available: Bool
    /// List of available campsite identifiers.
    public let availableCampsites: [String]?

    /// Creates a new availability instance.
    ///
    /// - Parameters:
    ///   - date: Date in ISO 8601 format.
    ///   - available: Whether sites are available.
    ///   - availableCampsites: List of available site identifiers.
    public init(
        date: String,
        available: Bool,
        availableCampsites: [String]? = nil
    ) {
        self.date = date
        self.available = available
        self.availableCampsites = availableCampsites
    }
}
