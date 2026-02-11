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
    @State private var viewMode: ActivityViewMode = .list
    @State private var segmentIndex: Int = 0
    @State private var selectedActivity: Activity? = nil
    @StateObject private var activityManager = ActivityManager.shared
    @State private var lastDataFetch: Date = .distantPast

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

    private func loadActivities(force: Bool = false) {
        guard force || Date().timeIntervalSince(lastDataFetch) > 30 else { return }
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
                lastDataFetch = Date()
            } catch {
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
                    loadActivities(force: true)
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
                    Task {
                        do {
                            let category: ActivityCategory = {
                                switch activityData.category {
                                case "Outdoor": return .outdoor
                                case "Work": return .work
                                case "Social": return .social
                                case "Food & Drink": return .foodDrink
                                case "Wellness": return .wellness
                                case "Adventure": return .adventure
                                default: return .social
                                }
                            }()

                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let timeFormatter = DateFormatter()
                            timeFormatter.dateFormat = "HH:mm"
                            let dateOnly = dateFormatter.date(from: activityData.date)
                            let timeOnly = timeFormatter.date(from: activityData.time)
                            let startsAt: Date = {
                                guard let d = dateOnly, let t = timeOnly else { return Date() }
                                let cal = Calendar.current
                                var comps = cal.dateComponents([.year, .month, .day], from: d)
                                let tc = cal.dateComponents([.hour, .minute], from: t)
                                comps.hour = tc.hour
                                comps.minute = tc.minute
                                return cal.date(from: comps) ?? Date()
                            }()

                            if let activityId = activityData.activityId {
                                try await activityManager.updateActivity(
                                    activityId,
                                    title: activityData.title,
                                    description: activityData.description.isEmpty ? nil : activityData.description,
                                    category: category,
                                    location: activityData.location,
                                    startsAt: startsAt,
                                    maxAttendees: activityData.maxAttendees,
                                    isPrivate: activityData.privacy == .private
                                )
                            } else {
                                try await activityManager.createActivity(
                                    title: activityData.title,
                                    description: activityData.description.isEmpty ? nil : activityData.description,
                                    category: category,
                                    location: activityData.location,
                                    startsAt: startsAt,
                                    maxAttendees: activityData.maxAttendees,
                                    imageUrl: nil,
                                    isPrivate: activityData.privacy == .private
                                )
                            }
                        } catch {
                        }
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailSheet(activity: activity) {
                    Task {
                        try? await activityManager.fetchActivities()
                        try? await activityManager.fetchMyActivities()
                    }
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
