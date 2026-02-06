//
//  DiscoverMapSheet.swift
//  Drift
//
//  Map of nearby people (dating or friends). Shows approximate (fuzzed) locations only.
//  User location is from profile city/state (latitude/longitude), not device GPS.
//  Pins use circular profile pictures; tap opens ProfileDetailView.
//

import SwiftUI
import MapKit
import CoreLocation
import DriftBackend

/// Returns a fuzzed coordinate for display so we never show exact location.
/// Offset is ~1.5–2.5 km in a consistent direction per profile (by id hash).
private func fuzzedCoordinate(lat: Double, lon: Double, profileId: UUID) -> CLLocationCoordinate2D {
    let seed = profileId.hashValue
    let angle = Double(abs(seed % 360)) * .pi / 180.0
    let offsetKm = 1.5 + Double(abs(seed % 100)) / 100.0 // 1.5–2.5 km

    let latOffset = (offsetKm / 111.0) * cos(angle)
    let lngOffset = (offsetKm / (111.0 * cos(lat * .pi / 180.0))) * sin(angle)

    return CLLocationCoordinate2D(latitude: lat + latOffset, longitude: lon + lngOffset)
}

/// User location: profile city/state (lat/lon) preferred; device location used as fallback for centering only.
struct DiscoverMapSheet: View {
    let profiles: [UserProfile]
    /// Current user's location (profile city/state or device). Used for centering and "You" pin only.
    let currentUserCoordinate: CLLocationCoordinate2D?
    /// When true, current user has chosen to hide their location on the map (no "You" pin, no recenter).
    let hideCurrentUserLocation: Bool
    /// When true, view is pushed (no dismiss button; back button pops).
    let isPushed: Bool
    var onDismiss: (() -> Void)? = nil
    let onSelectProfile: (UserProfile) -> Void
    let distanceMiles: (UserProfile) -> Int?

    @ObservedObject private var locationProvider = DiscoveryLocationProvider.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasCenteredOnce = false
    /// Geocoded coords for profiles that have location string but no lat/lon (so they appear on map).
    @State private var geocodedCoords: [UUID: CLLocationCoordinate2D] = [:]
    /// Cache by location string to avoid re-geocoding the same city.
    @State private var locationStringCache: [String: CLLocationCoordinate2D] = [:]

