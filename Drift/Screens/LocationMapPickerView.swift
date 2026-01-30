//
//  LocationMapPickerView.swift
//  Drift
//

import SwiftUI
import MapKit
import CoreLocation
import DriftBackend

struct LocationMapPickerView: View {
    @Binding var location: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared

    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var locationName: String = ""
    @State private var cityName: String = ""
    @State private var isGeocoding = false
    @State private var geocodeTask: Task<Void, Never>?
    @State private var hasInitialized = false
    @State private var isMapMoving = false
    @State private var showDragInstruction = true

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    var body: some View {
        ZStack {
            // Map - simple map without annotations
            Map(position: $cameraPosition)
                .mapStyle(.standard)
                .onMapCameraChange { context in
                    // Update coordinate immediately for pin position
                    let newCoordinate = context.region.center
                    // Always update selectedCoordinate so center button works
                    if selectedCoordinate == nil ||
                       abs(selectedCoordinate!.latitude - newCoordinate.latitude) > 0.0001 ||
                       abs(selectedCoordinate!.longitude - newCoordinate.longitude) > 0.0001 {
                        selectedCoordinate = newCoordinate
                    }

                    // Track map movement for fading instruction text
                    if hasInitialized {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showDragInstruction = false
                        }
                        isMapMoving = true
                    }

                    // Only geocode after initial setup and when user moves the map
                    // This prevents geocoding on the initial camera setup
                    if hasInitialized {
                        // Debounce reverse geocoding - only geocode after user stops moving
                        debouncedReverseGeocode(coordinate: newCoordinate)
                    } else {
                        // On first camera change after initialization, geocode once
                        hasInitialized = true
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                            await reverseGeocode(coordinate: newCoordinate)
                        }
                    }
                }

                // Centered pin overlay (always at center of screen)
                VStack {
                    Spacer()

                    // Location name label above pin (city only, no pin icon)
                    if !cityName.isEmpty {
                        Text(cityName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                            .offset(y: -30)
                    }

                    // Smaller RV icon at center
                    ZStack {
                        // RV icon
                        Image("rv_pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                    .offset(y: -20)

                    Spacer()
                }

                VStack {
                    // Top controls
                    HStack {
                        Spacer()

                        // Center button
                        Button(action: {
                            centerOnPin()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Center")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }

                    Spacer()

                    // Instructional text (fades when map moves)
                    if showDragInstruction {
                        Text("Drag the pin to set your location")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                            .opacity(showDragInstruction ? 1 : 0)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Current Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let savedLocation = cityName.isEmpty ? locationName : cityName
                        location = savedLocation
                        // Update the profile immediately and wait for completion
                        Task {
                            do {
                                let profileManager = ProfileManager.shared
                                try await profileManager.updateProfile(
                                    ProfileUpdateRequest(location: savedLocation)
                                )
                                // Refresh the profile to get updated data
                                try await profileManager.fetchCurrentProfile()
                                await MainActor.run {
                                    dismiss()
                                }
                            } catch {
                                print("Failed to update location: \(error)")
                                await MainActor.run {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .foregroundColor(burntOrange)
                    .disabled(cityName.isEmpty && locationName.isEmpty || isGeocoding)
                }
            }
            .onAppear {
                // Immediately hide tab bar and keep it hidden
                tabBarVisibility.isVisible = false
                // Also set it with animation after a brief delay to override any other changes
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
                initializeLocation()
            }
            .onDisappear {
                // Don't show tab bar here - let EditProfileScreen handle it
                // Cancel any pending geocoding when view disappears
                geocodeTask?.cancel()
            }
    }

    private func initializeLocation() {
        if !location.isEmpty {
            Task {
                let geocoder = CLGeocoder()
                do {
                    let placemarks = try await geocoder.geocodeAddressString(location)
                    await MainActor.run {
                        if let placemark = placemarks.first,
                           let coordinate = placemark.location?.coordinate {
                            selectedCoordinate = coordinate
                            cameraPosition = .region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            ))
                            // Set location name immediately from geocoding result
                            var components: [String] = []
                            if let city = placemark.locality {
                                components.append(city)
                                cityName = city
                            }
                            if let state = placemark.administrativeArea {
                                components.append(state)
                            }
                            if let country = placemark.country {
                                components.append(country)
                            }
                            locationName = components.joined(separator: ", ")
                            if cityName.isEmpty {
                                cityName = locationName
                            }
                        } else {
                            // Fallback to user location
                            cameraPosition = .userLocation(fallback: .automatic)
                        }
                        hasInitialized = true
                    }
                } catch {
                    await MainActor.run {
                        cameraPosition = .userLocation(fallback: .automatic)
                        hasInitialized = true
                    }
                }
            }
        } else {
            // Use user's current location
            cameraPosition = .userLocation(fallback: .automatic)
            // Set a flag to capture the coordinate when the map initializes
            hasInitialized = true
            // The coordinate will be set in onMapCameraChange
        }
    }

    private func centerOnPin() {
        // Center on the current pin location (selectedCoordinate)
        // This coordinate is always kept up to date by onMapCameraChange
        guard let coordinate = selectedCoordinate else {
            // If coordinate not set yet, wait a moment and try again
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await MainActor.run {
                    if let coordinate = selectedCoordinate {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            cameraPosition = .region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            ))
                        }
                    }
                }
            }
            return
        }

        // Force update the camera position to center on the pin
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }


    private func debouncedReverseGeocode(coordinate: CLLocationCoordinate2D) {
        // Cancel any pending geocoding task
        geocodeTask?.cancel()

        // Create a new task that will execute after a delay
        geocodeTask = Task {
            // Wait 0.5 seconds after map movement stops
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Check if task was cancelled (user moved map again)
            guard !Task.isCancelled else { return }

            // Now perform the reverse geocoding
            await reverseGeocode(coordinate: coordinate)
        }
    }

    @MainActor
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) async {
        guard !isGeocoding else { return }
        isGeocoding = true

        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
            isGeocoding = false

            if let placemark = placemarks.first {
                var components: [String] = []
                if let city = placemark.locality {
                    components.append(city)
                    cityName = city
                }
                if let state = placemark.administrativeArea {
                    components.append(state)
                }
                if let country = placemark.country {
                    components.append(country)
                }
                locationName = components.joined(separator: ", ")
                if cityName.isEmpty {
                    cityName = locationName
                }
            } else {
                let coordString = "\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
                locationName = coordString
                cityName = coordString
            }
        } catch {
            isGeocoding = false
            // On error, show coordinates
            let coordString = "\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
            locationName = coordString
            cityName = coordString
        }
    }
}
