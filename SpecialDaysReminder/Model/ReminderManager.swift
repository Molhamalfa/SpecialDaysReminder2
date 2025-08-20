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
                // FIXED: Added @unknown default to make the switch exhaustive.
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    // MARK: - Scheduling Multiple Reminders

    func scheduleReminder(for day: SpecialDayModel) {
        cancelReminder(for: day)

        guard day.reminderEnabled else {
            print("Reminders are disabled for \(day.name).")
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDay = calendar.startOfDay(for: day.nextOccurrenceDate)

        guard let daysUntil = calendar.dateComponents([.day], from: today, to: eventDay).day else {
            print("Could not calculate days until event.")
            return
        }

        guard daysUntil <= day.reminderDaysBefore else {
            print("Event '\(day.name)' is \(daysUntil) days away. Reminders start \(day.reminderDaysBefore) days before. No reminders scheduled yet.")
            return
        }
        
        guard daysUntil > 0 else {
            print("Event '\(day.name)' is today or has passed. No 'days before' reminders will be scheduled.")
            return
        }

        for dayIndex in 0..<daysUntil {
            
            guard let notificationFireDate = calendar.date(byAdding: .day, value: dayIndex, to: today) else { continue }

            let daysRemainingOnFireDate = daysUntil - dayIndex

            for (timeIndex, reminderTime) in day.reminderTimes.enumerated() {
                
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationFireDate)
                dateComponents.hour = calendar.component(.hour, from: reminderTime)
                dateComponents.minute = calendar.component(.minute, from: reminderTime)

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

                let notificationIdentifier = "\(day.id.recordName)-\(dayIndex)-\(timeIndex)"

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
