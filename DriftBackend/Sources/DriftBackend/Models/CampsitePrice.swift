import Foundation

/// Pricing information for a campsite.
///
/// Contains the nightly rate and currency details.
public struct CampsitePrice: Codable, Sendable {
    /// Price per night.
    public let perNight: Double?
    /// ISO 4217 currency code (e.g., "USD").
    public let currencyCode: String?
    /// Currency symbol or name (e.g., "$").
    public let currency: String?

    /// Creates a new campsite price.
    ///
    /// - Parameters:
    ///   - perNight: Price per night.
    ///   - currencyCode: ISO 4217 currency code.
    ///   - currency: Currency symbol or name.
    public init(
        perNight: Double? = nil,
        currencyCode: String? = nil,
        currency: String? = nil
    ) {
        self.perNight = perNight
        self.currencyCode = currencyCode
        self.currency = currency
    }
}
