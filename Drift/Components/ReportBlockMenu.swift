//
//  ReportBlockMenu.swift
//  Drift
//
//  Report and Block menu for message screen and dating/friends profiles.
//

import SwiftUI
import DriftBackend

/// A 3-dot menu that shows "Report" and "Block". Block asks for confirmation (native alert), then calls the backend and shows success. Report is a no-op for now.
struct ReportBlockMenu: View {
    let userId: UUID?
    var displayName: String? = nil
    var onReport: () -> Void = {}
    var onBlockComplete: (() -> Void)? = nil

    @StateObject private var friendsManager = FriendsManager.shared
    @State private var isBlocking = false
    @State private var blockError: String?
    @State private var showBlockError = false
    @State private var showBlockConfirm = false
    @State private var pendingBlockUserId: UUID?
    @State private var pendingBlockDisplayName: String = "this user"
    @State private var showBlockSuccess = false
    @State private var successBlockName: String = ""

    private let charcoalColor = Color("Charcoal")
    private var resolvedDisplayName: String { displayName ?? "this user" }

    var body: some View {
        Menu {
            Button {
                onReport()
            } label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            }

            Button(role: .destructive) {
                guard let userId else { return }
                pendingBlockUserId = userId
                pendingBlockDisplayName = resolvedDisplayName
                showBlockConfirm = true
            } label: {
                Label("Block", systemImage: "person.fill.xmark")
            }
            .disabled(userId == nil || isBlocking)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18))
                .foregroundColor(charcoalColor)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .disabled(userId == nil || isBlocking)
        .alert("Block \(pendingBlockDisplayName)?", isPresented: $showBlockConfirm) {
            Button("Cancel", role: .cancel) {
                pendingBlockUserId = nil
            }
            Button("Block", role: .destructive) {
                guard let id = pendingBlockUserId else { return }
                let name = pendingBlockDisplayName
                pendingBlockUserId = nil
                Task {
                    let success = await performBlock(id)
                    if success {
                        successBlockName = name
                        showBlockSuccess = true
                        onBlockComplete?()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to block \(pendingBlockDisplayName)?")
        }
        .alert("You have blocked \(successBlockName).", isPresented: $showBlockSuccess) {
            Button("OK", role: .cancel) {
                successBlockName = ""
            }
        }
        .alert("Block Failed", isPresented: $showBlockError) {
            Button("OK", role: .cancel) {
                blockError = nil
            }
        } message: {
            if let blockError {
                Text(blockError)
            }
        }
    }

    @MainActor
    private func performBlock(_ userId: UUID) async -> Bool {
        isBlocking = true
        blockError = nil
        defer { isBlocking = false }

        do {
            try await friendsManager.blockUser(userId)
            return true
        } catch {
            blockError = error.localizedDescription
            showBlockError = true
            return false
        }
    }
}

/// Styled 3-dot button for DiscoverScreen header (light background) or profile detail (dark overlay).
struct ReportBlockMenuButton: View {
    let userId: UUID?
    var displayName: String? = nil
    var onReport: () -> Void = {}
    var onBlockComplete: (() -> Void)? = nil
    /// When true, use light foreground for dark backgrounds (e.g. profile hero).
    var darkStyle: Bool = false
    /// When true, show only the ellipsis in black with no circle/background (matches plain back button).
    var plainStyle: Bool = false

    @StateObject private var friendsManager = FriendsManager.shared
    @State private var isBlocking = false
    @State private var blockError: String?
    @State private var showBlockError = false
    @State private var showBlockConfirm = false
    @State private var pendingBlockUserId: UUID?
    @State private var pendingBlockDisplayName: String = "this user"
    @State private var showBlockSuccess = false
    @State private var successBlockName: String = ""

    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private var resolvedDisplayName: String { displayName ?? "this user" }

    var body: some View {
        Menu {
            Button {
                onReport()
            } label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            }

            Button(role: .destructive) {
                guard let userId else { return }
                pendingBlockUserId = userId
                pendingBlockDisplayName = resolvedDisplayName
                showBlockConfirm = true
            } label: {
                Label("Block", systemImage: "person.fill.xmark")
            }
            .disabled(userId == nil || isBlocking)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: plainStyle ? 20 : (darkStyle ? 18 : 20), weight: plainStyle ? .medium : .regular))
                .foregroundColor(plainStyle ? .black : (darkStyle ? .white : inkMain))
                .frame(width: plainStyle ? 44 : (darkStyle ? 36 : 40), height: plainStyle ? 44 : (darkStyle ? 36 : 40))
                .background(plainStyle ? Color.clear : (darkStyle ? Color.white.opacity(0.2) : Color.white))
                .clipShape(Circle())
                .overlay(Circle().stroke(plainStyle ? Color.clear : (darkStyle ? Color.white.opacity(0.3) : Color.gray.opacity(0.2)), lineWidth: plainStyle ? 0 : 1))
                .shadow(color: plainStyle ? .clear : .black.opacity(darkStyle ? 0.2 : 0.05), radius: darkStyle ? 4 : 4, x: 0, y: 2)
        }
        .disabled(userId == nil || isBlocking)
        .alert("Block \(pendingBlockDisplayName)?", isPresented: $showBlockConfirm) {
            Button("Cancel", role: .cancel) {
                pendingBlockUserId = nil
            }
            Button("Block", role: .destructive) {
                guard let id = pendingBlockUserId else { return }
                let name = pendingBlockDisplayName
                pendingBlockUserId = nil
                Task {
                    let success = await performBlock(id)
                    if success {
                        successBlockName = name
                        showBlockSuccess = true
                        onBlockComplete?()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to block \(pendingBlockDisplayName)?")
        }
        .alert("You have blocked \(successBlockName).", isPresented: $showBlockSuccess) {
            Button("OK", role: .cancel) {
                successBlockName = ""
            }
        }
        .alert("Block Failed", isPresented: $showBlockError) {
            Button("OK", role: .cancel) {
                blockError = nil
            }
        } message: {
            if let blockError {
                Text(blockError)
            }
        }
    }

    @MainActor
    private func performBlock(_ userId: UUID) async -> Bool {
        isBlocking = true
        blockError = nil
        defer { isBlocking = false }

        do {
            try await friendsManager.blockUser(userId)
            return true
        } catch {
            blockError = error.localizedDescription
            showBlockError = true
            return false
        }
    }
}

#if DEBUG
struct ReportBlockMenu_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReportBlockMenu(userId: UUID())
            ReportBlockMenuButton(userId: UUID())
        }
        .padding()
    }
}
#endif
