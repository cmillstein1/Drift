import Foundation

/// Available amenities at a campground.
///
/// Tracks the presence of various facilities and services.
public struct CampgroundAmenities: Codable, Sendable {
    /// Whether toilets are available.
    public let toilets: Bool?
    /// Type of toilets (e.g., "flush", "vault").
    public let toiletKind: String?
    /// Whether trash collection is available.
    public let trash: Bool?
    /// Whether a camp store is on-site.
    public let campStore: Bool?
    /// Whether an RV dump station is available.
    public let dumpStation: Bool?
    /// Whether WiFi is available.
    public let wifi: Bool?
    /// Whether pets are allowed.
    public let petsAllowed: Bool?
    /// Whether showers are available.
    public let showers: Bool?
    /// Whether campfires are allowed.
    public let firesAllowed: Bool?
    /// Whether potable water is available.
    public let water: Bool?
    /// Whether electric hookups are available.
    public let electricHookups: Bool?
    /// Whether water hookups are available.
    public let waterHookups: Bool?
    /// Whether sewer hookups are available.
    public let sewerHookups: Bool?

    /// Creates a new amenities instance.
    ///
    /// - Parameters:
    ///   - toilets: Whether toilets are available.
    ///   - toiletKind: Type of toilets.
    ///   - trash: Whether trash collection is available.
    ///   - campStore: Whether a camp store is on-site.
    ///   - dumpStation: Whether an RV dump station is available.
    ///   - wifi: Whether WiFi is available.
    ///   - petsAllowed: Whether pets are allowed.
    ///   - showers: Whether showers are available.
    ///   - firesAllowed: Whether campfires are allowed.
    ///   - water: Whether potable water is available.
    ///   - electricHookups: Whether electric hookups are available.
    ///   - waterHookups: Whether water hookups are available.
    ///   - sewerHookups: Whether sewer hookups are available.
    public init(
        toilets: Bool? = nil,
        toiletKind: String? = nil,
        trash: Bool? = nil,
        campStore: Bool? = nil,
        dumpStation: Bool? = nil,
        wifi: Bool? = nil,
        petsAllowed: Bool? = nil,
        showers: Bool? = nil,
        firesAllowed: Bool? = nil,
        water: Bool? = nil,
        electricHookups: Bool? = nil,
        waterHookups: Bool? = nil,
        sewerHookups: Bool? = nil
    ) {
        self.toilets = toilets
        self.toiletKind = toiletKind
        self.trash = trash
        self.campStore = campStore
        self.dumpStation = dumpStation
        self.wifi = wifi
        self.petsAllowed = petsAllowed
        self.showers = showers
        self.firesAllowed = firesAllowed
        self.water = water
        self.electricHookups = electricHookups
        self.waterHookups = waterHookups
        self.sewerHookups = sewerHookups
    }
}
