//
//  CreateCommunityPostSheet.swift
//  Drift
//
//  Sheet for creating community posts (events and help requests)
//

import SwiftUI
import PhotosUI
import DriftBackend

struct CreateCommunityPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// When non-nil, the sheet is in edit mode for this event post: pre-filled and shows "Update" instead of "Post".
    var existingPost: CommunityPost? = nil
    @StateObject private var communityManager = CommunityManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var selectedType: CommunityPostType? = .event
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var eventPrivacy: EventPrivacy = .public
    @State private var showPrivacyDetails: Bool = false
    @State private var isDatingActivity: Bool = false
    @State private var selectedCategory: HelpCategory? = nil
    @State private var location: String = ""
    @State private var eventLatitude: Double? = nil
    @State private var eventLongitude: Double? = nil
    @State private var showLocationPicker: Bool = false
    @State private var maxAttendees: String = ""
    @State private var eventDate: Date = Date()
    @State private var eventTime: Date = Date()
    @State private var isSubmitting: Bool = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var showPhotoPicker: Bool = false

    private var isEditMode: Bool { existingPost != nil && existingPost?.type == .event }

    /// Only show "Dating activity" option when user is not in friends-only mode (i.e. they have dating or both discovery).
    private var hasDatingEnabled: Bool {
        supabaseManager.getDiscoveryMode() != .friends
    }

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    private var isFormValid: Bool {
        guard let type = selectedType else { return false }
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let hasDetails = !details.trimmingCharacters(in: .whitespaces).isEmpty

        if type == .help {
            return hasTitle && hasDetails && selectedCategory != nil
        }
        return hasTitle && hasDetails
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !isEditMode {
                        postTypeSelection
                    }
                    titleInput
                    detailsInput

                    if selectedType == .event {
                        eventFields
                    } else if selectedType == .help {
                        helpFields
                    }
                }
                .padding(24)
            }

            footerView
        }
        .background(warmWhite)
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(
                locationName: $location,
                latitude: $eventLatitude,
                longitude: $eventLongitude
            )
        }
        .onAppear { prefillIfEditing() }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditMode ? "Edit Event" : "Create Post")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(charcoal)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoal)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Post Type Selection

    private var postTypeSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Post Type *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoal)

            HStack(spacing: 12) {
                PostTypeCard(
                    type: .event,
                    isSelected: selectedType == .event,
                    onTap: { selectedType = .event }
                )
                PostTypeCard(
                    type: .help,
                    isSelected: selectedType == .help,
                    onTap: { selectedType = .help }
                )
            }
        }
    }

    // MARK: - Title Input

    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoal)

            TextField("What's this about?", text: $title)
                .font(.system(size: 16))
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
        }
    }

    // MARK: - Details Input

    private var detailsInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                Text("Details")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(charcoal)

            TextField("Tell people more...", text: $details, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(4...8)
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)

            Button {
                submitPost()
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isSubmitting ? (isEditMode ? "Updating..." : "Posting...") : (isEditMode ? "Update" : "Post"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(isFormValid && !isSubmitting ? .white : Color.gray.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isFormValid && !isSubmitting ? burntOrange : Color.gray.opacity(0.3))
                .clipShape(Capsule())
            }
            .disabled(!isFormValid || isSubmitting)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(warmWhite)
    }

    // MARK: - Helper Functions

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func prefillIfEditing() {
        guard let p = existingPost, p.type == .event else { return }
        selectedType = .event
        title = p.title
        details = p.content
        eventPrivacy = p.eventPrivacy ?? .public
        isDatingActivity = p.isDatingEvent ?? false
        location = p.eventLocation ?? ""
        eventLatitude = p.eventLatitude
        eventLongitude = p.eventLongitude
        maxAttendees = p.maxAttendees.map { String($0) } ?? ""
        if let dt = p.eventDatetime {
            let cal = Calendar.current
            eventDate = cal.startOfDay(for: dt)
            eventTime = dt
        }
    }

    private func submitPost() {
        guard let type = selectedType, isFormValid else { return }
        isSubmitting = true

        Task {
            do {
                if type == .event {
                    let calendar = Calendar.current
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: eventTime)
                    var combined = DateComponents()
                    combined.year = dateComponents.year
                    combined.month = dateComponents.month
                    combined.day = dateComponents.day
                    combined.hour = timeComponents.hour
                    combined.minute = timeComponents.minute
                    let eventDatetime = calendar.date(from: combined) ?? eventDate

                    if let postId = existingPost?.id, existingPost?.type == .event {
                        try await communityManager.updateEventPost(
                            postId,
                            title: title.trimmingCharacters(in: .whitespaces),
                            content: details.trimmingCharacters(in: .whitespaces),
                            datetime: eventDatetime,
                            location: location.isEmpty ? nil : location,
                            latitude: eventLatitude,
                            longitude: eventLongitude,
                            maxAttendees: Int(maxAttendees),
                            privacy: eventPrivacy,
                            isDatingEvent: hasDatingEnabled ? isDatingActivity : false
                        )
                    } else {
                        // Fetch header image from Unsplash once; store URL with post so card and detail use same image (no further API calls).
                        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
                        var eventImages: [String] = []
                        if !trimmedTitle.isEmpty {
                            let key = ProcessInfo.processInfo.environment["UNSPLASH_ACCESS_KEY"] ?? UnsplashConfig.accessKey
                            if let url = await UnsplashManager.fetchFirstImageURL(query: trimmedTitle, accessKey: key) {
                                eventImages = [url]
                            }
                        }
                        _ = try await communityManager.createEventPost(
                            title: trimmedTitle,
                            content: details.trimmingCharacters(in: .whitespaces),
                            datetime: eventDatetime,
                            location: location.isEmpty ? nil : location,
                            latitude: eventLatitude,
                            longitude: eventLongitude,
                            maxAttendees: Int(maxAttendees),
                            privacy: eventPrivacy,
                            images: eventImages,
                            isDatingEvent: hasDatingEnabled ? isDatingActivity : false
                        )
                    }
                } else {
                    var imageUrls: [String] = []
                    for image in selectedPhotos {
                        if let imageData = compressImage(image, maxFileSizeMB: 2.0) {
                            let url = try await communityManager.uploadPostImage(imageData)
                            imageUrls.append(url)
                        }
                    }

                    _ = try await communityManager.createHelpPost(
                        title: title.trimmingCharacters(in: .whitespaces),
                        content: details.trimmingCharacters(in: .whitespaces),
                        category: selectedCategory ?? .other,
                        images: imageUrls
                    )
                }
                dismiss()
            } catch {
                print("Failed to create post: \(error)")
                isSubmitting = false
            }
        }
    }

    // MARK: - Image Compression

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)

        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func compressImage(_ image: UIImage, maxFileSizeMB: Double) -> Data? {
        let resized = resizeImage(image, maxDimension: 1200)
        let maxFileSizeBytes = Int(maxFileSizeMB * 1024 * 1024)
        var compressionQuality: CGFloat = 0.8
        var imageData = resized.jpegData(compressionQuality: compressionQuality)

        while let data = imageData, data.count > maxFileSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = resized.jpegData(compressionQuality: compressionQuality)
        }

        return imageData
    }
}

