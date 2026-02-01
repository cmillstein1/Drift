//
//  ReportSheet.swift
//  Drift
//
//  Sheet for reporting users, posts, messages, or activities.
//  Three-step flow: Category → Details (optional) → Confirmation + Block offer
//

import SwiftUI
import DriftBackend

struct ReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reportManager = ReportManager.shared
    @StateObject private var friendsManager = FriendsManager.shared

    // What we're reporting
    let targetName: String
    let targetUserId: UUID

    // Content to report (only one should be set)
    var profile: UserProfile?
    var post: CommunityPost?
    var message: Message?
    var senderProfile: UserProfile?  // For message reports
    var activity: Activity?

    // Callback when complete
    var onComplete: ((Bool) -> Void)?  // Bool = did block

    // State
    @State private var currentStep: ReportStep = .selectCategory
    @State private var selectedCategory: ReportCategory?
    @State private var additionalDetails: String = ""
    @State private var isSubmitting = false
    @State private var showBlockConfirm = false
    @State private var isBlocking = false
    @State private var blockError: String?
    @State private var showBlockError = false

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    private enum ReportStep {
        case selectCategory
        case addDetails
        case confirmation
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            switch currentStep {
            case .selectCategory:
                categorySelectionView
            case .addDetails:
                detailsView
            case .confirmation:
                confirmationView
            }
        }
        .background(warmWhite)
        .alert("Block \(targetName)?", isPresented: $showBlockConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Block", role: .destructive) {
                performBlock()
            }
        } message: {
            Text("You won't see their content and they won't be able to contact you.")
        }
        .alert("Block Failed", isPresented: $showBlockError) {
            Button("OK", role: .cancel) {
                blockError = nil
            }
        } message: {
            if let error = blockError {
                Text(error)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                if currentStep == .addDetails {
                    Button {
                        withAnimation {
                            currentStep = .selectCategory
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoal)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }

                Text(headerTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoal)

                Spacer()

                if currentStep != .confirmation {
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
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }

    private var headerTitle: String {
        switch currentStep {
        case .selectCategory:
            return "Report \(targetName)"
        case .addDetails:
            return "Additional Details"
        case .confirmation:
            return "Report Submitted"
        }
    }

    // MARK: - Category Selection

    private var categorySelectionView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why are you reporting this?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoal)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(ReportCategory.allCases, id: \.self) { category in
                            ReportCategoryCard(
                                category: category,
                                isSelected: selectedCategory == category,
                                onTap: {
                                    selectedCategory = category
                                }
                            )
                        }
                    }
                }
                .padding(24)
            }

            // Footer with continue button
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)

                Button {
                    withAnimation {
                        currentStep = .addDetails
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedCategory != nil ? .white : Color.gray.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedCategory != nil ? burntOrange : Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
                .disabled(selectedCategory == nil)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(warmWhite)
        }
    }

    // MARK: - Details View

    private var detailsView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tell us more (optional)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoal)

                    Text("This helps our team investigate faster.")
                        .font(.system(size: 14))
                        .foregroundColor(charcoal.opacity(0.6))

                    TextField("What happened?", text: $additionalDetails, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(4...8)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )

                    Text("\(additionalDetails.count)/500")
                        .font(.system(size: 12))
                        .foregroundColor(charcoal.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(24)
            }

            // Footer with submit buttons
            VStack(spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)

                HStack(spacing: 12) {
                    Button {
                        submitReport()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .disabled(isSubmitting)

                    Button {
                        submitReport()
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(burntOrange)
                        .clipShape(Capsule())
                    }
                    .disabled(isSubmitting)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(warmWhite)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }

    // MARK: - Confirmation View

    private var confirmationView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("Thanks for letting us know")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoal)

                Text("We'll review this report and take action if needed.")
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Block offer
            VStack(spacing: 16) {
                Text("Would you also like to block \(targetName)?")
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.7))
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        showBlockConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            if isBlocking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isBlocking ? "Blocking..." : "Block")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .clipShape(Capsule())
                    }
                    .disabled(isBlocking)

                    Button {
                        onComplete?(false)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .disabled(isBlocking)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Actions

    private func submitReport() {
        guard let category = selectedCategory else { return }

        isSubmitting = true

        Task {
            do {
                if let profile = profile {
                    try await reportManager.reportProfile(
                        profile,
                        category: category,
                        description: additionalDetails.isEmpty ? nil : additionalDetails
                    )
                } else if let post = post {
                    try await reportManager.reportPost(
                        post,
                        category: category,
                        description: additionalDetails.isEmpty ? nil : additionalDetails
                    )
                } else if let message = message {
                    try await reportManager.reportMessage(
                        message,
                        senderProfile: senderProfile,
                        category: category,
                        description: additionalDetails.isEmpty ? nil : additionalDetails
                    )
                } else if let activity = activity {
                    try await reportManager.reportActivity(
                        activity,
                        category: category,
                        description: additionalDetails.isEmpty ? nil : additionalDetails
                    )
                } else {
                    // Fallback: create a profile-type snapshot
                    let snapshot = ContentSnapshot(
                        type: .profile,
                        userName: targetName
                    )
                    try await reportManager.submitReport(
                        reportedUserId: targetUserId,
                        category: category,
                        description: additionalDetails.isEmpty ? nil : additionalDetails,
                        snapshot: snapshot
                    )
                }

                await MainActor.run {
                    isSubmitting = false
                    withAnimation {
                        currentStep = .confirmation
                    }
                }
            } catch {
                print("Failed to submit report: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    // Still show confirmation even if email fails (report is saved)
                    withAnimation {
                        currentStep = .confirmation
                    }
                }
            }
        }
    }

    private func performBlock() {
        isBlocking = true

        Task {
            do {
                try await friendsManager.blockUser(targetUserId)
                await MainActor.run {
                    isBlocking = false
                    onComplete?(true)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isBlocking = false
                    blockError = error.localizedDescription
                    showBlockError = true
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Report Category Card

struct ReportCategoryCard: View {
    let category: ReportCategory
    let isSelected: Bool
    let onTap: () -> Void

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")

    private var categoryColor: Color {
        switch category {
        case .spam: return .red
        case .harassment: return .orange
        case .inappropriate: return .pink
        case .scam: return .blue
        case .other: return .gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? categoryColor : charcoal.opacity(0.6))

                Text(category.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? charcoal : charcoal.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 8)
            .background(isSelected ? categoryColor.opacity(0.1) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? categoryColor : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

#if DEBUG
struct ReportSheet_Previews: PreviewProvider {
    static var previews: some View {
        ReportSheet(
            targetName: "John Doe",
            targetUserId: UUID()
        )
    }
}
#endif
