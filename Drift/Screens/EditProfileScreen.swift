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
            
            ScrollView {
                VStack(spacing: 24) {
                    // My Photos & Videos Section
                    photosSection
                    
                    // Van Life Essentials
                    vanLifeEssentialsSection
                    
                    // My Journey
                    myJourneySection
                    
                    // Interests
                    interestsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
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
        EditPhotoSlotWithStroke(
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
        .frame(width: width, height: height)
        .clipped()
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
                    promptAnswers: cappedPrompts.isEmpty ? nil : cappedPrompts
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

// MARK: - Profile Edit Row

struct ProfileEditRow: View {
    let title: String
    let value: String
    var isMultiline: Bool = false
    let onTap: (() -> Void)?
    
    private let charcoalColor = Color("Charcoal")
    
    init(title: String, value: String, isMultiline: Bool = false, onTap: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.isMultiline = isMultiline
        self.onTap = onTap
    }
    
    var body: some View {
        let content = HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(value.contains("Add") ? charcoalColor.opacity(0.4) : charcoalColor.opacity(0.6))
                    .lineLimit(isMultiline ? 2 : 1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(charcoalColor.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        
        if let onTap = onTap {
            Button(action: onTap) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }
}

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

// MARK: - Edit Photo Slot With Stroke

struct EditPhotoSlotWithStroke: View {
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(softGray)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: burntOrange))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else if let previewImage = previewImage {
                previewImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(photoOverlay)
            } else if let url = photoUrl, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(softGray)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: charcoalColor.opacity(0.4)))
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(softGray)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(photoOverlay)
            } else {
                Button(action: onSelect) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundColor(Color.gray.opacity(0.3))
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

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(6)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                }
        }
    }
}

// MARK: - Editor Sheets

// LocationEditorSheet removed - replaced with LocationMapPickerView below


struct TravelPaceEditorSheet: View {
    @Binding var travelPace: EditProfileScreen.TravelPaceOption
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        NavigationView {
            ZStack {
                softGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(EditProfileScreen.TravelPaceOption.allCases, id: \.self) { pace in
                            Button(action: {
                                travelPace = pace
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pace.displayName.components(separatedBy: " - ").first ?? "")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(travelPace == pace ? .white : charcoalColor)
                                        
                                        Text(pace.displayName.components(separatedBy: " - ").last ?? "")
                                            .font(.system(size: 14))
                                            .foregroundColor(travelPace == pace ? .white.opacity(0.8) : charcoalColor.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    if travelPace == pace {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(20)
                                .background(travelPace == pace ? burntOrange : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Travel Pace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(charcoalColor)
                }
            }
        }
    }
}

// MARK: - About Editor View

struct AboutEditorView: View {
    @Binding var about: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @StateObject private var profileManager = ProfileManager.shared
    @State private var editedAbout: String = ""
    @State private var isSaving = false
    @State private var saveError: String?
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 0.97)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // About label (eyebrow)
                Text("ABOUT")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.41))
                    .padding(.horizontal, 16)
                
                // Text editor - normal height (~5 lines)
                TextEditor(text: $editedAbout)
                    .font(.system(size: 17))
                    .foregroundColor(charcoalColor)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    .frame(height: 160)
                    .padding(.horizontal, 16)
                    .scrollContentBackground(.hidden)
                
                if let saveError {
                    Text(saveError)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.top, 24)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveAbout()
                }
                .foregroundColor(burntOrange)
                .disabled(isSaving)
            }
        }
        .onAppear {
            editedAbout = about
            tabBarVisibility.isVisible = false
        }
        .onDisappear {
            // Keep tab bar hidden when popping back to Edit Profile
        }
    }
    
    private func saveAbout() {
        saveError = nil
        isSaving = true
        
        Task {
            do {
                let newBio = editedAbout.trimmingCharacters(in: .whitespacesAndNewlines)
                try await profileManager.updateProfile(ProfileUpdateRequest(
                    bio: newBio.isEmpty ? nil : newBio
                ))
                await MainActor.run {
                    about = editedAbout
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                }
            }
        }
    }
}

struct PromptEditorSheet: View {
    @Binding var promptAnswer: DriftBackend.PromptAnswer
    @Binding var isPresented: Bool
    var onDidSave: (() -> Void)? = nil