// MARK: - Event Fields Extension

extension CreateCommunityPostSheet {

    @ViewBuilder
    var eventFields: some View {
        VStack(spacing: 16) {
            dateTimeRow
            locationField
            maxAttendeesField
            privacySettings

            if hasDatingEnabled {
                datingToggle
            }
        }
    }

    private var dateTimeRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text("Date *")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(charcoal)

                DatePicker("", selection: $eventDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                    Text("Time")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(charcoal)

                DatePicker("", selection: $eventTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
            }
        }
    }

    private var locationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "mappin")
                    .font(.system(size: 14))
                Text("Location")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(charcoal)

            Button {
                showLocationPicker = true
            } label: {
                HStack {
                    if location.isEmpty {
                        Text("Select location on map")
                            .font(.system(size: 16))
                            .foregroundColor(charcoal.opacity(0.4))
                    } else {
                        Text(location)
                            .font(.system(size: 16))
                            .foregroundColor(charcoal)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "map")
                        .font(.system(size: 16))
                        .foregroundColor(burntOrange)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(eventLatitude != nil ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                )
            }
        }
    }

    private var maxAttendeesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "person.2")
                    .font(.system(size: 14))
                Text("Max Attendees")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(charcoal)

            TextField("Leave empty for unlimited", text: $maxAttendees)
                .font(.system(size: 16))
                .keyboardType(.numberPad)
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
        }
    }

    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lock")
                        .font(.system(size: 14))
                    Text("Privacy Settings")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(charcoal)

                Spacer()

                Button {
                    withAnimation {
                        showPrivacyDetails.toggle()
                    }
                } label: {
                    Text(showPrivacyDetails ? "Hide" : "Learn more")
                        .font(.system(size: 14))
                        .foregroundColor(burntOrange)
                }
            }

            VStack(spacing: 12) {
                PrivacyOptionButton(
                    title: EventPrivacy.public.displayName,
                    description: EventPrivacy.public.description,
                    icon: EventPrivacy.public.icon,
                    iconColor: forestGreen,
                    isSelected: eventPrivacy == .public,
                    accentColor: burntOrange,
                    onTap: { eventPrivacy = .public }
                )

                PrivacyOptionButton(
                    title: EventPrivacy.private.displayName,
                    description: EventPrivacy.private.description,
                    icon: EventPrivacy.private.icon,
                    iconColor: charcoal,
                    isSelected: eventPrivacy == .private,
                    accentColor: burntOrange,
                    onTap: { eventPrivacy = .private }
                )
            }

            if showPrivacyDetails {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(skyBlue)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("**Public:** Anyone can see all details and join directly.")
                        Text("**Private:** Date and description visible, but location and attendees hidden until approved. You approve each join request.")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(charcoal.opacity(0.7))
                }
                .padding(12)
                .background(skyBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
        )
    }

    private var datingToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.circle")
                .font(.system(size: 16))
                .foregroundColor(burntOrange)
            Text("Dating activity?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoal)
            Spacer()
            Toggle("", isOn: $isDatingActivity)
                .toggleStyle(SwitchToggleStyle(tint: burntOrange))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
        )
    }
}

