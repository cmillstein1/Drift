//
//  PhotoUploadScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import PhotosUI

struct PhotoSlot: Identifiable {
    let id: Int
    var image: UIImage?
}

struct PhotoUploadScreen: View {
    let onContinue: () -> Void
    
    @State private var photos: [PhotoSlot] = [
        PhotoSlot(id: 1, image: nil),
        PhotoSlot(id: 2, image: nil),
        PhotoSlot(id: 3, image: nil),
        PhotoSlot(id: 4, image: nil),
        PhotoSlot(id: 5, image: nil),
        PhotoSlot(id: 6, image: nil)
    ]
    @State private var selectedPhotoIndex: Int? = nil
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var gridOpacity: [Double] = Array(repeating: 0, count: 6)
    @State private var gridScale: [Double] = Array(repeating: 0.9, count: 6)
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    private var uploadedCount: Int {
        photos.filter { $0.image != nil }.count
    }
    
    private var canContinue: Bool {
        uploadedCount >= 2
    }
    
    var body: some View {
        ZStack {
            warmWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ProgressIndicator(currentStep: 5, totalSteps: 8)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("My photos")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(charcoalColor)
                                .opacity(titleOpacity)
                                .offset(x: titleOffset)
                            
                            Text("Add at least 2 photos to continue")
                                .font(.system(size: 16))
                                .foregroundColor(charcoalColor.opacity(0.7))
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                                .opacity(subtitleOpacity)
                                .offset(x: subtitleOffset)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        
                        // Photo Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                                PhotoSlotView(
                                    photo: photo,
                                    opacity: gridOpacity[index],
                                    scale: gridScale[index],
                                    onTap: {
                                        selectedPhotoIndex = index
                                    },
                                    onRemove: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            photos[index].image = nil
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Helper Text
                        HStack {
                            Text("\(uploadedCount)/6 photos uploaded")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor.opacity(0.8))
                            
                            Spacer()
                            
                            if uploadedCount >= 2 {
                                Text("Drag to reorder")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                
                VStack(spacing: 12) {
                    if uploadedCount < 2 {
                        Text(uploadedCount == 0 ? "Photos are required to continue" : "\(2 - uploadedCount) more photo needed")
                            .font(.system(size: 14))
                            .foregroundColor(burntOrange)
                    }
                    
                    Button(action: {
                        onContinue()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canContinue ? burntOrange : Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .disabled(!canContinue)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map { PhotoPickerItem(id: $0) } },
            set: { selectedPhotoIndex = $0?.id }
        )) { item in
            PhotoPicker(selectedImage: Binding(
                get: { photos[item.id].image },
                set: { photos[item.id].image = $0 }
            ))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                subtitleOpacity = 1
                subtitleOffset = 0
            }
            
            for index in 0..<6 {
                withAnimation(.easeOut(duration: 0.4).delay(0.2 + Double(index) * 0.1)) {
                    gridOpacity[index] = 1
                    gridScale[index] = 1
                }
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
    }
}

struct PhotoPickerItem: Identifiable {
    let id: Int
}

struct PhotoSlotView: View {
    let photo: PhotoSlot
    let opacity: Double
    let scale: Double
    let onTap: () -> Void
    let onRemove: () -> Void
    
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    var body: some View {
        ZStack {
            if let image = photo.image {
                // Uploaded Photo
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        Button(action: onRemove) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(burntOrange)
                                .clipShape(Circle())
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
                    .onTapGesture {
                        onTap()
                    }
            } else {
                // Empty Slot
                Button(action: onTap) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.gray.opacity(0.3))
                            .frame(height: 180)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 48))
                                .foregroundColor(burntOrange.opacity(0.4))
                            
                            ZStack {
                                Circle()
                                    .fill(burntOrange)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .opacity(opacity)
        .scaleEffect(scale)
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            let provider = result.itemProvider
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    DispatchQueue.main.async {
                        if let image = object as? UIImage {
                            self.parent.selectedImage = image
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoUploadScreen {
        print("Continue tapped")
    }
}
