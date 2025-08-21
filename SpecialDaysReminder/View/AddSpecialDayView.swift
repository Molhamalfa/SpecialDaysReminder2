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
    
    @State private var showSettingsAlert = false

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
                    isAllDay: $isAllDay,
                    viewModel: viewModel,
                    showSettingsAlert: $showSettingsAlert
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
                        if !viewModel.isPremiumUser && viewModel.specialDays.count >= 5 {
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
            .alert("Enable Notifications", isPresented: $showSettingsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("To enable reminders, you need to grant notification permissions in the Settings app.")
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
    
    var viewModel: SpecialDaysListViewModel
    @Binding var showSettingsAlert: Bool
    
    var body: some View {
        Section(header: Text("Reminder")) {
            Toggle("Enable Reminders", isOn: $reminderEnabled.animation())
                .onChange(of: reminderEnabled) { _, newValue in
                    if newValue {
                        viewModel.requestNotificationPermission { granted in
                            if !granted {
                                showSettingsAlert = true
                                reminderEnabled = false
                            }
                        }
                    }
                }
            
            if reminderEnabled {
                // UPDATED: Picker now includes an option for the day of the event.
                Picker("Start Reminders", selection: $reminderDaysBefore) {
                    Text("On the day of the event").tag(0)
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
                    // UPDATED: The DatePicker now has a dynamic range to prevent setting
                    // a reminder time after the event's time.
                    if !isAllDay {
                        let calendar = Calendar.current
                        let eventTimeComponents = calendar.dateComponents([.hour, .minute], from: eventDate)
                        let genericDay = Date()
                        let endOfRange = calendar.date(bySettingHour: eventTimeComponents.hour ?? 23, minute: eventTimeComponents.minute ?? 59, second: 0, of: genericDay) ?? genericDay
                        let startOfRange = calendar.startOfDay(for: genericDay)
                        let timeRange = startOfRange...endOfRange
                        
                        DatePicker("Time \(index + 1)", selection: $reminderTimes[index], in: timeRange, displayedComponents: .hourAndMinute)
                    } else {
                        DatePicker("Time \(index + 1)", selection: $reminderTimes[index], displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
    }
}
