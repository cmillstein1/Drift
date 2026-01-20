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
    @State private var simplePleasure: String = ""
    @State private var rigInfo: String = ""
    @State private var datingLooksLike: String = ""
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
                            // Photo Grid Section (Bumble/Hinge style)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("My Photos")
                                    .font(.system(size: 14, weight: .semibold))
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
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )

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

                            // My Simple Pleasure Prompt
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Rectangle()
                                        .fill(Color(red: 1.0, green: 0.37, blue: 0.37))
                                        .frame(width: 4, height: 20)
                                        .clipShape(RoundedRectangle(cornerRadius: 2))

                                    Text("My Simple Pleasure")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(charcoalColor)
                                }

                                Text("What's a small moment that brings you joy?")
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))

                                ZStack(alignment: .topLeading) {
                                    if simplePleasure.isEmpty {
                                        Text("e.g., Waking up to sunrise with a hot cup of coffee...")
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
                                        .background(softGray)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }

                                HStack {
                                    Spacer()
                                    Text("\(simplePleasure.count)/500")
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

                            // The Rig
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "box.truck.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 1.0, green: 0.37, blue: 0.37))

                                    Text("The Rig")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(charcoalColor)
                                }

                                Text("Describe your vehicle or home on wheels")
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))

                                TextField("e.g., 2019 Sprinter 144\", Self-Converted, Solar Powered", text: Binding(
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
                                    .background(softGray)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))

                                HStack {
                                    Spacer()
                                    Text("\(rigInfo.count)/300")
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

                            // Dating Me Looks Like Prompt
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Dating Me Looks Like")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)

                                Text("Paint a picture of what adventures await")
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))

                                ZStack(alignment: .topLeading) {
                                    if datingLooksLike.isEmpty {
                                        Text("e.g., Finding hidden trails and cooking dinner under the stars...")
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
                                        .frame(minHeight: 80)
                                        .scrollContentBackground(.hidden)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(softGray)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }

                                HStack {
                                    Spacer()
                                    Text("\(datingLooksLike.count)/500")
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
                travelPace = TravelPaceOption.from(profile.travelPace)
                photos = profile.photos
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
                    datingLooksLike: datingLooksLike.isEmpty ? nil : datingLooksLike
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

                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(burntOrange)
                                    .frame(width: 32, height: 32)

                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            if isMainPhoto {
                                Text("Main")
                                    .font(.system(size: 10, weight: .medium))
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

#Preview {
    EditProfileSheet(isPresented: .constant(true))
}
