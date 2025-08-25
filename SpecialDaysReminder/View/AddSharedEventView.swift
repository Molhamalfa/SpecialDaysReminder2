//
//  AddSharedEventView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import CloudKit

struct AddSharedEventView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel
    let info: SharedEventInfo
    @Binding var showingPremiumSheet: Bool
    @Binding var sharedEventInfo: SharedEventInfo?

    @State private var selectedCategoryID: CKRecord.ID?

    var body: some View {
        NavigationView {
            VStack {
                if let icon = info.icon {
                    Text(icon)
                        .font(.system(size: 80))
                }
                
                Text(info.name)
                    .font(.title)
                Text("For: \(info.forWhom)")
                    .font(.headline)
                Text(info.date, style: .date)
                    .font(.subheadline)
                
                Form {
                    Section(header: Text("Choose a Category")) {
                        Picker("Category", selection: $selectedCategoryID) {
                            Text("Uncategorized").tag(nil as CKRecord.ID?)
                            ForEach(viewModel.categories) { category in
                                HStack {
                                    Text(category.icon)
                                    Text(category.displayName)
                                }
                                .tag(category.id as CKRecord.ID?)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
            }
            .navigationTitle("Add Shared Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        sharedEventInfo = nil
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if !viewModel.isPremiumUser && viewModel.specialDays.count >= 5 {
                            showingPremiumSheet = true
                            sharedEventInfo = nil
                        } else {
                            let selectedCategory = viewModel.categories.first { $0.id == selectedCategoryID }
                            let newDay = SpecialDayModel(
                                name: info.name,
                                date: info.date,
                                forWhom: info.forWhom,
                                category: selectedCategory,
                                recurrence: info.recurrence,
                                isAllDay: info.isAllDay,
                                reminderEnabled: info.reminderEnabled,
                                reminderDaysBefore: info.reminderDaysBefore,
                                reminderFrequency: info.reminderFrequency,
                                reminderTimes: info.reminderTimes
                            )
                            viewModel.addSpecialDay(newDay)
                            sharedEventInfo = nil
                        }
                    }
                }
            }
        }
    }
}
