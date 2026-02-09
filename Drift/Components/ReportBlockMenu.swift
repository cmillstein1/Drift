//
//  ReportBlockMenu.swift
//  Drift
//
//  Report and Block menu for message screen and dating/friends profiles.
//

import SwiftUI
import DriftBackend

/// A 3-dot menu that shows "Report", "Block", and optionally "Remove Friend". Block asks for confirmation (native alert), then calls the backend and shows success. Report opens the ReportSheet.
struct ReportBlockMenu: View {
    let userId: UUID?
    var displayName: String? = nil
    var profile: UserProfile? = nil  // For report snapshot
    var onReport: () -> Void = {}
    var onBlockComplete: (() -> Void)? = nil
    var onRemoveFriendComplete: (() -> Void)? = nil

    @StateObject private var friendsManager = FriendsManager.shared
    @State private var isBlocking = false
    @State private var blockError: String?
    @State private var showBlockError = false
    @State private var showBlockConfirm = false
    @State private var pendingBlockUserId: UUID?
    @State private var pendingBlockDisplayName: String = "this user"
    @State private var showBlockSuccess = false
    @State private var successBlockName: String = ""
    @State private var showReportSheet = false
    @State private var showRemoveFriendConfirm = false
    @State private var isRemovingFriend = false

    private let charcoalColor = Color("Charcoal")
    private var resolvedDisplayName: String { displayName ?? "this user" }

    private var friendRecord: Friend? {
        guard let userId else { return nil }
        return friendsManager.friends.first { friend in
            friend.status == .accepted &&
            (friend.requesterId == userId || friend.addresseeId == userId)
        }
    }

    var body: some View {
        Menu {
            Button {
                showReportSheet = true
            } label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            }
            .disabled(userId == nil)

            if friendRecord != nil {
                Button(role: .destructive) {
                    showRemoveFriendConfirm = true
                } label: {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
                .disabled(isRemovingFriend)
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
                .rotationEffect(.degrees(-90))
                .foregroundColor(charcoalColor)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .disabled(userId == nil || isBlocking)
        .sheet(isPresented: $showReportSheet) {
            if let userId = userId {
                ReportSheet(
                    targetName: resolvedDisplayName,
                    targetUserId: userId,
                    profile: profile,
                    onComplete: { didBlock in
                        if didBlock {
                            onBlockComplete?()
                        }
                    }
                )
            }
        }
        .alert("Remove \(resolvedDisplayName) as a friend?", isPresented: $showRemoveFriendConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    await performRemoveFriend()
                }
            }
        } message: {
            Text("You will no longer be connected as friends. You can send a new friend request later.")
        }
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
    private func performRemoveFriend() async {
        guard let record = friendRecord else { return }
        isRemovingFriend = true
        defer { isRemovingFriend = false }

        do {
            try await friendsManager.removeFriend(record.id)
            onRemoveFriendComplete?()
        } catch {
            blockError = error.localizedDescription
            showBlockError = true
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
    var profile: UserProfile? = nil  // For report snapshot
    var onReport: () -> Void = {}
    var onBlockComplete: (() -> Void)? = nil
    var onRemoveFriendComplete: (() -> Void)? = nil
    /// When true, use light foreground for dark backgrounds (e.g. profile hero).
    var darkStyle: Bool = false
    /// When true, show only the ellipsis in black with no circle/background (matches plain back button).
    var plainStyle: Bool = false
    /// When true with plainStyle, show horizontal three dots (ellipsis) instead of vertical.
    var horizontalEllipsis: Bool = false

    @StateObject private var friendsManager = FriendsManager.shared
    @State private var isBlocking = false
    @State private var blockError: String?
    @State private var showBlockError = false
    @State private var showBlockConfirm = false
    @State private var pendingBlockUserId: UUID?
    @State private var pendingBlockDisplayName: String = "this user"
    @State private var showBlockSuccess = false
    @State private var successBlockName: String = ""
    @State private var showReportSheet = false
    @State private var showRemoveFriendConfirm = false
    @State private var isRemovingFriend = false

    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private var resolvedDisplayName: String { displayName ?? "this user" }

    private var friendRecord: Friend? {
        guard let userId else { return nil }
        return friendsManager.friends.first { friend in
            friend.status == .accepted &&
            (friend.requesterId == userId || friend.addresseeId == userId)
        }
    }

    var body: some View {
        Menu {
            Button {
                showReportSheet = true
            } label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            }
            .disabled(userId == nil)

            if friendRecord != nil {
                Button(role: .destructive) {
                    showRemoveFriendConfirm = true
                } label: {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
                .disabled(isRemovingFriend)
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
            Group {
                if plainStyle {
                    if horizontalEllipsis {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(inkMain.opacity(0.6))
                            .frame(width: 28, height: 28)
                    } else {
                        VStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(Color.gray.opacity(0.45))
                                    .frame(width: 3, height: 3)
                            }
                        }
                        .frame(width: 28, height: 28)
                    }
                } else {
                    Image(systemName: "ellipsis")
                        .font(.system(size: darkStyle ? 18 : 20, weight: .regular))
                        .rotationEffect(.degrees(-90))
                        .foregroundColor(darkStyle ? .white : inkMain)
                        .frame(width: darkStyle ? 36 : 40, height: darkStyle ? 36 : 40)
                        .background(darkStyle ? Color.white.opacity(0.2) : Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(darkStyle ? Color.white.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(darkStyle ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .disabled(userId == nil || isBlocking)
        .sheet(isPresented: $showReportSheet) {
            if let userId = userId {
                ReportSheet(
                    targetName: resolvedDisplayName,
                    targetUserId: userId,
                    profile: profile,
                    onComplete: { didBlock in
                        if didBlock {
                            onBlockComplete?()
                        }
                    }
                )
            }
        }
        .alert("Remove \(resolvedDisplayName) as a friend?", isPresented: $showRemoveFriendConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    await performRemoveFriend()
                }
            }
        } message: {
            Text("You will no longer be connected as friends. You can send a new friend request later.")
        }
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
    private func performRemoveFriend() async {
        guard let record = friendRecord else { return }
        isRemovingFriend = true
        defer { isRemovingFriend = false }

        do {
            try await friendsManager.removeFriend(record.id)
            onRemoveFriendComplete?()
        } catch {
            blockError = error.localizedDescription
            showBlockError = true
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
