//
//  ActivitiesScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

enum ActivityViewMode {
    case list
    case map
}

struct ActivitiesScreen: View {
    @State private var showCreateSheet = false
    @State private var showPaywall = false
    @State private var viewMode: ActivityViewMode = .list
    @State private var segmentIndex: Int = 0
    @State private var selectedActivity: Activity? = nil
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @StateObject private var activityManager = ActivityManager.shared

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

    private var activities: [Activity] {
        activityManager.activities
    }

    @State private var selectedCategory: String = "All"

    private let categories = ["All", "Outdoor", "Work", "Social", "Food & Drink"]

    private func loadActivities() {
        Task {
            do {
                let category: ActivityCategory? = {
                    switch selectedCategory {
                    case "Outdoor": return .outdoor
                    case "Work": return .work
                    case "Social": return .social
                    case "Food & Drink": return .foodDrink
                    default: return nil
                    }
                }()
                try await activityManager.fetchActivities(category: category)
                await activityManager.subscribeToActivities()
            } catch {
                print("Failed to load activities: \(error)")
            }
        }
    }
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    
    var filteredActivities: [Activity] {
        if selectedCategory == "All" {
            return activities
        }
        let category: ActivityCategory? = {
            switch selectedCategory {
            case "Outdoor": return .outdoor
            case "Work": return .work
            case "Social": return .social
            case "Food & Drink": return .foodDrink
            default: return nil
            }
        }()
        guard let category = category else { return activities }
        return activities.filter { $0.category == category }
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
                            if revenueCatManager.hasProAccess {
                                showCreateSheet = true
                            } else {
                                showPaywall = true
                            }
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
                                viewMode = newIndex == 0 ? .list : .map
                            }
                        )
                    )
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(softGray)
                
                // Content
                .onChange(of: viewMode) { _ in
                    segmentIndex = viewMode == .list ? 0 : 1
                }
                .onAppear {
                    segmentIndex = viewMode == .list ? 0 : 1
                    loadActivities()
                }
                .onChange(of: selectedCategory) { _ in
                    loadActivities()
                }

                if viewMode == .map {
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
                                    ActivityCard(activity: activity) {
                                        selectedActivity = activity
                                    }
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
                    // Handle activity creation via backend
                    Task {
                        do {
                            let category: ActivityCategory = {
                                switch activityData.category {
                                case "Outdoor": return .outdoor
                                case "Work": return .work
                                case "Social": return .social
                                case "Food & Drink": return .foodDrink
                                default: return .social
                                }
                            }()

                            // Parse date and time
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
                            let startsAt = dateFormatter.date(from: "\(activityData.date) \(activityData.time)") ?? Date()

                            try await activityManager.createActivity(
                                title: activityData.title,
                                description: nil,
                                category: category,
                                location: activityData.location,
                                startsAt: startsAt,
                                maxAttendees: activityData.maxAttendees,
                                imageUrl: nil
                            )
                        } catch {
                            print("Failed to create activity: \(error)")
                        }
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallScreen(isOpen: $showPaywall, source: .createActivity)
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailSheet(activity: activity)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    ActivitiesScreen()
}
