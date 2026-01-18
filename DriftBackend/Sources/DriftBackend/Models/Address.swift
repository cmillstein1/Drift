import Foundation

/// A physical mailing address.
///
/// Represents a street address with city, state, and country components.
public struct Address: Codable, Sendable {
    /// Primary street address line.
    public let street1: String?
    /// Secondary street address line (apartment, suite, etc.).
    public let street2: String?
    /// City name.
    public let city: String?
    /// Postal/ZIP code.
    public let zipcode: String?
    /// Full country name.
    public let country: String?
    /// ISO country code (e.g., "US").
    public let countryCode: String?
    /// Full state/province name.
    public let state: String?
    /// State/province abbreviation (e.g., "CA").
    public let stateCode: String?
    /// Fully formatted address string.
    public let full: String?

    /// Creates a new address.
    ///
    /// - Parameters:
    ///   - street1: Primary street address line.
    ///   - street2: Secondary street address line.
    ///   - city: City name.
    ///   - zipcode: Postal/ZIP code.
    ///   - country: Full country name.
    ///   - countryCode: ISO country code.
    ///   - state: Full state/province name.
    ///   - stateCode: State/province abbreviation.
    ///   - full: Fully formatted address string.
    public init(
        street1: String? = nil,
        street2: String? = nil,
        city: String? = nil,
        zipcode: String? = nil,
        country: String? = nil,
        countryCode: String? = nil,
        state: String? = nil,
        stateCode: String? = nil,
        full: String? = nil
    ) {
        self.street1 = street1
        self.street2 = street2
        self.city = city
        self.zipcode = zipcode
        self.country = country
        self.countryCode = countryCode
        self.state = state
        self.stateCode = stateCode
        self.full = full
    }
}