    @State private var selectedPrompt: String = ""
    @State private var answer: String = ""
    @State private var showPromptSelection = false
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)
    private let maxAnswerLength = 300
    
    var body: some View {
        NavigationView {
            ZStack {
                softGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Prompt field (no label)
                        Button(action: {
                            showPromptSelection = true
                        }) {
                            HStack {
                                Text(selectedPrompt.isEmpty ? "Select a prompt" : selectedPrompt)
                                    .font(.system(size: 16, weight: selectedPrompt.isEmpty ? .regular : .semibold))
                                    .foregroundColor(selectedPrompt.isEmpty ? charcoalColor.opacity(0.6) : charcoalColor)
                                Spacer()
                                
                                Image(systemName: "pencil")
                                    
                                
                            }
                            .padding(20)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Answer field (no label, with character count)
                        VStack(alignment: .trailing, spacing: 8) {
                            TextEditor(text: Binding(
                                get: { answer },
                                set: { newValue in
                                    if newValue.count <= maxAnswerLength {
                                        answer = newValue
                                    }
                                }
                            ))
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .frame(minHeight: 150)
                            .overlay(
                                Group {
                                    if answer.isEmpty {
                                        VStack {
                                            HStack {
                                                Text("Your answer")
                                                    .foregroundColor(charcoalColor.opacity(0.4))
                                                    .padding(.leading, 20)
                                                    .padding(.top, 24)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .allowsHitTesting(false)
                            )
                            
                            Text("\(answer.count)/\(maxAnswerLength)")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.5))
                        }
                        
                        // Tips section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.yellow)
                                Text("Tips for a great answer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                tipRow("Be specific and authentic - share real details about yourself")
                                tipRow("Keep it conversational and approachable")
                                tipRow("Give others something to connect with or ask about")
                            }
                        }
                        .padding(20)
                        .background(warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(charcoalColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        promptAnswer = DriftBackend.PromptAnswer(prompt: selectedPrompt, answer: answer)
                        isPresented = false
                        onDidSave?()
                    }
                    .foregroundColor(burntOrange)
                    .disabled(selectedPrompt.isEmpty || answer.isEmpty)
                }
            }
            .onAppear {
                selectedPrompt = promptAnswer.prompt
                answer = promptAnswer.answer
            }
            .sheet(isPresented: $showPromptSelection) {
                PromptSelectionSheet(
                    selectedPrompts: Set([selectedPrompt].filter { !$0.isEmpty }),
                    onSelect: { promptText in
                        selectedPrompt = promptText
                        showPromptSelection = false
                    }
                )
            }
        }
    }
    
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(charcoalColor.opacity(0.6))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.8))
        }
    }
}

// MARK: - Location Map Picker Sheet

// MARK: - Location Map Picker View (for navigation)

struct LocationMapPickerView: View {
    @Binding var location: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var locationName: String = ""
    @State private var cityName: String = ""
    @State private var isGeocoding = false
    @State private var geocodeTask: Task<Void, Never>?
    @State private var hasInitialized = false
    @State private var isMapMoving = false
    @State private var showDragInstruction = true
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    var body: some View {
        ZStack {
            // Map - simple map without annotations
            Map(position: $cameraPosition)
                .mapStyle(.standard)
                .onMapCameraChange { context in
                    // Update coordinate immediately for pin position
                    let newCoordinate = context.region.center
                    // Always update selectedCoordinate so center button works
                    if selectedCoordinate == nil || 
                       abs(selectedCoordinate!.latitude - newCoordinate.latitude) > 0.0001 ||
                       abs(selectedCoordinate!.longitude - newCoordinate.longitude) > 0.0001 {
                        selectedCoordinate = newCoordinate
                    }
                    
                    // Track map movement for fading instruction text
                    if hasInitialized {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showDragInstruction = false
                        }
                        isMapMoving = true
                    }
                    
                    // Only geocode after initial setup and when user moves the map
                    // This prevents geocoding on the initial camera setup
                    if hasInitialized {
                        // Debounce reverse geocoding - only geocode after user stops moving
                        debouncedReverseGeocode(coordinate: newCoordinate)
                    } else {
                        // On first camera change after initialization, geocode once
                        hasInitialized = true
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                            await reverseGeocode(coordinate: newCoordinate)
                        }
                    }
                }
                
