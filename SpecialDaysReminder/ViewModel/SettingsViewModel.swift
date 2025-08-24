//
//  SettingsViewModel.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var autoDeletePassedEvents: Bool {
        didSet {
            UserDefaults.standard.set(autoDeletePassedEvents, forKey: "autoDeletePassedEvents")
        }
    }

    init() {
        self.autoDeletePassedEvents = UserDefaults.standard.bool(forKey: "autoDeletePassedEvents")
    }
}
