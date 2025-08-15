//
//  EditCategoriesViewModel.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import SwiftUI
import Combine

class EditCategoriesViewModel: ObservableObject {
    @Published var categories: [SpecialDayCategory]
    
    private var specialDaysListViewModel: SpecialDaysListViewModel
    private var cancellables = Set<AnyCancellable>()

    init(specialDaysListViewModel: SpecialDaysListViewModel) {
        self.specialDaysListViewModel = specialDaysListViewModel
        self.categories = specialDaysListViewModel.categories
        
        // This sink ensures that if categories are changed elsewhere, this view reflects it.
        specialDaysListViewModel.$categories
            .assign(to: \.categories, on: self)
            .store(in: &cancellables)
    }

    func deleteCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
        // The deletion is saved immediately.
        saveChanges()
    }

    func saveChanges() {
        // Update the main view model with the edited categories.
        specialDaysListViewModel.categories = self.categories
    }
}
