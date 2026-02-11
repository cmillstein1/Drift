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
    @StateObject var profileManager = ProfileManager.shared
    @State var name: String = ""
    @State var age: String = ""
    @State var birthday: Date?
    @State var currentLocation: String = ""
    @State var about: String = ""
    @State var rigInfo: String = ""
    @State var promptAnswers: [DriftBackend.PromptAnswer] = []
    @State var travelPace: TravelPaceOption = .slow
    @State var interests: [String] = []
    @State var photos: [String] = []
    @State var photoImages: [Int: Image] = [:]
    @State var selectedPhotoIndex: Int?
    // Lifestyle fields
    @State var workStyle: WorkStyle?
    @State var homeBase: String = ""
    @State var morningPerson: Bool?
    @State var travelStopsCount: Int = 0
    @State var travelStops: [DriftBackend.TravelStop] = []
    @State var selectedPhotoItem: PhotosPickerItem?
    @State var isUploadingPhoto: Int? = nil
    @State var draggedPhoto: Int?
    @State private var isSaving = false
    @State private var showPromptsEditor = false
    @State private var hasChanges = false
    @State private var originalProfileData: ProfileSnapshot?
    @State private var hasLoadedInitialData = false
    @State var showUnsavedChangesAlert = false

    // Navigation states
    @State private var showLocationEditor = false
    @State var showTravelPaceEditor = false
    @State var showPromptEditor = false
    @State var selectedPromptIndex: Int?
    @State var showInterestEditor = false
    @State var showWorkStyleEditor = false

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
    
    let softGray = Color("SoftGray")
    let charcoalColor = Color("Charcoal")
    let burntOrange = Color("BurntOrange")
    let desertSand = Color("DesertSand")

    /// Max number of prompt answers allowed in My Journey.
    static let maxPrompts = 3

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
        let workStyle: WorkStyle?
        let homeBase: String
        let morningPerson: Bool?

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
                   lhs.photos == rhs.photos &&
                   lhs.workStyle == rhs.workStyle &&
                   lhs.homeBase == rhs.homeBase &&
                   lhs.morningPerson == rhs.morningPerson
        }
    }
    
    var body: some View {
        mainContentWithNav
            .onAppear(perform: handleOnAppear)
            .onChange(of: name) { _, _ in checkForChanges() }
            .onChange(of: age) { _, _ in checkForChanges() }
            .onChange(of: currentLocation) { _, _ in checkForChanges() }
            .onChange(of: about) { _, _ in checkForChanges() }
            .onChange(of: rigInfo) { _, _ in checkForChanges() }
            .onChange(of: promptAnswers.count) { _, _ in checkForChanges() }
            .onChange(of: travelPace) { _, _ in checkForChanges() }
            .onChange(of: interests) { _, _ in checkForChanges() }
            .onChange(of: photos) { _, _ in checkForChanges() }
            .onChange(of: workStyle) { _, _ in checkForChanges() }
            .onChange(of: homeBase) { _, _ in checkForChanges() }
            .onChange(of: morningPerson) { _, _ in checkForChanges() }
            .photosPicker(isPresented: photosPickerBinding, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in handlePhotoSelection(newItem) }
            .sheet(isPresented: $showInterestEditor) { interestEditorSheet }
            .sheet(isPresented: $showTravelPaceEditor) { travelPaceEditorSheet }
            .sheet(isPresented: $showWorkStyleEditor) { workStyleEditorSheet }
            .sheet(isPresented: $showPromptEditor) { promptEditorSheet }
    }

    private var mainContentWithNav: some View {
        mainContent
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
                unsavedChangesAlertButtons
            } message: {
                Text("You have unsaved changes. Would you like to save them before leaving?")
            }
    }

    // MARK: - Main Content

    private var mainContent: some View {
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
    }

    // MARK: - Lifecycle Handlers

    private func handleOnAppear() {
        if !hasLoadedInitialData {
            loadProfileData()
            hasLoadedInitialData = true
        }
    }

    private func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        if let item = newItem, let index = selectedPhotoIndex {
            uploadPhoto(item, at: index)
            selectedPhotoItem = nil
        }
    }

    private var photosPickerBinding: Binding<Bool> {
        Binding(
            get: { selectedPhotoIndex != nil },
            set: { if !$0 { selectedPhotoIndex = nil } }
        )
    }

    // MARK: - Sheet Views

    private var interestEditorSheet: some View {
        InterestEditorSheet(
            selectedInterests: $interests,
            isPresented: $showInterestEditor
        )
    }

    private var travelPaceEditorSheet: some View {
        TravelPaceEditorSheet(
            travelPace: $travelPace,
            isPresented: $showTravelPaceEditor
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var workStyleEditorSheet: some View {
        WorkStyleEditorSheet(
            workStyle: $workStyle,
            isPresented: $showWorkStyleEditor
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var promptEditorSheet: some View {
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

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                if hasChanges {
                    showUnsavedChangesAlert = true
                } else {
                    onBack()
                }
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

    // MARK: - Unsaved Changes Alert Buttons

    @ViewBuilder
    private var unsavedChangesAlertButtons: some View {
        Button("Save", role: .none) {
            saveChanges()
        }
        Button("Discard", role: .destructive) {
            onBack()
        }
        Button("Cancel", role: .cancel) { }
    }

    // MARK: - Edit Tab Content

    private var editTabContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                photosSection
                travelPlansSection
                vanLifeEssentialsSection
                myJourneySection
                lifestyleSection
                interestsSection
            }
            .padding(16)
        }
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

        print("🟢 [LOAD] loadProfileData() called")
        print("🟢 [LOAD] profile.workStyle: \(String(describing: profile.workStyle))")
        print("🟢 [LOAD] profile.homeBase: \(String(describing: profile.homeBase))")
        print("🟢 [LOAD] profile.morningPerson: \(String(describing: profile.morningPerson))")

        // Load travel stops
        Task {
            do {
                let stops = try await profileManager.fetchTravelSchedule()
                await MainActor.run {
                    travelStops = stops
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
            photos: photos,
            workStyle: workStyle,
            homeBase: homeBase,
            morningPerson: morningPerson
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
            photos: photos,
            workStyle: workStyle,
            homeBase: homeBase,
            morningPerson: morningPerson
        )

        let changed = current != original
        if changed != hasChanges {
            print("🟡 [CHANGES] hasChanges: \(changed)")
            if original.workStyle != current.workStyle {
                print("🟡 [CHANGES] workStyle changed: \(String(describing: original.workStyle)) -> \(String(describing: current.workStyle))")
            }
            if original.homeBase != current.homeBase {
                print("🟡 [CHANGES] homeBase changed: \(original.homeBase) -> \(current.homeBase)")
            }
            if original.morningPerson != current.morningPerson {
                print("🟡 [CHANGES] morningPerson changed: \(String(describing: original.morningPerson)) -> \(String(describing: current.morningPerson))")
            }
        }
        hasChanges = changed
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
    
    func removePhoto(at index: Int) {
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
        ImageCompression.compressImage(image, maxFileSizeMB: maxFileSizeMB)
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

        print("🔵 [SAVE] saveChanges() called")
        print("🔵 [SAVE] workStyle: \(String(describing: workStyle))")
        print("🔵 [SAVE] homeBase: \(homeBase)")
        print("🔵 [SAVE] morningPerson: \(String(describing: morningPerson))")

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
                print("🔵 [SAVE] Calling profileManager.updateProfile...")
                try await profileManager.updateProfile(updates)
                print("🔵 [SAVE] updateProfile succeeded!")
                await MainActor.run {
                    if promptAnswers.count > Self.maxPrompts {
                        promptAnswers = cappedPrompts
                    }
                    isSaving = false
                    onBack()
                }
            } catch {
                print("🔴 [SAVE] Failed to save profile: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Helpers

struct EditProfileInterestItem: Identifiable {
    let id: String
    let name: String

    init(_ name: String) {
        self.id = name
        self.name = name
    }
}

// MARK: - Photo Drop Delegate

struct EditProfilePhotoDropDelegate: DropDelegate {
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

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

