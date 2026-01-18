import Foundation

/// Response from a campground search query.
///
/// Contains the matching campgrounds and pagination information.
public struct CampgroundSearchResponse: Codable, Sendable {
    /// List of campgrounds matching the search criteria.
    public let campgrounds: [Campground]
    /// Total number of matching campgrounds.
    public let total: Int?
    /// Maximum results per page.
    public let limit: Int?
    /// Number of results skipped.
    public let offset: Int?

    /// Creates a new search response.
    ///
    /// - Parameters:
    ///   - campgrounds: Matching campgrounds.
    ///   - total: Total matches.
    ///   - limit: Results per page.
    ///   - offset: Results skipped.
    public init(
        campgrounds: [Campground],
        total: Int? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.campgrounds = campgrounds
        self.total = total
        self.limit = limit
        self.offset = offset
    }
}
