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
    
    // Track search center and radius
    @State private var searchCenter: CLLocationCoordinate2D?
    @State private var searchRadiusMiles: Double = 200.0
    @State private var showSearchHereButton = false
    
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
                currentRegion = newRegion
                
                // Check if user has moved outside the search radius
                checkIfOutsideSearchRadius(center: newRegion.center)
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
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .sheet(item: $selectedCampground) { campground in
            CampgroundDetailSheet(campground: campground)
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
            // When location is updated, center map and fetch campgrounds
            if let location = locationManager.userLocation {
                // Center on user location only on first update
                if !hasCenteredOnUser {
                    hasCenteredOnUser = true
                    withAnimation(.easeInOut(duration: 1.0)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                            )
                        )
                    }
                    
                    // Fetch campgrounds for user's location
                    Task {
                        await fetchCampgroundsForLocation(center: location)
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
    
    // Fetch a single campground by ID from Campflare API
    private func fetchCampground(id: String) async {
        isLoadingCampgrounds = true
        
        do {
            let campground = try await CampflareManager.shared.fetchCampground(id: id)
            
            print("✅ Successfully fetched campground: \(campground.name) (ID: \(campground.id))")
            
            await MainActor.run {
                self.campgrounds = [campground]
                self.isLoadingCampgrounds = false
            }
        } catch {
            print("❌ Error fetching campground: \(error.localizedDescription)")
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
        
        print("🌲 Fetching campgrounds within 200 miles of (\(center.latitude), \(center.longitude))...")
        
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
            print("✅ Found \(response.campgrounds.count) campgrounds")
            
            await MainActor.run {
                self.campgrounds = response.campgrounds
                self.searchCenter = center
                self.isLoadingCampgrounds = false
                self.isFetchingAllUS = false
            }
        } catch {
            print("❌ Error fetching campgrounds: \(error.localizedDescription)")
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

// MARK: - Campground Detail Sheet

struct CampgroundDetailSheet: View {
    let campground: Campground
    @Environment(\.dismiss) private var dismiss
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(campground.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(charcoalColor)
                        
                        if let address = campground.location.address {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                
                                Text(address.full ?? "\(address.city ?? ""), \(address.stateCode ?? "")")
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                        
                        if campground.status == "open" {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(forestGreen)
                                    .frame(width: 10, height: 10)
                                
                                Text("Open")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(charcoalColor)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Description
                    if let description = campground.longDescription ?? campground.mediumDescription ?? campground.shortDescription {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            Text(description)
                                .font(.system(size: 16))
                                .foregroundColor(charcoalColor.opacity(0.8))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Amenities
                    if let amenities = campground.amenities {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Amenities")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                if amenities.toilets == true {
                                    AmenityRow(icon: "toilet", text: "Toilets", kind: amenities.toiletKind)
                                }
                                if amenities.showers == true {
                                    AmenityRow(icon: "drop.fill", text: "Showers")
                                }
                                if amenities.water == true {
                                    AmenityRow(icon: "drop.fill", text: "Water")
                                }
                                if amenities.electricHookups == true {
                                    AmenityRow(icon: "bolt.fill", text: "Electric Hookups")
                                }
                                if amenities.waterHookups == true {
                                    AmenityRow(icon: "hose.fill", text: "Water Hookups")
                                }
                                if amenities.sewerHookups == true {
                                    AmenityRow(icon: "pipe.and.drop.fill", text: "Sewer Hookups")
                                }
                                if amenities.dumpStation == true {
                                    AmenityRow(icon: "arrow.down.circle.fill", text: "Dump Station")
                                }
                                if amenities.firesAllowed == true {
                                    AmenityRow(icon: "flame.fill", text: "Fires Allowed")
                                }
                                if amenities.petsAllowed == true {
                                    AmenityRow(icon: "pawprint.fill", text: "Pets Allowed")
                                }
                                if amenities.wifi == true {
                                    AmenityRow(icon: "wifi", text: "WiFi")
                                }
                                if amenities.campStore == true {
                                    AmenityRow(icon: "bag.fill", text: "Camp Store")
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Price
                    if let price = campground.price {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pricing")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            if let min = price.minimum, let max = price.maximum {
                                if min == max {
                                    Text("$\(Int(min)) per night")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                } else {
                                    Text("$\(Int(min)) - $\(Int(max)) per night")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Contact
                    if let contact = campground.contact {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            if let phone = contact.primaryPhone {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(burntOrange)
                                    Text(phone)
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                }
                            }
                            
                            if let email = contact.primaryEmail {
                                HStack(spacing: 8) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(burntOrange)
                                    Text(email)
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Reservation
                    if let reservationUrl = campground.reservationUrl {
                        Link(destination: URL(string: reservationUrl)!) {
                            HStack {
                                Text("Make Reservation")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.white)
                            }
                            .padding(20)
                            .background(burntOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Campground Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(burntOrange)
                }
            }
        }
    }
}

struct AmenityRow: View {
    let icon: String
    let text: String
    var kind: String? = nil
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(charcoalColor.opacity(0.7))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                if let kind = kind {
                    Text(kind.capitalized)
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color("SoftGray"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MapScreen()
}
