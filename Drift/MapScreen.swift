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

struct NearbyUser: Identifiable {
    let id: Int
    let name: String
    let age: Int
    let distance: String
    let lifestyle: String
    let lat: Double
    let lng: Double
}

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
    @StateObject private var locationManager = MapLocationManager()
    @State private var nearbyUsers: [NearbyUser] = []
    
    @State private var selectedUser: NearbyUser? = nil
    @State private var pulseScale: CGFloat = 1.0
    @State private var hasCenteredOnUser = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation()
                
                ForEach(nearbyUsers) { user in
                    Annotation(user.name, coordinate: CLLocationCoordinate2D(latitude: user.lat, longitude: user.lng)) {
                        UserMapMarker(
                            user: user,
                            isSelected: selectedUser?.id == user.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedUser = user
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    StatsCard(count: nearbyUsers.count)
                        .padding(.leading, 16)
                        .padding(.top, 16)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
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
                        }
                        
                        FilterButton()
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                if let selectedUser = selectedUser {
                    UserCard(user: selectedUser) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.selectedUser = nil
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
        }
        .onChange(of: locationManager.locationUpdated) { oldValue, newValue in
            // When location is updated, center map and generate nearby users
            if let location = locationManager.userLocation {
                // Generate nearby users relative to user's location
                if nearbyUsers.isEmpty {
                    nearbyUsers = generateNearbyUsers(relativeTo: location)
                }
                
                // Center on user location only on first update
                if !hasCenteredOnUser {
                    hasCenteredOnUser = true
                    withAnimation(.easeInOut(duration: 1.0)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                            )
                        )
                    }
                }
            }
        }
    }
    
    // Generate nearby users positioned relative to the user's location
    private func generateNearbyUsers(relativeTo userLocation: CLLocationCoordinate2D) -> [NearbyUser] {
        // Small offsets in degrees (approximately 0.01 degree ≈ 1 km)
        let offsets: [(lat: Double, lng: Double, distance: String)] = [
            (0.015, 0.015, "2 mi"),   // Northeast
            (-0.02, 0.01, "3 mi"),    // Southeast
            (0.01, -0.025, "4 mi"),   // Northwest
            (-0.015, -0.02, "5 mi")   // Southwest
        ]
        
        return [
            NearbyUser(id: 1, name: "Sarah", age: 28, distance: offsets[0].distance, lifestyle: "Van Life", 
                     lat: userLocation.latitude + offsets[0].lat, lng: userLocation.longitude + offsets[0].lng),
            NearbyUser(id: 2, name: "Marcus", age: 31, distance: offsets[1].distance, lifestyle: "Digital Nomad", 
                     lat: userLocation.latitude + offsets[1].lat, lng: userLocation.longitude + offsets[1].lng),
            NearbyUser(id: 3, name: "Luna", age: 26, distance: offsets[2].distance, lifestyle: "Van Life", 
                     lat: userLocation.latitude + offsets[2].lat, lng: userLocation.longitude + offsets[2].lng),
            NearbyUser(id: 4, name: "Jake", age: 29, distance: offsets[3].distance, lifestyle: "Backpacker", 
                     lat: userLocation.latitude + offsets[3].lat, lng: userLocation.longitude + offsets[3].lng)
        ]
    }
}

struct UserMapMarker: View {
    let user: NearbyUser
    let isSelected: Bool
    
    @State private var scale: CGFloat = 1.0
    
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
    var body: some View {
        ZStack {
            Circle()
                .fill(burntOrange)
                .frame(width: isSelected ? 56 : 48, height: isSelected ? 56 : 48)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 5 : 4)
                )
                .shadow(color: .black.opacity(0.3), radius: isSelected ? 12 : 8, x: 0, y: 4)
            
            Circle()
                .fill(forestGreen)
                .frame(width: 16, height: 16)
                .offset(x: isSelected ? 20 : 18, y: isSelected ? 20 : 18)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .scaleEffect(scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct StatsCard: View {
    let count: Int
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nearby")
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.6))
            
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(charcoalColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct FilterButton: View {
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        Button(action: {
            // Handle filter action
        }) {
            Text("Filters")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
        }
    }
}

struct UserCard: View {
    let user: NearbyUser
    let onView: () -> Void
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(user.name), \(user.age)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    
                    Text("\(user.distance) away")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Text(user.lifestyle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(charcoalColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(desertSand)
                    .clipShape(Capsule())
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