// MARK: - Help Fields Extension

extension CreateCommunityPostSheet {

    @ViewBuilder
    var helpFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            categoryPicker
            photosSection
        }
        .sheet(isPresented: $showPhotoPicker) {
            HelpPostPhotoPicker(
                maxSelection: 4 - selectedPhotos.count,
                onImagesSelected: { images in
                    let remainingSlots = 4 - selectedPhotos.count
                    let imagesToAdd = Array(images.prefix(remainingSlots))
                    selectedPhotos.append(contentsOf: imagesToAdd)
                }
            )
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoal)

            Menu {
                ForEach(HelpCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.displayName)
                        }
                    }
                }
            } label: {
                HStack {
                    if let category = selectedCategory {
                        Image(systemName: category.icon)
                            .foregroundColor(Color(category.color))
                        Text(category.displayName)
                            .font(.system(size: 16))
                            .foregroundColor(charcoal)
                    } else {
                        Text("Select a category...")
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(charcoal.opacity(0.4))
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 14))
                Text("Photos")
                    .font(.system(size: 14, weight: .medium))
                Text("(optional)")
                    .font(.system(size: 12))
                    .foregroundColor(charcoal.opacity(0.5))
            }
            .foregroundColor(charcoal)

            if selectedPhotos.isEmpty {
                addPhotosButton
            } else {
                photosGrid
            }
        }
    }

    private var addPhotosButton: some View {
        Button {
            showPhotoPicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(burntOrange)
                Text("Add photos")
                    .font(.system(size: 16))
                    .foregroundColor(charcoal)
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }

    private var photosGrid: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, image in
                    photoThumbnail(image: image, index: index)
                }

                if selectedPhotos.count < 4 {
                    addMoreButton
                }
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.5, opacity: 0.3), lineWidth: 2)
            )

            Text("\(selectedPhotos.count)/4 photos")
                .font(.system(size: 12))
                .foregroundColor(charcoal.opacity(0.5))
        }
    }

    private func photoThumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                withAnimation {
                    _ = selectedPhotos.remove(at: index)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }

    private var addMoreButton: some View {
        Button {
            showPhotoPicker = true
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.5, opacity: 0.1))
                .frame(height: 80)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(charcoal.opacity(0.4))
                )
        }
    }
}

// MARK: - Help Post Photo Picker

struct HelpPostPhotoPicker: UIViewControllerRepresentable {
    let maxSelection: Int
    let onImagesSelected: ([UIImage]) -> Void
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelection

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: HelpPostPhotoPicker

        init(_ parent: HelpPostPhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else { return }

            var loadedImages: [UIImage] = []
            let group = DispatchGroup()

            for result in results {
                group.enter()
                let provider = result.itemProvider

                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage {
                            loadedImages.append(image)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.parent.onImagesSelected(loadedImages)
            }
        }
    }
}

// MARK: - Privacy Option Button

struct PrivacyOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    private let charcoal = Color("Charcoal")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(charcoal)

                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(charcoal.opacity(0.6))
                }

                Spacer()

                if isSelected {
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 20, height: 20)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? accentColor.opacity(0.05) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

// MARK: - Post Type Card

struct PostTypeCard: View {
    let type: CommunityPostType
    let isSelected: Bool
    let onTap: () -> Void

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")

    private var iconColor: Color {
        switch type {
        case .event: return .purple
        case .help: return burntOrange
        }
    }

    private var icon: String {
        switch type {
        case .event: return "calendar"
        case .help: return "wrench.and.screwdriver"
        }
    }

    private var title: String {
        switch type {
        case .event: return "Event"
        case .help: return "Help"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? iconColor : charcoal.opacity(0.6))

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? charcoal : charcoal.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? burntOrange.opacity(0.05) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}
