//
//  EditProfileSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import PhotosUI
import DriftBackend

struct TravelStop: Identifiable {
    var id: String
    var location: String
    var startDate: String
    var endDate: String
}

struct EditProfileSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared

    @State private var name: String = ""
    @State private var currentLocation: String = ""
    @State private var about: String = ""
    @State private var simplePleasure: String = ""
    @State private var rigInfo: String = ""
    @State private var datingLooksLike: String = ""
    @State private var promptAnswers: [DriftBackend.PromptAnswer] = []
    @State private var travelPace: TravelPaceOption = .slow
    @State private var travelSchedule: [TravelStop] = []
    @State private var isSaving = false

    // Image upload states
    @State private var photos: [String] = []
    @State private var photoImages: [Int: Image] = [:] // Index -> preview image
    @State private var selectedPhotoIndex: Int?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto: Int? = nil
    @State private var uploadError: String?
    @State private var showUploadError = false

    @State private var showDatePicker = false
    @State private var selectedDateStopId: String = ""
    @State private var selectedDateField: DateFieldType?
    @State private var selectedDate: Date = Date()
    
    // Dating preferences states
    @State private var interestedIn: InterestedIn = .everyone
    @State private var maxDistance: Double = 50
    @State private var minAge: Double = 18
    @State private var maxAge: Double = 50
    @State private var showInterestedInModal: Bool = false
    
    // Collapsible section states - all collapsed by default
    @State private var expandedSections: [SectionType: Bool] = [
        .basics: false,
        .about: false,
        .dating: false,
        .travel: false
    ]
    
    enum SectionType {
        case basics, about, dating, travel
    }

    enum DateFieldType {
        case startDate
        case endDate
    }

    enum TravelPaceOption: String, CaseIterable {
        case slow = "slow"
        case moderate = "moderate"
        case fast = "fast"

        var label: String {
            switch self {
            case .slow: return "Slow Traveler"
            case .moderate: return "Moderate Pace"
            case .fast: return "Fast Mover"
            }
        }

        var description: String {
            switch self {
            case .slow: return "Months in each location"
            case .moderate: return "Weeks in each location"
            case .fast: return "Days in each location"
            }
        }

        var toBackendType: TravelPace {
            switch self {
            case .slow: return .slow
            case .moderate: return .moderate
            case .fast: return .fast
            }
        }

        static func from(_ backendPace: TravelPace?) -> TravelPaceOption {
            guard let pace = backendPace else { return .slow }
            switch pace {
            case .slow: return .slow
            case .moderate: return .moderate
            case .fast: return .fast
            }
        }
    }
    
    // Computed property to check if any section is expanded
    private var hasExpandedSection: Bool {
        expandedSections.values.contains(true)
    }

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)
    
    private var showDatingSection: Bool {
        // Only show dating section if user is NOT in "friends only" mode
        supabaseManager.getDiscoveryMode() != .friends
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Profile")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Basics Section
                    CollapsibleSection(
                        title: "Profile Basics",
                        subtitle: "Photos, name & location",
                        icon: "person.crop.rectangle",
                        iconBackgroundColor: burntOrange.opacity(0.1),
                        iconColor: burntOrange,
                        isExpanded: expandedSections[.basics] ?? false,
                        onToggle: { toggleSection(.basics) }
                    ) {
                        profileBasicsContent
                    }
                    
                    // About Me Section
                    CollapsibleSection(
                        title: "About Me",
                        subtitle: "Your story & simple pleasures",
                        icon: "globe.americas",
                        iconBackgroundColor: forestGreen.opacity(0.1),
                        iconColor: forestGreen,
                        isExpanded: expandedSections[.about] ?? false,
                        onToggle: { toggleSection(.about) }
                    ) {
                        aboutMeContent
                    }
                    
                    // Dating Profile Section - Only show if not in friends-only mode
                    if showDatingSection {
                        CollapsibleSection(
                            title: "Dating Profile",
                            subtitle: "What adventures await?",
                            icon: "heart.fill",
                            iconBackgroundColor: nil,
                            iconColor: .white,
                            iconGradient: LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            isExpanded: expandedSections[.dating] ?? false,
                            onToggle: { toggleSection(.dating) }
                        ) {
                            datingProfileContent
                        }
                    }
                    
                    // Travel Info Section
                    CollapsibleSection(
                        title: "Travel Info",
                        subtitle: "Your pace & schedule",
                        icon: "mappin.circle",
                        iconBackgroundColor: skyBlue.opacity(0.2),
                        iconColor: skyBlue,
                        isExpanded: expandedSections[.travel] ?? false,
                        onToggle: { toggleSection(.travel) }
                    ) {
                        travelInfoContent
                    }
                    
                    // Save Button
                    Button(action: {
                        saveChanges()
                    }) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, sunsetRose]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .disabled(isSaving)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(warmWhite)
            .scrollContentBackground(.hidden)
        }
        .background(warmWhite)
        .preference(key: ExpandedSectionPreferenceKey.self, value: hasExpandedSection)
        .onAppear {
            loadProfileData()
        }
        .photosPicker(
            isPresented: Binding(
                get: { selectedPhotoIndex != nil },
                set: { if !$0 { selectedPhotoIndex = nil } }
            ),
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let item = newItem, let index = selectedPhotoIndex {
                uploadPhoto(item, at: index)
                selectedPhotoItem = nil
            }
        }
        .alert("Upload Error", isPresented: $showUploadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(uploadError ?? "An error occurred while uploading")
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationView {
                VStack {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let dateString = formatter.string(from: selectedDate)
                            
                            if let idx = travelSchedule.firstIndex(where: { $0.id == selectedDateStopId }),
                               let field = selectedDateField {
                                if field == .startDate {
                                    travelSchedule[idx].startDate = dateString
                                } else {
                                    travelSchedule[idx].endDate = dateString
                                }
                            }
                            
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Section Toggle
    
    private func toggleSection(_ section: SectionType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            expandedSections[section]?.toggle()
        }
    }
    
    // MARK: - Profile Basics Content
    
    private var profileBasicsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // My Photos
            VStack(alignment: .leading, spacing: 8) {
                Text("My Photos")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                Text("First photo is your profile picture")
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        EditPhotoSlot(
                            index: index,
                            photoUrl: index < photos.count ? photos[index] : nil,
                            previewImage: photoImages[index],
                            isUploading: isUploadingPhoto == index,
                            isMainPhoto: index == 0,
                            onSelect: {
                                selectedPhotoIndex = index
                            },
                            onRemove: {
                                removePhoto(at: index)
                            }
                        )
                    }
                }
            }
            
            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                TextField("Your name", text: $name)
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
            }
            
            // Current Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Location")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                HStack {
                    Image(systemName: "mappin")
                        .font(.system(size: 16))
                        .foregroundColor(charcoalColor.opacity(0.4))
                    
                    TextField("City, State/Country", text: $currentLocation)
                        .font(.system(size: 16))
                        .foregroundColor(charcoalColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - About Me Content
    
    private var aboutMeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // About
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                ZStack(alignment: .topLeading) {
                    if about.isEmpty {
                        Text("Tell people about yourself...")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: Binding(
                        get: { about },
                        set: { newValue in
                            if newValue.count <= 500 {
                                about = newValue
                            }
                        }
                    ))
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                
                HStack {
                    Spacer()
                    Text("\(about.count)/500")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
            
            // My Simple Pleasure
            VStack(alignment: .leading, spacing: 8) {
                Text("My Simple Pleasure")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                Text("What's a small moment that brings you joy?")
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
                
                ZStack(alignment: .topLeading) {
                    if simplePleasure.isEmpty {
                        Text("e.g., Morning coffee with a sunrise view...")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: Binding(
                        get: { simplePleasure },
                        set: { newValue in
                            if newValue.count <= 500 {
                                simplePleasure = newValue
                            }
                        }
                    ))
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                
                HStack {
                    Spacer()
                    Text("\(simplePleasure.count)/500")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
            
            // The Rig
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor)
                    
                    Text("The Rig")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor)
                }
                
                Text("Describe your vehicle or home on wheels")
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
                
                TextField("e.g., 2019 Sprinter 144\", Self-Converted, Solar-Powered", text: Binding(
                    get: { rigInfo },
                    set: { newValue in
                        if newValue.count <= 300 {
                            rigInfo = newValue
                        }
                    }
                ))
                .font(.system(size: 16))
                .foregroundColor(charcoalColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
                
                HStack {
                    Spacer()
                    Text("\(rigInfo.count)/300")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Dating Profile Content
    
    private var datingProfileContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Dating Me Looks Like
            VStack(alignment: .leading, spacing: 8) {
                Text("Dating Me Looks Like")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                Text("Paint a picture of what adventures await")
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
                
                ZStack(alignment: .topLeading) {
                    if datingLooksLike.isEmpty {
                        Text("e.g., Spontaneous road trips, cooking breakfast outside, stargazing from the roof...")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: Binding(
                        get: { datingLooksLike },
                        set: { newValue in
                            if newValue.count <= 500 {
                                datingLooksLike = newValue
                            }
                        }
                    ))
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                
                HStack {
                    Spacer()
                    Text("\(datingLooksLike.count)/500")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
            
            // Dating Preferences Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Dating Preferences")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoalColor)
                
                // I'm Interested In
                Button(action: {
                    showInterestedInModal = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I'm interested in")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor)
                            
                            Text(interestedIn.displayName)
                                .font(.system(size: 13))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                
                // Maximum Distance
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Maximum distance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor)
                        
                        Spacer()
                        
                        Text("\(Int(maxDistance)) mi")
                            .font(.system(size: 13))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    Slider(value: $maxDistance, in: 1...200, step: 1)
                        .tint(burntOrange)
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
                
                // Age Range
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Age range")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor)
                        
                        Spacer()
                        
                        Text("\(Int(minAge)) – \(Int(maxAge))")
                            .font(.system(size: 13))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    DatingAgeRangeSlider(
                        minValue: $minAge,
                        maxValue: $maxAge,
                        range: 18...80,
                        accentColor: burntOrange,
                        gradientColors: [burntOrange, sunsetRose]
                    )
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
            }
            
            // Profile Prompts
            if !promptAnswers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile Prompts")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor)
                    
                    Text("Your prompt answers")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    
                    VStack(spacing: 12) {
                        ForEach(Array(promptAnswers.enumerated()), id: \.offset) { index, promptAnswer in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(promptAnswer.prompt)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                
                                Text(promptAnswer.answer)
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showInterestedInModal) {
            InterestedInSheet(
                isPresented: $showInterestedInModal,
                selection: $interestedIn
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Travel Info Content
    
    private var travelInfoContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Travel Pace
            VStack(alignment: .leading, spacing: 12) {
                Text("Travel Pace")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                VStack(spacing: 8) {
                    ForEach(TravelPaceOption.allCases, id: \.self) { pace in
                        Button(action: {
                            travelPace = pace
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pace.label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(travelPace == pace ? .white : charcoalColor)
                                
                                Text(pace.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(travelPace == pace ? .white.opacity(0.8) : charcoalColor.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                travelPace == pace ?
                                LinearGradient(
                                    gradient: Gradient(colors: [forestGreen, skyBlue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.white]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(travelPace == pace ? Color.clear : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                        }
                    }
                }
            }
            
            // Travel Schedule
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Travel Schedule")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor)
                        
                        Text("Where are you headed next?")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        travelSchedule.append(
                            TravelStop(
                                id: UUID().uuidString,
                                location: "",
                                startDate: "",
                                endDate: ""
                            )
                        )
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            Text("Add")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                }
                
                if travelSchedule.isEmpty {
                    VStack(spacing: 8) {
                        Text("No travel plans yet. Add your next destination!")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.gray.opacity(0.3))
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(travelSchedule.enumerated()), id: \.element.id) { index, stop in
                            TravelStopCard(
                                index: index,
                                stop: stop,
                                onLocationChange: { newLocation in
                                    if let idx = travelSchedule.firstIndex(where: { $0.id == stop.id }) {
                                        travelSchedule[idx].location = newLocation
                                    }
                                },
                                onStartDateTap: {
                                    selectedDateStopId = stop.id
                                    selectedDateField = .startDate
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd"
                                    if let date = formatter.date(from: stop.startDate) {
                                        selectedDate = date
                                    } else {
                                        selectedDate = Date()
                                    }
                                    showDatePicker = true
                                },
                                onEndDateTap: {
                                    selectedDateStopId = stop.id
                                    selectedDateField = .endDate
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd"
                                    if let date = formatter.date(from: stop.endDate) {
                                        selectedDate = date
                                    } else {
                                        selectedDate = Date()
                                    }
                                    showDatePicker = true
                                },
                                onRemove: {
                                    travelSchedule.removeAll { $0.id == stop.id }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func compressImage(_ image: UIImage, maxFileSizeMB: Double) -> Data? {
        let maxFileSizeBytes = Int(maxFileSizeMB * 1024 * 1024)
        var compressionQuality: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compressionQuality)

        while let data = imageData, data.count > maxFileSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }

        return imageData
    }

    private func loadProfileData() {
        // Fetch fresh profile data from server
        Task {
            do {
                try await profileManager.fetchCurrentProfile()
            } catch {
                print("Failed to fetch profile: \(error)")
            }

            await MainActor.run {
                guard let profile = profileManager.currentProfile else { return }

                name = profile.name ?? ""
                currentLocation = profile.location ?? ""
                about = profile.bio ?? ""
                simplePleasure = profile.simplePleasure ?? ""
                rigInfo = profile.rigInfo ?? ""
                datingLooksLike = profile.datingLooksLike ?? ""
                promptAnswers = profile.promptAnswers ?? []
                travelPace = TravelPaceOption.from(profile.travelPace)
                photos = profile.photos
                
                // Load dating preferences
                if let orientation = profile.orientation {
                    interestedIn = InterestedIn(rawValue: orientation) ?? .everyone
                }
                // Note: maxDistance, minAge, maxAge could be loaded from profile if stored
            }
        }
    }

    private func uploadPhoto(_ item: PhotosPickerItem, at index: Int) {
        isUploadingPhoto = index

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "EditProfile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load image data"])
                }

                // Show preview immediately
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        photoImages[index] = Image(uiImage: uiImage)
                    }
                }

                // Compress image
                guard let uiImage = UIImage(data: data),
                      let compressed = compressImage(uiImage, maxFileSizeMB: 2.0) else {
                    throw NSError(domain: "EditProfile", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
                }

                // Upload photo
                let url = try await profileManager.uploadPhoto(compressed)

                // If this is the first photo (index 0), also set it as avatar
                if index == 0 {
                    _ = try await profileManager.uploadAvatar(compressed)
                }

                await MainActor.run {
                    // Update photos array at the correct index
                    if index < photos.count {
                        photos[index] = url
                    } else {
                        // Fill gaps with empty strings if needed, then add
                        while photos.count < index {
                            photos.append("")
                        }
                        photos.append(url)
                    }
                    isUploadingPhoto = nil
                }
            } catch {
                print("Failed to upload photo: \(error)")
                await MainActor.run {
                    uploadError = "Failed to upload photo: \(error.localizedDescription)"
                    showUploadError = true
                    isUploadingPhoto = nil
                    photoImages.removeValue(forKey: index)
                }
            }
        }
    }

    private func removePhoto(at index: Int) {
        guard index < photos.count else { return }

        let photoUrl = photos[index]
        photos.remove(at: index)
        photoImages.removeValue(forKey: index)

        // If removing the first photo, update avatar to next available
        if index == 0 && !photos.isEmpty {
            // Set new first photo as avatar
            Task {
                if let firstPhotoUrl = photos.first,
                   let url = URL(string: firstPhotoUrl),
                   let data = try? Data(contentsOf: url) {
                    _ = try? await profileManager.uploadAvatar(data)
                }
            }
        }

        // Delete from storage
        Task {
            try? await profileManager.deletePhoto(photoUrl)
        }
    }

    private func saveChanges() {
        isSaving = true

        Task {
            do {
                let updates = ProfileUpdateRequest(
                    name: name.isEmpty ? nil : name,
                    bio: about.isEmpty ? nil : about,
                    photos: photos.isEmpty ? nil : photos,
                    location: currentLocation.isEmpty ? nil : currentLocation,
                    travelPace: travelPace.toBackendType,
                    simplePleasure: simplePleasure.isEmpty ? nil : simplePleasure,
                    rigInfo: rigInfo.isEmpty ? nil : rigInfo,
                    datingLooksLike: datingLooksLike.isEmpty ? nil : datingLooksLike,
                    promptAnswers: promptAnswers.isEmpty ? nil : promptAnswers
                )

                try await profileManager.updateProfile(updates)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("Failed to save profile: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Preference Key for Expanded State

struct ExpandedSectionPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue() || value
    }
}

// MARK: - Collapsible Section Component

struct CollapsibleSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconBackgroundColor: Color?
    let iconColor: Color
    var iconGradient: LinearGradient? = nil
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: Content
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Button
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        if let gradient = iconGradient {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(gradient)
                                .frame(width: 40, height: 40)
                        } else if let bgColor = iconBackgroundColor {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(bgColor)
                                .frame(width: 40, height: 40)
                        }
                        
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoalColor)
                        
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable Content
            if isExpanded {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
                
                content
                    .padding(16)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
        )
    }
}

// MARK: - Travel Stop Card

struct TravelStopCard: View {
    let index: Int
    let stop: TravelStop
    let onLocationChange: (String) -> Void
    let onStartDateTap: () -> Void
    let onEndDateTap: () -> Void
    let onRemove: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stop \(index + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor.opacity(0.6))
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            HStack {
                Image(systemName: "mappin")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.4))
                
                TextField("Location", text: Binding(
                    get: { stop.location },
                    set: { onLocationChange($0) }
                ))
                .font(.system(size: 14))
                .foregroundColor(charcoalColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
            
            HStack(spacing: 8) {
                // Start Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Date")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    
                    Button(action: onStartDateTap) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.4))
                            
                            Text(stop.startDate.isEmpty ? "Select date" : stop.startDate)
                                .font(.system(size: 12))
                                .foregroundColor(stop.startDate.isEmpty ? charcoalColor.opacity(0.4) : charcoalColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                }
                
                // End Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("End Date")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    
                    Button(action: onEndDateTap) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.4))
                            
                            Text(stop.endDate.isEmpty ? "Select date" : stop.endDate)
                                .font(.system(size: 12))
                                .foregroundColor(stop.endDate.isEmpty ? charcoalColor.opacity(0.4) : charcoalColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(softGray)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Edit Photo Slot

struct EditPhotoSlot: View {
    let index: Int
    let photoUrl: String?
    let previewImage: Image?
    let isUploading: Bool
    let isMainPhoto: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")

    var body: some View {
        ZStack {
            if isUploading {
                // Loading state
                RoundedRectangle(cornerRadius: 16)
                    .fill(softGray)
                    .aspectRatio(3/4, contentMode: .fit)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: burntOrange))
                    )
            } else if let previewImage = previewImage {
                // Preview image (while uploading completes)
                previewImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .aspectRatio(3/4, contentMode: .fit)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(photoOverlay)
            } else if let url = photoUrl, !url.isEmpty {
                // Existing photo
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(softGray)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: charcoalColor.opacity(0.4)))
                        )
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(3/4, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(photoOverlay)
            } else {
                // Empty slot
                Button(action: onSelect) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundColor(Color.gray.opacity(0.3))
                            .aspectRatio(3/4, contentMode: .fit)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(softGray)
                            )

                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(burntOrange)
                                    .frame(width: 40, height: 40)

                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            if isMainPhoto {
                                Text("Main")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var photoOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // Main photo badge
            if isMainPhoto {
                VStack {
                    HStack {
                        Text("MAIN")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(burntOrange)
                            .clipShape(Capsule())
                            .padding(6)

                        Spacer()
                    }
                    Spacer()
                }
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(6)

            // Tap to replace
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                }
        }
    }
}

// MARK: - Dating Age Range Slider

struct DatingAgeRangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    let accentColor: Color
    let gradientColors: [Color]
    
    @State private var isDraggingMin = false
    @State private var isDraggingMax = false
    
    private let thumbSize: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let minPercent = (minValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            let maxPercent = (maxValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                // Active range track
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(maxPercent - minPercent) * width, height: 4)
                    .offset(x: CGFloat(minPercent) * width)
                
                // Min thumb
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .offset(x: CGFloat(minPercent) * width - thumbSize / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingMin = true
                                let newPercent = max(0, min(value.location.x / width, CGFloat((maxValue - 1 - range.lowerBound) / (range.upperBound - range.lowerBound))))
                                let newValue = range.lowerBound + Double(newPercent) * (range.upperBound - range.lowerBound)
                                minValue = max(range.lowerBound, min(newValue, maxValue - 1))
                            }
                            .onEnded { _ in
                                isDraggingMin = false
                            }
                    )
                
                // Max thumb
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .offset(x: CGFloat(maxPercent) * width - thumbSize / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingMax = true
                                let newPercent = max(CGFloat((minValue + 1 - range.lowerBound) / (range.upperBound - range.lowerBound)), min(value.location.x / width, 1))
                                let newValue = range.lowerBound + Double(newPercent) * (range.upperBound - range.lowerBound)
                                maxValue = max(minValue + 1, min(newValue, range.upperBound))
                            }
                            .onEnded { _ in
                                isDraggingMax = false
                            }
                    )
            }
        }
        .frame(height: thumbSize)
    }
}

#Preview {
    EditProfileSheet(isPresented: .constant(true))
}