                // Centered pin overlay (always at center of screen)
                VStack {
                    Spacer()
                    
                    // Location name label above pin (city only, no pin icon)
                    if !cityName.isEmpty {
                        Text(cityName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                            .offset(y: -30)
                    }
                    
                    // Smaller RV icon at center
                    ZStack {
                        // RV icon
                        Image("rv_pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                    .offset(y: -20)
                    
                    Spacer()
                }
                
                VStack {
                    // Top controls
                    HStack {
                        Spacer()
                        
                        // Center button
                        Button(action: {
                            centerOnPin()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Center")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                    
                    // Instructional text (fades when map moves)
                    if showDragInstruction {
                        Text("Drag the pin to set your location")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                            .opacity(showDragInstruction ? 1 : 0)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Current Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let savedLocation = cityName.isEmpty ? locationName : cityName
                        location = savedLocation
                        // Update the profile immediately and wait for completion
                        Task {
                            do {
                                let profileManager = ProfileManager.shared
                                try await profileManager.updateProfile(
                                    ProfileUpdateRequest(location: savedLocation)
                                )
                                // Refresh the profile to get updated data
                                try await profileManager.fetchCurrentProfile()
                                await MainActor.run {
                                    dismiss()
                                }
                            } catch {
                                print("Failed to update location: \(error)")
                                await MainActor.run {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .foregroundColor(burntOrange)
                    .disabled(cityName.isEmpty && locationName.isEmpty || isGeocoding)
                }
            }
            .onAppear {
                // Immediately hide tab bar and keep it hidden
                tabBarVisibility.isVisible = false
                // Also set it with animation after a brief delay to override any other changes
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        tabBarVisibility.isVisible = false
                    }
                }
                initializeLocation()
            }
            .onDisappear {
                // Don't show tab bar here - let EditProfileScreen handle it
                // Cancel any pending geocoding when view disappears
                geocodeTask?.cancel()
            }
    }
    
    private func initializeLocation() {
        if !location.isEmpty {
            Task {
                let geocoder = CLGeocoder()
                do {
                    let placemarks = try await geocoder.geocodeAddressString(location)
                    await MainActor.run {
                        if let placemark = placemarks.first,
                           let coordinate = placemark.location?.coordinate {
                            selectedCoordinate = coordinate
                            cameraPosition = .region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            ))
                            // Set location name immediately from geocoding result
                            var components: [String] = []
                            if let city = placemark.locality {
                                components.append(city)
                                cityName = city
                            }
                            if let state = placemark.administrativeArea {
                                components.append(state)
                            }
                            if let country = placemark.country {
                                components.append(country)
                            }
                            locationName = components.joined(separator: ", ")
                            if cityName.isEmpty {
                                cityName = locationName
                            }
                        } else {
                            // Fallback to user location
                            cameraPosition = .userLocation(fallback: .automatic)
                        }
                        hasInitialized = true
                    }
                } catch {
                    await MainActor.run {
                        cameraPosition = .userLocation(fallback: .automatic)
                        hasInitialized = true
                    }
                }
            }
        } else {
            // Use user's current location
            cameraPosition = .userLocation(fallback: .automatic)
            // Set a flag to capture the coordinate when the map initializes
            hasInitialized = true
            // The coordinate will be set in onMapCameraChange
        }
    }
    
    private func centerOnPin() {
        // Center on the current pin location (selectedCoordinate)
        // This coordinate is always kept up to date by onMapCameraChange
        guard let coordinate = selectedCoordinate else {
            // If coordinate not set yet, wait a moment and try again
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await MainActor.run {
                    if let coordinate = selectedCoordinate {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            cameraPosition = .region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            ))
                        }
                    }
                }
            }
            return
        }
        
        // Force update the camera position to center on the pin
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    
    private func debouncedReverseGeocode(coordinate: CLLocationCoordinate2D) {
        // Cancel any pending geocoding task
        geocodeTask?.cancel()
        
        // Create a new task that will execute after a delay
        geocodeTask = Task {
            // Wait 0.5 seconds after map movement stops
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if task was cancelled (user moved map again)
            guard !Task.isCancelled else { return }
            
            // Now perform the reverse geocoding
            await reverseGeocode(coordinate: coordinate)
        }
    }
    
    @MainActor
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) async {
        guard !isGeocoding else { return }
        isGeocoding = true
        
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
            isGeocoding = false
            
            if let placemark = placemarks.first {
                var components: [String] = []
                if let city = placemark.locality {
                    components.append(city)
                    cityName = city
                }
                if let state = placemark.administrativeArea {
                    components.append(state)
                }
                if let country = placemark.country {
                    components.append(country)
                }
                locationName = components.joined(separator: ", ")
                if cityName.isEmpty {
                    cityName = locationName
                }
            } else {
                let coordString = "\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
                locationName = coordString
                cityName = coordString
            }
        } catch {
            isGeocoding = false
            // On error, show coordinates
            let coordString = "\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
            locationName = coordString
            cityName = coordString
        }
    }
}


