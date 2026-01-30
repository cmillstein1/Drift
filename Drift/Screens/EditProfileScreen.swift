//
//  EditProfileScreen.swift
//  Drift
//
//  Created for profile editing as navigation destination
//

import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import DriftBackend

struct EditProfileScreen: View {
    let onBack: () -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileManager = ProfileManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var birthday: Date?
    @State private var currentLocation: String = ""
    @State private var about: String = ""
    @State private var rigInfo: String = ""
    @State private var promptAnswers: [DriftBackend.PromptAnswer] = []
    @State private var travelPace: TravelPaceOption = .slow
    @State private var interests: [String] = []
    @State private var photos: [String] = []
    @State private var photoImages: [Int: Image] = [:]
    @State private var selectedPhotoIndex: Int?
    // Lifestyle fields
    @State private var workStyle: WorkStyle?
    @State private var homeBase: String = ""
    @State private var morningPerson: Bool?
    @State private var travelStopsCount: Int = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto: Int? = nil
    @State private var draggedPhoto: Int?
    @State private var isSaving = false
    @State private var showPromptsEditor = false
    @State private var hasChanges = false
    @State private var originalProfileData: ProfileSnapshot?
    
    // Navigation states
    @State private var showLocationEditor = false
    @State private var showTravelPaceEditor = false
    @State private var showPromptEditor = false
    @State private var selectedPromptIndex: Int?
    @State private var showInterestEditor = false
    @State private var showWorkStyleEditor = false

    // Tab selection
    @State private var selectedTab: ProfileTab = .edit

    enum ProfileTab: String, CaseIterable {
        case edit = "Edit"
        case preview = "Preview"
    }
    
    
    enum TravelPaceOption: String, CaseIterable {
        case slow = "slow"
        case moderate = "moderate"
        case fast = "fast"
        
