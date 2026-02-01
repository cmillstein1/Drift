//
//  DiscoveryLocationProvider.swift
//  Drift
//
//  Provides the user's current device location for distance filtering in Discover (dating)
//  and Nearby Friends. Uses location services when enabled; falls back to profile's stored
//  coordinates when permission is denied or location unavailable.
//

import Foundation
import CoreLocation
import Combine

final class DiscoveryLocationProvider: NSObject, ObservableObject {
    static let shared = DiscoveryLocationProvider()

    /// Last known device location; nil if permission denied or not yet received.
    /// Updated on main thread so SwiftUI observes changes.
    @Published private(set) var lastCoordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 500 // meters – avoid constant updates
    }

    /// Request a fresh location update for distance filtering. Call when user opens Discover or Friends.
    /// If already authorized, triggers a one-shot update; otherwise requests permission.
    func requestLocation() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    /// Latitude for distance filter; nil if device location unavailable.
    var latitudeForFilter: Double? { lastCoordinate?.latitude }

    /// Longitude for distance filter; nil if device location unavailable.
    var longitudeForFilter: Double? { lastCoordinate?.longitude }
}

extension DiscoveryLocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            DispatchQueue.main.async {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coord = location.coordinate
        DispatchQueue.main.async { [weak self] in
            self?.lastCoordinate = coord
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Leave lastCoordinate unchanged; callers fall back to profile coords
    }
}
