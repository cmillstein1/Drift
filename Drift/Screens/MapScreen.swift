//
//  MapScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import DriftBackend
import Auth

class MapLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationUpdated: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        locationUpdated.toggle() // Toggle to trigger onChange
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}

struct MapScreen: View {
    var embedded: Bool = false

    @StateObject private var locationManager = MapLocationManager()
    @StateObject private var communityManager = CommunityManager.shared
    @State private var campgrounds: [Campground] = []
    @State private var isLoadingCampgrounds = false
    @State private var currentRegion: MKCoordinateRegion?
    @State private var isFetchingAllUS = false

    @State private var selectedCampground: Campground? = nil
    @State private var selectedEvent: CommunityPost? = nil
    @State private var pulseScale: CGFloat = 1.0
    @State private var hasCenteredOnUser = false
    @State private var hasFetchedInitialCampgrounds = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    // Track search center and radius
    @State private var searchCenter: CLLocationCoordinate2D?
    @State private var searchRadiusMiles: Double = 200.0
    @State private var showSearchHereButton = false

    // Map type selection
    @State private var selectedMapType: MapStyleType = .standard

    // Filter events with coordinates
    private var eventsWithLocation: [CommunityPost] {
        communityManager.posts.filter { post in
            post.type == .event &&
            post.eventLatitude != nil &&
            post.eventLongitude != nil
        }
    }

    // Check if current user can see exact location for an event
    private func canSeeExactLocation(for event: CommunityPost) -> Bool {
        // Public events - everyone sees exact location
        if event.eventPrivacy == .public {
            return true
        }
        // Host can see exact location
        if let currentUserId = SupabaseManager.shared.currentUser?.id,
           event.authorId == currentUserId {
            return true
        }
        // Attendees can see exact location
        if event.isAttendingEvent == true {
            return true
        }
        return false
    }

    // Get display coordinates for an event (exact or approximate)
    private func displayCoordinate(for event: CommunityPost) -> CLLocationCoordinate2D? {
        guard let lat = event.eventLatitude, let lng = event.eventLongitude else {
            return nil
        }

        if canSeeExactLocation(for: event) {
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else {
            // For private events, offset by ~1-2km in a random but consistent direction
            // Use event ID to generate consistent offset so marker doesn't jump around
            let seed = event.id.hashValue
            let angle = Double(abs(seed % 360)) * .pi / 180.0
            let offsetKm = 1.0 + Double(abs(seed % 100)) / 100.0 // 1-2km offset

            // Approximate conversion: 1 degree latitude ≈ 111km
            let latOffset = (offsetKm / 111.0) * cos(angle)
            let lngOffset = (offsetKm / (111.0 * cos(lat * .pi / 180.0))) * sin(angle)

            return CLLocationCoordinate2D(latitude: lat + latOffset, longitude: lng + lngOffset)
        }
    }
    
    enum MapStyleType: CaseIterable {
        case standard
        case traffic
        case satellite
        
        var icon: String {
            switch self {
            case .standard: return "map"
            case .traffic: return "car"
            case .satellite: return "globe.americas"
            }
        }
        
        var label: String {
            switch self {
            case .standard: return "Standard"
            case .traffic: return "Traffic"
            case .satellite: return "Satellite"
            }
        }
        
        func next() -> MapStyleType {
            let allCases = MapStyleType.allCases
            let currentIndex = allCases.firstIndex(of: self) ?? 0
            let nextIndex = (currentIndex + 1) % allCases.count
            return allCases[nextIndex]
        }
    }
    
    private var currentMapStyle: MapStyle {
        switch selectedMapType {
        case .standard:
            return .standard
        case .traffic:
            return .standard(emphasis: .muted, showsTraffic: true)
        case .satellite:
            return .imagery
        }
    }
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation()

                // Campground markers
                ForEach(campgrounds) { campground in
                    Annotation(campground.name, coordinate: CLLocationCoordinate2D(latitude: campground.location.latitude, longitude: campground.location.longitude)) {
                        CampgroundMapMarker(
                            campground: campground,
                            isSelected: selectedCampground?.id == campground.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCampground = campground
                            }
                        }
                    }
                }