        var displayName: String {
            switch self {
            case .slow: return "Slow Traveler - Months in each location"
            case .moderate: return "Moderate Pace - Weeks in each location"
            case .fast: return "Fast Mover - Days in each location"
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
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let desertSand = Color("DesertSand")
    
    /// Max number of prompt answers allowed in My Journey.
    private static let maxPrompts = 3

    // Track original state for change detection
    struct ProfileSnapshot: Equatable {
        let name: String
        let age: String
        let birthday: Date?
        let location: String
        let about: String
        let rigInfo: String
        let promptAnswers: [DriftBackend.PromptAnswer]
        let travelPace: TravelPaceOption
        let interests: [String]
        let photos: [String]
        
        static func == (lhs: ProfileSnapshot, rhs: ProfileSnapshot) -> Bool {
            return lhs.name == rhs.name &&
                   lhs.age == rhs.age &&
                   lhs.birthday == rhs.birthday &&
                   lhs.location == rhs.location &&
                   lhs.about == rhs.about &&
                   lhs.rigInfo == rhs.rigInfo &&
                   lhs.promptAnswers.count == rhs.promptAnswers.count &&
                   zip(lhs.promptAnswers, rhs.promptAnswers).allSatisfy { $0.prompt == $1.prompt && $0.answer == $1.answer } &&
                   lhs.travelPace == rhs.travelPace &&
                   lhs.interests == rhs.interests &&
                   lhs.photos == rhs.photos
        }
    }
    
    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()

            VStack(spacing: 0) {
                tabSelector

                if selectedTab == .edit {
                    editTabContent
                } else {
                    profilePreviewView
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(charcoalColor)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Edit Profile")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(charcoalColor)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if hasChanges {
                        saveChanges()
                    } else {
                        onBack()
                    }
                }) {
                    Text(hasChanges ? "Save" : "Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(burntOrange)
                }
                .disabled(isSaving)
            }
        }
        .task {
            // Hide tab bar immediately when view appears (runs as early as possible)
            tabBarVisibility.isVisible = false
        }
        .onAppear {
            loadProfileData()
            // Hide tab bar immediately (no animation) to prevent it from showing during navigation
            tabBarVisibility.isVisible = false
            // Continuously ensure it stays hidden
            Task { @MainActor in
                // Check multiple times to ensure it stays hidden
                for delay in [0.05, 0.1, 0.2, 0.3, 0.5] {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    tabBarVisibility.isVisible = false
                }
            }
        }
        .onDisappear {
            // Don't show tab bar here - we may have only pushed to a child (About, Age, etc.).
            // ProfileScreen shows the tab bar when navigation path becomes empty.
        }
        .onChange(of: name) { _, _ in checkForChanges() }
        .onChange(of: age) { _, _ in checkForChanges() }
        .onChange(of: currentLocation) { _, _ in checkForChanges() }
        .onChange(of: about) { _, _ in checkForChanges() }
        .onChange(of: rigInfo) { _, _ in checkForChanges() }
        .onChange(of: promptAnswers) { _, _ in checkForChanges() }
        .onChange(of: travelPace) { _, _ in checkForChanges() }
        .onChange(of: interests) { _, _ in checkForChanges() }
        .onChange(of: photos) { _, _ in checkForChanges() }
        .onChange(of: workStyle) { _, _ in checkForChanges() }
        .onChange(of: homeBase) { _, _ in checkForChanges() }
        .onChange(of: morningPerson) { _, _ in checkForChanges() }
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
        .sheet(isPresented: $showInterestEditor) {
            InterestEditorSheet(
                selectedInterests: $interests,
                isPresented: $showInterestEditor
            )
        }
        .sheet(isPresented: $showTravelPaceEditor) {
            TravelPaceEditorSheet(
                travelPace: $travelPace,
                isPresented: $showTravelPaceEditor
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showWorkStyleEditor) {
            WorkStyleEditorSheet(
                workStyle: $workStyle,
                isPresented: $showWorkStyleEditor
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPromptEditor) {
            if let index = selectedPromptIndex {
                PromptEditorSheet(
                    promptAnswer: Binding(
                        get: { promptAnswers[index] },
                        set: { promptAnswers[index] = $0 }
                    ),
                    isPresented: $showPromptEditor,
                    onDidSave: { savePromptsToProfile() }
                )
            } else {
                PromptEditorSheet(
                    promptAnswer: Binding(
                        get: { DriftBackend.PromptAnswer(prompt: "", answer: "") },
                        set: { if promptAnswers.count < Self.maxPrompts { promptAnswers.append($0) } }
                    ),
                    isPresented: $showPromptEditor,
                    onDidSave: { savePromptsToProfile() }
                )
            }
        }
    }
    
    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .white : charcoalColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? charcoalColor : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Edit Tab Content

    private var editTabContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                photosSection
                vanLifeEssentialsSection
                myJourneySection
                travelPlansSection
                lifestyleSection
                interestsSection
            }
            .padding(16)
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Photos & Videos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoalColor.opacity(0.6))
            
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let spacing: CGFloat = 12
                let totalSpacing = spacing * 2 // 2 gaps between 3 columns
                let itemWidth = (availableWidth - totalSpacing) / 3
                let itemHeight = itemWidth * 4 / 3 // 3:4 aspect ratio
                let gridColumns = [
                    GridItem(.fixed(itemWidth), spacing: spacing),
                    GridItem(.fixed(itemWidth), spacing: spacing),
                    GridItem(.fixed(itemWidth), spacing: spacing)
                ]
                
