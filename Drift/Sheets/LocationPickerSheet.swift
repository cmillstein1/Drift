//
//  LocationPickerSheet.swift
//  Drift
//
//  Location picker with map and search for events
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct LocationPickerSheet: View {
    @Environment(\.dismiss) var dismiss

    @Binding var locationName: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?

    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedPlacemark: MKPlacemark?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showSearchResults: Bool = false
    @State private var isReverseGeocoding: Bool = false
    @State private var isMapMoving: Bool = false
    @State private var geocodeTask: DispatchWorkItem?
    @State private var hasInitialized: Bool = false

    @StateObject private var locationManager = LocationPickerLocationManager()

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")

    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    UserAnnotation()
                }
                .onMapCameraChange(frequency: .continuous) { context in
                    let newCenter = context.region.center
                    selectedLocation = newCenter
                    isMapMoving = true
                    showSearchResults = false

                    // Debounced reverse geocode
                    geocodeTask?.cancel()
                    let task = DispatchWorkItem {
                        isMapMoving = false
                        reverseGeocode(coordinate: newCenter)
                    }
                    geocodeTask = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
                }
                .ignoresSafeArea(edges: .bottom)

                // Center pin overlay (fixed on screen, map moves underneath)
                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(burntOrange)

                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 14))
                        .foregroundColor(burntOrange)
                        .offset(y: -6)
                }
                .offset(y: isMapMoving ? -8 : 0)
                .animation(.easeOut(duration: 0.15), value: isMapMoving)
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    // Search bar
                    searchBarSection

                    // Search results
                    if showSearchResults && !searchResults.isEmpty {
                        searchResultsList
                    }

                    Spacer()

                    // Selected location card
                    selectedLocationCard
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(charcoal)
                }
            }
            .onAppear {
                if let lat = latitude, let lng = longitude {
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    cameraPosition = .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    ))
                } else if let userLoc = locationManager.userLocation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: userLoc,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
        }
    }

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(charcoal.opacity(0.5))

                TextField("Search places or addresses...", text: $searchText)
                    .font(.system(size: 16))
                    .onSubmit {
                        searchLocation()
                    }
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            searchResults = []
                            showSearchResults = false
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        showSearchResults = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(charcoal.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            if isSearching {
                ProgressView()
                    .tint(burntOrange)
            } else if !searchText.isEmpty {
                Button {
                    searchLocation()
                } label: {
                    Text("Search")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(burntOrange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults, id: \.self) { item in
                    Button {
                        selectSearchResult(item)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(burntOrange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Unknown")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(charcoal)
                                    .lineLimit(1)

                                if let address = formatAddress(item.placemark) {
                                    Text(address)
                                        .font(.system(size: 13))
                                        .foregroundColor(charcoal.opacity(0.6))
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .frame(maxHeight: 250)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var selectedLocationCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(burntOrange.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(burntOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if isMapMoving || isReverseGeocoding {
                        Text("Move map to place pin")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoal)

                        Text("Release to update location")
                            .font(.system(size: 13))
                            .foregroundColor(charcoal.opacity(0.6))
                    } else if let placemark = selectedPlacemark {
                        Text(placemark.name ?? formatCoordinates(selectedLocation))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoal)
                            .lineLimit(1)

                        if let address = formatAddress(placemark) {
                            Text(address)
                                .font(.system(size: 13))
                                .foregroundColor(charcoal.opacity(0.6))
                                .lineLimit(1)
                        }
                    } else if let location = selectedLocation {
                        Text(formatCoordinates(location))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoal)
                    } else {
                        Text("Pan the map to select a location")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoal)
                    }
                }

                Spacer()
            }
            .padding(16)

            Button {
                confirmLocation()
            } label: {
                Text("Confirm Location")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isMapMoving ? forestGreen.opacity(0.5) : forestGreen)
                    .clipShape(Capsule())
            }
            .disabled(isMapMoving)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: -4)
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    // MARK: - Actions

    private func searchLocation() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        showSearchResults = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        // If we have user location, bias results toward it
        if let userLoc = locationManager.userLocation {
            request.region = MKCoordinateRegion(
                center: userLoc,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            )
        }

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false

            if let results = response?.mapItems {
                searchResults = results
            } else {
                searchResults = []
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        selectedLocation = coordinate
        selectedPlacemark = item.placemark
        showSearchResults = false

        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    private func confirmLocation() {
        guard let location = selectedLocation else { return }

        latitude = location.latitude
        longitude = location.longitude

        if let placemark = selectedPlacemark {
            locationName = placemark.name ?? formatAddress(placemark) ?? formatCoordinates(location)
        } else {
            locationName = formatCoordinates(location)
        }

        dismiss()
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        isReverseGeocoding = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            isReverseGeocoding = false
            if let placemark = placemarks?.first {
                selectedPlacemark = MKPlacemark(placemark: placemark)
            }
        }
    }

    // MARK: - Helpers

    private func formatAddress(_ placemark: MKPlacemark?) -> String? {
        guard let placemark = placemark else { return nil }

        var parts: [String] = []

        if let locality = placemark.locality {
            parts.append(locality)
        }
        if let adminArea = placemark.administrativeArea {
            parts.append(adminArea)
        }

        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func formatCoordinates(_ location: CLLocationCoordinate2D?) -> String {
        guard let location = location else { return "" }
        return String(format: "%.4f, %.4f", location.latitude, location.longitude)
    }
}

// MARK: - Location Manager

class LocationPickerLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
    }
}
