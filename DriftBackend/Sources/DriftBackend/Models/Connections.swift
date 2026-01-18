import Foundation

/// External system identifiers for a campground.
///
/// Maps the campground to identifiers in other databases and reservation systems.
public struct Connections: Codable, Sendable {
    /// Recreation Information Database (RIDB) facility identifier.
    public let ridbFacilityId: String?
    /// US Forest Service site identifier.
    public let usfsSiteId: String?
    /// Legacy Campflare v1 API campground identifiers.
    public let v1CampgroundIds: [String]?

    /// Creates a new connections instance.
    ///
    /// - Parameters:
    ///   - ridbFacilityId: RIDB facility identifier.
    ///   - usfsSiteId: USFS site identifier.
    ///   - v1CampgroundIds: Legacy v1 campground identifiers.
    public init(
        ridbFacilityId: String? = nil,
        usfsSiteId: String? = nil,
        v1CampgroundIds: [String]? = nil
    ) {
        self.ridbFacilityId = ridbFacilityId
        self.usfsSiteId = usfsSiteId
        self.v1CampgroundIds = v1CampgroundIds
    }
}
