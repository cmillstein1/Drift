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
        print("Location error: \(error.localizedDescription)")
    }
}

struct MapScreen: View {
    var embedded: Bool = false
    
    @StateObject private var locationManager = MapLocationManager()
    @State private var campgrounds: [Campground] = []
    @State private var isLoadingCampgrounds = false
    @State private var currentRegion: MKCoordinateRegion?
    @State private var isFetchingAllUS = false
    
    @State private var selectedCampground: Campground? = nil
    @State private var pulseScale: CGFloat = 1.0
    @State private var hasCenteredOnUser = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    
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
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .onMapCameraChange { context in
                let newRegion = context.region
                let previousDelta = currentRegion?.span.latitudeDelta ?? 0
                currentRegion = newRegion
                
                // Check if zoomed out enough to show all US campgrounds (latitudeDelta > 20 degrees)
                if newRegion.span.latitudeDelta > 20.0 {
                    // Zoomed out to show entire US, fetch all campgrounds
                    if previousDelta <= 20.0 || campgrounds.isEmpty {
                        print("🗺️ Zoomed out - fetching all US campgrounds (delta: \(newRegion.span.latitudeDelta))")
                        Task {
                            await fetchAllUSCampgrounds()
                        }
                    }
                } else if newRegion.span.latitudeDelta < 1.0 {
                    // Zoomed in, fetch nearby campgrounds based on map center
                    let centerLat = newRegion.center.latitude
                    let centerLng = newRegion.center.longitude
                    print("🗺️ Zoomed in - fetching nearby campgrounds (delta: \(newRegion.span.latitudeDelta), center: \(centerLat), \(centerLng))")
                    Task {
                        await fetchNearbyCampgrounds(latitude: centerLat, longitude: centerLng)
                    }
                }
            }
            
