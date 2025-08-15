//
//  CalendarManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import EventKit // Required for interacting with Calendar and Reminders
import EventKitUI // Potentially for presenting system UI for access, though not directly used here

// MARK: - CalendarManager
// This class handles all interactions with the user's iOS Calendar (EventKit framework).
// It's responsible for requesting access, fetching events, and converting them to SpecialDayModel.
class CalendarManager: ObservableObject {

    // MARK: - Properties

    // The Event Store is the primary interface for accessing calendar and reminder data.
    private let eventStore = EKEventStore()

    // MARK: - Authorization

    // Requests authorization to access the user's calendar events.
    // The completion handler provides a boolean indicating success and an optional error.
    func requestCalendarAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // UPDATED: Use requestFullAccessToEvents for iOS 17+ compatibility
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            // NOTE: The warning "Variable 'self' was written to, but never read" on this line is a common false positive from Xcode.
            // The 'self' is correctly captured and used in the DispatchQueue.main.async block below to ensure the completion
            // handler is executed on the main thread. This warning can be safely ignored.
            guard self != nil else { return }
            
            DispatchQueue.main.async {
                if granted {
                    print("Calendar access granted.")
                    completion(true, nil)
                } else {
                    print("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false, error)
                }
            }
        }
    }

    // Checks the current authorization status for calendar events.
    func getAuthorizationStatus() -> EKAuthorizationStatus {
        // Note: EKEventStore.authorizationStatus(for: .event) is still valid for checking status.
        // The deprecation applies to the *request* method.
        return EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Fetching Events

    // Fetches calendar events within a specified date range.
    // It filters for events that are not all-day and have a valid start date.
    // UPDATED: Now returns [EKEvent] directly instead of [SpecialDayModel].
    func fetchEvents(startDate: Date, endDate: Date, completion: @escaping ([EKEvent]) -> Void) {
        let calendars = eventStore.calendars(for: .event) // Get all calendars
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)

        // Fetch events asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let ekEvents = self.eventStore.events(matching: predicate)
            
            // Filter out events that are all-day or don't have a title/start date
            let filteredEvents = ekEvents.filter { ekEvent in
                return ekEvent.title != nil && !ekEvent.title!.isEmpty && ekEvent.startDate != nil
            }

            DispatchQueue.main.async {
                completion(filteredEvents) // Return EKEvent directly
            }
        }
    }
}
