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

enum ActivityView {
    case list
    case map
}

struct ActivitiesScreen: View {
    @State private var showCreateSheet = false
    @State private var view: ActivityView = .list
    @State private var segmentIndex: Int = 0
    
    private var segmentOptions: [SegmentOption] {
        [
            SegmentOption(
                id: 0,
                title: "List",
                icon: "list.bullet",
                activeColor: burntOrange
            ),
            SegmentOption(
                id: 1,
                title: "Map",
                icon: "map",
                activeColor: burntOrange
            )
        ]
    }
    
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
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    
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
            
            VStack(spacing: 0) {
                // Sticky Header with Toggle
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Activities")
                                .font(.system(size: 24, weight: .bold))
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
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(burntOrange)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // List/Map Toggle
                    SegmentToggle(
                        options: segmentOptions,
                        selectedIndex: Binding(
                            get: { segmentIndex },
                            set: { newIndex in
                                segmentIndex = newIndex
                                view = newIndex == 0 ? .list : .map
                            }
                        )
                    )
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(softGray)
                
                // Content
                .onChange(of: view) { _ in
                    segmentIndex = view == .list ? 0 : 1
                }
                .onAppear {
                    segmentIndex = view == .list ? 0 : 1
                }
                
                if view == .map {
                    MapScreen(embedded: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Category Filters
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
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                            
                            // Activities List
                            VStack(spacing: 16) {
                                ForEach(filteredActivities) { activity in
                                    ActivityCard(activity: activity)
                                        .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
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

#Preview {
    ActivitiesScreen()
}
