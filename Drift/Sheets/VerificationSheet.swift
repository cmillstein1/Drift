//
//  VerificationSheet.swift
//  Drift
//
//  Created for VerifyFaceID integration
//

import SwiftUI
import DriftBackend

struct VerificationView: View {
    @StateObject private var verifyFaceIDManager = VerifyFaceIDManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isVerifying = false
    @State private var verificationResult: VerificationState = .idle
    @State private var errorMessage: String?
    
    enum VerificationState: Equatable {
        case idle
        case verifying
        case success
        case failure(String)
    }
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Done button
                HStack {
                    Spacer()
                    Button(action: {
                        tabBarVisibility.isVisible = true
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                
                // Content based on state
                switch verificationResult {
                case .idle:
                    idleContent
                case .verifying:
                    verifyingContent
                case .success:
                    successContent
                case .failure(let message):
                    failureContent(message: message)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Hide tab bar when verification screen appears
            tabBarVisibility.isVisible = false
        }
        .onDisappear {
            // Show tab bar when verification screen disappears
            tabBarVisibility.isVisible = true
        }
        .fullScreenCover(isPresented: $showCamera) {
            FaceVerificationCameraView(capturedImage: $capturedImage)
                .ignoresSafeArea(.all)
        }
        .onChange(of: capturedImage) { oldValue, newValue in
            if let image = newValue {
                verifyFace(image: image)
            }
        }
    }
    
    // MARK: - Content Views
    
    private var idleContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon with badge
            VStack(spacing: 0) {
                ZStack {
                    // Large gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                    
                    // Shield checkmark icon
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.white)
                }
                .overlay(alignment: .bottomTrailing) {
                    // Small checkmark badge
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .padding(.bottom, 32)
            
            // Title
            Text("Verify Your Identity")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(charcoalColor)
                .padding(.bottom, 12)
            
            // Description
            Text("Take a selfie to verify your identity. We'll compare it with your profile photo.")
                .font(.system(size: 16))
                .foregroundColor(charcoalColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            
            // Instructions Card
            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(
                    number: "1",
                    text: "Make sure you're in good lighting"
                )
                InstructionRow(
                    number: "2",
                    text: "Look directly at the camera"
                )
                InstructionRow(
                    number: "3",
                    text: "Remove any face coverings"
                )
            }
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            Spacer()
            
            // Take Selfie Button
            Button(action: {
                showCamera = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Take Selfie")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [burntOrange, sunsetRose]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: burntOrange.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var verifyingContent: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(burntOrange)
            
            Text("Verifying your identity...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(charcoalColor.opacity(0.7))
        }
        .padding(40)
    }
    
    private var successContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Large gradient checkmark icon
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [burntOrange, sunsetRose]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 32)
            
            // Title
            Text("You're Verified!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(charcoalColor)
                .padding(.bottom, 16)
            
            // Description
            Text("Your profile now has a verification badge. This helps build trust in the Drift community.")
                .font(.system(size: 16))
                .foregroundColor(charcoalColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            
            // Verified Member Badge Card
            HStack(spacing: 16) {
                // Small gradient icon
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, sunsetRose]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Verified Member")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(charcoalColor)
                    
                    Text("Identity confirmed")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            Spacer()
            
            // Done Button
            Button(action: {
                tabBarVisibility.isVisible = true
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, sunsetRose]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: burntOrange.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func failureContent(message: String) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                
                Text("Verification Failed")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(charcoalColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    verificationResult = .idle
                    capturedImage = nil
                }) {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(burntOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(40)
        }
    }
    
    
    // MARK: - Functions
    
    private func verifyFace(image: UIImage) {
        guard let profile = profileManager.currentProfile else {
            verificationResult = .failure("Profile not found")
            return
        }
        
        // Get reference photo URL (use avatar or first photo)
        guard let referenceURL = profile.primaryDisplayPhotoUrl, !referenceURL.isEmpty else {
            verificationResult = .failure("Please add a profile photo first")
            return
        }
        
        // Resize and compress selfie image to ensure it's suitable for face detection
        // Face detection works better with images that are at least 200x200 pixels
        let targetSize = CGSize(width: 800, height: 800)
        let resizedImage = image.resized(to: targetSize, aspectFill: true)
        
        // Convert image to JPEG data with good quality
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.85) else {
            verificationResult = .failure("Failed to process image")
            return
        }
        
        print("📸 Verification starting...")
        print("📸 Reference URL: \(referenceURL)")
        print("📸 Selfie size: \(imageData.count) bytes")
        
        // Verify reference URL is accessible
        Task {
            do {
                // Test if reference URL is accessible
                if let url = URL(string: referenceURL) {
                    let (_, response) = try await URLSession.shared.data(from: url)
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📸 Reference URL status: \(httpResponse.statusCode)")
                        if httpResponse.statusCode != 200 {
                            await MainActor.run {
                                verificationResult = .failure("Reference photo is not accessible. Please try again.")
                                isVerifying = false
                            }
                            return
                        }
                    }
                }
            } catch {
                print("⚠️ Could not verify reference URL accessibility: \(error)")
                // Continue anyway - might still work
            }
            
            await MainActor.run {
                verificationResult = .verifying
                isVerifying = true
            }
            
            do {
                let result = try await verifyFaceIDManager.verifyFace(
                    referenceURL: referenceURL,
                    selfieImageData: imageData
                )
                
                // Update profile to verified
                try await profileManager.updateProfile(
                    ProfileUpdateRequest(verified: true)
                )
                
                await MainActor.run {
                    verificationResult = .success
                    isVerifying = false
                }
            } catch let error as VerifyFaceIDError {
                await MainActor.run {
                    isVerifying = false
                    verificationResult = .failure(error.localizedDescription ?? "Verification failed")
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    verificationResult = .failure(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: String
    let text: String
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        HStack(spacing: 16) {
            // Number circle
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoalColor)
            }
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(charcoalColor)
            
            Spacer()
        }
    }
}


#Preview {
    NavigationStack {
        VerificationView()
    }
}
