import Foundation

/// Request parameters for searching campgrounds.
///
/// Use this to filter campgrounds by location, amenities, and other criteria.
public struct CampgroundSearchRequest: Codable, Sendable {
    /// Text query to search campground names and descriptions.
    public let query: String?
    /// Maximum number of results to return.
    public let limit: Int?
    /// Filter by required amenities (e.g., ["showers", "wifi"]).
    public let amenities: [String]?
    /// Minimum RV length accommodation required in feet.
    public let minimumRvLength: Double?
    /// Minimum trailer length accommodation required in feet.
    public let minimumTrailerLength: Double?
    /// Filter for campgrounds that accommodate large RVs.
    public let bigRigFriendly: Bool?
    /// Filter by cell service carriers (e.g., ["verizon", "att"]).
    public let cellService: [String]?
    /// Filter by operational status (e.g., "open").
    public let status: String?
    /// Filter by campground type.
    public let kind: String?
    /// Filter by available campsite types.
    public let campsiteKinds: [String]?
    /// Geographic bounding box to search within.
    public let bbox: BoundingBox?
    /// Legacy v1 campground identifier for lookup.
    public let v1CampgroundId: String?

    /// Creates a new search request.
    ///
    /// - Parameters:
    ///   - query: Text search query.
    ///   - limit: Maximum results.
    ///   - amenities: Required amenities.
    ///   - minimumRvLength: Minimum RV length in feet.
    ///   - minimumTrailerLength: Minimum trailer length in feet.
    ///   - bigRigFriendly: Require big rig accommodation.
    ///   - cellService: Required cell carriers.
    ///   - status: Operational status filter.
    ///   - kind: Campground type filter.
    ///   - campsiteKinds: Campsite type filters.
    ///   - bbox: Geographic bounding box.
    ///   - v1CampgroundId: Legacy identifier.
    public init(
        query: String? = nil,
        limit: Int? = nil,
        amenities: [String]? = nil,
        minimumRvLength: Double? = nil,
        minimumTrailerLength: Double? = nil,
        bigRigFriendly: Bool? = nil,
        cellService: [String]? = nil,
        status: String? = nil,
        kind: String? = nil,
        campsiteKinds: [String]? = nil,
        bbox: BoundingBox? = nil,
        v1CampgroundId: String? = nil
    ) {
        self.query = query
        self.limit = limit
        self.amenities = amenities
        self.minimumRvLength = minimumRvLength
        self.minimumTrailerLength = minimumTrailerLength
        self.bigRigFriendly = bigRigFriendly
        self.cellService = cellService
        self.status = status
        self.kind = kind
        self.campsiteKinds = campsiteKinds
        self.bbox = bbox
        self.v1CampgroundId = v1CampgroundId
    }
}
