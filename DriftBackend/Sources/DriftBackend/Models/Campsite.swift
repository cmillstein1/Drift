import Foundation

/// An individual campsite within a campground.
///
/// Contains details about a specific site including location, amenities,
/// equipment restrictions, and pricing.
public struct Campsite: Codable, Identifiable, Sendable {
    /// Unique identifier for the campsite.
    public let id: String
    /// Identifier of the parent campground.
    public let campgroundId: String
    /// Display name or number of the site.
    public let name: String
    /// Type of site (e.g., "standard", "group", "rv").
    public let kind: String
    /// Name of the loop or section containing this site.
    public let loopName: String?
    /// Latitude coordinate of the site.
    public let latitude: Double?
    /// Longitude coordinate of the site.
    public let longitude: Double?
    /// URL for making reservations for this specific site.
    public let reservationUrl: String?
    /// List of equipment types allowed at this site.
    public let equipment: [CampsiteEquipment]?
    /// Site type as listed by the reservation system.
    public let kindListed: String?
    /// Check-in/check-out schedule for this site.
    public let schedule: CampsiteSchedule?
    /// Pricing information for this site.
    public let price: CampsitePrice?
    /// Whether the site has a fire pit.
    public let firepit: Bool?
    /// Whether the site has a picnic table.
    public let picnicTable: Bool?
    /// Whether the site is ADA accessible.
    public let adaAccessible: Bool?
    /// Whether water hookups are available.
    public let waterHookups: Bool?
    /// Whether electric hookups are available.
    public let electricHookups: Bool?
    /// Whether sewer hookups are available.
    public let sewerHookups: Bool?
    /// Maximum number of people allowed.
    public let maxPeople: Int?
    /// Maximum number of vehicles allowed.
    public let maxCars: Int?
    /// Whether the site is a pull-through site.
    public let pullThrough: Bool?
    /// Length of the driveway in feet.
    public let drivewayLength: Int?
    /// Maximum RV length in feet.
    public let maxRvLength: Int?
    /// Maximum trailer length in feet.
    public let maxTrailerLength: Double?
    /// Photos of this campsite.
    public let photos: [CampgroundPhoto]?

    /// Creates a new campsite instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - campgroundId: Parent campground identifier.
    ///   - name: Site name or number.
    ///   - kind: Type of site.
    ///   - loopName: Loop or section name.
    ///   - latitude: Latitude coordinate.
    ///   - longitude: Longitude coordinate.
    ///   - reservationUrl: Reservation URL.
    ///   - equipment: Allowed equipment types.
    ///   - kindListed: Listed site type.
    ///   - schedule: Check-in/check-out schedule.
    ///   - price: Pricing information.
    ///   - firepit: Whether a fire pit exists.
    ///   - picnicTable: Whether a picnic table exists.
    ///   - adaAccessible: Whether ADA accessible.
    ///   - waterHookups: Whether water hookups exist.
    ///   - electricHookups: Whether electric hookups exist.
    ///   - sewerHookups: Whether sewer hookups exist.
    ///   - maxPeople: Maximum occupancy.
    ///   - maxCars: Maximum vehicles.
    ///   - pullThrough: Whether pull-through.
    ///   - drivewayLength: Driveway length in feet.
    ///   - maxRvLength: Maximum RV length in feet.
    ///   - maxTrailerLength: Maximum trailer length in feet.
    ///   - photos: Site photos.
    public init(
        id: String,
        campgroundId: String,
        name: String,
        kind: String,
        loopName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        reservationUrl: String? = nil,
        equipment: [CampsiteEquipment]? = nil,
        kindListed: String? = nil,
        schedule: CampsiteSchedule? = nil,
        price: CampsitePrice? = nil,
        firepit: Bool? = nil,
        picnicTable: Bool? = nil,
        adaAccessible: Bool? = nil,
        waterHookups: Bool? = nil,
        electricHookups: Bool? = nil,
        sewerHookups: Bool? = nil,
        maxPeople: Int? = nil,
        maxCars: Int? = nil,
        pullThrough: Bool? = nil,
        drivewayLength: Int? = nil,
        maxRvLength: Int? = nil,
        maxTrailerLength: Double? = nil,
        photos: [CampgroundPhoto]? = nil
    ) {
        self.id = id
        self.campgroundId = campgroundId
        self.name = name
        self.kind = kind
        self.loopName = loopName
        self.latitude = latitude
        self.longitude = longitude
        self.reservationUrl = reservationUrl
        self.equipment = equipment
        self.kindListed = kindListed
        self.schedule = schedule
        self.price = price
        self.firepit = firepit
        self.picnicTable = picnicTable
        self.adaAccessible = adaAccessible
        self.waterHookups = waterHookups
        self.electricHookups = electricHookups
        self.sewerHookups = sewerHookups
        self.maxPeople = maxPeople
        self.maxCars = maxCars
        self.pullThrough = pullThrough
        self.drivewayLength = drivewayLength
        self.maxRvLength = maxRvLength
        self.maxTrailerLength = maxTrailerLength
        self.photos = photos
    }
}
