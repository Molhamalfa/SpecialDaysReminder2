//
//  EditSpecialDayView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct EditSpecialDayView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var specialDay: SpecialDayModel
    @State private var reminderTimes: [Date]
    
    private var themeColor: Color {
        if let categoryID = specialDay.categoryID,
           let category = viewModel.categories.first(where: { $0.id == categoryID }) {
            return category.color
        }
        return .gray
    }

    init(viewModel: SpecialDaysListViewModel, specialDay: SpecialDayModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _specialDay = State(initialValue: specialDay)
        
        if specialDay.reminderTimes.isEmpty {
            _reminderTimes = State(initialValue: [Self.defaultTime()])
        } else {
            _reminderTimes = State(initialValue: specialDay.reminderTimes)
        }
    }
    
    private static func defaultTime() -> Date {
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }

    var body: some View {
        Form {
            EventDetailsSection(specialDay: $specialDay, viewModel: viewModel, themeColor: themeColor)
            ReminderSettingsSection(specialDay: $specialDay, reminderTimes: $reminderTimes, themeColor: themeColor)
        }
        .navigationTitle("Edit Special Day")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    specialDay.reminderTimes = specialDay.reminderEnabled ? reminderTimes : []
                    viewModel.updateSpecialDay(specialDay)
                    dismiss()
                }
            }
        }
        .onAppear { viewModel.requestNotificationPermission() }
    }
}

// MARK: - Helper Views

private struct EventDetailsSection: View {
    @Binding var specialDay: SpecialDayModel
    @ObservedObject var viewModel: SpecialDaysListViewModel
    let themeColor: Color
    
    var body: some View {
        Section(header: Text("Event Details")) {
            TextField("Event Name", text: $specialDay.name)
            
            DatePicker("Date", selection: $specialDay.date, displayedComponents: specialDay.isAllDay ? .date : [.date, .hourAndMinute])

            Toggle("All-Day Event", isOn: $specialDay.isAllDay.animation())

            TextField("For Whom", text: $specialDay.forWhom)
            
            Picker("Category", selection: $specialDay.categoryID) {
                Text("Uncategorized").tag(nil as UUID?)
                ForEach(viewModel.categories) { cat in
                    HStack {
                        Text(cat.icon)
                        Text(cat.displayName)
                    }
                    .tag(cat.id as UUID?)
                }
            }
            .pickerStyle(.menu)

            Picker("Repeats", selection: $specialDay.recurrence) {
                ForEach(RecurrenceType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            TextField("Notes (Optional)", text: Binding(get: { specialDay.notes ?? "" }, set: { specialDay.notes = $0.isEmpty ? nil : $0 }), axis: .vertical)
        }
    }
}

private struct ReminderSettingsSection: View {
    @Binding var specialDay: SpecialDayModel
    @Binding var reminderTimes: [Date]
    let themeColor: Color
    
    // This computed property defines the valid time range for the reminder picker.
    private var reminderTimeRange: PartialRangeThrough<Date> {
        // The user can select any time up to and including the event's specific time.
        return ...specialDay.date
    }
    
    private static func defaultTime() -> Date {
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    var body: some View {
        Section(header: Text("Reminder")) {
            Toggle("Enable Reminders", isOn: $specialDay.reminderEnabled.animation())
                .tint(themeColor)
            
            if specialDay.reminderEnabled {
                // RESTORED: The full set of reminder options.
                Picker("Start Reminders", selection: $specialDay.reminderDaysBefore) {
                    ForEach(1...7, id: \.self) { day in
                        Text("\(day) day\(day > 1 ? "s" : "") before").tag(day)
                    }
                }
                
                Picker("Reminders per Day", selection: $specialDay.reminderFrequency) {
                    ForEach(1...3, id: \.self) { freq in
                        Text("\(freq) time\(freq > 1 ? "s" : "")").tag(freq)
                    }
                }
                .onChange(of: specialDay.reminderFrequency) { _, newFrequency in
                    let currentCount = reminderTimes.count
                    if newFrequency > currentCount {
                        reminderTimes.append(contentsOf: Array(repeating: Self.defaultTime(), count: newFrequency - currentCount))
                    } else if newFrequency < currentCount {
                        reminderTimes.removeLast(currentCount - newFrequency)
                    }
                }
                
                ForEach(reminderTimes.indices, id: \.self) { index in
                    // UPDATED: This picker is now constrained for non-all-day events.
                    if !specialDay.isAllDay {
                        DatePicker("Time \(index + 1)", selection: $reminderTimes[index], in: reminderTimeRange, displayedComponents: .hourAndMinute)
                    } else {
                        DatePicker("Time \(index + 1)", selection: $reminderTimes[index], displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
    }
}
