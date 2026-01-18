import Foundation

/// Pricing information for a campground.
///
/// Contains the price range and currency details.
public struct CampgroundPrice: Codable, Sendable {
    /// Minimum nightly price.
    public let minimum: Double?
    /// Maximum nightly price.
    public let maximum: Double?
    /// ISO 4217 currency code (e.g., "USD").
    public let currencyCode: String?
    /// Currency symbol or name (e.g., "$").
    public let currency: String?

    /// Creates a new campground price.
    ///
    /// - Parameters:
    ///   - minimum: Minimum nightly price.
    ///   - maximum: Maximum nightly price.
    ///   - currencyCode: ISO 4217 currency code.
    ///   - currency: Currency symbol or name.
    public init(
        minimum: Double? = nil,
        maximum: Double? = nil,
        currencyCode: String? = nil,
        currency: String? = nil
    ) {
        self.minimum = minimum
        self.maximum = maximum
        self.currencyCode = currencyCode
        self.currency = currency
    }
}
