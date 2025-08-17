//
//  AddSpecialDayView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import CloudKit

struct AddSpecialDayView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel
    @Environment(\.dismiss) var dismiss
    
    @Binding var showingPremiumSheet: Bool
    
    let initialCategory: SpecialDayCategory?
    
    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var forWhom: String = ""
    @State private var categoryID: CKRecord.ID?
    @State private var notes: String = ""
    @State private var recurrence: RecurrenceType = .yearly
    @State private var isAllDay: Bool = true
    
    @State private var reminderEnabled: Bool = false
    @State private var reminderDaysBefore: Int = 1
    @State private var reminderFrequency: Int = 1
    @State private var reminderTimes: [Date] = [AddSpecialDayView.defaultTime()]

    init(viewModel: SpecialDaysListViewModel, initialCategory: SpecialDayCategory?, showingPremiumSheet: Binding<Bool>) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.initialCategory = initialCategory
        _showingPremiumSheet = showingPremiumSheet
        _categoryID = State(initialValue: initialCategory?.id)
    }

    private var isSaveButtonDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        forWhom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    static func defaultTime() -> Date {
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }

    var body: some View {
        NavigationView {
            Form {
                AddEventDetailsSection(
                    name: $name,
                    date: $date,
                    forWhom: $forWhom,
                    categoryID: $categoryID,
                    notes: $notes,
                    recurrence: $recurrence,
                    isAllDay: $isAllDay,
                    viewModel: viewModel
                )
                
                AddReminderSettingsSection(
                    reminderEnabled: $reminderEnabled,
                    reminderDaysBefore: $reminderDaysBefore,
                    reminderFrequency: $reminderFrequency,
                    reminderTimes: $reminderTimes,
                    eventDate: $date,
                    isAllDay: $isAllDay
                )
            }
            .navigationTitle("Add Special Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !viewModel.isPremiumUser && viewModel.specialDays.count >= 3 {
                            showingPremiumSheet = true
                            dismiss()
                        } else {
                            let selectedCategory = viewModel.categories.first { $0.id == categoryID }
                            
                            let newDay = SpecialDayModel(
                                name: name,
                                date: date,
                                forWhom: forWhom,
                                category: selectedCategory,
                                notes: notes.isEmpty ? nil : notes,
                                recurrence: recurrence,
                                isAllDay: isAllDay,
                                reminderEnabled: reminderEnabled,
                                reminderDaysBefore: reminderDaysBefore,
                                reminderFrequency: reminderFrequency,
                                reminderTimes: reminderEnabled ? reminderTimes : []
                            )
                            viewModel.addSpecialDay(newDay)
                            dismiss()
                        }
                    }
                    .disabled(isSaveButtonDisabled)
                }
            }
        }
    }
}

// MARK: - Helper Views

private struct AddEventDetailsSection: View {
    @Binding var name: String
    @Binding var date: Date
    @Binding var forWhom: String
    @Binding var categoryID: CKRecord.ID?
    @Binding var notes: String
    @Binding var recurrence: RecurrenceType
    @Binding var isAllDay: Bool
    @ObservedObject var viewModel: SpecialDaysListViewModel

    var body: some View {
        Section(header: Text("Event Details")) {
            TextField("Event Name", text: $name)
            DatePicker("Date", selection: $date, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
            Toggle("All-Day Event", isOn: $isAllDay.animation())
            TextField("For Whom", text: $forWhom)
            Picker("Category", selection: $categoryID) {
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
            Picker("Repeats", selection: $recurrence) {
                ForEach(RecurrenceType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            TextField("Notes (Optional)", text: $notes, axis: .vertical)
        }
    }
}

private struct AddReminderSettingsSection: View {
    @Binding var reminderEnabled: Bool
    @Binding var reminderDaysBefore: Int
    @Binding var reminderFrequency: Int
    @Binding var reminderTimes: [Date]
    @Binding var eventDate: Date
    @Binding var isAllDay: Bool

    private var reminderTimeRange: PartialRangeThrough<Date> {
        return ...eventDate
    }
    
    var body: some View {
        Section(header: Text("Reminder")) {
            Toggle("Enable Reminders", isOn: $reminderEnabled.animation())
            
            if reminderEnabled {
                Picker("Start Reminders", selection: $reminderDaysBefore) {
                    ForEach(1...7, id: \.self) { day in
                        Text("\(day) day\(day > 1 ? "s" : "") before").tag(day)
                    }
                }
                
                Picker("Reminders per Day", selection: $reminderFrequency) {
                    ForEach(1...3, id: \.self) { freq in
                        Text("\(freq) time\(freq > 1 ? "s" : "")").tag(freq)
                    }
                }
                .onChange(of: reminderFrequency) { _, newFrequency in
                    let currentCount = reminderTimes.count
                    if newFrequency > currentCount {
                        reminderTimes.append(contentsOf: Array(repeating: AddSpecialDayView.defaultTime(), count: newFrequency - currentCount))
                    } else if newFrequency < currentCount {
                        reminderTimes.removeLast(currentCount - newFrequency)
                    }
                }
                
                ForEach(reminderTimes.indices, id: \.self) { index in
                    if !isAllDay {
                        DatePicker("Time \(index + 1)", selection: $reminderTimes[index], in: reminderTimeRange, displayedComponents: .hourAndMinute)
                    } else {
                        DatePicker("Time \(index + 1)", selection: $reminderTimes[index], displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
    }
}
