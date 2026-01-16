//
//  ActivitiesScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct Activity: Identifiable {
    let id: Int
    let title: String
    let location: String
    let date: String
    let attendees: Int
    let maxAttendees: Int
    let host: String
    let category: String
    let imageURL: String
}

struct ActivitiesScreen: View {
    @State private var showCreateSheet = false
    @State private var activities: [Activity] = [
        Activity(
            id: 1,
            title: "Sunrise Hike",
            location: "Big Sur Trail",
            date: "Tomorrow, 6:00 AM",
            attendees: 4,
            maxAttendees: 8,
            host: "Sarah",
            category: "Outdoor",
            imageURL: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb3VudGFpbiUyMGhpa2luZyUyMGFkdmVudHVyZXxlbnwxfHx8fDE3NjgzODg4MDN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
        ),
        Activity(
            id: 2,
            title: "Beach Coworking",
            location: "Carmel Beach",
            date: "Today, 10:00 AM",
            attendees: 3,
            maxAttendees: 6,
            host: "Marcus",
            category: "Work",
            imageURL: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaWdpdGFsJTIwbm9tYWQlMjBiZWFjaHxlbnwxfHx8fDE3Njg1MDYwNTJ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
        ),
        Activity(
            id: 3,
            title: "Campfire Stories",
            location: "Pfeiffer Campground",
            date: "Friday, 7:00 PM",
            attendees: 7,
            maxAttendees: 12,
            host: "Luna",
            category: "Social",
            imageURL: "https://images.unsplash.com/photo-1533088339408-74fcf62b8e6a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYW1wZmlyZSUyMGZyaWVuZHN8ZW58MXx8fHwxNzY4NTA2MDUzfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
        ),
        Activity(
            id: 4,
            title: "Morning Surf Session",
            location: "Mavericks Beach",
            date: "Saturday, 7:30 AM",
            attendees: 2,
            maxAttendees: 5,
            host: "Jake",
            category: "Outdoor",
            imageURL: "https://images.unsplash.com/photo-1723301205328-1079fe589f97?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdXJmaW5nJTIwb2NlYW58ZW58MXx8fHwxNzY4NDY2NTI0fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
        )
    ]
    
    @State private var selectedCategory: String = "All"
    
    private let categories = ["All", "Outdoor", "Work", "Social", "Food & Drink"]
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
    var filteredActivities: [Activity] {
        if selectedCategory == "All" {
            return activities
        }
        return activities.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Activities")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            Text("Join or create meetups")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showCreateSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(burntOrange)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                CategoryButton(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)
                    
                    VStack(spacing: 16) {
                        ForEach(filteredActivities) { activity in
                            ActivityCard(activity: activity)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            
            // Create Activity Sheet
            .sheet(isPresented: $showCreateSheet) {
                CreateActivitySheet { activityData in
                    // Handle activity creation
                    let newActivity = Activity(
                        id: activities.count + 1,
                        title: activityData.title,
                        location: activityData.location,
                        date: "\(activityData.date) \(activityData.time)",
                        attendees: 0,
                        maxAttendees: activityData.maxAttendees,
                        host: "You",
                        category: activityData.category,
                        imageURL: "" // You can add image URL handling here
                    )
                    activities.insert(newActivity, at: 0)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : charcoalColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? charcoalColor : Color.white)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityCard: View {
    let activity: Activity
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: activity.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                }
                .frame(height: 160)
                .clipped()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                
                Text(activity.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(charcoalColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                            .background(.ultraThinMaterial)
                    )
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(activity.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        Text(activity.location)
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        Text(activity.date)
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        Text("\(activity.attendees)/\(activity.maxAttendees) going")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                }
                
                HStack {
                    HStack(spacing: 0) {
                        Text("Hosted by ")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        Text(activity.host)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(burntOrange)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Handle join
                    }) {
                        Text("Join")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(forestGreen)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ActivitiesScreen()
}
