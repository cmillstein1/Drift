//
//  HometownScreen.swift
//  Drift
//
//  Created by Claude on 1/19/26.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import DriftBackend

class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var isSearching = false

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func search(query: String) {
        searchQuery = query
        if query.isEmpty {
            completions = []
            isSearching = false
        } else {
            isSearching = true
            completer.queryFragment = query
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter to show cities/regions, not specific addresses
        completions = completer.results.filter { completion in
            // Prefer results that look like cities (have subtitle with region/country)
            !completion.subtitle.isEmpty
        }
        isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        isSearching = false
    }
}

class ReverseGeocoder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var cityName: String?
    @Published var isLoading = true

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func fetchCurrentCity() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        } else {
            isLoading = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            isLoading = false
            return
        }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let placemark = placemarks?.first {
                    // Build city string: "City, State" or "City, Country"
                    var components: [String] = []
                    if let city = placemark.locality {
                        components.append(city)
                    }
                    if let state = placemark.administrativeArea {
                        components.append(state)
                    } else if let country = placemark.country {
                        components.append(country)
                    }
                    self?.cityName = components.joined(separator: ", ")
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
    }
}

struct HometownScreen: View {
    let onContinue: () -> Void

    @StateObject private var searchCompleter = LocationSearchCompleter()
    @StateObject private var reverseGeocoder = ReverseGeocoder()
    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedLocation: String = ""
    @State private var isSaving = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var textFieldOpacity: Double = 0
    @State private var textFieldOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @FocusState private var isTextFieldFocused: Bool

    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)

    private var canContinue: Bool {
        !selectedLocation.isEmpty
    }

    var body: some View {
        ZStack {
            warmWhite
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator is shown in OnboardingFlow
                Spacer()
                    .frame(height: 24)

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Confirm your location")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)
                            .offset(x: titleOffset)

                        Text("Edit if this doesn't look right")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.top, 8)
                            .opacity(subtitleOpacity)
                            .offset(x: subtitleOffset)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    VStack(spacing: 0) {
                        // Loading state
                        if reverseGeocoder.isLoading && selectedLocation.isEmpty {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(0.9)
                                Text("Finding your location...")
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .opacity(textFieldOpacity)
                        }

                        // Search Field
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(charcoalColor.opacity(0.5))

                            TextField("Search for a city", text: Binding(
                                get: { searchCompleter.searchQuery },
                                set: { searchCompleter.search(query: $0) }
                            ))
                            .font(.system(size: 17))
                            .foregroundColor(charcoalColor)
                            .focused($isTextFieldFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)

                            if !searchCompleter.searchQuery.isEmpty {
                                Button(action: {
                                    searchCompleter.search(query: "")
                                    selectedLocation = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(charcoalColor.opacity(0.3))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isTextFieldFocused ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                        )
                        .padding(.horizontal, 24)
                        .opacity(textFieldOpacity)
                        .offset(y: textFieldOffset)

                        // Selected Location Display
                        if !selectedLocation.isEmpty && searchCompleter.completions.isEmpty && !searchCompleter.isSearching {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(burntOrange)

                                Text(selectedLocation)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor)

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(burntOrange)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(burntOrange.opacity(0.1))
                            )
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Autocomplete Results
                        if !searchCompleter.completions.isEmpty {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(searchCompleter.completions, id: \.self) { completion in
                                        Button(action: {
                                            selectLocation(completion)
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "mappin.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(burntOrange.opacity(0.6))

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(completion.title)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(charcoalColor)
                                                        .lineLimit(1)
                                                        .frame(maxWidth: .infinity, alignment: .leading)

                                                    if !completion.subtitle.isEmpty {
                                                        Text(completion.subtitle)
                                                            .font(.system(size: 14))
                                                            .foregroundColor(charcoalColor.opacity(0.6))
                                                            .lineLimit(1)
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                    }
                                                }

                                                Spacer(minLength: 0)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        if completion != searchCompleter.completions.last {
                                            Divider()
                                                .padding(.leading, 48)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            }
                            .frame(maxHeight: 300)
                        }
                    }

                    Spacer()

                    Button(action: {
                        saveAndContinue()
                    }) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(canContinue ? burntOrange : Color.gray.opacity(0.3))
                    .clipShape(Capsule())
                    .disabled(!canContinue || isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Fetch current location and reverse geocode
            reverseGeocoder.fetchCurrentCity()

            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1
                titleOffset = 0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                subtitleOpacity = 1
                subtitleOffset = 0
            }

            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                textFieldOpacity = 1
                textFieldOffset = 0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
        .onChange(of: reverseGeocoder.cityName) { _, newValue in
            // Pre-fill the selected location when reverse geocoding completes
            if let city = newValue, selectedLocation.isEmpty {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedLocation = city
                }
            }
        }
    }

    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        let locationString = completion.subtitle.isEmpty
            ? completion.title
            : "\(completion.title), \(completion.subtitle)"

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedLocation = locationString
            searchCompleter.search(query: "")
        }
        isTextFieldFocused = false
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveAndContinue() {
        isSaving = true
        Task {
            do {
                try await profileManager.updateProfile(
                    ProfileUpdateRequest(location: selectedLocation)
                )
            } catch {
                print("Failed to save location: \(error)")
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }
}

#Preview {
    HometownScreen {
        print("Continue tapped")
    }
}