                // Event markers
                ForEach(eventsWithLocation) { event in
                    if let coordinate = displayCoordinate(for: event) {
                        Annotation(event.title, coordinate: coordinate) {
                            EventMapMarker(
                                event: event,
                                isSelected: selectedEvent?.id == event.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedEvent = event
                                }
                            }
                        }
                    }
                }
            }
            .mapStyle(currentMapStyle)
            .ignoresSafeArea()
            .onMapCameraChange { context in
                let newRegion = context.region
                currentRegion = newRegion
                
                // Check if user has moved outside the search radius
                checkIfOutsideSearchRadius(center: newRegion.center)
            }
            
            VStack {
                HStack {
                    // Map type toggle button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMapType = selectedMapType.next()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: selectedMapType.icon)
                                .font(.system(size: 14, weight: .medium))
                            Text(selectedMapType.label)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(charcoalColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Center on user location button
                    if locationManager.userLocation != nil {
                        Button(action: {
                            if let location = locationManager.userLocation {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    cameraPosition = .region(
                                        MKCoordinateRegion(
                                            center: location,
                                            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                                        )
                                    )
                                }
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(skyBlue)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                }
                
                Spacer()
                
                // Map pins are displayed via ForEach above
                
                // "Search here" button when outside search radius
                if showSearchHereButton, let currentCenter = currentRegion?.center {
                    VStack {
                        Spacer()
                        Button(action: {
                            Task {
                                await fetchCampgroundsForLocation(center: currentCenter)
                            }
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Search here")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(burntOrange)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.bottom, 140)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .sheet(item: $selectedCampground) { campground in
            CampgroundDetailSheet(campground: campground)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(initialPost: event)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }

            // Request location permission if not already granted
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }

            // Fetch community posts for events
            Task {
                try? await communityManager.fetchPosts()
            }

            // If we already have user location, center on it and fetch campgrounds
            if let location = locationManager.userLocation {
                if !hasCenteredOnUser {
                    hasCenteredOnUser = true
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                        )
                    )
                }

                // Fetch campgrounds only once on initial load
                if !hasFetchedInitialCampgrounds {
                    hasFetchedInitialCampgrounds = true
                    Task {
                        await fetchCampgroundsForLocation(center: location)
                    }
                }
            }
        }
        .onChange(of: locationManager.locationUpdated) { oldValue, newValue in
            // When location is updated, center map and fetch campgrounds (only on first update)
            if let location = locationManager.userLocation {
                if !hasCenteredOnUser {
                    hasCenteredOnUser = true
                    withAnimation(.easeInOut(duration: 0.5)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                            )
                        )
                    }
                }

                // Fetch campgrounds only once on initial load
                if !hasFetchedInitialCampgrounds {
                    hasFetchedInitialCampgrounds = true
                    Task {
                        await fetchCampgroundsForLocation(center: location)
                    }
                }
            }
        }
    }
    
    // Fetch a single campground by ID from Campflare API
    private func fetchCampground(id: String) async {
        isLoadingCampgrounds = true
        
        do {
            let campground = try await CampflareManager.shared.fetchCampground(id: id)
            
            await MainActor.run {
                self.campgrounds = [campground]
                self.isLoadingCampgrounds = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingCampgrounds = false
            }
        }
    }
    
    // Calculate bounding box from center point and radius in miles
    private func boundingBox(center: CLLocationCoordinate2D, radiusMiles: Double) -> BoundingBox {
        // 1 degree of latitude ≈ 69 miles
        // 1 degree of longitude ≈ 69 miles * cos(latitude)
        let latDelta = radiusMiles / 69.0
        let lonDelta = radiusMiles / (69.0 * cos(center.latitude * .pi / 180.0))
        
        return BoundingBox(
            minLatitude: center.latitude - latDelta,
            maxLatitude: center.latitude + latDelta,
            minLongitude: center.longitude - lonDelta,
            maxLongitude: center.longitude + lonDelta
        )
    }
    
    // Calculate distance between two coordinates in miles
    private func distanceInMiles(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1609.34 // Convert meters to miles
    }
    
    // Check if current map center is outside the search radius
    private func checkIfOutsideSearchRadius(center: CLLocationCoordinate2D) {
        guard let searchCenter = searchCenter else { return }
        
        let distance = distanceInMiles(from: searchCenter, to: center)
        showSearchHereButton = distance > searchRadiusMiles
    }
    
    // Fetch campgrounds for a specific location
    private func fetchCampgroundsForLocation(center: CLLocationCoordinate2D) async {
        guard !isFetchingAllUS else { return }
        isFetchingAllUS = true
        isLoadingCampgrounds = true
        showSearchHereButton = false
        
        let bbox = boundingBox(center: center, radiusMiles: searchRadiusMiles)
        
        let searchRequest = CampgroundSearchRequest(
            query: nil,
            limit: 100,
            amenities: nil,
            minimumRvLength: nil,
            minimumTrailerLength: nil,
            bigRigFriendly: nil,
            cellService: nil,
            status: "open",
            kind: nil,
            campsiteKinds: nil,
            bbox: bbox,
            v1CampgroundId: nil
        )
        
        do {
            let response = try await CampflareManager.shared.searchCampgrounds(request: searchRequest)
            
            await MainActor.run {
                self.campgrounds = response.campgrounds
                self.searchCenter = center
                self.isLoadingCampgrounds = false
                self.isFetchingAllUS = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingCampgrounds = false
                self.isFetchingAllUS = false
            }
        }
    }
}

struct CampgroundMapMarker: View {
    let campground: Campground
    let isSelected: Bool
    
    @State private var scale: CGFloat = 1.0
    
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    
    var body: some View {
        ZStack {
            Image(systemName: "tent.fill")
                .font(.system(size: isSelected ? 24 : 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: isSelected ? 48 : 40, height: isSelected ? 48 : 40)
                .background(
                    Circle()
                        .fill(forestGreen)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isSelected ? 4 : 3)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: isSelected ? 12 : 8, x: 0, y: 4)
        }
        .scaleEffect(scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CampgroundCard: View {
    let campground: Campground
    let onView: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let desertSand = Color("DesertSand")
    private let forestGreen = Color("ForestGreen")
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(campground.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoalColor)
                    .lineLimit(2)
                
                if let address = campground.location.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        Text(address.city ?? address.state ?? "")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                
                if campground.status == "open" {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(forestGreen)
                            .frame(width: 8, height: 8)
                        
                        Text("Open")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(charcoalColor)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onView) {
                Text("View")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(burntOrange)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
}

struct EventMapMarker: View {
    let event: CommunityPost
    let isSelected: Bool

    @State private var scale: CGFloat = 1.0

    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let charcoal = Color("Charcoal")

    private var isPrivateEvent: Bool {
        event.eventPrivacy?.isPrivate == true
    }

    var body: some View {
        ZStack {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: isSelected ? 28 : 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: isSelected ? 48 : 40, height: isSelected ? 48 : 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isSelected ? 4 : 3)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: isSelected ? 12 : 8, x: 0, y: 4)

            // Private event lock badge
            if isPrivateEvent {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(charcoal)
                    .clipShape(Circle())
                    .offset(x: isSelected ? 18 : 14, y: isSelected ? -18 : -14)
            }
        }
        .scaleEffect(scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    MapScreen()
}
