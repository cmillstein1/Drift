import Foundation

/// A campground location with amenities, pricing, and availability information.
///
/// Use this type to represent campground data from the Campflare API.
/// Campgrounds contain location details, amenities, photos, and metadata
/// about reservation availability.
public struct Campground: Codable, Identifiable, Sendable {
    /// Unique identifier for the campground.
    public let id: String
    /// Display name of the campground.
    public let name: String
    /// Current operational status (e.g., "open", "closed").
    public let status: String
    /// Human-readable description of the status.
    public let statusDescription: String?
    /// Type of campground (e.g., "campground", "rv_park").
    public let kind: String?
    /// Brief description of the campground.
    public let shortDescription: String?
    /// Medium-length description with more details.
    public let mediumDescription: String?
    /// Full detailed description of the campground.
    public let longDescription: String?
    /// Geographic location and address information.
    public let location: CampgroundLocation
    /// Default check-in/check-out schedule.
    public let defaultCampsiteSchedule: CampsiteSchedule?
    /// Available amenities at this campground.
    public let amenities: CampgroundAmenities?
    /// Maximum RV length in feet that can be accommodated.
    public let maxRvLength: Double?
    /// Maximum trailer length in feet that can be accommodated.
    public let maxTrailerLength: Double?
    /// Whether the campground has pull-through sites.
    public let hasPullThroughSites: Bool?
    /// Whether the campground can accommodate large RVs.
    public let bigRigFriendly: Bool?
    /// URL for making reservations.
    public let reservationUrl: String?
    /// External links related to the campground.
    public let links: [CampgroundLink]?
    /// Photos of the campground.
    public let photos: [CampgroundPhoto]?
    /// Active alerts or warnings for the campground.
    public let alerts: [CampgroundAlert]?
    /// Pricing information.
    public let price: CampgroundPrice?
    /// Cell service quality by carrier.
    public let cellService: CellService?
    /// Managing agency information.
    public let management: Management?
    /// Contact information for the campground.
    public let contact: Contact?
    /// External system identifiers.
    public let connections: Connections?
    /// Metadata about data availability and freshness.
    public let metadata: CampgroundMetadata?

    /// Creates a new campground instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the campground.
    ///   - name: Display name of the campground.
    ///   - status: Current operational status.
    ///   - statusDescription: Human-readable status description.
    ///   - kind: Type of campground.
    ///   - shortDescription: Brief description.
    ///   - mediumDescription: Medium-length description.
    ///   - longDescription: Full detailed description.
    ///   - location: Geographic location and address.
    ///   - defaultCampsiteSchedule: Default check-in/check-out times.
    ///   - amenities: Available amenities.
    ///   - maxRvLength: Maximum RV length in feet.
    ///   - maxTrailerLength: Maximum trailer length in feet.
    ///   - hasPullThroughSites: Whether pull-through sites exist.
    ///   - bigRigFriendly: Whether large RVs can be accommodated.
    ///   - reservationUrl: URL for reservations.
    ///   - links: External links.
    ///   - photos: Campground photos.
    ///   - alerts: Active alerts.
    ///   - price: Pricing information.
    ///   - cellService: Cell service quality.
    ///   - management: Managing agency.
    ///   - contact: Contact information.
    ///   - connections: External system identifiers.
    ///   - metadata: Data availability metadata.
    public init(
        id: String,
        name: String,
        status: String,
        statusDescription: String? = nil,
        kind: String? = nil,
        shortDescription: String? = nil,
        mediumDescription: String? = nil,
        longDescription: String? = nil,
        location: CampgroundLocation,
        defaultCampsiteSchedule: CampsiteSchedule? = nil,
        amenities: CampgroundAmenities? = nil,
        maxRvLength: Double? = nil,
        maxTrailerLength: Double? = nil,
        hasPullThroughSites: Bool? = nil,
        bigRigFriendly: Bool? = nil,
        reservationUrl: String? = nil,
        links: [CampgroundLink]? = nil,
        photos: [CampgroundPhoto]? = nil,
        alerts: [CampgroundAlert]? = nil,
        price: CampgroundPrice? = nil,
        cellService: CellService? = nil,
        management: Management? = nil,
        contact: Contact? = nil,
        connections: Connections? = nil,
        metadata: CampgroundMetadata? = nil
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.statusDescription = statusDescription
        self.kind = kind
        self.shortDescription = shortDescription
        self.mediumDescription = mediumDescription
        self.longDescription = longDescription
        self.location = location
        self.defaultCampsiteSchedule = defaultCampsiteSchedule
        self.amenities = amenities
        self.maxRvLength = maxRvLength
        self.maxTrailerLength = maxTrailerLength
        self.hasPullThroughSites = hasPullThroughSites
        self.bigRigFriendly = bigRigFriendly
        self.reservationUrl = reservationUrl
        self.links = links
        self.photos = photos
        self.alerts = alerts
        self.price = price
        self.cellService = cellService
        self.management = management
        self.contact = contact
        self.connections = connections
        self.metadata = metadata
    }
}
