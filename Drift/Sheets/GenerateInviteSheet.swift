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
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Invite Code")
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
            .background(softGray)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    if let code = inviteManager.currentInviteCode {
                        // Show generated code
                        VStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(burntOrange.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(burntOrange)
                            }
                            .padding(.top, 32)
                            
                            // Code Display
                            VStack(spacing: 8) {
                                Text("Your Invite Code")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                
                                Text(code)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(charcoalColor)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(burntOrange.opacity(0.3), lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            }
                            
                            // Info text
                            Text("Share this code with a friend to invite them to Drift")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 24)
                    } else if inviteManager.isGenerating {
                        // Loading state
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
                    } else {
                        // Error state
                        if let error = inviteManager.error {
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
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            
            // Share Button (only show when code is generated)
            if inviteManager.currentInviteCode != nil {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("Share")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(burntOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(softGray)
                }
            }
        }
        .background(softGray)
        .sheet(isPresented: $showShareSheet) {
            if let code = inviteManager.currentInviteCode {
                ShareSheet(items: [ShareItemWithIcon(text: "Join me on Drift! Use my invite code: \(code)")])
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
    let appIcon: UIImage?
    
    init(text: String) {
        self.text = text
        
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
        
        // Method 3: Try common app icon names
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
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Join me on Drift!"
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Join me on Drift!"
        metadata.originalURL = URL(string: "https://drift.app")
        
        // Set the app icon as the preview image
        if let icon = appIcon {
            let imageProvider = NSItemProvider(object: icon)
            metadata.imageProvider = imageProvider
        }
        
        return metadata
    }
}

#Preview {
    GenerateInviteSheet(isPresented: .constant(true))
}
