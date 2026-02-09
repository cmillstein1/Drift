//
//  LocationSearchField.swift
//  Drift
//
//  Reusable location text field with MKLocalSearchCompleter autocomplete
//

import SwiftUI
import MapKit
import Combine

struct LocationSearchField: View {
    @Binding var locationName: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?

    @StateObject private var completer = TravelLocationSearchCompleter()
    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool

    private let charcoal = Color("Charcoal")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle")
                    .font(.system(size: 20))
                    .foregroundColor(charcoal.opacity(0.4))

                TextField("Where are you going?", text: $locationName)
                    .font(.system(size: 16))
                    .foregroundColor(charcoal)
                    .focused($isFocused)
                    .onChange(of: locationName) { _, newValue in
                        completer.search(query: newValue)
                        showSuggestions = !newValue.isEmpty && isFocused
                    }

                if !locationName.isEmpty {
                    Button {
                        locationName = ""
                        latitude = nil
                        longitude = nil
                        completer.results = []
                        showSuggestions = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(charcoal.opacity(0.4))
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if showSuggestions && !completer.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(completer.results.prefix(5), id: \.self) { completion in
                        Button {
                            selectCompletion(completion)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(charcoal.opacity(0.4))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(charcoal)
                                        .lineLimit(1)

                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.system(size: 13))
                                            .foregroundColor(charcoal.opacity(0.6))
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }

                        if completion != completer.results.prefix(5).last {
                            Divider()
                                .padding(.leading, 46)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.top, 4)
            }
        }
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            guard let mapItem = response?.mapItems.first else { return }

            let displayName: String
            if !completion.subtitle.isEmpty {
                displayName = "\(completion.title), \(completion.subtitle)"
            } else {
                displayName = completion.title
            }

            locationName = displayName
            latitude = mapItem.placemark.coordinate.latitude
            longitude = mapItem.placemark.coordinate.longitude
            showSuggestions = false
            isFocused = false
        }
    }
}

// MARK: - Search Completer

class TravelLocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func search(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Silently handle - user can still type manually
    }
}
