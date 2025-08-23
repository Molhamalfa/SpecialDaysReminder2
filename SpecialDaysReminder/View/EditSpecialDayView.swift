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
    
    @State private var isAllDay: Bool
    @State private var reminderEnabled: Bool
    
    @State private var showSettingsAlert = false
    
    private var themeColor: Color {
        if let category = viewModel.category(for: specialDay) {
            return category.color
        }
        return .gray
    }

    init(viewModel: SpecialDaysListViewModel, specialDay: SpecialDayModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _specialDay = State(initialValue: specialDay)
        
        _isAllDay = State(initialValue: specialDay.isAllDay)
        _reminderEnabled = State(initialValue: specialDay.reminderEnabled)
        
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
            formContent
        }
        .navigationTitle("Edit Special Day")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            toolbarContent
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
        .onAppear {
            viewModel.requestNotificationPermission { _ in
                // No action is needed here, as this is just a pre-emptive check.
            }
        }
    }
    
    @ViewBuilder
    private var formContent: some View {
        // MARK: - Event Details Section
        Section(header: Text("Event Details")) {
            TextField("Event Name", text: $specialDay.name)
            
            DatePicker("Date", selection: $specialDay.date, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])

            Toggle("All-Day Event", isOn: $isAllDay.animation())

            TextField("For Whom", text: $specialDay.forWhom)
            
            Picker("Category", selection: $specialDay.categoryReference) {
                Text("Uncategorized").tag(nil as CKRecord.Reference?)
                ForEach(viewModel.categories) { cat in
                    HStack {
                        Text(cat.icon)
                        Text(cat.displayName)
                    }
                    .tag(CKRecord.Reference(recordID: cat.id, action: .none) as CKRecord.Reference?)
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
        
        // MARK: - Reminder Settings Section
        Section(header: Text("Reminder")) {
            Toggle("Enable Reminders", isOn: $reminderEnabled)
                .tint(themeColor)
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
                Picker("Start Reminders", selection: $specialDay.reminderDaysBefore) {
                    Text("On the day of the event").tag(0)
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
                    if !isAllDay {
                        let calendar = Calendar.current
                        let eventTimeComponents = calendar.dateComponents([.hour, .minute], from: specialDay.date)
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
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save", action: saveChanges)
        }
    }
    
    private func saveChanges() {
        specialDay.isAllDay = isAllDay
        specialDay.reminderEnabled = reminderEnabled
        specialDay.reminderTimes = reminderEnabled ? reminderTimes : []
        
        viewModel.updateSpecialDay(specialDay)
        dismiss()
    }
}
