//
//  CommunityEventCard.swift
//  Drift
//
//  Created by Casey Millstein on 2/4/26.
//

import SwiftUI
import DriftBackend

struct CommunityEventCard: View {
    let event: CommunityPost
    var onTap: (() -> Void)? = nil

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")

    /// Get the first image from the event, or nil
    private var eventImageUrl: String? {
        event.images.first
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Large image
            if let imageUrl = eventImageUrl {
                CachedAsyncImage(url: URL(string: imageUrl), targetSize: CGSize(width: 280, height: 320)) { phase in
                    switch phase {
                    case .empty:
                        placeholderGradient
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderGradient
                    @unknown default:
                        placeholderGradient
                    }
                }
                .frame(width: 280, height: 320)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                placeholderGradient
                    .frame(width: 280, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            // Dating tag (top right)
            if event.isDatingEvent == true {
                Text("Dating")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(burntOrange.opacity(0.85))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(12)
            }

            // Bottom pill with event info
            HStack(spacing: 12) {
                // Host avatar
                CachedAsyncImage(url: URL(string: event.author?.primaryDisplayPhotoUrl ?? ""), targetSize: CGSize(width: 40, height: 40)) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            )
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                // Event name and date
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(charcoalColor)
                        .lineLimit(1)

                    if let formattedDate = event.formattedEventDate {
                        Text(formattedDate)
                            .font(.system(size: 11))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(charcoalColor.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 280, height: 320)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    @ViewBuilder
    private var placeholderGradient: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    burntOrange,
                    burntOrange.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "calendar")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    CommunityEventCard(
        event: CommunityPost(
            authorId: UUID(),
            type: .event,
            title: "Sunrise Hike at Big Sur",
            content: "Join us for an amazing hike!",
            images: ["https://images.unsplash.com/photo-1603741614953-4187ed84cc50?w=800"],
            eventDatetime: Date().addingTimeInterval(86400),
            eventLocation: "Big Sur, CA",
            maxAttendees: 8,
            currentAttendees: 4,
            author: UserProfile(
                id: UUID(),
                name: "Casey",
                age: 28,
                bio: "Van life",
                avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                photos: [],
                location: "CA",
                verified: true,
                lifestyle: .vanLife,
                interests: [],
                lookingFor: .friends,
                promptAnswers: []
            )
        )
    )
    .padding()
}
