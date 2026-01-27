//
//  CreateActivitySheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct CreateActivitySheet: View {
    @Environment(\.dismiss) var dismiss
    /// When non-nil, the sheet is in edit mode: pre-filled and shows "Update" instead of "Create Activity".
    var existingActivity: Activity? = nil
    let onSubmit: (ActivityData) -> Void
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = ""
    @State private var location: String = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var date: Date = Date()
    @State private var time: Date = Date()
    @State private var maxAttendees: String = ""
    @State private var coverImage: UIImage? = nil
    @State private var privacy: PrivacySetting = .public
    @State private var requireApproval: Bool = false
    @State private var showPrivacyDetails: Bool = false
    @State private var showLocationPicker: Bool = false
    
    private var isEditMode: Bool { existingActivity != nil }
    private let categories = ["Outdoor", "Work", "Social", "Food & Drink", "Creative", "Wellness"]
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    
    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !category.isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty &&
        !maxAttendees.isEmpty &&
        Int(maxAttendees) ?? 0 >= 2
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                warmWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    scrollableContent
                    sheetFooter
                }
            }
            .navigationTitle(isEditMode ? "Edit Activity" : "Create Activity")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { prefillIfEditing() }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(charcoalColor)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerSheet(
                    locationName: $location,
                    latitude: $latitude,
                    longitude: $longitude
                )
            }
        }
    }
    
    private var scrollableContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                                // Activity Title
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Activity Title *")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                    
                                    TextField("e.g., Sunrise Hike", text: $title)
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                )
                                        )
                                }
                                .padding(.horizontal, 24)
                                
                                // Description
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 14))
                                            .foregroundColor(charcoalColor)
                                        Text("Description")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(charcoalColor)
                                    }
                                    
                                    TextField("What's the plan?", text: $description, axis: .vertical)
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                        .lineLimit(3...6)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                )
                                        )
                                }
                                .padding(.horizontal, 24)
                                
                                // Category
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category *")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 8),
                                        GridItem(.flexible(), spacing: 8),
                                        GridItem(.flexible(), spacing: 8)
                                    ], spacing: 8) {
                                        ForEach(categories, id: \.self) { cat in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                                    category = cat
                                                }
                                            }) {
                                                Text(cat)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(category == cat ? burntOrange : charcoalColor)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .background(
                                                        Capsule()
                                                            .fill(category == cat ? burntOrange.opacity(0.05) : Color.white)
                                                            .overlay(
                                                                Capsule()
                                                                    .stroke(category == cat ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                                                            )
                                                    )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                // Location
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "mappin")
                                            .font(.system(size: 14))
                                            .foregroundColor(charcoalColor)
                                        Text("Location *")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(charcoalColor)
                                    }

                                    Button {
                                        showLocationPicker = true
                                    } label: {
                                        HStack {
                                            if location.isEmpty {
                                                Text("Select location on map")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(charcoalColor.opacity(0.4))
                                            } else {
                                                Text(location)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(charcoalColor)
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                            Image(systemName: "map")
                                                .font(.system(size: 16))
                                                .foregroundColor(burntOrange)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(latitude != nil ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                                                )
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                // Date & Time
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 14))
                                                .foregroundColor(charcoalColor)
                                            Text("Date *")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(charcoalColor)
                                        }
                                        
                                        DatePicker("", selection: $date, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 14))
                                                .foregroundColor(charcoalColor)
                                            Text("Time *")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(charcoalColor)
                                        }
                                        
                                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 24)
                                
                                // Max Attendees
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.2")
                                            .font(.system(size: 14))
                                            .foregroundColor(charcoalColor)
                                        Text("Max Attendees *")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(charcoalColor)
                                    }
                                    
                                    TextField("e.g., 10", text: $maxAttendees)
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                        .keyboardType(.numberPad)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                )
                                        )
                                }
                                .padding(.horizontal, 24)
                                
                                privacySettingsSection
                            }
                            .padding(.bottom, 24)
                        }
    }
    
    private var sheetFooter: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: handleSubmit) {
                Text(isEditMode ? "Update" : "Create Activity")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canSubmit ? burntOrange : Color.gray.opacity(0.3))
                    .clipShape(Capsule())
            }
            .disabled(!canSubmit)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(warmWhite)
    }
    
    private var privacySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lock")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor)
                    Text("Privacy Settings")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showPrivacyDetails.toggle()
                    }
                }) {
                    Text(showPrivacyDetails ? "Hide" : "Learn more")
                        .font(.system(size: 14))
                        .foregroundColor(burntOrange)
                }
            }
            
            VStack(spacing: 12) {
                PrivacyOption(
                    icon: "globe",
                    iconColor: forestGreen,
                    title: "Public",
                    description: "Anyone can see and join",
                    isSelected: privacy == .public,
                    onTap: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            privacy = .public
                        }
                    }
                )
                
                PrivacyOption(
                    icon: "person.2",
                    iconColor: burntOrange,
                    title: "Friends Only",
                    description: "Only your connections can see",
                    isSelected: privacy == .friends,
                    onTap: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            privacy = .friends
                        }
                    }
                )
                
                PrivacyOption(
                    icon: "lock",
                    iconColor: charcoalColor,
                    title: "Private",
                    description: "Invite only",
                    isSelected: privacy == .private,
                    onTap: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            privacy = .private
                        }
                    }
                )
            }
            
            // Require Approval Toggle
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.checkmark")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    Text("Require approval to join")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor)
                }
                
                Spacer()
                
                Toggle("", isOn: $requireApproval)
                    .toggleStyle(SwitchToggleStyle(tint: forestGreen))
            }
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Privacy Details
            if showPrivacyDetails {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(skyBlue)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Public:** Your activity appears in the main feed and can be discovered by all Drift users.")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.7))
                            
                            Text("**Friends Only:** Only visible to people you've connected with on Drift.")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.7))
                            
                            Text("**Private:** You manually invite specific people. Activity won't appear in any feeds.")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.7))
                        }
                    }
                }
                .padding(12)
                .background(skyBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                )
        )
        .padding(.horizontal, 24)
    }
    
    private func prefillIfEditing() {
        guard let a = existingActivity else { return }
        title = a.title
        description = a.description ?? ""
        category = a.category.displayName
        location = a.location
        let cal = Calendar.current
        date = cal.startOfDay(for: a.startsAt)
        time = a.startsAt
        maxAttendees = String(a.maxAttendees)
        privacy = a.isPrivate ? .private : .public
    }

    private func handleSubmit() {
        if canSubmit {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            let activityData = ActivityData(
                activityId: existingActivity?.id,
                title: title,
                description: description,
                category: category,
                location: location,
                latitude: latitude,
                longitude: longitude,
                date: dateFormatter.string(from: date),
                time: timeFormatter.string(from: time),
                maxAttendees: Int(maxAttendees) ?? 0,
                coverImage: coverImage,
                privacy: privacy,
                requireApproval: requireApproval
            )

            onSubmit(activityData)
            dismiss()
        }
    }
}

enum PrivacySetting {
    case `public`
    case friends
    case `private`
}

struct ActivityData {
    /// When non-nil, the submit is an update for this activity; otherwise create.
    var activityId: UUID? = nil
    let title: String
    let description: String
    let category: String
    let location: String
    let latitude: Double?
    let longitude: Double?
    let date: String
    let time: String
    let maxAttendees: Int
    let coverImage: UIImage?
    let privacy: PrivacySetting
    let requireApproval: Bool
}

struct PrivacyOption: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(charcoalColor)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(burntOrange)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? burntOrange.opacity(0.05) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateActivitySheet { activityData in
        print("Activity created: \(activityData.title)")
    }
}
