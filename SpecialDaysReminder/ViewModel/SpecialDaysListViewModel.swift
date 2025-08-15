//
//  SpecialDaysListViewModel.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import Combine
import WidgetKit
import SwiftUI

class SpecialDaysListViewModel: ObservableObject {

    @Published var specialDays: [SpecialDayModel] = [] {
        didSet { saveSpecialDays() }
    }
    
    @Published var categories: [SpecialDayCategory] = [] {
        didSet { saveCategories() }
    }
    
    @Published var allDaysCategoryColor: Color = .purple {
        didSet { saveAllDaysCategoryColor() }
    }
    
    @Published var searchText: String = ""

    private let specialDaysKey = "specialDays"
    private let categoriesKey = "specialDayCategories"
    private let allDaysColorKey = "allDaysCategoryColorHex"
    private let appGroupIdentifier = "group.com.molham.SpecialDaysReminder"
    private var sharedUserDefaults: UserDefaults?
    
    private let reminderManager = ReminderManager()

    init() {
        sharedUserDefaults = UserDefaults(suiteName: appGroupIdentifier)
        loadCategories()
        loadSpecialDays()
        loadAllDaysCategoryColor()
    }

    private func sortSpecialDays() {
        specialDays.sort {
            let isUpcoming0 = $0.daysUntil >= 0
            let isUpcoming1 = $1.daysUntil >= 0
            if isUpcoming0 != isUpcoming1 { return isUpcoming0 }
            if isUpcoming0 { return $0.daysUntil < $1.daysUntil }
            return $0.daysUntil > $1.daysUntil
        }
    }

    private func saveSpecialDays() {
        guard let sharedUserDefaults = sharedUserDefaults else { return }
        if let encoded = try? JSONEncoder().encode(specialDays) {
            sharedUserDefaults.set(encoded, forKey: specialDaysKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func loadSpecialDays() {
        guard let sharedUserDefaults = sharedUserDefaults else { return }
        if let savedSpecialDays = sharedUserDefaults.data(forKey: specialDaysKey),
           let decodedDays = try? JSONDecoder().decode([SpecialDayModel].self, from: savedSpecialDays) {
            self.specialDays = decodedDays
            sortSpecialDays()
        }
    }
    
    private func saveCategories() {
        guard let sharedUserDefaults = sharedUserDefaults else { return }
        if let encoded = try? JSONEncoder().encode(categories) {
            sharedUserDefaults.set(encoded, forKey: categoriesKey)
        }
    }

    private func loadCategories() {
        guard let userDefaults = sharedUserDefaults else { return }
        if let savedCategories = userDefaults.data(forKey: categoriesKey),
           let decodedCategories = try? JSONDecoder().decode([SpecialDayCategory].self, from: savedCategories) {
            self.categories = decodedCategories
        } else {
            self.categories = []
        }
    }
    
    private func saveAllDaysCategoryColor() {
        guard let userDefaults = sharedUserDefaults else { return }
        let colorHex = allDaysCategoryColor.toHex() ?? "#800080"
        userDefaults.set(colorHex, forKey: allDaysColorKey)
    }
    
    private func loadAllDaysCategoryColor() {
        guard let userDefaults = sharedUserDefaults else { return }
        if let colorHex = userDefaults.string(forKey: allDaysColorKey) {
            self.allDaysCategoryColor = Color(hex: colorHex) ?? .purple
        } else {
            self.allDaysCategoryColor = .purple
        }
    }
    
    func addSpecialDay(_ day: SpecialDayModel) {
        specialDays.append(day)
        sortSpecialDays()
        reminderManager.scheduleReminder(for: day)
    }

    func updateSpecialDay(_ day: SpecialDayModel) {
        if let index = specialDays.firstIndex(where: { $0.id == day.id }) {
            specialDays[index] = day
            sortSpecialDays()
            reminderManager.scheduleReminder(for: day)
        }
    }

    func deleteSpecialDay(id: UUID) {
        if let dayToDelete = specialDays.first(where: { $0.id == id }) {
            reminderManager.cancelReminder(for: dayToDelete)
            specialDays.removeAll { $0.id == id }
        }
    }
    
    func addCategory(_ category: SpecialDayCategory) {
        categories.append(category)
    }
    
    func category(for day: SpecialDayModel) -> SpecialDayCategory? {
        return categories.first { $0.id == day.categoryID }
    }
    
    func specialDays(for category: SpecialDayCategory) -> [SpecialDayModel] {
        return specialDays.filter { $0.categoryID == category.id }
    }
    
    func requestNotificationPermission() {
        reminderManager.requestNotificationAuthorization { _ in }
    }
}
