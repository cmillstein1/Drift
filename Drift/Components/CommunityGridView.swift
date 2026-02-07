//
//  CommunityGridView.swift
//  Drift
//
//  Created by Casey Millstein on 2/4/26.
//

import SwiftUI
import DriftBackend

struct CommunityGridView: View {
    let profiles: [UserProfile]
    let events: [CommunityPost]
    let distanceMiles: (UserProfile) -> Int?
    /// When set, each card shows these interest names (e.g. shared interests). When nil, cards use profile.interests.
    var sharedInterests: ((UserProfile) -> [String])? = nil
    /// Top spacing for overlay header. Use smaller value (e.g. 60) when no mode switcher is shown.
    var topSpacing: CGFloat = 120
    /// When true, shows a loading placeholder instead of the "No travelers nearby" empty state.
    var isLoading: Bool = false
    let onSelectProfile: (UserProfile) -> Void
    let onSelectEvent: (CommunityPost) -> Void
    let onConnect: (UUID) -> Void

    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)

    var body: some View {
        if isLoading && profiles.isEmpty {
            // Show soft loading state instead of "No travelers nearby" during initial fetch
            ZStack {
                softGray.ignoresSafeArea()
                ProgressView()
                    .tint(Color.gray.opacity(0.5))
                    .scaleEffect(1.1)
            }
        } else if profiles.isEmpty && events.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Top spacing for overlay header
                    Color.clear.frame(height: topSpacing)

                    // Events Section (horizontal scroll) - always show
                    eventsSection

                    // Nearby Friends Section
                    nearbyFriendsSection
                }
                .padding(.bottom, 100) // Space for tab bar
            }
            .background(softGray)
        }
    }

    // MARK: - Events Section

    @ViewBuilder
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("Upcoming Events")
                .font(.campfire(.regular, size: 20))
                .foregroundColor(charcoalColor)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if events.isEmpty {
                // Empty state placeholder
                emptyEventsPlaceholder
            } else {
                // Horizontal scroll of event cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(events) { event in
                            CommunityEventCard(
                                event: event,
                                onTap: { onSelectEvent(event) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var emptyEventsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(inkSub.opacity(0.4))

            Text("No upcoming events nearby")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(inkSub)

            Text("Create an activity to meet other travelers!")
                .font(.system(size: 12))
                .foregroundColor(inkSub.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    // MARK: - Nearby Friends Section

    @ViewBuilder
    private var nearbyFriendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("Nearby Friends")
                //.font(.system(size: 20, weight: .bold))
                .font(.campfire(.regular, size: 20))
                .foregroundColor(charcoalColor)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Profile grid
            if profiles.isEmpty {
                noFriendsPlaceholder
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(profiles) { profile in
                        CommunityProfileGridCard(
                            profile: profile,
                            distanceMiles: distanceMiles(profile),
                            displayInterests: sharedInterests?(profile),
                            onTap: { onSelectProfile(profile) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private var noFriendsPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3")
                .font(.system(size: 32))
                .foregroundColor(inkSub.opacity(0.5))
            Text("No travelers nearby yet")
                .font(.system(size: 14))
                .foregroundColor(inkSub)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 48))
                .foregroundColor(inkSub)
            Text("No travelers nearby")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(inkSub)
            Text("Check back soon or expand your search area")
                .font(.system(size: 14))
                .foregroundColor(inkSub.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(softGray)
    }
}

#Preview {
    CommunityGridView(
        profiles: [
            UserProfile(
                id: UUID(),
                name: "Sarah",
                age: 28,
                bio: "Van-lifer",
                avatarUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
                photos: ["https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800"],
                location: "Big Sur, CA",
                verified: true,
                lifestyle: .vanLife,
                interests: ["Van Life", "Photography"],
                lookingFor: .friends,
                promptAnswers: []
            ),
            UserProfile(
                id: UUID(),
                name: "Marcus",
                age: 31,
                bio: "RV Life",
                avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                photos: ["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800"],
                location: "Yellowstone, WY",
                verified: true,
                lifestyle: .rvLife,
                interests: ["Coding", "Dogs"],
                lookingFor: .friends,
                promptAnswers: []
            )
        ],
        events: [
            CommunityPost(
                authorId: UUID(),
                type: .event,
                title: "Sunrise Hike",
                content: "Join us for an early morning hike!",
                images: ["https://images.unsplash.com/photo-1603741614953-4187ed84cc50?w=800"],
                eventDatetime: Date().addingTimeInterval(86400),
                eventLocation: "Big Sur Trail",
                maxAttendees: 8,
                currentAttendees: 4
            ),
            CommunityPost(
                authorId: UUID(),
                type: .event,
                title: "Coffee & Code",
                content: "Work together at a local cafe",
                eventDatetime: Date().addingTimeInterval(172800),
                eventLocation: "Local Cafe",
                maxAttendees: 6,
                currentAttendees: 2
            )
        ],
        distanceMiles: { _ in 12 },
        onSelectProfile: { _ in },
        onSelectEvent: { _ in },
        onConnect: { _ in }
    )
}
