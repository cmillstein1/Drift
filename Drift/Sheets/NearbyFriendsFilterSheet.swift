//
//  NearbyFriendsFilterSheet.swift
//  Drift
//
//  Filter sheet for Nearby Friends: discovery range.
//

import SwiftUI
import CoreLocation
import DriftBackend

// MARK: - Reference Coordinate

/// A simple lat/lon pair used as a reference point for distance filtering.
struct ReferenceCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Filter Preferences

struct NearbyFriendsFilterPreferences: Equatable, Codable {
    var maxDistanceMiles: Int
    var alongMyRoute: Bool

    static let `default` = NearbyFriendsFilterPreferences(
        maxDistanceMiles: 50,
        alongMyRoute: true
    )

    /// 200 = slider max = no distance limit.
    var isUnlimitedDistance: Bool { maxDistanceMiles >= 200 }

    var hasActiveFilters: Bool {
        maxDistanceMiles != 50 || !alongMyRoute
    }

    /// Returns whether a profile passes the distance filter.
    /// When `alongMyRoute` is true, the profile passes if it's within range of the current location
    /// OR any of the supplied route coordinates (same logic as event filtering).
    /// `geocodedCoords` provides fallback coordinates for profiles whose location string was geocoded.
    func matches(
        _ profile: UserProfile,
        currentUserLat: Double?,
        currentUserLon: Double?,
        routeCoordinates: [ReferenceCoordinate] = [],
        geocodedCoords: [UUID: CLLocationCoordinate2D] = [:]
    ) -> Bool {
        // Slider at max = no distance limit
        if isUnlimitedDistance { return true }

        // Build list of reference points
        var referencePoints: [ReferenceCoordinate] = []
        if let ulat = currentUserLat, let ulon = currentUserLon {
            referencePoints.append(ReferenceCoordinate(latitude: ulat, longitude: ulon))
        }
        if alongMyRoute {
            referencePoints.append(contentsOf: routeCoordinates)
        }

        // No reference points at all — skip distance filtering
        guard !referencePoints.isEmpty else { return true }

        // Use stored coordinates, or fall back to geocoded location string
        // Treat sentinel values (-999) and out-of-range coords as missing
        let plat: Double
        let plon: Double
        if let lat = profile.latitude, let lon = profile.longitude,
           abs(lat) <= 90, abs(lon) <= 180 {
            plat = lat
            plon = lon
        } else if let geocoded = geocodedCoords[profile.id] {
            plat = geocoded.latitude
            plon = geocoded.longitude
        } else {
            // No coordinates and no geocoded fallback — can't verify distance, exclude
            return false
        }

        // Pass if within range of ANY reference point
        return referencePoints.contains { ref in
            let miles = Self.haversineMiles(lat1: ref.latitude, lon1: ref.longitude, lat2: plat, lon2: plon)
            return miles <= Double(maxDistanceMiles)
        }
    }

    /// Returns whether an event passes the distance filter.
    /// Events without coordinates are shown (can't verify distance, don't hide them).
    func matchesEvent(
        _ event: CommunityPost,
        currentUserLat: Double?,
        currentUserLon: Double?,
        routeCoordinates: [ReferenceCoordinate] = []
    ) -> Bool {
        // Slider at max = no distance limit
        if isUnlimitedDistance { return true }

        // Build list of reference points
        var referencePoints: [ReferenceCoordinate] = []
        if let ulat = currentUserLat, let ulon = currentUserLon {
            referencePoints.append(ReferenceCoordinate(latitude: ulat, longitude: ulon))
        }
        if alongMyRoute {
            referencePoints.append(contentsOf: routeCoordinates)
        }

        // No reference points — skip distance filtering
        guard !referencePoints.isEmpty else { return true }

        // Event has no coordinates — still show it (don't hide events without location data)
        guard let elat = event.eventLatitude, let elon = event.eventLongitude else { return true }

        // Pass if within range of ANY reference point
        return referencePoints.contains { ref in
            let miles = Self.haversineMiles(lat1: ref.latitude, lon1: ref.longitude, lat2: elat, lon2: elon)
            return miles <= Double(maxDistanceMiles)
        }
    }

    /// Distance in miles between two points (Haversine formula).
    private static func haversineMiles(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 3959.0 // Earth radius in miles
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}

extension NearbyFriendsFilterPreferences {
    private static let storageKey = "friendsFilterPreferences"

    static func fromStorage() -> NearbyFriendsFilterPreferences {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let prefs = try? JSONDecoder().decode(Self.self, from: data) else {
            return .default
        }
        return prefs
    }

    func saveToStorage() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// MARK: - Sheet

struct NearbyFriendsFilterSheet: View {
    @Binding var isPresented: Bool
    @Binding var preferences: NearbyFriendsFilterPreferences
    @Environment(\.dismiss) private var dismiss

    @State private var maxDistanceMiles: Double
    @State private var alongMyRoute: Bool

    init(isPresented: Binding<Bool>, preferences: Binding<NearbyFriendsFilterPreferences>) {
        _isPresented = isPresented
        _preferences = preferences
        let p = preferences.wrappedValue
        _maxDistanceMiles = State(initialValue: Double(p.maxDistanceMiles))
        _alongMyRoute = State(initialValue: p.alongMyRoute)
    }

    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")

    var body: some View {
        VStack(spacing: 0) {
            filterSheetHeader
            filterFormContent
            applyButtonSection
        }
        .background(softGray)
    }

    private var filterSheetHeader: some View {
        HStack {
            Text("Discovery Range")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(charcoalColor)
                .padding(.top, 8)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)
                    .frame(width: 32, height: 32)
                    .background(softGray)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(softGray)
    }

    private var filterFormContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Set how far away you want to discover travelers")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                VStack(spacing: 16) {
                    distanceSection
                    alongMyRouteSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .background(softGray)
    }

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Maximum distance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                Spacer()
                Text(Int(maxDistanceMiles) >= 200 ? "Anywhere" : "\(Int(maxDistanceMiles)) mi")
                    .font(.system(size: 13))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            Slider(value: $maxDistanceMiles, in: 5...200, step: 5)
                .tint(forestGreen)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var alongMyRouteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $alongMyRoute) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Along my route")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor)
                    Text("Show travelers near your travel plan stops")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.5))
                }
            }
            .tint(forestGreen)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var applyButtonSection: some View {
        VStack(spacing: 0) {
            Button(action: applyAndDismiss) {
                Text("Apply filters")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [skyBlue, forestGreen]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(softGray)
    }

    private func applyAndDismiss() {
        preferences = NearbyFriendsFilterPreferences(
            maxDistanceMiles: Int(maxDistanceMiles),
            alongMyRoute: alongMyRoute
        )
        ProfileManager.shared.communityPrefsVersion += 1
        dismiss()
    }
}

#Preview {
    NearbyFriendsFilterSheet(
        isPresented: .constant(true),
        preferences: .constant(.default)
    )
}