// MARK: - Interest Editor Sheet

struct InterestEditorSheet: View {
    @Binding var selectedInterests: [String]
    @Binding var isPresented: Bool
    
    @State private var selectedInterestsSet: Set<String>
    @State private var categories: [InterestCategory] = [
        InterestCategory(
            title: "Food & drink",
            interests: [
                Interest(emoji: "🍺", label: "Beer"),
                Interest(emoji: "🧋", label: "Boba tea"),
                Interest(emoji: "☕", label: "Coffee"),
                Interest(emoji: "🍝", label: "Foodie"),
                Interest(emoji: "🍸", label: "Gin"),
                Interest(emoji: "🍕", label: "Pizza"),
                Interest(emoji: "🍣", label: "Sushi"),
                Interest(emoji: "🍭", label: "Sweet tooth"),
                Interest(emoji: "🌮", label: "Tacos"),
                Interest(emoji: "🍵", label: "Tea"),
                Interest(emoji: "🌱", label: "Vegan"),
                Interest(emoji: "🥗", label: "Vegetarian"),
                Interest(emoji: "🥃", label: "Whisky"),
                Interest(emoji: "🍷", label: "Wine")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Traveling",
            interests: [
                Interest(emoji: "🎒", label: "Backpacking"),
                Interest(emoji: "🏖️", label: "Beaches"),
                Interest(emoji: "🏕️", label: "Camping"),
                Interest(emoji: "🏙️", label: "Exploring new cities"),
                Interest(emoji: "🎣", label: "Fishing trips"),
                Interest(emoji: "⛰️", label: "Hiking trips"),
                Interest(emoji: "🚗", label: "Road trips"),
                Interest(emoji: "🧖", label: "Spa weekends"),
                Interest(emoji: "🏡", label: "Staycations"),
                Interest(emoji: "❄️", label: "Winter sports")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Creative",
            interests: [
                Interest(emoji: "🎨", label: "Art"),
                Interest(emoji: "📸", label: "Photography"),
                Interest(emoji: "✍️", label: "Writing"),
                Interest(emoji: "🎭", label: "Theater"),
                Interest(emoji: "🎸", label: "Music"),
                Interest(emoji: "💃", label: "Dancing")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Active",
            interests: [
                Interest(emoji: "🏃", label: "Running"),
                Interest(emoji: "🚴", label: "Cycling"),
                Interest(emoji: "🧘", label: "Yoga"),
                Interest(emoji: "🏋️", label: "Gym"),
                Interest(emoji: "🏊", label: "Swimming"),
                Interest(emoji: "⛷️", label: "Skiing")
            ],
            expanded: true
        )
    ]
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)
    
    init(selectedInterests: Binding<[String]>, isPresented: Binding<Bool>) {
        self._selectedInterests = selectedInterests
        self._isPresented = isPresented
        _selectedInterestsSet = State(initialValue: Set(selectedInterests.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                warmWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(categories.indices), id: \.self) { index in
                            InterestCategorySection(
                                category: Binding(
                                    get: { categories[index] },
                                    set: { categories[index] = $0 }
                                ),
                                selectedInterests: $selectedInterestsSet
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(charcoalColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        selectedInterests = Array(selectedInterestsSet)
                        isPresented = false
                    }
                    .foregroundColor(burntOrange)
                }
            }
        }
    }
}

struct InterestCategorySection: View {
    @Binding var category: InterestCategory
    @Binding var selectedInterests: Set<String>
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    category.expanded.toggle()
                }
            }) {
                HStack {
                    Text(category.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(charcoalColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.4))
                        .rotationEffect(.degrees(category.expanded ? 180 : 0))
                }
            }
            
            if category.expanded {
                FlowLayout(data: category.interests, spacing: 8) { interest in
                    EditProfileInterestPill(
                        interest: interest,
                        isSelected: selectedInterests.contains(interest.label),
                        onTap: {
                            if selectedInterests.contains(interest.label) {
                                selectedInterests.remove(interest.label)
                            } else {
                                selectedInterests.insert(interest.label)
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

private struct EditProfileInterestPill: View {
    let interest: Interest
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let desertSand = Color("DesertSand")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(interest.emoji)
                    .font(.system(size: 14))
                Text(interest.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : charcoalColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? burntOrange : desertSand)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Name Editor View

struct NameEditorView: View {
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @State private var editedName: String = ""
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let sectionHeaderColor = Color(red: 0.29, green: 0.33, blue: 0.41)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 0.97)
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Name label (eyebrow)
                    HStack {
                        Text("NAME")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(sectionHeaderColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    
                    // Text field in a card
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Enter your name", text: $editedName)
                            .font(.system(size: 17))
                            .foregroundColor(charcoalColor)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    name = editedName
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(burntOrange)
                .disabled(editedName.isEmpty)
            }
        }
        .onAppear {
            editedName = name
            // Immediately hide tab bar and keep it hidden
            tabBarVisibility.isVisible = false
            // Also set it with animation after a brief delay to override any other changes
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    tabBarVisibility.isVisible = false
                }
            }
        }
        .onDisappear {
            // Don't show tab bar here - let EditProfileScreen handle it
        }
    }
}

// MARK: - Age Editor View

struct AgeEditorView: View {
    @Binding var age: String
    @Binding var birthday: Date?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @State private var selectedDate: Date = Date()
    
    private let calendar = Calendar.current
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let sectionHeaderColor = Color(red: 0.29, green: 0.33, blue: 0.41)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 0.97)
    
    private var calculatedAge: Int {
        calendar.dateComponents([.year], from: selectedDate, to: Date()).year ?? 0
    }
    
    private var isDateValid: Bool {
        let maxDate = calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        return selectedDate <= maxDate
    }
    
    private var minDate: Date {
        calendar.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    }
    
    private var maxDate: Date {
        calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Age label (eyebrow)
                    HStack {
                        Text("AGE")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(sectionHeaderColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    
                    // Date picker in a card
                    VStack(spacing: 12) {
                        DatePicker(
                            "Birthday",
                            selection: $selectedDate,
                            in: minDate...maxDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        
                        if !isDateValid {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text("You must be 18 or older")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .padding(.top, 8)
                        } else {
                            Text("Age: \(calculatedAge)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor.opacity(0.6))
                                .padding(.top, 8)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("Age")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    age = "\(calculatedAge)"
                    birthday = selectedDate
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(burntOrange)
                .disabled(!isDateValid)
            }
        }
        .onAppear {
            // Initialize date picker from current birthday or age
            if let existingBirthday = birthday {
                selectedDate = existingBirthday
            } else if let ageInt = Int(age), ageInt >= 18 {
                // Calculate birthday from age (approximate - use Jan 1st of that year)
                if let birthday = calendar.date(byAdding: .year, value: -ageInt, to: Date()) {
                    selectedDate = birthday
                } else {
                    selectedDate = maxDate
                }
            } else {
                // Default to 18 years ago
                selectedDate = maxDate
            }
            // Immediately hide tab bar and keep it hidden
            tabBarVisibility.isVisible = false
            // Also set it with animation after a brief delay to override any other changes
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    tabBarVisibility.isVisible = false
                }
            }
        }
        .onDisappear {
            // Don't show tab bar here - let EditProfileScreen handle it
        }
    }
}