    private let softGray = Color("SoftGray")
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)

    /// Best available user location: profile first, then device (updates when location arrives). Nil when user has hidden location.
    private var effectiveUserCoordinate: CLLocationCoordinate2D? {
        guard !hideCurrentUserLocation else { return nil }
        return currentUserCoordinate ?? locationProvider.lastCoordinate
    }

    /// Profiles that have stored coordinates (shown at fuzzed position).
    private var profilesWithLocation: [UserProfile] {
        profiles.filter { $0.latitude != nil && $0.longitude != nil }
    }

    /// Show people at their city/state: use stored lat/lon, or geocoded location string, fuzzed.
    private var profilesToShow: [(profile: UserProfile, coordinate: CLLocationCoordinate2D)] {
        var result: [(UserProfile, CLLocationCoordinate2D)] = []
        for p in profiles {
            if let lat = p.latitude, let lon = p.longitude {
                result.append((p, fuzzedCoordinate(lat: lat, lon: lon, profileId: p.id)))
            } else if let coord = geocodedCoords[p.id] {
                result.append((p, fuzzedCoordinate(lat: coord.latitude, lon: coord.longitude, profileId: p.id)))
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // "You" at profile or device location (hidden when user has hide location on map)
                if !hideCurrentUserLocation, let userCoord = effectiveUserCoordinate {
                    Annotation("You", coordinate: userCoord) {
                        ZStack {
                            Circle()
                                .fill(Color("SkyBlue"))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }

                ForEach(profilesToShow, id: \.profile.id) { item in
                    Annotation(item.profile.displayName, coordinate: item.coordinate) {
                        DiscoverMapPin(profile: item.profile)
                            .onTapGesture {
                                onSelectProfile(item.profile)
                            }
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()

            VStack {
                // Sheet-only: close button in top-right when not pushed
                if !isPushed, let onDismiss = onDismiss {
                    HStack {
                        Spacer()
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 60)
                    }
                }
                Spacer()
                if profilesToShow.isEmpty {
                    // Empty state centered on map
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 32))
                            .foregroundColor(inkSub)
                        Text("No one to show on the map yet")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(inkMain)
                        Text("Only people who have set their city/state in profile appear here.")
                            .font(.system(size: 13))
                            .foregroundColor(inkSub)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                } else {
                    Text("Approximate locations only — exact position is never shown")
                        .font(.system(size: 11))
                        .foregroundColor(inkSub)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Nearby")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Centering button in nav bar: across from back button (top right)
            if effectiveUserCoordinate != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if let userCoord = effectiveUserCoordinate {
                            cameraPosition = .region(MKCoordinateRegion(
                                center: userCoord,
                                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                            ))
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("SkyBlue"))
                    }
                }
            }
        }
        .onAppear {
            tabBarVisibility.isVisible = false
            DiscoveryLocationProvider.shared.requestLocation()
            centerMapIfNeeded()
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    if !hasCenteredOnce, effectiveUserCoordinate != nil {
                        centerMapIfNeeded()
                    }
                }
            }
        }
        .onDisappear {
            tabBarVisibility.isVisible = true
        }
        .task {
            await geocodeProfilesWithLocationStringOnly()
        }
    }

    /// Geocode profiles that have location string but no lat/lon so they appear on the map.
    private func geocodeProfilesWithLocationStringOnly() async {
        let needGeocode = profiles.filter { p in
            (p.latitude == nil || p.longitude == nil) &&
            (p.location != nil && !p.location!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        let geocoder = CLGeocoder()
        for p in needGeocode {
            let locationString = p.location!.trimmingCharacters(in: .whitespacesAndNewlines)
            let cached: CLLocationCoordinate2D? = await MainActor.run { locationStringCache[locationString] }
            if let cached = cached {
                await MainActor.run { geocodedCoords[p.id] = cached }
                continue
            }
            guard let placemarks = try? await geocoder.geocodeAddressString(locationString),
                  let coord = placemarks.first?.location?.coordinate else { continue }
            await MainActor.run {
                locationStringCache[locationString] = coord
                geocodedCoords[p.id] = coord
            }
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s between requests to avoid rate limit
        }
        await MainActor.run {
            if !hasCenteredOnce, !geocodedCoords.isEmpty || !profilesWithLocation.isEmpty {
                centerMapIfNeeded()
            }
        }
    }

    private func centerMapIfNeeded() {
        guard !hasCenteredOnce else { return }
        let user = effectiveUserCoordinate
        let toShow = profilesToShow.map(\.coordinate)

        let center: CLLocationCoordinate2D
        let span: MKCoordinateSpan

        if let userCoord = user, !toShow.isEmpty {
            // Center on user and use a span that includes all pins (so pins are visible)
            let lats = toShow.map(\.latitude) + [userCoord.latitude]
            let lons = toShow.map(\.longitude) + [userCoord.longitude]
            let minLat = lats.min() ?? userCoord.latitude
            let maxLat = lats.max() ?? userCoord.latitude
            let minLon = lons.min() ?? userCoord.longitude
            let maxLon = lons.max() ?? userCoord.longitude
            let pad = 0.05
            center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            span = MKCoordinateSpan(
                latitudeDelta: max(0.3, (maxLat - minLat) + pad),
                longitudeDelta: max(0.3, (maxLon - minLon) + pad)
            )
        } else if let userCoord = user {
            center = userCoord
            span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        } else if let first = profilesWithLocation.first,
                  let lat = first.latitude, let lon = first.longitude {
            center = fuzzedCoordinate(lat: lat, lon: lon, profileId: first.id)
            span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        } else {
            return
        }

        hasCenteredOnce = true
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

/// Circular profile image used as a map pin. Same styling as discover cards.
struct DiscoverMapPin: View {
    let profile: UserProfile

    private let pinSize: CGFloat = 44
    private let borderWidth: CGFloat = 2
    private let forestGreen = Color("ForestGreen")

    private var imageURL: String? {
        profile.photos.first ?? profile.avatarUrl
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let urlString = imageURL, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderView
                        case .empty:
                            placeholderView
                        @unknown default:
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
            }
            .frame(width: pinSize, height: pinSize)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: borderWidth)
            )
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)

            if profile.verified {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(forestGreen)
                    .background(Circle().fill(Color.white))
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(softGrayPlaceholder)
            Text(profile.initials)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(inkSub)
        }
    }

    private let softGrayPlaceholder = Color(red: 0.95, green: 0.95, blue: 0.96)
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
}

#Preview {
    DiscoverMapSheet(
        profiles: [],
        currentUserCoordinate: nil,
        hideCurrentUserLocation: false,
        isPushed: true,
        onSelectProfile: { _ in },
        distanceMiles: { _ in nil }
    )
}
