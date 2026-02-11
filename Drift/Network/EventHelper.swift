//
//  EventHelper.swift
//  Drift
//
//  Handles calendar integration and event reminder notifications
//

import Foundation
import EventKit
import UserNotifications

@MainActor
class EventHelper {
    static let shared = EventHelper()

    private let eventStore = EKEventStore()

    private init() {}

    // MARK: - Calendar Integration

    /// Adds an event to the user's calendar
    /// - Parameters:
    ///   - title: Event title
    ///   - notes: Event description/notes
    ///   - startDate: When the event starts
    ///   - location: Optional location string
    /// - Returns: True if successfully added
    func addToCalendar(
        title: String,
        notes: String?,
        startDate: Date,
        location: String?
    ) async -> Bool {
        // Request calendar access
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await eventStore.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }

        guard granted else {
            return false
        }

        // Create the calendar event
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(3600) // Default 1 hour duration
        event.calendar = eventStore.defaultCalendarForNewEvents

        if let location = location {
            event.location = location
        }

        // Add a 1-hour reminder alarm
        let alarm = EKAlarm(relativeOffset: -3600)
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Local Notifications

    /// Schedules a local notification 1 hour before an event
    /// - Parameters:
    ///   - eventId: Unique identifier for the event (used as notification ID)
    ///   - eventTitle: Title to show in notification
    ///   - eventDate: When the event starts
    func scheduleEventReminder(
        eventId: UUID,
        eventTitle: String,
        eventDate: Date
    ) async {
        let center = UNUserNotificationCenter.current()

        // Check notification permission
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            return
        }

        // Calculate 1 hour before the event
        let reminderDate = eventDate.addingTimeInterval(-3600)

        // Don't schedule if the reminder time has already passed
        guard reminderDate > Date() else {
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Event Starting Soon"
        content.body = "\(eventTitle) starts in 1 hour!"
        content.sound = .default
        content.userInfo = ["eventId": eventId.uuidString]

        // Create trigger for 1 hour before event
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Create request with event ID as identifier (for easy cancellation)
        let request = UNNotificationRequest(
            identifier: "event-reminder-\(eventId.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
        }
    }

    /// Cancels a previously scheduled event reminder
    /// - Parameter eventId: The event's UUID
    func cancelEventReminder(eventId: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["event-reminder-\(eventId.uuidString)"]
        )
    }
}
