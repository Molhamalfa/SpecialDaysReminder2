//
//  ReminderManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import UserNotifications

class ReminderManager {
    
    // MARK: - Notification Permissions

    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification authorization granted.")
                    completion(true)
                } else {
                    print("Notification authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        }
    }

    // MARK: - Scheduling Multiple Reminders

    func scheduleReminder(for day: SpecialDayModel) {
        // First, cancel any existing reminders for this event to avoid duplicates.
        cancelReminder(for: day)

        // Ensure reminders are enabled for this event.
        guard day.reminderEnabled else {
            print("Reminders are disabled for \(day.name).")
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDay = calendar.startOfDay(for: day.nextOccurrenceDate)

        // Calculate how many days are actually between today and the event.
        guard let daysUntil = calendar.dateComponents([.day], from: today, to: eventDay).day else {
            print("Could not calculate days until event.")
            return
        }

        // --- LOGIC FIX ---
        // 1. Check if the reminder window has been reached.
        // If the event is further away than the reminder setting, do nothing.
        guard daysUntil <= day.reminderDaysBefore else {
            print("Event '\(day.name)' is \(daysUntil) days away. Reminders start \(day.reminderDaysBefore) days before. No reminders scheduled yet.")
            return
        }
        
        // 2. Ensure the event is not in the past.
        guard daysUntil > 0 else {
            // Event is today or in the past, so no "days before" reminders are needed.
            print("Event '\(day.name)' is today or has passed. No 'days before' reminders will be scheduled.")
            return
        }
        // --- END OF FIX ---

        // Loop from today up to the day before the event. `daysUntil` gives us the correct number of iterations.
        // For example, if daysUntil is 3, we loop for today (index 0), tomorrow (index 1), and the day after (index 2).
        for dayIndex in 0..<daysUntil {
            
            // This is the actual date the notification will be sent on.
            guard let notificationFireDate = calendar.date(byAdding: .day, value: dayIndex, to: today) else { continue }

            // This is how many days are left from the perspective of the notification's fire date.
            let daysRemainingOnFireDate = daysUntil - dayIndex

            // Now, loop through each of the user-defined times for that day.
            for (timeIndex, reminderTime) in day.reminderTimes.enumerated() {
                
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationFireDate)
                dateComponents.hour = calendar.component(.hour, from: reminderTime)
                dateComponents.minute = calendar.component(.minute, from: reminderTime)

                // Ensure the final trigger date is in the future from this exact moment.
                guard let triggerDate = calendar.date(from: dateComponents), triggerDate > Date() else {
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = "Reminder: \(day.name)"
                
                if daysRemainingOnFireDate == 1 {
                    content.body = "Don't forget! \(day.forWhom)'s \(day.name) is tomorrow."
                } else {
                    content.body = "Don't forget! \(day.forWhom)'s \(day.name) is in \(daysRemainingOnFireDate) days."
                }
                content.sound = .default

                // Create a unique identifier for each notification.
                let notificationIdentifier = "\(day.id.uuidString)-\(dayIndex)-\(timeIndex)"

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification for \(day.name): \(error.localizedDescription)")
                    } else {
                        print("Successfully scheduled reminder for \(day.name) on \(triggerDate) with ID: \(notificationIdentifier)")
                    }
                }
            }
        }
    }

    // MARK: - Canceling Reminders

    func cancelReminder(for day: SpecialDayModel) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.hasPrefix(day.id.uuidString) }
                .map { $0.identifier }
            
            if !identifiersToCancel.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
                print("Canceled \(identifiersToCancel.count) pending notifications for \(day.name).")
            }
        }
    }
}
