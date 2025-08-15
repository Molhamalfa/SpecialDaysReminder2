//
//  CategoryDetailViewModel.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import Combine

class CategoryDetailViewModel: ObservableObject {
    @Published var specialDaysForCategory: [SpecialDayModel] = []

    private let category: SpecialDayCategory?
    private var specialDaysListViewModel: SpecialDaysListViewModel
    private var cancellables = Set<AnyCancellable>()

    init(category: SpecialDayCategory?, specialDaysListViewModel: SpecialDaysListViewModel) {
        self.category = category
        self.specialDaysListViewModel = specialDaysListViewModel
        
        // Subscribe to changes in the main list of special days
        specialDaysListViewModel.$specialDays
            .sink { [weak self] _ in
                self?.updateFilteredDays()
            }
            .store(in: &cancellables)
            
        // Initial data load
        updateFilteredDays()
    }

    private func updateFilteredDays() {
        let allDays = specialDaysListViewModel.specialDays
        if let category = category {
            // Filter by the specific category if one is provided
            self.specialDaysForCategory = allDays.filter { $0.categoryID == category.id }
        } else {
            // Otherwise, show all special days
            self.specialDaysForCategory = allDays
        }
        // Sort the results by the next occurrence date
        self.specialDaysForCategory.sort { $0.nextOccurrenceDate < $1.nextOccurrenceDate }
    }

    func deleteDay(id: UUID) {
        specialDaysListViewModel.deleteSpecialDay(id: id)
    }
}
