//
//  CalendarImportViewModel.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import EventKit
import Combine
import SwiftUI

struct ImportableCalendarEvent: Identifiable {
    let id = UUID()
    let ekEvent: EKEvent
    var isSelected: Bool = false

    var startDate: Date {
        ekEvent.startDate ?? Date()
    }
}

class CalendarImportViewModel: ObservableObject {
    @Published var importableEvents: [ImportableCalendarEvent] = []
    @Published var calendarAuthorized: Bool = false
    @Published var statusMessage: String?
    @Published var isLoading: Bool = false

    private let calendarManager = CalendarManager()
    private var specialDaysListViewModel: SpecialDaysListViewModel
    private var cancellables = Set<AnyCancellable>()

    init(specialDaysListViewModel: SpecialDaysListViewModel) {
        self.specialDaysListViewModel = specialDaysListViewModel
        checkCalendarAuthorizationStatus()
    }

    func checkCalendarAuthorizationStatus() {
        DispatchQueue.main.async {
            let status = self.calendarManager.getAuthorizationStatus()
            if #available(iOS 17.0, *) {
                self.calendarAuthorized = (status == .fullAccess)
            } else {
                self.calendarAuthorized = (status == .authorized)
            }

            if !self.calendarAuthorized && status != .notDetermined {
                self.statusMessage = "Calendar access denied. Please enable in iOS Settings to import events."
            } else if self.calendarAuthorized {
                self.statusMessage = nil
                self.fetchCalendarEvents()
            }
        }
    }

    func requestCalendarAuthorization() {
        isLoading = true
        statusMessage = "Requesting calendar access..."
        calendarManager.requestCalendarAuthorization { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.calendarAuthorized = granted
                if granted {
                    self?.statusMessage = nil
                    self?.fetchCalendarEvents()
                } else {
                    self?.statusMessage = "Calendar access denied: \(error?.localizedDescription ?? "Unknown error"). Please enable in iOS Settings."
                }
            }
        }
    }

    func fetchCalendarEvents() {
        guard calendarAuthorized else {
            statusMessage = "Calendar access not authorized. Cannot fetch events."
            return
        }

        isLoading = true
        statusMessage = "Loading events from calendar..."

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate) ?? startDate

        calendarManager.fetchEvents(startDate: startDate, endDate: endDate) { [weak self] ekEvents in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                self.importableEvents = ekEvents.compactMap { ekEvent -> ImportableCalendarEvent? in
                    guard let eventStartDate = ekEvent.startDate, eventStartDate >= Date() else {
                        return nil
                    }
                    guard let tempSpecialDay = self.convertEKEventToSpecialDayModel(ekEvent: ekEvent) else {
                        return nil
                    }
                    let isDuplicate = self.specialDaysListViewModel.specialDays.contains { existingDay in
                        existingDay.name == tempSpecialDay.name &&
                        Calendar.current.isDate(existingDay.date, inSameDayAs: tempSpecialDay.date) &&
                        existingDay.forWhom == tempSpecialDay.forWhom
                    }
                    return isDuplicate ? nil : ImportableCalendarEvent(ekEvent: ekEvent)
                }

                self.importableEvents.sort { $0.startDate < $1.startDate }

                if self.importableEvents.isEmpty {
                    self.statusMessage = "No new upcoming events found in your calendar for import."
                } else {
                    self.statusMessage = "Select events to import."
                }
            }
        }
    }
    
    private func convertEKEventToSpecialDayModel(ekEvent: EKEvent) -> SpecialDayModel? {
        return SpecialDayModel(
            name: ekEvent.title ?? "Unknown Event",
            date: ekEvent.startDate ?? Date(),
            forWhom: ekEvent.notes ?? "N/A",
            category: nil,
            notes: ekEvent.notes,
            // FIXED: Changed 'isYearly' to 'recurrence' to match the data model.
            recurrence: .oneTime
        )
    }

    func importSelectedEvents() {
        let selectedDays = importableEvents.filter { $0.isSelected }.compactMap {
            self.convertEKEventToSpecialDayModel(ekEvent: $0.ekEvent)
        }

        if selectedDays.isEmpty {
            statusMessage = "No events selected for import."
            return
        }

        for day in selectedDays {
            specialDaysListViewModel.addSpecialDay(day)
        }
        statusMessage = "Successfully imported \(selectedDays.count) event(s)."
        importableEvents.removeAll { $0.isSelected }
    }
}