            VStack {
                HStack {
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
                
                // Show message if no campgrounds found
                if campgrounds.isEmpty && !isLoadingCampgrounds {
                    VStack(spacing: 12) {
                        Image(systemName: "tent.fill")
                            .font(.system(size: 48))
                            .foregroundColor(charcoalColor.opacity(0.3))
                        
                        Text("No Campgrounds Found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(charcoalColor)
                        
                        Text("The Campflare API isn't returning data. This may be due to API key permissions or data availability.")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 32)
                    .padding(.bottom, 100)
                }
                
                if let selectedCampground = selectedCampground {
                    CampgroundCard(campground: selectedCampground) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.selectedCampground = nil
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
            
            // Request location permission if not already granted
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }
            
            // Test API access with a known campground ID
            Task {
            }
        }
        .onChange(of: locationManager.locationUpdated) { oldValue, newValue in
            // When location is updated, center map
            if let location = locationManager.userLocation {
                // Center on user location only on first update
                if !hasCenteredOnUser {
                    hasCenteredOnUser = true
                    withAnimation(.easeInOut(duration: 1.0)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                            )
                        )
                    }
                }
            }
        }
        .onAppear {
            // On initial load, if no region is set, start with a US-wide view
            if currentRegion == nil {
                // Set initial view to show entire US
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of US
                        span: MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 60.0) // Show entire US
                    )
                )
            }
        }
    }
    
    // Fetch nearby campgrounds from Campflare API
    private func fetchNearbyCampgrounds(latitude: Double, longitude: Double) async {
        isLoadingCampgrounds = true
        
        do {
            // Try with a larger radius first (200km) to increase chances of finding campgrounds
            let searchRequest = CampgroundSearchRequest(
                latitude: latitude,
                longitude: longitude,
                radius: 200, // Increased to 200 km radius
                state: nil,
                stateCode: nil,
                kind: nil,
                amenities: nil,
                limit: 100,
                offset: nil
            )
            
            let response = try await CampflareManager.shared.searchCampgrounds(request: searchRequest)
            
            print("📍 Found \(response.campgrounds.count) campgrounds near (\(latitude), \(longitude))")
            
            await MainActor.run {
                self.campgrounds = response.campgrounds
                self.isLoadingCampgrounds = false
            }
        } catch {
            print("❌ Error fetching campgrounds: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingCampgrounds = false
            }
        }
    }
    
    // Fetch all US campgrounds (when zoomed out)
    private func fetchAllUSCampgrounds() async {
        guard !isFetchingAllUS else { return }
        isFetchingAllUS = true
        isLoadingCampgrounds = true
        print("🌲 Starting to fetch all US campgrounds...")
        
        do {
            // Try fetching by popular states with lots of campgrounds
            // This is a workaround since searching without constraints returns empty
            let states = ["CA", "CO", "UT", "AZ", "OR", "WA", "MT", "WY", "ID", "NV", "NM", "TX", "FL", "NC", "VA", "NY", "ME", "VT", "NH", "MI"]
            var allCampgrounds: [Campground] = []
            var processedStates = 0
            
            // Try searching by popular camping locations first to test if API has data
            let popularLocations: [(lat: Double, lng: Double, name: String)] = [
                (37.8651, -119.5383, "Yosemite, CA"),
                (36.1069, -112.1129, "Grand Canyon, AZ"),
                (40.3428, -105.6836, "Rocky Mountain NP, CO"),
                (44.4280, -110.5885, "Yellowstone, WY"),
                (38.9072, -77.0369, "Washington DC area"),
                (34.0522, -118.2437, "Los Angeles, CA"),
                (40.7128, -74.0060, "New York, NY"),
                (47.6062, -122.3321, "Seattle, WA"),
                (45.5152, -122.6784, "Portland, OR"),
                (39.7392, -104.9903, "Denver, CO")
            ]
            
            // First, try searching by popular locations
            for location in popularLocations {
                print("🌲 Searching near \(location.name) (\(location.lat), \(location.lng))")
                
                let searchRequest = CampgroundSearchRequest(
                    latitude: location.lat,
                    longitude: location.lng,
                    radius: 100, // 100 km radius
                    state: nil,
                    stateCode: nil,
                    kind: nil,
                    amenities: nil,
                    limit: 50,
                    offset: nil
                )
                
                do {
                    let response = try await CampflareManager.shared.searchCampgrounds(request: searchRequest)
                    print("🌲 \(location.name) returned \(response.campgrounds.count) campgrounds")
                    allCampgrounds.append(contentsOf: response.campgrounds)
                    
                    // Limit total to prevent performance issues
                    if allCampgrounds.count >= 500 {
                        print("🌲 Reached limit of 500 campgrounds, stopping")
                        break
                    }
                } catch {
                    print("⚠️ Error fetching for \(location.name): \(error.localizedDescription)")
                    continue
                }
            }
            
            // If we still don't have enough, try by state codes
            if allCampgrounds.count < 100 {
                print("🌲 Trying state-based search as fallback...")
                for stateCode in states.prefix(10) { // Limit to first 10 states
                    processedStates += 1
                    print("🌲 Fetching campgrounds for state: \(stateCode) (\(processedStates)/10)")
                    
                    let searchRequest = CampgroundSearchRequest(
                        latitude: nil,
                        longitude: nil,
                        radius: nil,
                        state: nil,
                        stateCode: stateCode,
                        kind: nil,
                        amenities: nil,
                        limit: 100,
                        offset: nil
                    )
                    
                    do {
                        let response = try await CampflareManager.shared.searchCampgrounds(request: searchRequest)
                        print("🌲 State \(stateCode) returned \(response.campgrounds.count) campgrounds")
                        allCampgrounds.append(contentsOf: response.campgrounds)
                        
                        // Limit total to prevent performance issues
                        if allCampgrounds.count >= 500 {
                            print("🌲 Reached limit of 500 campgrounds, stopping")
                            break
                        }
                    } catch {
                        print("⚠️ Error fetching for state \(stateCode): \(error.localizedDescription)")
                        continue
                    }
                }
            }
            
            print("🌲 Total campgrounds fetched: \(allCampgrounds.count) from \(processedStates) states")
            
            await MainActor.run {
                self.campgrounds = allCampgrounds
                self.isLoadingCampgrounds = false
                self.isFetchingAllUS = false
            }
        } catch {
            print("❌ Error fetching all US campgrounds: \(error.localizedDescription)")
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

#Preview {
    MapScreen()
}
