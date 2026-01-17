//
//  ActivityDetailSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct Attendee: Identifiable {
    let id: Int
    let name: String
    let avatar: String
}

struct ActivityDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let activity: Activity
    @State private var isJoined: Bool = false
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    // Mock attendees data
    private let mockAttendees: [Attendee] = [
        Attendee(id: 1, name: "Sarah M.", avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop"),
        Attendee(id: 2, name: "Marcus T.", avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop"),
        Attendee(id: 3, name: "Luna K.", avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop"),
        Attendee(id: 4, name: "Jake R.", avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop")
    ]
    
    var displayedAttendees: [Attendee] {
        Array(mockAttendees.prefix(activity.attendees))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Image Section
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: activity.imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Color.gray.opacity(0.2)
                                ProgressView()
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                        @unknown default:
                            EmptyView()
                        }
                }
                .frame(height: 256)
                .clipped()
                
                // Gradient Overlay
                LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                )
                .frame(height: 256)
                
                // Header Controls
                HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(charcoalColor)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            handleShare()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(charcoalColor)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Title Overlay
                VStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Text("Hosted by")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                Text(activity.host)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .frame(height: 256)
            
            // Content ScrollView
            ScrollView {
                VStack(spacing: 0) {
                        // Key Info Cards
                        HStack(spacing: 12) {
                            // Date & Time Card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                    Text("Date & Time")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                                
                                Text(activity.date)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                Text(activity.time ?? "2 hours")
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(softGray)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Attendees Card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                    Text("Attendees")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                                
                                Text("\(activity.attendees)/\(activity.maxAttendees) joined")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                // Progress Bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white)
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [forestGreen, skyBlue]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(
                                                width: geometry.size.width * CGFloat(activity.attendees) / CGFloat(activity.maxAttendees),
                                                height: 6
                                            )
                                    }
                                }
                                .frame(height: 6)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(softGray)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                        
                        // Location Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "mappin")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Location")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                Spacer()
                                
                                Text(activity.category)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(12)
                                    )
                            }
                            
                            Text(activity.location)
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor)
                            
                            Text(activity.exactLocation ?? "Exact location shared after joining")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(softGray)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About This Activity")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(charcoalColor)
                            
                            Text(activity.description ?? "Join us for an amazing experience! This is a great opportunity to meet fellow travelers and create unforgettable memories. All skill levels welcome. Don't forget to bring water and good vibes!")
                                .font(.system(size: 15))
                                .foregroundColor(charcoalColor.opacity(0.7))
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Attendees Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Who's Going")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                Spacer()
                                
                                Text("\(activity.attendees) \(activity.attendees == 1 ? "person" : "people")")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(displayedAttendees) { attendee in
                                        HStack(spacing: 8) {
                                            AsyncImage(url: URL(string: attendee.avatar)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 32, height: 32)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                case .failure:
                                                    Image(systemName: "person.circle.fill")
                                                        .foregroundColor(.gray)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                            
                                            Text(attendee.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(charcoalColor)
                                            
                                            if attendee.id == 1 {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(forestGreen)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(softGray)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100) // Space for bottom action bar
                }
            }
            
            // Bottom Action Bar
            VStack(spacing: 0) {
                Divider()
                    .background(Color.gray.opacity(0.2))
                
                HStack(spacing: 12) {
                        Button(action: {
                            handleMessage()
                        }) {
                            Image(systemName: "message")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(burntOrange)
                                .frame(width: 48, height: 48)
                                .background(Color.clear)
                                .overlay(
                                    Circle()
                                        .stroke(burntOrange, lineWidth: 2)
                                )
                        }
                        
                        Button(action: {
                            handleJoin()
                        }) {
                            Text(isJoined ? "Joined ✓" : "Join Activity")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    isJoined
                                        ? LinearGradient(
                                            gradient: Gradient(colors: [charcoalColor, charcoalColor.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        : LinearGradient(
                                            gradient: Gradient(colors: [forestGreen, skyBlue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                )
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .background(Color.white)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func handleJoin() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isJoined.toggle()
        }
    }
    
    private func handleShare() {
        // Share functionality
        print("Share activity")
    }
    
    private func handleMessage() {
        // Message host functionality
        print("Message host")
    }
}

#Preview {
    ActivityDetailSheet(
        activity: Activity(
            id: 1,
            title: "Sunrise Hike",
            location: "Big Sur Trail",
            date: "Tomorrow, 6:00 AM",
            attendees: 4,
            maxAttendees: 8,
            host: "Sarah",
            category: "Outdoor",
            imageURL: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb3VudGFpbiUyMGhpa2luZyUyMGFkdmVudHVyZXxlbnwxfHx8fDE3NjgzODg4MDN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
            description: "Join us for an amazing sunrise hike! This is a great opportunity to meet fellow travelers and create unforgettable memories. All skill levels welcome. Don't forget to bring water and good vibes!",
            time: "2 hours",
            exactLocation: "Trailhead parking lot"
        )
    )
}
