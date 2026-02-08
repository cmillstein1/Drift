//
//  AllEventsSheet.swift
//  Drift
//
//  Created by Claude on 2/7/26.
//

import SwiftUI
import DriftBackend

struct AllEventsSheet: View {
    let events: [CommunityPost]
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedEvent: CommunityPost? = nil

    private let categories = ["All", "Community", "Dating"]
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")

    private var filteredEvents: [CommunityPost] {
        var result = events
        if selectedCategory == "Dating" {
            result = result.filter { $0.isDatingEvent == true }
        } else if selectedCategory == "Community" {
            result = result.filter { $0.isDatingEvent != true }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                ($0.eventLocation ?? "").localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()

            VStack(spacing: 0) {
                // Search + filters header
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.4))
                        TextField("Search events...", text: $searchQuery)
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(searchQuery.isEmpty ? Color.gray.opacity(0.2) : burntOrange, lineWidth: 2)
                            )
                    )

                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedCategory == category ? .white : charcoalColor)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == category ? burntOrange : Color.white)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(selectedCategory == category ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .bottom
                )

                // Events list
                if filteredEvents.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(charcoalColor.opacity(0.3))
                        Text("No events found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.5))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEvents) { event in
                                eventRow(event)
                                    .onTapGesture {
                                        selectedEvent = event
                                    }
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("All Events")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(initialPost: event)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private func eventRow(_ event: CommunityPost) -> some View {
        HStack(spacing: 14) {
            // Event image thumbnail
            if let imageUrl = event.images.first, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(burntOrange.opacity(0.2))
                            .overlay(
                                Image(systemName: "calendar")
                                    .foregroundColor(burntOrange.opacity(0.5))
                            )
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(burntOrange.opacity(0.2))
                            .overlay(
                                Image(systemName: "calendar")
                                    .foregroundColor(burntOrange.opacity(0.5))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(burntOrange.opacity(0.2))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 24))
                            .foregroundColor(burntOrange.opacity(0.5))
                    )
            }

            // Event info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoalColor)
                    .lineLimit(1)

                if let date = event.formattedEventDate {
                    Text(date)
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }

                if let location = event.eventLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                        Text(location)
                            .lineLimit(1)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.5))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(charcoalColor.opacity(0.3))
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
