//
//  EditSpecialDayView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import CloudKit

struct EditSpecialDayView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var specialDay: SpecialDayModel
    @State private var reminderTimes: [Date]
    
    private var themeColor: Color {
        // Updated to use the new category(for:) helper method.
        if let category = viewModel.category(for: specialDay) {
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
    
    // A binding to specifically manage the category reference's record ID.
    private var categoryRecordID: Binding<CKRecord.ID?> {
        Binding(
            get: { self.specialDay.categoryReference?.recordID },
            set: { newID in
                if let newID = newID {
                    self.specialDay.categoryReference = CKRecord.Reference(recordID: newID, action: .none)
                } else {
                    self.specialDay.categoryReference = nil
                }
            }
        )
    }
    
    var body: some View {
        Section(header: Text("Event Details")) {
            TextField("Event Name", text: $specialDay.name)
            
            DatePicker("Date", selection: $specialDay.date, displayedComponents: specialDay.isAllDay ? .date : [.date, .hourAndMinute])

            Toggle("All-Day Event", isOn: $specialDay.isAllDay.animation())

            TextField("For Whom", text: $specialDay.forWhom)
            
            // Picker now binds to our custom categoryRecordID binding.
            Picker("Category", selection: categoryRecordID) {
                Text("Uncategorized").tag(nil as CKRecord.ID?)
                ForEach(viewModel.categories) { cat in
                    HStack {
                        Text(cat.icon)
                        Text(cat.displayName)
                    }
                    .tag(cat.id as CKRecord.ID?)
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

// ReminderSettingsSection remains unchanged.
private struct ReminderSettingsSection: View {
    @Binding var specialDay: SpecialDayModel
    @Binding var reminderTimes: [Date]
    let themeColor: Color
    
    private var reminderTimeRange: PartialRangeThrough<Date> {
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
