import Foundation

/// Geographic location information for a campground.
///
/// Contains coordinates, elevation, address details, and driving directions.
public struct CampgroundLocation: Codable, Sendable {
    /// Latitude coordinate in degrees.
    public let latitude: Double
    /// Longitude coordinate in degrees.
    public let longitude: Double
    /// Elevation above sea level in feet.
    public let elevation: Double?
    /// Physical address of the campground.
    public let address: Address?
    /// Driving directions to reach the campground.
    public let directions: String?

    /// Creates a new campground location.
    ///
    /// - Parameters:
    ///   - latitude: Latitude coordinate in degrees.
    ///   - longitude: Longitude coordinate in degrees.
    ///   - elevation: Elevation above sea level in feet.
    ///   - address: Physical address.
    ///   - directions: Driving directions.
    public init(
        latitude: Double,
        longitude: Double,
        elevation: Double? = nil,
        address: Address? = nil,
        directions: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.address = address
        self.directions = directions
    }
}
