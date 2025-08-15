//
//  CategoryDetailViewModel.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import Combine
import CloudKit

class CategoryDetailViewModel: ObservableObject {
    @Published var specialDaysForCategory: [SpecialDayModel] = []

    private let category: SpecialDayCategory?
    private var specialDaysListViewModel: SpecialDaysListViewModel
    private var cancellables = Set<AnyCancellable>()

    init(category: SpecialDayCategory?, specialDaysListViewModel: SpecialDaysListViewModel) {
        self.category = category
        self.specialDaysListViewModel = specialDaysListViewModel
        
        specialDaysListViewModel.$specialDays
            .sink { [weak self] _ in
                self?.updateFilteredDays()
            }
            .store(in: &cancellables)
            
        updateFilteredDays()
    }

    private func updateFilteredDays() {
        let allDays = specialDaysListViewModel.specialDays
        if let category = category {
            // Filtering is now based on the categoryReference's recordID.
            self.specialDaysForCategory = allDays.filter { $0.categoryReference?.recordID == category.id }
        } else {
            self.specialDaysForCategory = allDays
        }
        self.specialDaysForCategory.sort { $0.nextOccurrenceDate < $1.nextOccurrenceDate }
    }

    // The delete function now accepts a CKRecord.ID.
    func deleteDay(id: CKRecord.ID) {
        specialDaysListViewModel.deleteSpecialDay(id: id)
    }
}
