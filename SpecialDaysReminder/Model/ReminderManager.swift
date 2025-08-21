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
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    completion(true)
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            completion(granted)
                        }
                    }
                case .denied:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    // MARK: - Scheduling Multiple Reminders

    // UPDATED: The scheduling logic is now more robust and correctly includes the event day.
    func scheduleReminder(for day: SpecialDayModel) {
        cancelReminder(for: day)

        guard day.reminderEnabled else {
            print("Reminders are disabled for \(day.name).")
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDate = calendar.startOfDay(for: day.nextOccurrenceDate)

        // Loop backwards from the event day for the number of days the user selected.
        for dayOffset in 0...day.reminderDaysBefore {
            guard let notificationDate = calendar.date(byAdding: .day, value: -dayOffset, to: eventDate) else { continue }
            
            // Only schedule reminders for today or future dates.
            guard notificationDate >= today else { continue }

            let daysRemaining = calendar.dateComponents([.day], from: notificationDate, to: eventDate).day ?? 0

            for (timeIndex, reminderTime) in day.reminderTimes.enumerated() {
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                dateComponents.hour = calendar.component(.hour, from: reminderTime)
                dateComponents.minute = calendar.component(.minute, from: reminderTime)

                // This check ensures we don't schedule a reminder for a time that has already passed today.
                guard let triggerDate = calendar.date(from: dateComponents), triggerDate > Date() else {
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = "Reminder: \(day.name)"
                
                if daysRemaining == 0 {
                    content.body = "Don't forget! \(day.forWhom)'s \(day.name) is today."
                } else if daysRemaining == 1 {
                    content.body = "Don't forget! \(day.forWhom)'s \(day.name) is tomorrow."
                } else {
                    content.body = "Don't forget! \(day.forWhom)'s \(day.name) is in \(daysRemaining) days."
                }
                content.sound = .default

                let notificationIdentifier = "\(day.id.recordName)-\(dayOffset)-\(timeIndex)"

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
                .filter { $0.identifier.hasPrefix(day.id.recordName) }
                .map { $0.identifier }
            
            if !identifiersToCancel.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
                print("Canceled \(identifiersToCancel.count) pending notifications for \(day.name).")
            }
        }
    }
}
