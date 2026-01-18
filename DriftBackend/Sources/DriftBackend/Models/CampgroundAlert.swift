import Foundation

/// An alert or warning for a campground.
///
/// Represents important notices such as closures, hazards, or special conditions.
public struct CampgroundAlert: Codable, Sendable {
    /// Title of the alert.
    public let title: String
    /// Detailed content of the alert.
    public let content: String
    /// Name of the information source.
    public let sourceName: String?
    /// URL to the original alert source.
    public let sourceUrl: String?
    /// Date when the alert becomes active (ISO 8601 format).
    public let startDate: String?
    /// Date when the alert expires (ISO 8601 format).
    public let endDate: String?

    /// Creates a new campground alert.
    ///
    /// - Parameters:
    ///   - title: Title of the alert.
    ///   - content: Detailed content.
    ///   - sourceName: Name of the information source.
    ///   - sourceUrl: URL to the original source.
    ///   - startDate: Alert start date.
    ///   - endDate: Alert end date.
    public init(
        title: String,
        content: String,
        sourceName: String? = nil,
        sourceUrl: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil
    ) {
        self.title = title
        self.content = content
        self.sourceName = sourceName
        self.sourceUrl = sourceUrl
        self.startDate = startDate
        self.endDate = endDate
    }
}
