import Foundation

/// Cell phone service quality ratings by carrier.
///
/// Signal strength values range from 0 (no signal) to 1 (excellent signal).
public struct CellService: Codable, Sendable {
    /// Verizon signal strength (0-1 scale).
    public let verizon: Double?
    /// T-Mobile signal strength (0-1 scale).
    public let tmobile: Double?
    /// AT&T signal strength (0-1 scale).
    public let att: Double?
    /// US Cellular signal strength (0-1 scale).
    public let uscell: Double?

    /// Creates a new cell service rating.
    ///
    /// - Parameters:
    ///   - verizon: Verizon signal strength.
    ///   - tmobile: T-Mobile signal strength.
    ///   - att: AT&T signal strength.
    ///   - uscell: US Cellular signal strength.
    public init(
        verizon: Double? = nil,
        tmobile: Double? = nil,
        att: Double? = nil,
        uscell: Double? = nil
    ) {
        self.verizon = verizon
        self.tmobile = tmobile
        self.att = att
        self.uscell = uscell
    }
}
