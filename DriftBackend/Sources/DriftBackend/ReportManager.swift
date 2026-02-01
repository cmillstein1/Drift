import Foundation
import Supabase

/// Manager for submitting user reports.
///
/// Handles reporting profiles, posts, messages, and activities via Edge Function.
@MainActor
public class ReportManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = ReportManager()

    /// Whether a report is currently being submitted.
    @Published public var isSubmitting = false

    /// The last error message, if any.
    @Published public var errorMessage: String?

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Report Submission

    /// Submits a report for a user profile.
    ///
    /// - Parameters:
    ///   - profile: The profile being reported.
    ///   - category: The report category.
    ///   - description: Optional additional details from the reporter.
    public func reportProfile(
        _ profile: UserProfile,
        category: ReportCategory,
        description: String? = nil
    ) async throws {
        let snapshot = ContentSnapshot.from(profile: profile)
        try await submitReport(
            reportedUserId: profile.id,
            category: category,
            description: description,
            snapshot: snapshot
        )
    }

    /// Submits a report for a community post.
    ///
    /// - Parameters:
    ///   - post: The post being reported.
    ///   - category: The report category.
    ///   - description: Optional additional details from the reporter.
    public func reportPost(
        _ post: CommunityPost,
        category: ReportCategory,
        description: String? = nil
    ) async throws {
        let snapshot = ContentSnapshot.from(post: post)
        try await submitReport(
            reportedUserId: post.authorId,
            category: category,
            description: description,
            postId: post.id,
            snapshot: snapshot
        )
    }

    /// Submits a report for a message.
    ///
    /// - Parameters:
    ///   - message: The message being reported.
    ///   - senderProfile: Optional sender profile for snapshot data.
    ///   - category: The report category.
    ///   - description: Optional additional details from the reporter.
    public func reportMessage(
        _ message: Message,
        senderProfile: UserProfile? = nil,
        category: ReportCategory,
        description: String? = nil
    ) async throws {
        let snapshot = ContentSnapshot.from(message: message, senderProfile: senderProfile)
        try await submitReport(
            reportedUserId: message.senderId,
            category: category,
            description: description,
            messageId: message.id,
            snapshot: snapshot
        )
    }

    /// Submits a report for an activity.
    ///
    /// - Parameters:
    ///   - activity: The activity being reported.
    ///   - category: The report category.
    ///   - description: Optional additional details from the reporter.
    public func reportActivity(
        _ activity: Activity,
        category: ReportCategory,
        description: String? = nil
    ) async throws {
        let snapshot = ContentSnapshot.from(activity: activity)
        try await submitReport(
            reportedUserId: activity.hostId,
            category: category,
            description: description,
            activityId: activity.id,
            snapshot: snapshot
        )
    }

    /// Generic report submission for direct use.
    ///
    /// - Parameters:
    ///   - reportedUserId: The ID of the user being reported.
    ///   - category: The report category.
    ///   - description: Optional additional details.
    ///   - postId: Optional post ID if reporting a post.
    ///   - messageId: Optional message ID if reporting a message.
    ///   - activityId: Optional activity ID if reporting an activity.
    ///   - snapshot: Content snapshot for the report.
    public func submitReport(
        reportedUserId: UUID,
        category: ReportCategory,
        description: String? = nil,
        postId: UUID? = nil,
        messageId: UUID? = nil,
        activityId: UUID? = nil,
        snapshot: ContentSnapshot
    ) async throws {
        guard SupabaseManager.shared.currentUser != nil else {
            throw ReportError.notAuthenticated
        }

        isSubmitting = true
        errorMessage = nil

        defer { isSubmitting = false }

        do {
            let session = try await client.auth.session

            let request = ReportRequest(
                reportedUserId: reportedUserId,
                category: category,
                description: description,
                postId: postId,
                messageId: messageId,
                activityId: activityId,
                contentSnapshot: snapshot
            )

            let response: ReportResponse = try await client.functions.invoke(
                "send-report",
                options: FunctionInvokeOptions(
                    headers: ["Authorization": "Bearer \(session.accessToken)"],
                    body: request
                )
            )

            if !response.success {
                let errorMsg = response.error ?? "Failed to submit report"
                errorMessage = errorMsg
                throw ReportError.submissionFailed(errorMsg)
            }
        } catch let error as ReportError {
            throw error
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = errorMsg
            throw ReportError.submissionFailed(errorMsg)
        }
    }
}

// MARK: - ReportError

public enum ReportError: LocalizedError {
    case notAuthenticated
    case submissionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to report content."
        case .submissionFailed(let message):
            return message
        }
    }
}
