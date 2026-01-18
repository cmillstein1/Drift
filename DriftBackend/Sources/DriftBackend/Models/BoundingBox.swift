import Foundation

/// A geographic bounding box for spatial queries.
///
/// Defines a rectangular area using minimum and maximum coordinates.
public struct BoundingBox: Codable, Sendable {
    /// Southern boundary latitude.
    public let minLatitude: Double
    /// Northern boundary latitude.
    public let maxLatitude: Double
    /// Western boundary longitude.
    public let minLongitude: Double
    /// Eastern boundary longitude.
    public let maxLongitude: Double

    /// Creates a new bounding box.
    ///
    /// - Parameters:
    ///   - minLatitude: Southern boundary latitude.
    ///   - maxLatitude: Northern boundary latitude.
    ///   - minLongitude: Western boundary longitude.
    ///   - maxLongitude: Eastern boundary longitude.
    public init(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }
}
