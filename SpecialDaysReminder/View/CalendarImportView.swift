//
//  CalendarImportView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct CalendarImportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: CalendarImportViewModel

    init(specialDaysListViewModel: SpecialDaysListViewModel) {
        _viewModel = StateObject(wrappedValue: CalendarImportViewModel(specialDaysListViewModel: specialDaysListViewModel))
    }

    var body: some View {
        NavigationView {
            VStack {
                if let message = viewModel.statusMessage {
                    Text(message)
                        .padding()
                }

                if viewModel.isLoading {
                    ProgressView("Loading events...")
                } else if !viewModel.calendarAuthorized {
                    Button("Grant Calendar Access") {
                        viewModel.requestCalendarAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    List {
                        ForEach($viewModel.importableEvents) { $event in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(event.ekEvent.title ?? "Unknown Event")
                                        .font(.headline)
                                    Text(event.startDate, style: .date)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Toggle("", isOn: $event.isSelected)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    Button("Add Selected Events") {
                        viewModel.importSelectedEvents()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.importableEvents.filter({ $0.isSelected }).isEmpty)
                    .padding()
                }
            }
            .navigationTitle("Import Calendar Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.checkCalendarAuthorizationStatus()
            }
        }
        // REMOVED: .preferredColorScheme(.dark) to allow this view to adapt.
    }
}
