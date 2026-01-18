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

    @State private var name: String = ""
    @State private var currentLocation: String = ""
    @State private var about: String = ""
    @State private var travelPace: TravelPaceOption = .slow
    @State private var travelSchedule: [TravelStop] = []
    @State private var isSaving = false

    // Image upload states
    @State private var avatarItem: PhotosPickerItem?
    @State private var headerItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var headerImage: Image?
    @State private var avatarUrl: String?
    @State private var headerUrl: String?
    @State private var photos: [String] = []
    @State private var isUploadingAvatar = false
    @State private var isUploadingHeader = false
    @State private var uploadError: String?
    @State private var showUploadError = false

    @State private var showDatePicker = false
    @State private var selectedDateStopId: String = ""
    @State private var selectedDateField: DateFieldType?
    @State private var selectedDate: Date = Date()

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

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Profile")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(width: 32, height: 32)
                        .background(softGray)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            // Content
            ScrollView {
                        VStack(spacing: 0) {
                            // Header & Profile Image Section
                            VStack(spacing: 0) {
                                // Header Image
                                ZStack(alignment: .bottomTrailing) {
                                    if let headerImage = headerImage {
                                        headerImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 150)
                                            .clipped()
                                    } else if let headerUrl = headerUrl ?? photos.first, !headerUrl.isEmpty {
                                        AsyncImage(url: URL(string: headerUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(height: 150)
                                        .clipped()
                                    } else {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [forestGreen, skyBlue]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(height: 150)
                                    }

                                    PhotosPicker(selection: $headerItem, matching: .images) {
                                        HStack(spacing: 6) {
                                            if isUploadingHeader {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: charcoalColor))
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 14))
                                            }
                                            Text("Edit Cover")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(charcoalColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(Capsule())
                                    }
                                    .padding(12)
                                    .disabled(isUploadingHeader)
                                }

                                // Profile Avatar (overlapping header)
                                HStack {
                                    ZStack(alignment: .bottomTrailing) {
                                        if let avatarImage = avatarImage {
                                            avatarImage
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        } else {
                                            AsyncImage(url: URL(string: avatarUrl ?? "")) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.2))
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(charcoalColor.opacity(0.4))
                                                }
                                            }
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        }

                                        PhotosPicker(selection: $avatarItem, matching: .images) {
                                            ZStack {
                                                Circle()
                                                    .fill(burntOrange)
                                                    .frame(width: 32, height: 32)

                                                if isUploadingAvatar {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                        .scaleEffect(0.7)
                                                } else {
                                                    Image(systemName: "camera.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                        .disabled(isUploadingAvatar)
                                    }
                                    .offset(y: -50)

                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, -30)
                            }
                            .padding(.bottom, 24)

                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                TextField("Your name", text: $name)
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(softGray)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )
                            
                            // Current Location
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Location")
                                    .font(.system(size: 14, weight: .semibold))
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
                                .background(softGray)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )
                            
                            // About
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.system(size: 14, weight: .semibold))
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
                                        .background(softGray)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                
                                HStack {
                                    Spacer()
                                    Text("\(about.count)/500")
                                        .font(.system(size: 12))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )
                            
                            // Travel Pace
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Travel Pace")
                                    .font(.system(size: 14, weight: .semibold))
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
                                            .padding(16)
                                            .background(
                                                travelPace == pace ?
                                                LinearGradient(
                                                    gradient: Gradient(colors: [forestGreen, skyBlue]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ) :
                                                LinearGradient(
                                                    gradient: Gradient(colors: [softGray, softGray]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )
                            
                            // Travel Schedule
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Travel Schedule")
                                            .font(.system(size: 14, weight: .semibold))
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
                                    .padding(32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                            .foregroundColor(Color.gray.opacity(0.3))
                                    )
                                } else {
                                    VStack(spacing: 16) {
                                        ForEach(Array(travelSchedule.enumerated()), id: \.element.id) { index, stop in
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Text("Stop \(index + 1)")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(charcoalColor.opacity(0.6))
                                                    
                                                    Spacer()
                                                    
                                                    Button(action: {
                                                        travelSchedule.removeAll { $0.id == stop.id }
                                                    }) {
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
                                                        set: { newValue in
                                                            if let idx = travelSchedule.firstIndex(where: { $0.id == stop.id }) {
                                                                travelSchedule[idx].location = newValue
                                                            }
                                                        }
                                                    ))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(charcoalColor)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                
                                                HStack(spacing: 8) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("Start Date")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(charcoalColor.opacity(0.6))
                                                        
                                                        Button(action: {
                                                            selectedDateStopId = stop.id
                                                            selectedDateField = .startDate
                                                            // Parse existing date or use today
                                                            let formatter = DateFormatter()
                                                            formatter.dateFormat = "yyyy-MM-dd"
                                                            if let date = formatter.date(from: stop.startDate) {
                                                                selectedDate = date
                                                            } else {
                                                                selectedDate = Date()
                                                            }
                                                            showDatePicker = true
                                                        }) {
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
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                        }
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("End Date")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(charcoalColor.opacity(0.6))
                                                        
                                                        Button(action: {
                                                            selectedDateStopId = stop.id
                                                            selectedDateField = .endDate
                                                            // Parse existing date or use today
                                                            let formatter = DateFormatter()
                                                            formatter.dateFormat = "yyyy-MM-dd"
                                                            if let date = formatter.date(from: stop.endDate) {
                                                                selectedDate = date
                                                            } else {
                                                                selectedDate = Date()
                                                            }
                                                            showDatePicker = true
                                                        }) {
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
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(16)
                                            .background(softGray)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            
                            // Save Button
                            VStack(spacing: 0) {
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
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .disabled(isSaving)
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                .padding(.bottom, 32)
                            }
                            .background(Color.white)
                        }
                    }
                    .background(Color.white)
        }
        .onAppear {
            loadProfileData()
        }
        .onChange(of: avatarItem) { _, newItem in
            if let newItem = newItem {
                uploadAvatar(newItem)
            }
        }
        .onChange(of: headerItem) { _, newItem in
            if let newItem = newItem {
                uploadHeaderPhoto(newItem)
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
        guard let profile = profileManager.currentProfile else { return }

        name = profile.name ?? ""
        currentLocation = profile.location ?? ""
        about = profile.bio ?? ""
        travelPace = TravelPaceOption.from(profile.travelPace)
        avatarUrl = profile.avatarUrl
        photos = profile.photos
    }

    private func uploadAvatar(_ item: PhotosPickerItem) {
        isUploadingAvatar = true

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "EditProfile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load image data"])
                }

                // Show preview immediately
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        avatarImage = Image(uiImage: uiImage)
                    }
                }

                // Compress image
                guard let uiImage = UIImage(data: data),
                      let compressed = compressImage(uiImage, maxFileSizeMB: 2.0) else {
                    throw NSError(domain: "EditProfile", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
                }

                let url = try await profileManager.uploadAvatar(compressed)
                await MainActor.run {
                    avatarUrl = url
                    isUploadingAvatar = false
                }
            } catch {
                print("------- DETAILED UPLOAD ERROR (AVATAR) -------")
                print("Error Type: \(type(of: error))")
                print("Error: \(error)")
                print("Localized Description: \(error.localizedDescription)")
                
                let nsError = error as NSError
                print("NSError Domain: \(nsError.domain)")
                print("NSError Code: \(nsError.code)")
                print("NSError UserInfo: \(nsError.userInfo)")

                if let decodingError = error as? DecodingError {
                    print("DECODING ERROR: \(decodingError)")
                }
                
                print("------------------------------------")
                
                print("Failed to upload avatar: \(error)")
                await MainActor.run {
                    uploadError = "Failed to upload profile photo: \(error.localizedDescription)"
                    showUploadError = true
                    isUploadingAvatar = false
                    avatarImage = nil // Clear preview on error
                }
            }
        }
    }

    private func uploadHeaderPhoto(_ item: PhotosPickerItem) {
        isUploadingHeader = true

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "EditProfile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load image data"])
                }

                // Show preview immediately
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        headerImage = Image(uiImage: uiImage)
                    }
                }

                // Compress image
                guard let uiImage = UIImage(data: data),
                      let compressed = compressImage(uiImage, maxFileSizeMB: 2.0) else {
                    throw NSError(domain: "EditProfile", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
                }

                let url = try await profileManager.uploadPhoto(compressed)
                await MainActor.run {
                    // Insert at the beginning for header
                    photos.insert(url, at: 0)
                    isUploadingHeader = false
                }
            } catch {
                print("------- DETAILED UPLOAD ERROR -------")
                print("Error Type: \(type(of: error))")
                print("Error: \(error)")
                print("Localized Description: \(error.localizedDescription)")
                
                let nsError = error as NSError
                print("NSError Domain: \(nsError.domain)")
                print("NSError Code: \(nsError.code)")
                print("NSError UserInfo: \(nsError.userInfo)")

                if let decodingError = error as? DecodingError {
                    print("DECODING ERROR: \(decodingError)")
                }
                
                print("------------------------------------")
                
                print("Failed to upload header photo: \(error)")
                await MainActor.run {
                    uploadError = "Failed to upload cover photo: \(error.localizedDescription)"
                    showUploadError = true
                    isUploadingHeader = false
                    headerImage = nil // Clear preview on error
                }
            }
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
                    travelPace: travelPace.toBackendType
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

#Preview {
    EditProfileSheet(isPresented: .constant(true))
}
