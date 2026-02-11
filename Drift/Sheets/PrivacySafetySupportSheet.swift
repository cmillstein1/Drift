//
//  PrivacySafetySupportSheet.swift
//  Drift
//
//  Combined Privacy, Safety & Support — Blocked users and future options.
//

import SwiftUI
import DriftBackend
import Auth

/// Pushed screen from Profile (Privacy, Safety & Support). Use as navigation destination.
struct PrivacySafetySupportScreen: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var showDeleteAccountConfirmation = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?
    @State private var showDeleteError = false
    @State private var isUpdatingLocationPrivacy = false
    @State private var locationPrivacyError: String?
    @State private var showLocationPrivacyError = false
    /// Local value for optimistic toggle so it slides smoothly; synced from profile on appear and on error revert.
    @State private var hideLocationOnMapLocal: Bool = false

    private let charcoalColor = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Manage your privacy, safety, and get help.")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                VStack(spacing: 16) {
                    // Hide my location on the map
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(skyBlue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 18))
                                .foregroundColor(skyBlue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hide my location on the map")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoalColor)
                            Text("Your pin won't appear on the Nearby map for you or others")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        Spacer()
                        Toggle("", isOn: $hideLocationOnMapLocal)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(forestGreen)
                            .onChange(of: hideLocationOnMapLocal) { _, newValue in
                                Task { await updateHideLocationOnMap(newValue) }
                            }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .onAppear {
                        hideLocationOnMapLocal = profileManager.currentProfile?.hideLocationOnMap ?? false
                    }
                    .onChange(of: profileManager.currentProfile?.hideLocationOnMap) { _, newValue in
                        if let value = newValue {
                            hideLocationOnMapLocal = value
                        }
                    }
                    .onChange(of: showLocationPrivacyError) { _, show in
                        if show {
                            hideLocationOnMapLocal = profileManager.currentProfile?.hideLocationOnMap ?? false
                        }
                    }

                    // Blocked users (own card with rounded corners)
                    NavigationLink {
                        BlockedUsersView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(forestGreen)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "person.fill.xmark")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Blocked users")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                Text("View and unblock people you've blocked")
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor.opacity(0.4))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    // Delete account
                    Button {
                        showDeleteAccountConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "trash")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delete account")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                Text("Permanently delete your account and all data")
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            Spacer()
                            if isDeletingAccount {
                                ProgressView()
                                    .scaleEffect(0.9)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isDeletingAccount)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 24)
        }
        .background(softGray)
        .navigationTitle("Privacy, Safety & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(softGray, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(.black)
        .alert("Delete account?", isPresented: $showDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete account", role: .destructive) {
                Task { await confirmDeleteAccount() }
            }
        } message: {
            Text("Deleting your account is irreversible. All your data will be wiped and you will need to create a new account to use Drift again.")
        }
        .alert("Error", isPresented: $showDeleteError) {
            Button("OK") { showDeleteError = false; deleteAccountError = nil }
        } message: {
            if let error = deleteAccountError {
                Text(error)
            }
        }
        .alert("Couldn't update setting", isPresented: $showLocationPrivacyError) {
            Button("OK") { showLocationPrivacyError = false; locationPrivacyError = nil }
        } message: {
            if let error = locationPrivacyError {
                Text(error)
            }
        }
    }

    private func confirmDeleteAccount() async {
        isDeletingAccount = true
        deleteAccountError = nil
        defer { isDeletingAccount = false }
        do {
            try await SupabaseManager.shared.deleteAccount()
        } catch {
            deleteAccountError = error.localizedDescription
            showDeleteError = true
        }
    }

    private func updateHideLocationOnMap(_ hide: Bool) async {
        isUpdatingLocationPrivacy = true
        defer { isUpdatingLocationPrivacy = false }
        do {
            try await profileManager.updateProfile(ProfileUpdateRequest(hideLocationOnMap: hide))
        } catch {
            locationPrivacyError = error.localizedDescription
            showLocationPrivacyError = true
        }
    }
}

/// Sheet wrapper (e.g. if presented modally elsewhere). Prefer pushing PrivacySafetySupportScreen from Profile.
struct PrivacySafetySupportSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss

    private let charcoalColor = Color("Charcoal")

    var body: some View {
        NavigationStack {
            PrivacySafetySupportScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)
                }
            }
        }
    }
}

// MARK: - Blocked Users List (swipe left to unblock; custom row, no gray background)

struct BlockedUsersView: View {
    @StateObject private var friendsManager = FriendsManager.shared
    @State private var blockedList: [Friend] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var unblockingId: UUID?

    private let charcoalColor = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")

    var body: some View {
        Group {
            if isLoading && blockedList.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Loading…")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if blockedList.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.fill.xmark")
                        .font(.system(size: 44))
                        .foregroundColor(charcoalColor.opacity(0.3))
                    Text("No blocked users")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(charcoalColor)
                    Text("People you block will appear here. Swipe left or long-press a row to unblock.")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(blockedList) { friend in
                        BlockedUserRowContent(
                            friend: friend,
                            unblockingId: $unblockingId
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                Task { await unblock(friend) }
                            } label: {
                                Label("Unblock", systemImage: "person.badge.plus")
                            }
                            .tint(forestGreen)
                        }
                        .contextMenu {
                            Button {
                                Task { await unblock(friend) }
                            } label: {
                                Label("Unblock", systemImage: "person.badge.plus")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(softGray)
            }
        }
        .background(softGray)
        .navigationTitle("Blocked users")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBlocked()
        }
    }

    private func loadBlocked() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            blockedList = try await friendsManager.fetchBlockedUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func unblock(_ friend: Friend) async {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id,
              let userId = friend.otherProfile(currentUserId: currentUserId)?.id else { return }
        unblockingId = userId
        defer { unblockingId = nil }
        do {
            try await friendsManager.unblockUser(userId)
            blockedList.removeAll { f in
                f.otherProfile(currentUserId: currentUserId)?.id == userId
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Blocked User Row (matches messages Hide/Delete style: swipeActions + contextMenu)

private struct BlockedUserRowContent: View {
    let friend: Friend
    @Binding var unblockingId: UUID?

    private let charcoalColor = Color("Charcoal")

    var body: some View {
        let currentUserId = SupabaseManager.shared.currentUser?.id
        let profile = currentUserId.flatMap { friend.otherProfile(currentUserId: $0) }
        let userId = profile?.id

        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: profile?.primaryDisplayPhotoUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(charcoalColor.opacity(0.08))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(charcoalColor.opacity(0.08))
                        .overlay(Image(systemName: "person.fill").foregroundColor(.gray.opacity(0.5)))
                @unknown default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(charcoalColor.opacity(0.08))
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(profile?.displayName ?? "Unknown")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(charcoalColor)
                if let location = profile?.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                        Text(location)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(charcoalColor.opacity(0.6))
                }
            }

            if let userId, unblockingId == userId {
                ProgressView()
                    .scaleEffect(0.9)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#if DEBUG
#Preview("Privacy & Support") {
    PrivacySafetySupportSheet(isPresented: .constant(true))
}
#Preview("Blocked users") {
    NavigationStack {
        BlockedUsersView()
    }
}
#endif
