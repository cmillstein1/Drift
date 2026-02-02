//
//  DistanceHelper.swift
//  Drift
//
//  Haversine distance in miles for discover cards.
//

import Foundation

enum DistanceHelper {
    /// Distance in miles between two points. Returns nil if any coordinate is missing.
    static func miles(
        from userLat: Double?, _ userLon: Double?,
        to profileLat: Double?, _ profileLon: Double?
    ) -> Int? {
        guard let lat1 = userLat, let lon1 = userLon,
              let lat2 = profileLat, let lon2 = profileLon else { return nil }
        let R = 3959.0 // Earth radius in miles
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return Int(round(R * c))
    }
}
