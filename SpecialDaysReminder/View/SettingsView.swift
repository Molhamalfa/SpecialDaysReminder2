//
//  SettingsView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject var specialDaysListViewModel: SpecialDaysListViewModel

    var body: some View {
        Form {
            Section(header: Text("Events Management")) {
                Toggle("Auto-delete passed one-time events", isOn: $viewModel.autoDeletePassedEvents)
                    .onChange(of: viewModel.autoDeletePassedEvents) { _, newValue in
                        if newValue {
                            specialDaysListViewModel.deletePassedOneTimeEvents()
                        }
                    }
            }
        }
        .navigationTitle("Settings")
    }
}

// UPDATED: The preview provider now includes the necessary view model.
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock IAPManager for the preview.
        let iapManager = IAPManager(storeManager: StoreManager())
        // Create a mock SpecialDaysListViewModel for the preview.
        let specialDaysListViewModel = SpecialDaysListViewModel(iapManager: iapManager)
        
        NavigationView {
            SettingsView(specialDaysListViewModel: specialDaysListViewModel)
        }
    }
}
