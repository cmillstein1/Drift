//
//  GenerateInviteSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/24/26.
//

import SwiftUI
import UIKit
import LinkPresentation
import DriftBackend

struct GenerateInviteSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @StateObject private var inviteManager = InviteManager.shared
    @State private var showShareSheet = false
    @State private var copied = false
    @State private var characterAnimations: [Bool] = []
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let code = inviteManager.currentInviteCode {
                        inviteCodeContent(code: code)
                    } else if inviteManager.isGenerating {
                        loadingContent
                    } else if let error = inviteManager.error {
                        errorContent(error: error)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
            .scrollContentBackground(.hidden)
            .background(softGray)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(softGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .background {
            softGray
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showShareSheet) {
            if let code = inviteManager.currentInviteCode {
                ShareSheet(items: [ShareItemWithIcon(text: "Join me on Drift! Use my invite code: \(code)", inviteCode: code)])
            }
        }
        .onAppear {
            // Generate code when sheet appears
            if inviteManager.currentInviteCode == nil && !inviteManager.isGenerating {
                Task {
                    await inviteManager.generateInviteCode()
                }
            }
        }
        .onChange(of: inviteManager.currentInviteCode) { oldValue, newValue in
            if let code = newValue {
                // Animate characters appearing one by one
                characterAnimations = Array(repeating: false, count: code.count)
                for index in 0..<code.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                        if index < characterAnimations.count {
                            characterAnimations[index] = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Invite code content (properly spaced)
    
    @ViewBuilder
    private func inviteCodeContent(code: String) -> some View {
        VStack(alignment: .center, spacing: 24) {
            // Header icon
            Image("RV_Only")
                .resizable()
                .scaledToFit()
                .frame(width: 124, height: 124)
                .padding(.top, 8)
            
            Text("Your Invite Code")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(charcoalColor)
            
            // Subtitle — single block with line spacing so it never overlaps
            Text("Share this code with friends to invite them to Drift")
                .font(.subheadline)
                .foregroundColor(charcoalColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
            
            // Code display
            VStack(spacing: 14) {
                Text("INVITE CODE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .tracking(1.4)
                HStack(spacing: 8) {
                    ForEach(Array(code.enumerated()), id: \.offset) { index, char in
                        CharacterBox(
                            character: String(char),
                            index: index,
                            isAnimated: characterAnimations.count > index ? characterAnimations[index] : false
                        )
                    }
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [desertSand, desertSand.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            // Info card
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(skyBlue.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text("🎁")
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite Your Community")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(charcoalColor)
                    Text("Friends who join with your code get priority access. Help grow the Drift community!")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [skyBlue.opacity(0.1), forestGreen.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(skyBlue.opacity(0.2), lineWidth: 1)
            )
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: handleCopy) {
                    HStack(spacing: 8) {
                        if copied {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                        } else {
                            Image(systemName: "square.on.square")
                                .font(.system(size: 20, weight: .medium))
                        }
                        Text(copied ? "Copied!" : "Copy Code")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, sunsetRose]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: burntOrange.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: { showShareSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .medium))
                        Text("Share Invite")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(charcoalColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(charcoalColor.opacity(0.25), lineWidth: 2)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(burntOrange)
            Text("Generating invite code...")
                .font(.system(size: 16))
                .foregroundColor(charcoalColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private func errorContent(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Error")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(charcoalColor)
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private func handleCopy() {
        guard let code = inviteManager.currentInviteCode else { return }
        
        UIPasteboard.general.string = code
        copied = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

// MARK: - Character Box

struct CharacterBox: View {
    let character: String
    let index: Int
    let isAnimated: Bool
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .frame(width: 48, height: 56)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            
            Text(character)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(charcoalColor)
        }
        .scaleEffect(isAnimated ? 1.0 : 0)
        .rotationEffect(.degrees(isAnimated ? 0 : -180))
        .animation(
            .spring(response: 0.5, dampingFraction: 0.6),
            value: isAnimated
        )
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Item with App Icon

class ShareItemWithIcon: NSObject, UIActivityItemSource {
    let text: String
    let inviteCode: String
    let appIcon: UIImage?
    
    init(text: String, inviteCode: String) {
        self.text = text
        self.inviteCode = inviteCode
        
        // Get app icon - try multiple methods
        var icon: UIImage?
        
        // Method 1: Try AppIcon from assets
        if let assetIcon = UIImage(named: "AppIcon") {
            icon = assetIcon
        }
        
        // Method 2: Try to get from bundle icons
        if icon == nil {
            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
               let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
               let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
               let firstIconName = iconFiles.first {
                icon = UIImage(named: firstIconName)
            }
        }
        
        // Method 3: Try common app icon asset names
        if icon == nil {
            let commonNames = ["AppIcon-60x60", "AppIcon-76x76", "AppIcon-1024x1024", "Icon-60", "Icon-76", "Icon"]
            for name in commonNames {
                if let foundIcon = UIImage(named: name) {
                    icon = foundIcon
                    break
                }
            }
        }
        
        self.appIcon = icon
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        // Return URL so iOS uses link metadata for preview
        return URL(string: "https://drift.app/invite?code=\(inviteCode)")!
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // Return URL so the link metadata preview works
        // The URL contains the invite code, and the preview shows the app icon
        return URL(string: "https://drift.app/invite?code=\(inviteCode)")
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Join me on Drift!"
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Join me on Drift!"
        metadata.originalURL = URL(string: "https://drift.app/invite?code=\(inviteCode)")
        
        // Set the app icon as the preview image - iOS will display this in the preview box
        if let icon = appIcon {
            // Create a high-resolution square version (iOS prefers square images for link previews)
            let targetSize: CGFloat = 1024 // Large size for crisp display
            let squareSize = CGSize(width: targetSize, height: targetSize)
            
            UIGraphicsBeginImageContextWithOptions(squareSize, false, 0)
            defer { UIGraphicsEndImageContext() }
            
            // Draw icon to fill the entire square
            icon.draw(in: CGRect(origin: .zero, size: squareSize))
            
            if let squareIcon = UIGraphicsGetImageFromCurrentImageContext() {
                let imageProvider = NSItemProvider(object: squareIcon)
                metadata.imageProvider = imageProvider
            }
        }
        
        return metadata
    }
}

#Preview {
    GenerateInviteSheet(isPresented: .constant(true))
}
