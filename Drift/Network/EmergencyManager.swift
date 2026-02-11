//
//  EmergencyManager.swift
//  Drift
//
//  Created for emergency services integration
//

import UIKit
import Foundation

/// Manager for handling emergency service calls
/// Automatically detects country and uses appropriate emergency number
/// 
/// Location Sharing:
/// - iOS automatically shares GPS coordinates with emergency services via HELO (Hybridized Emergency Location)
/// - Uses RapidSOS integration to send precise location (GPS + Wi-Fi + cell tower data) to 911 centers
/// - On iPhone 14+ with no cellular/Wi-Fi, Emergency SOS via Satellite automatically includes:
///   - GPS coordinates (latitude, longitude, elevation)
///   - Medical ID (if set up)
///   - Battery level
///   - Emergency questionnaire answers
/// - No third-party service or additional code needed - iOS handles this natively
@MainActor
class EmergencyManager {
    static let shared = EmergencyManager()
    
    private init() {}
    
    /// Emergency number mapping by country code
    /// Common emergency numbers:
    /// - 911: US, Canada, parts of Central/South America
    /// - 112: EU countries, many others (universal in EU)
    /// - 999: UK, Ireland, some Commonwealth countries
    /// - 000: Australia
    private let emergencyNumbers: [String: String] = [
        "US": "911",
        "CA": "911",
        "GB": "999",
        "IE": "999",
        "AU": "000",
        "NZ": "111",
        "JP": "110",
        "CN": "110",
        "IN": "100",
        "BR": "190",
        "MX": "911",
        "DE": "112",
        "FR": "112",
        "IT": "112",
        "ES": "112",
        "NL": "112",
        "BE": "112",
        "AT": "112",
        "CH": "112",
        "SE": "112",
        "NO": "112",
        "DK": "112",
        "FI": "112",
        "PL": "112",
        "PT": "112",
        "GR": "112",
        "CZ": "112",
        "HU": "112",
        "RO": "112",
        "BG": "112",
        "HR": "112",
        "SK": "112",
        "SI": "112",
        "EE": "112",
        "LV": "112",
        "LT": "112",
        "LU": "112",
        "MT": "112",
        "CY": "112",
        "IS": "112",
        "LI": "112",
        "MC": "112",
        "SM": "112",
        "VA": "112",
        "AD": "112",
        "RU": "112",
        "TR": "112",
        "ZA": "10111",
        "EG": "122",
        "SA": "999",
        "AE": "999",
        "IL": "100",
        "KR": "119",
        "TH": "191",
        "SG": "999",
        "MY": "999",
        "PH": "911",
        "ID": "110",
        "VN": "113",
        "TW": "110",
    ]
    
    /// Get the emergency number for the current country
    /// Falls back to 911 if country not found
    var currentEmergencyNumber: String {
        let countryCode = Locale.current.region?.identifier ?? "US"
        return emergencyNumbers[countryCode] ?? "911"
    }
    
    /// Get the emergency number for a specific country code
    func emergencyNumber(for countryCode: String) -> String {
        return emergencyNumbers[countryCode.uppercased()] ?? "911"
    }
    
    /// Call emergency services
    /// 
    /// Location is automatically shared:
    /// - Regular calls: iOS uses HELO/RapidSOS to automatically send GPS coordinates to emergency services
    /// - Satellite calls (iPhone 14+): Location, elevation, Medical ID, and battery level are automatically included
    /// 
    /// On iPhone 14+ with no cellular/Wi-Fi, iOS automatically uses Emergency SOS via Satellite
    /// - Parameter number: Emergency number to call (defaults to current country's number)
    func callEmergency(number: String? = nil) {
        let emergencyNumber = number ?? currentEmergencyNumber
        
        // Construct the tel URL
        guard let phoneURL = URL(string: "tel://\(emergencyNumber)") else {
            return
        }
        
        // Check if device can make calls
        guard UIApplication.shared.canOpenURL(phoneURL) else {
            // Show alert to user
            return
        }
        
        // Open the phone dialer with emergency number
        // iOS will automatically use satellite if no cellular/Wi-Fi available (iPhone 14+)
        UIApplication.shared.open(phoneURL, options: [:]) { success in
            if success {
            } else {
            }
        }
    }
    
    /// Check if device supports phone calls
    var canMakeCalls: Bool {
        guard let phoneURL = URL(string: "tel://911") else { return false }
        return UIApplication.shared.canOpenURL(phoneURL)
    }
}