                photoGrid(
                    columns: gridColumns,
                    itemWidth: itemWidth,
                    itemHeight: itemHeight
                )
            }
            .frame(height: (UIScreen.main.bounds.width - 64) / 3 * 4 / 3 * 2 + 12)
            
            Text("Tap to edit, drag to reorder")
                .font(.system(size: 12))
                .foregroundColor(charcoalColor.opacity(0.5))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func photoGrid(columns: [GridItem], itemWidth: CGFloat, itemHeight: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                photoSlot(at: index, width: itemWidth, height: itemHeight)
            }
        }
    }
    
    private func photoSlot(at index: Int, width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            EditPhotoSlotWithStroke(
                index: index,
                photoUrl: index < photos.count ? photos[index] : nil,
                previewImage: photoImages[index],
                isUploading: isUploadingPhoto == index,
                isMainPhoto: index == 0,
                showMainBadge: false,
                onSelect: {
                    selectedPhotoIndex = index
                },
                onRemove: {
                    removePhoto(at: index)
                }
            )
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if index == 0 {
                EditProfileMainBadgeView()
                    .padding(.top, 18)
                    .padding(.leading, 18)
            }
        }
        .frame(width: width, height: height)
        .opacity(draggedPhoto == index ? 0.6 : 1.0)
        .scaleEffect(draggedPhoto == index ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: draggedPhoto)
        .contentShape(Rectangle())
        .onDrag {
            draggedPhoto = index
            return NSItemProvider(object: "\(index)" as NSString)
        }
        .onDrop(of: [.text], delegate: EditProfilePhotoDropDelegate(
            sourceIndex: draggedPhoto ?? index,
            destinationIndex: index,
            photos: $photos,
            photoImages: $photoImages,
            draggedPhoto: $draggedPhoto
        ))
    }
    
    // MARK: - Van Life Essentials Section
    
    private var vanLifeEssentialsSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Van Life Essentials")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoalColor.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            Divider()
                .background(Color.gray.opacity(0.1))
            
            // Name
            NavigationLink(destination: NameEditorView(name: $name)) {
                ProfileEditRow(
                    title: "Name",
                    value: name.isEmpty ? "Add your name" : name
                )
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    // Hide tab bar immediately when tapped
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
            )
            
            Divider()
                .background(Color.gray.opacity(0.1))
            
            // Age
            NavigationLink(destination: AgeEditorView(age: $age, birthday: $birthday)) {
                ProfileEditRow(
                    title: "Age",
                    value: age.isEmpty ? "Add your age" : age
                )
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    // Hide tab bar immediately when tapped
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
            )
            
            Divider()
                .background(Color.gray.opacity(0.1))
            
            // Location
            NavigationLink(destination: LocationMapPickerView(location: $currentLocation)) {
                ProfileEditRow(
                    title: "Current Location",
                    value: currentLocation.isEmpty ? "Add location" : currentLocation
                )
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    // Hide tab bar immediately when tapped
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
            )
            
            Divider()
            .background(Color.gray.opacity(0.1))
            
            // The Rig
            NavigationLink(destination: RigDetailsView(rigInfo: $rigInfo)) {
                ProfileEditRow(
                    title: "The Rig",
                    value: rigInfo.isEmpty ? "Add your rig info" : rigInfo
                )
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    // Hide tab bar immediately when tapped
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
            )
            
            Divider()
                .background(Color.gray.opacity(0.1))
            
            // Travel Pace
            ProfileEditRow(
                title: "Travel Pace",
                value: travelPace.displayName,
                onTap: {
                    showTravelPaceEditor = true
                }
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - My Journey Section
    
    private var myJourneySection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("My Journey")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoalColor.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            Divider()
                .background(Color.gray.opacity(0.1))
            
            // About
            NavigationLink(destination: AboutEditorView(about: $about)) {
                ProfileEditRow(
                    title: "About",
                    value: about.isEmpty ? "Add your answer" : about,
                    isMultiline: true
                )
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    // Hide tab bar immediately when tapped
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
            )
            
            // Prompts
            if !promptAnswers.isEmpty {
                ForEach(Array(promptAnswers.enumerated()), id: \.offset) { index, promptAnswer in
                    Divider()
                        .background(Color.gray.opacity(0.1))
                    
                    Button(action: {
                        selectedPromptIndex = index
                        showPromptEditor = true
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(promptAnswer.prompt)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor)
                            
                            Text(promptAnswer.answer)
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Add prompt button if less than max
            if promptAnswers.count < Self.maxPrompts {
                Divider()
                    .background(Color.gray.opacity(0.1))
                
                Button(action: {
                    selectedPromptIndex = nil
                    showPromptEditor = true
                }) {
                    HStack {
                        Text("Add a prompt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.4))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Travel Plans Section

    private var travelPlansSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Travel Plans")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoalColor.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)

            Divider()
                .background(Color.gray.opacity(0.1))

            // Travel Plans row
            NavigationLink(destination: TravelPlansEditorView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upcoming Destinations")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor)

                        Text(travelStopsCount > 0 ? "\(travelStopsCount) destination\(travelStopsCount == 1 ? "" : "s") planned" : "Add your travel plans")
                            .font(.system(size: 14))
                            .foregroundColor(travelStopsCount > 0 ? charcoalColor.opacity(0.6) : charcoalColor.opacity(0.4))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Lifestyle Section

    private var lifestyleSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Lifestyle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoalColor.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)

            Divider()
                .background(Color.gray.opacity(0.1))

            // Work Style
            ProfileEditRow(
                title: "Work Style",
                value: workStyle?.displayName ?? "Add work style",
                onTap: {
                    showWorkStyleEditor = true
                }
            )

            Divider()
                .background(Color.gray.opacity(0.1))

            // Home Base
            NavigationLink(destination: HomeBaseEditorView(homeBase: $homeBase)) {
                ProfileEditRow(
                    title: "Home Base",
                    value: homeBase.isEmpty ? "Add home base" : homeBase
                )
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
            )

            Divider()
                .background(Color.gray.opacity(0.1))

            // Morning Person
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Morning Person")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor)

                    Text(morningPerson == nil ? "Not set" : (morningPerson! ? "Yes" : "No"))
                        .font(.system(size: 14))
                        .foregroundColor(morningPerson == nil ? charcoalColor.opacity(0.4) : charcoalColor.opacity(0.6))
                }

                Spacer()

                // Toggle buttons
                HStack(spacing: 8) {
                    Button {
                        morningPerson = true
                    } label: {
                        Text("Yes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(morningPerson == true ? .white : charcoalColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(morningPerson == true ? burntOrange : desertSand)
                            .clipShape(Capsule())
                    }

                    Button {
                        morningPerson = false
                    } label: {
                        Text("No")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(morningPerson == false ? .white : charcoalColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(morningPerson == false ? burntOrange : desertSand)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Profile Preview View (Discover Card Style)

    private var profilePreviewView: some View {
        let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96)
        let forestGreen = Color("ForestGreen")

        return ScrollView {
            VStack(spacing: 0) {
                // Card container
                VStack(spacing: 0) {
                    // ----- First Image with header overlay -----
                    ZStack(alignment: .bottom) {
                        // First photo
                        if let firstPhoto = photos.first, !firstPhoto.isEmpty,
                           let url = URL(string: firstPhoto) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    previewPlaceholderGradient
                                }
                            }
                        } else {
                            previewPlaceholderGradient
                        }

                        // Gradient overlay
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.7), location: 0.0),
                                .init(color: .clear, location: 0.5)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )

                        // Header info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .bottom, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(name.isEmpty ? "Your Name" : name), \(age.isEmpty ? "25" : age)")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)

                                    if !currentLocation.isEmpty {
                                        HStack(spacing: 6) {
                                            Image(systemName: "mappin")
                                                .font(.system(size: 14))
                                            Text(currentLocation)
                                                .font(.system(size: 14))
                                        }
                                        .foregroundColor(.white.opacity(0.9))
                                    }
                                }

                                Spacer()

                                // Like button placeholder
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(20)
                    }
                    .aspectRatio(3/4, contentMode: .fit)

                    // ----- Interests -----
                    if !interests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Interests")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(charcoalColor.opacity(0.6))
                            PreviewWrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                                ForEach(interests, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        if let emoji = DriftUI.emoji(for: tag) {
                                            Text(emoji)
                                                .font(.system(size: 14))
                                        }
                                        Text(tag)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(charcoalColor)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(desertSand)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.white)
                        .overlay(
                            Rectangle().frame(height: 1).foregroundColor(gray100),
                            alignment: .bottom
                        )
                    }

                    // ----- Bio -----
                    if !about.isEmpty {
                        Text(about)
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.white)
                            .overlay(
                                Rectangle().frame(height: 1).foregroundColor(gray100),
                                alignment: .bottom
                            )
                    }

                    // ----- Prompt 1 -----
                    if let firstPrompt = promptAnswers.first {
                        previewPromptSection(question: firstPrompt.prompt, answer: firstPrompt.answer)
                    }

                    // ----- Second Image -----
                    if photos.count > 1, let secondPhoto = photos[safe: 1], !secondPhoto.isEmpty,
                       let url = URL(string: secondPhoto) {
                        ZStack(alignment: .topTrailing) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    previewPlaceholderGradient
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()

                            // Like button
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .padding(16)
                        }
                    }

                    // ----- Lifestyle -----
                    if profileManager.currentProfile?.lifestyle != nil || workStyle != nil || !homeBase.isEmpty || morningPerson != nil {
                        LifestyleCard(
                            lifestyle: profileManager.currentProfile?.lifestyle,
                            workStyle: workStyle,
                            homeBase: homeBase.isEmpty ? nil : homeBase,
                            morningPerson: morningPerson
                        )
                        .overlay(
                            Rectangle().frame(height: 1).foregroundColor(gray100),
                            alignment: .bottom
                        )
                    }

                    // ----- Prompt 2 -----
                    if promptAnswers.count > 1 {
                        previewPromptSection(question: promptAnswers[1].prompt, answer: promptAnswers[1].answer)
                    }

                    // ----- Third Image -----
                    if photos.count > 2, let thirdPhoto = photos[safe: 2], !thirdPhoto.isEmpty,
                       let url = URL(string: thirdPhoto) {
                        ZStack(alignment: .topTrailing) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    previewPlaceholderGradient
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()

                            // Like button
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .padding(16)
                        }
                    }

                    // ----- Prompt 3 -----
                    if promptAnswers.count > 2 {
                        previewPromptSection(question: promptAnswers[2].prompt, answer: promptAnswers[2].answer)
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                // Info text
                Text("This is how your profile appears to others in Discover")
                    .font(.system(size: 13))
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .padding(.bottom, 24)
            }
        }
    }

    private var previewPlaceholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func previewPromptSection(question: String, answer: String) -> some View {
        let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96)

        return VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(burntOrange)
            Text(answer)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(charcoalColor)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(gray100),
            alignment: .bottom
        )
    }

    // MARK: - Interests Section
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoalColor.opacity(0.6))
            
            if interests.isEmpty {
                Button(action: {
                    showInterestEditor = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Interest")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.gray.opacity(0.3))
                    )
                }
            } else {
                FlowLayout(data: interests.map { InterestItem($0) }, spacing: 8) { item in
                    ProfileInterestTag(interest: item.name)
                }
                
                Button(action: {
                    showInterestEditor = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Interest")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.gray.opacity(0.3))
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func loadProfileData() {
        guard let profile = profileManager.currentProfile else { return }
        
        name = profile.name ?? ""
        // Get age from profile, or calculate from birthday
        if let ageValue = profile.age {
            age = "\(ageValue)"
        } else if let profileBirthday = profile.birthday {
            birthday = profileBirthday
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: profileBirthday, to: Date())
            if let years = ageComponents.year {
                age = "\(years)"
            }
        }
        currentLocation = profile.location ?? ""
        about = profile.bio ?? ""
        rigInfo = profile.rigInfo ?? ""
        promptAnswers = profile.promptAnswers ?? []
        travelPace = TravelPaceOption.from(profile.travelPace)
        interests = profile.interests
        photos = profile.photos
        workStyle = profile.workStyle
        homeBase = profile.homeBase ?? ""
        morningPerson = profile.morningPerson

        // Load travel stops count
        Task {
            do {
                let stops = try await profileManager.fetchTravelSchedule()
                await MainActor.run {
                    travelStopsCount = stops.count
                }
            } catch {
                print("Failed to load travel stops: \(error)")
            }
        }

        // Save snapshot for change detection
        originalProfileData = ProfileSnapshot(
            name: name,
            age: age,
            birthday: birthday,
            location: currentLocation,
            about: about,
            rigInfo: rigInfo,
            promptAnswers: promptAnswers,
            travelPace: travelPace,
            interests: interests,
            photos: photos
        )
    }
    
    private func checkForChanges() {
        guard let original = originalProfileData else {
            hasChanges = false
            return
        }
        
        let current = ProfileSnapshot(
            name: name,
            age: age,
            birthday: birthday,
            location: currentLocation,
            about: about,
            rigInfo: rigInfo,
            promptAnswers: promptAnswers,
            travelPace: travelPace,
            interests: interests,
            photos: photos
        )
        
        hasChanges = current != original
    }
    
    private func uploadPhoto(_ item: PhotosPickerItem, at index: Int) {
        isUploadingPhoto = index
        
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "EditProfile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load image data"])
                }
                
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        photoImages[index] = Image(uiImage: uiImage)
                    }
                }
                
                guard let uiImage = UIImage(data: data),
                      let compressed = compressImage(uiImage, maxFileSizeMB: 2.0) else {
                    throw NSError(domain: "EditProfile", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
                }
                
                // If replacing an existing photo, delete the old one first
                if index < photos.count && !photos[index].isEmpty {
                    let oldUrl = photos[index]
                    try? await profileManager.deletePhoto(oldUrl)
                }
                
                let url = try await profileManager.uploadPhoto(compressed)
                
                // If this is the first photo (index 0), also set it as avatar
                if index == 0 {
                    _ = try await profileManager.uploadAvatar(compressed)
                }
                
                await MainActor.run {
                    // Always replace at the specific index, overwriting existing
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
                    selectedPhotoIndex = nil
                }
            } catch {
                print("Failed to upload photo: \(error)")
                await MainActor.run {
                    isUploadingPhoto = nil
                    photoImages.removeValue(forKey: index)
                    selectedPhotoIndex = nil
                }
            }
        }
    }
    
    private func removePhoto(at index: Int) {
        guard index < photos.count else { return }
        
        let photoUrl = photos[index]
        photos.remove(at: index)
        photoImages.removeValue(forKey: index)
        
        if index == 0 && !photos.isEmpty {
            Task {
                if let firstPhotoUrl = photos.first,
                   let url = URL(string: firstPhotoUrl),
                   let data = try? Data(contentsOf: url) {
                    _ = try? await profileManager.uploadAvatar(data)
                }
            }
        }
        
        Task {
            try? await profileManager.deletePhoto(photoUrl)
        }
    }
    
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
    
    /// Saves current prompt answers to the profile (max 3). Call after user saves in PromptEditorSheet.
    private func savePromptsToProfile() {
        let capped = Array(promptAnswers.prefix(Self.maxPrompts))
        Task {
            do {
                try await profileManager.updateProfile(ProfileUpdateRequest(
                    promptAnswers: capped.isEmpty ? nil : capped
                ))
            } catch {
                print("Failed to save prompts: \(error)")
            }
        }
    }

    private func saveChanges() {
        isSaving = true
        
        Task {
            do {
                let cappedPrompts = Array(promptAnswers.prefix(Self.maxPrompts))
                let updates = ProfileUpdateRequest(
                    name: name.isEmpty ? nil : name,
                    birthday: birthday,
                    bio: about.isEmpty ? nil : about,
                    photos: photos.isEmpty ? nil : photos,
                    location: currentLocation.isEmpty ? nil : currentLocation,
                    travelPace: travelPace.toBackendType,
                    interests: interests.isEmpty ? nil : interests,
                    rigInfo: rigInfo.isEmpty ? nil : rigInfo,
                    promptAnswers: cappedPrompts.isEmpty ? nil : cappedPrompts,
                    workStyle: workStyle,
                    homeBase: homeBase.isEmpty ? nil : homeBase,
                    morningPerson: morningPerson
                )
                try await profileManager.updateProfile(updates)
                await MainActor.run {
                    if promptAnswers.count > Self.maxPrompts {
                        promptAnswers = cappedPrompts
                    }
                    isSaving = false
                    // Show tab bar before going back
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = true
                    }
                    onBack()
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

// MARK: - Private Helpers

private struct InterestItem: Identifiable {
    let id: String
    let name: String
    
    init(_ name: String) {
        self.id = name
        self.name = name
    }
}

private let forestGreen = Color("ForestGreen")

// MARK: - Photo Drop Delegate

private struct EditProfilePhotoDropDelegate: DropDelegate {
    let sourceIndex: Int
    let destinationIndex: Int
    @Binding var photos: [String]
    @Binding var photoImages: [Int: Image]
    @Binding var draggedPhoto: Int?
    
    /// Perform the swap only when the user drops (releases), not on drag-over. Dragged photo takes this slot; the photo in this slot moves to the dragged photo’s spot.
    func performDrop(info: DropInfo) -> Bool {
        let dragged = draggedPhoto
        DispatchQueue.main.async {
            defer { draggedPhoto = nil }
            guard let src = dragged,
                  src != destinationIndex,
                  src >= 0, src < 6,
                  destinationIndex >= 0, destinationIndex < 6 else {
                return
            }
            guard src < photos.count || destinationIndex < photos.count else {
                return
            }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                if src < photos.count && destinationIndex < photos.count {
                    // Both slots have photos: swap them
                    photos.swapAt(src, destinationIndex)
                    let sourceImage = photoImages[src]
                    let destImage = photoImages[destinationIndex]
                    photoImages[src] = destImage
                    photoImages[destinationIndex] = sourceImage
                } else if src < photos.count {
                    // Dragged from filled slot to empty slot (or another position): bubble to target index or end
                    var p = photos
                    var pi = photoImages
                    var idx = src
                    let dest = min(destinationIndex, p.count - 1) // empty slot = move to end
                    while idx < dest {
                        p.swapAt(idx, idx + 1)
                        let a = pi[idx]; let b = pi[idx + 1]
                        pi[idx] = b; pi[idx + 1] = a
                        idx += 1
                    }
                    while idx > dest {
                        p.swapAt(idx - 1, idx)
                        let a = pi[idx - 1]; let b = pi[idx]
                        pi[idx - 1] = b; pi[idx] = a
                        idx -= 1
                    }
                    photos = p
                    photoImages = pi
                } else if destinationIndex < photos.count {
                    // Dragged from empty slot onto a photo: that photo moves to the empty slot (at src)
                    var p = photos
                    var pi = photoImages
                    var idx = destinationIndex
                    let dest = min(src, p.count - 1)
                    while idx < dest {
                        p.swapAt(idx, idx + 1)
                        let a = pi[idx]; let b = pi[idx + 1]
                        pi[idx] = b; pi[idx + 1] = a
                        idx += 1
                    }
                    while idx > dest {
                        p.swapAt(idx - 1, idx)
                        let a = pi[idx - 1]; let b = pi[idx]
                        pi[idx - 1] = b; pi[idx] = a
                        idx -= 1
                    }
                    photos = p
                    photoImages = pi
                }
            }
        }
        return true
    }
}

// MARK: - Preview Wrapping HStack Layout

private struct PreviewWrappingHStack: Layout {
    var alignment: HorizontalAlignment = .leading
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }
            currentX += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
