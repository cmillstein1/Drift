import Foundation

/// Managing agency information for a campground.
///
/// Contains details about the government or private entity that operates the campground.
public struct Management: Codable, Sendable {
    /// Name of the managing agency (e.g., "USDA Forest Service").
    public let agencyName: String?
    /// Unique identifier for the agency.
    public let agencyId: String?
    /// Agency's official website URL.
    public let agencyWebsite: String?

    /// Creates a new management instance.
    ///
    /// - Parameters:
    ///   - agencyName: Name of the managing agency.
    ///   - agencyId: Unique identifier for the agency.
    ///   - agencyWebsite: Agency's website URL.
    public init(
        agencyName: String? = nil,
        agencyId: String? = nil,
        agencyWebsite: String? = nil
    ) {
        self.agencyName = agencyName
        self.agencyId = agencyId
        self.agencyWebsite = agencyWebsite
    }
}
