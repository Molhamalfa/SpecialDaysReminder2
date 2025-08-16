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
import CloudKit

// MARK: - ViewModel State
enum CloudKitState {
    case idle
    case loading
    case loaded
    case error(Error)
}

// MARK: - Widget-Specific Models
struct WidgetCategory: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let colorHex: String
    let icon: String
}

struct WidgetSpecialDay: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let date: Date
    let forWhom: String
    let notes: String?
    let recurrenceRawValue: String
    let isAllDay: Bool
    let categoryID: String?
}


class SpecialDaysListViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var specialDays: [SpecialDayModel] = []
    @Published var categories: [SpecialDayCategory] = []
    @Published var allDaysCategoryColor: Color = .purple
    @Published var searchText: String = ""
    
    @Published var cloudKitState: CloudKitState = .idle
    @Published var isSignedInToiCloud: Bool = false
    
    // NEW: Properties to manage the presentation of the sharing sheet.
    @Published var shareToShow: CKShare?
    @Published var categoryToShare: SpecialDayCategory?
    @Published var isShowingSharingView = false

    // MARK: - Private Properties
    private let allDaysColorKey = "allDaysCategoryColorHex"
    private let appGroupIdentifier = "group.com.molham.SpecialDaysReminder"
    private var sharedUserDefaults: UserDefaults?
    
    private let reminderManager = ReminderManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        sharedUserDefaults = UserDefaults(suiteName: appGroupIdentifier)
        loadAllDaysCategoryColor()
        
        CloudKitManager.shared.accountStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.cloudKitState = .error(error)
                }
            } receiveValue: { [weak self] status in
                self?.handleAccountStatus(status)
            }
            .store(in: &cancellables)
    }

    // MARK: - CloudKit Account Handling
    
    private func handleAccountStatus(_ status: CKAccountStatus) {
        self.isSignedInToiCloud = (status == .available)
        
        switch status {
        case .available:
            migrateDataToCloudKit { [weak self] in
                self?.fetchCategoriesAndSpecialDays()
            }
        case .noAccount, .restricted, .couldNotDetermine:
            self.cloudKitState = .error(CloudKitError.iCloudAccountNotFound)
        @unknown default:
            self.cloudKitState = .error(CloudKitError.iCloudAccountUnknown)
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchCategoriesAndSpecialDays(isSilent: Bool = false) {
        if !isSilent {
            cloudKitState = .loading
        }
        
        Task {
            do {
                let categoryQuery = CKQuery(recordType: CloudKitRecordType.category.rawValue, predicate: NSPredicate(value: true))
                let (categoryMatchResults, _) = try await CloudKitManager.shared.privateDatabase.records(matching: categoryQuery)
                let categoryRecords = try categoryMatchResults.map { try $0.1.get() }
                let fetchedCategories = categoryRecords.compactMap(SpecialDayCategory.init)
                
                let specialDayQuery = CKQuery(recordType: CloudKitRecordType.specialDay.rawValue, predicate: NSPredicate(value: true))
                let (specialDayMatchResults, _) = try await CloudKitManager.shared.privateDatabase.records(matching: specialDayQuery)
                let specialDayRecords = try specialDayMatchResults.map { try $0.1.get() }
                let fetchedSpecialDays = specialDayRecords.compactMap(SpecialDayModel.init)
                
                await MainActor.run {
                    self.categories = fetchedCategories
                    self.specialDays = fetchedSpecialDays
                    self.sortSpecialDays()
                    self.cloudKitState = .loaded
                    self.saveDataForWidget()
                }
            } catch {
                await MainActor.run {
                    self.cloudKitState = .error(error)
                }
            }
        }
    }

    // MARK: - Data Modification (CRUD Operations)
    
    func addCategory(_ category: SpecialDayCategory) {
        DispatchQueue.main.async {
            self.categories.append(category)
        }
        
        CloudKitManager.shared.privateDatabase.save(category.record) { [weak self] (savedRecord, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving category: \(error.localizedDescription)")
                    self?.cloudKitState = .error(error)
                    self?.categories.removeAll { $0.id == category.id }
                    return
                }
                self?.fetchCategoriesAndSpecialDays(isSilent: true)
            }
        }
    }
    
    func deleteCategory(at offsets: IndexSet) {
        let categoriesToDelete = offsets.map { self.categories[$0] }
        let categoryIDsToDelete = categoriesToDelete.map { $0.id }
        
        let specialDayIDsToDelete = self.specialDays
            .filter { day in
                guard let categoryRef = day.categoryReference else { return false }
                return categoryIDsToDelete.contains(categoryRef.recordID)
            }
            .map { $0.id }
            
        let allRecordIDsToDelete = categoryIDsToDelete + specialDayIDsToDelete
        
        DispatchQueue.main.async {
            self.categories.remove(atOffsets: offsets)
        }
        
        guard !allRecordIDsToDelete.isEmpty else {
            print("No records to delete for this category, removed locally.")
            return
        }

        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: allRecordIDsToDelete)
        operation.modifyRecordsResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully deleted \(allRecordIDsToDelete.count) records from CloudKit.")
                    self?.fetchCategoriesAndSpecialDays(isSilent: true)
                case .failure(let error):
                    print("Error deleting categories from CloudKit: \(error.localizedDescription)")
                    self?.cloudKitState = .error(error)
                    self?.fetchCategoriesAndSpecialDays()
                }
            }
        }
        
        CloudKitManager.shared.privateDatabase.add(operation)
    }
    
    func addSpecialDay(_ day: SpecialDayModel) {
        DispatchQueue.main.async {
            self.specialDays.append(day)
            self.sortSpecialDays()
        }
        
        CloudKitManager.shared.privateDatabase.save(day.record) { [weak self] (savedRecord, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving special day: \(error.localizedDescription)")
                    self?.cloudKitState = .error(error)
                    self?.specialDays.removeAll { $0.id == day.id }
                    return
                }
                
                self?.fetchCategoriesAndSpecialDays(isSilent: true)
                if let savedRecord = savedRecord, let updatedDay = SpecialDayModel(record: savedRecord) {
                    self?.reminderManager.scheduleReminder(for: updatedDay)
                }
            }
        }
    }

    func updateSpecialDay(_ day: SpecialDayModel) {
        CloudKitManager.shared.privateDatabase.save(day.record) { [weak self] (savedRecord, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error updating special day: \(error.localizedDescription)")
                    self?.cloudKitState = .error(error)
                    return
                }
                
                self?.fetchCategoriesAndSpecialDays(isSilent: true)
                if let savedRecord = savedRecord, let updatedDay = SpecialDayModel(record: savedRecord) {
                    self?.reminderManager.scheduleReminder(for: updatedDay)
                }
            }
        }
    }

    func deleteSpecialDay(id: CKRecord.ID) {
        if let dayToDelete = specialDays.first(where: { $0.id == id }) {
            reminderManager.cancelReminder(for: dayToDelete)
        }
        
        CloudKitManager.shared.privateDatabase.delete(withRecordID: id) { [weak self] (deletedRecordID, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error deleting special day: \(error.localizedDescription)")
                    self?.cloudKitState = .error(error)
                    return
                }
                self?.fetchCategoriesAndSpecialDays(isSilent: true)
            }
        }
    }
    
    // NEW: Function to initiate the sharing process.
    func shareCategory(_ category: SpecialDayCategory) {
        Task {
            do {
                let share = try await CloudKitManager.shared.fetchOrCreateShare(for: category)
                await MainActor.run {
                    self.categoryToShare = category
                    self.shareToShow = share
                    self.isShowingSharingView = true
                }
            } catch {
                print("Failed to fetch or create share: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper & Utility Functions
    
    private func sortSpecialDays() {
        specialDays.sort {
            let isUpcoming0 = $0.daysUntil >= 0
            let isUpcoming1 = $1.daysUntil >= 0
            if isUpcoming0 != isUpcoming1 { return isUpcoming0 }
            if isUpcoming0 { return $0.daysUntil < $1.daysUntil }
            return $0.daysUntil > $1.daysUntil
        }
    }
    
    func category(for day: SpecialDayModel) -> SpecialDayCategory? {
        guard let categoryRef = day.categoryReference else { return nil }
        return categories.first { $0.id == categoryRef.recordID }
    }
    
    func specialDays(for category: SpecialDayCategory) -> [SpecialDayModel] {
        return specialDays.filter { $0.categoryReference?.recordID == category.id }
    }
    
    func requestNotificationPermission() {
        reminderManager.requestNotificationAuthorization { _ in }
    }
    
    // MARK: - UserDefaults for Simple Config & Widget
    
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
    
    private func saveDataForWidget() {
        guard let userDefaults = sharedUserDefaults else { return }
        
        let widgetCategories = categories.map {
            WidgetCategory(id: $0.id.recordName, name: $0.name, colorHex: $0.colorHex, icon: $0.icon)
        }
        
        let widgetSpecialDays = specialDays.map {
            WidgetSpecialDay(id: $0.id.recordName, name: $0.name, date: $0.date, forWhom: $0.forWhom, notes: $0.notes, recurrenceRawValue: $0.recurrence.rawValue, isAllDay: $0.isAllDay, categoryID: $0.categoryReference?.recordID.recordName)
        }
        
        if let encodedCategories = try? JSONEncoder().encode(widgetCategories) {
            userDefaults.set(encodedCategories, forKey: "widgetCategories")
        }
        
        if let encodedDays = try? JSONEncoder().encode(widgetSpecialDays) {
            userDefaults.set(encodedDays, forKey: "widgetSpecialDays")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Data Migration
extension SpecialDaysListViewModel {
    
    private enum LegacyRecurrenceType: String, Codable {
        case oneTime = "One Time"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    private struct LegacyCategory: Codable {
        let id: UUID
        let name: String
        let colorHex: String
        let icon: String
    }
    
    private struct LegacySpecialDay: Codable {
        let id: UUID
        let name: String
        let date: Date
        let forWhom: String
        let categoryID: UUID?
        let notes: String?
        let recurrence: LegacyRecurrenceType
        let isAllDay: Bool
        let reminderEnabled: Bool
        let reminderDaysBefore: Int
        let reminderFrequency: Int
        let reminderTimes: [Date]
    }
    
    func migrateDataToCloudKit(completion: @escaping () -> Void) {
        let migrationKey = "migrationCompleted"
        guard let userDefaults = sharedUserDefaults, !userDefaults.bool(forKey: migrationKey) else {
            completion()
            return
        }
        
        print("Starting data migration from UserDefaults to CloudKit...")
        
        guard let savedCategoriesData = userDefaults.data(forKey: "specialDayCategories"),
              let legacyCategories = try? JSONDecoder().decode([LegacyCategory].self, from: savedCategoriesData) else {
            print("No old category data found to migrate.")
            userDefaults.set(true, forKey: migrationKey)
            completion()
            return
        }
        
        let savedDaysData = userDefaults.data(forKey: "specialDays")
        let legacyDays = (savedDaysData != nil) ? (try? JSONDecoder().decode([LegacySpecialDay].self, from: savedDaysData!)) : []
        
        var categoryRecords: [CKRecord] = []
        var specialDayRecords: [CKRecord] = []
        var uuidToRecordIDMap: [UUID: CKRecord.ID] = [:]
        
        for legacyCategory in legacyCategories {
            let newCategory = SpecialDayCategory(name: legacyCategory.name, color: Color(hex: legacyCategory.colorHex) ?? .purple, icon: legacyCategory.icon)
            categoryRecords.append(newCategory.record)
            uuidToRecordIDMap[legacyCategory.id] = newCategory.id
        }
        
        if let legacyDays = legacyDays {
            for legacyDay in legacyDays {
                var categoryReference: CKRecord.Reference? = nil
                if let categoryUUID = legacyDay.categoryID, let categoryRecordID = uuidToRecordIDMap[categoryUUID] {
                    categoryReference = CKRecord.Reference(recordID: categoryRecordID, action: .deleteSelf)
                }
                
                let newRecord = CKRecord(recordType: "SpecialDay")
                newRecord["name"] = legacyDay.name
                newRecord["date"] = legacyDay.date
                newRecord["forWhom"] = legacyDay.forWhom
                newRecord["category"] = categoryReference
                newRecord["notes"] = legacyDay.notes
                newRecord["recurrence"] = (RecurrenceType(rawValue: legacyDay.recurrence.rawValue) ?? .yearly).rawValue
                newRecord["isAllDay"] = legacyDay.isAllDay
                newRecord["reminderEnabled"] = legacyDay.reminderEnabled
                newRecord["reminderDaysBefore"] = legacyDay.reminderDaysBefore
                newRecord["reminderFrequency"] = legacyDay.reminderFrequency
                newRecord["reminderTimes"] = legacyDay.reminderTimes
                
                specialDayRecords.append(newRecord)
            }
        }
        
        let allRecords = categoryRecords + specialDayRecords
        guard !allRecords.isEmpty else {
            print("No records to migrate.")
            userDefaults.set(true, forKey: migrationKey)
            completion()
            return
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: allRecords, recordIDsToDelete: nil)
        operation.modifyRecordsResultBlock = { result in
            switch result {
            case .success:
                print("Successfully migrated \(allRecords.count) records to CloudKit.")
                userDefaults.set(true, forKey: migrationKey)
            case .failure(let error):
                print("Error migrating data: \(error.localizedDescription)")
            }
            completion()
        }
        
        CloudKitManager.shared.privateDatabase.add(operation)
    }
}


// MARK: - Custom Errors
enum CloudKitError: LocalizedError {
    case iCloudAccountNotFound
    case iCloudAccountUnknown
    
    var errorDescription: String? {
        switch self {
        case .iCloudAccountNotFound:
            return "Not signed into iCloud. Please sign in via Settings to use cloud features."
        case .iCloudAccountUnknown:
            return "Could not determine iCloud account status. Please try again."
        }
    }
}
