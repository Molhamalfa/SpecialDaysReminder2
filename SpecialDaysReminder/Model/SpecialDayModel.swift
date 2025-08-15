//
//  SpecialDayModel.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import SwiftUI
import CloudKit

// MARK: - Enums and Extensions (Unchanged)

public enum RecurrenceType: String, CaseIterable {
    case oneTime = "One Time"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var displayName: String {
        return self.rawValue
    }
}

extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else { return nil }
        let r = Float(components[0]); let g = Float(components[1]); let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if str.hasPrefix("#") { str.remove(at: str.startIndex) }
        if str.count != 6 { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: str).scanHexInt64(&rgbValue)
        self.init(red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: Double(rgbValue & 0x0000FF) / 255.0)
    }
}

// MARK: - CloudKit-Ready Models

// FIXED: Added conformance to Hashable and Equatable.
public struct SpecialDayCategory: Identifiable, Hashable {
    private(set) var record: CKRecord
    
    public var id: CKRecord.ID { record.recordID }
    
    public var name: String {
        get { record["name"] as? String ?? "" }
        set { record["name"] = newValue }
    }
    
    public var colorHex: String {
        get { record["colorHex"] as? String ?? "#800080" }
        set { record["colorHex"] = newValue }
    }
    
    public var icon: String {
        get { record["icon"] as? String ?? "⭐️" }
        set { record["icon"] = newValue }
    }

    public var color: Color {
        get { Color(hex: colorHex) ?? .purple }
        set { self.colorHex = newValue.toHex() ?? "#800080" }
    }
    
    public var displayName: String {
        return name
    }
    
    init(name: String, color: Color, icon: String) {
        self.record = CKRecord(recordType: "Category")
        self.name = name
        self.color = color
        self.icon = icon
    }
    
    init?(record: CKRecord) {
        guard record.recordType == "Category" else { return nil }
        self.record = record
    }
    
    // Conformance to Equatable by comparing the unique record ID.
    public static func == (lhs: SpecialDayCategory, rhs: SpecialDayCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    // Conformance to Hashable by hashing the unique record ID.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct SpecialDayModel: Identifiable {
    private(set) var record: CKRecord
    
    public var id: CKRecord.ID { record.recordID }

    public var name: String {
        get { record["name"] as? String ?? "" }
        set { record["name"] = newValue }
    }
    
    public var date: Date {
        get { record["date"] as? Date ?? Date() }
        set { record["date"] = newValue }
    }
    
    public var forWhom: String {
        get { record["forWhom"] as? String ?? "" }
        set { record["forWhom"] = newValue }
    }
    
    public var notes: String? {
        get { record["notes"] as? String }
        set { record["notes"] = newValue }
    }
    
    public var recurrence: RecurrenceType {
        get {
            guard let recurrenceRawValue = record["recurrence"] as? String,
                  let type = RecurrenceType(rawValue: recurrenceRawValue) else {
                return .yearly
            }
            return type
        }
        set { record["recurrence"] = newValue.rawValue }
    }
    
    public var isAllDay: Bool {
        get { record["isAllDay"] as? Bool ?? true }
        set { record["isAllDay"] = newValue }
    }
    
    public var reminderEnabled: Bool {
        get { record["reminderEnabled"] as? Bool ?? false }
        set { record["reminderEnabled"] = newValue }
    }
    
    public var reminderDaysBefore: Int {
        get { record["reminderDaysBefore"] as? Int ?? 1 }
        set { record["reminderDaysBefore"] = newValue }
    }
    
    public var reminderFrequency: Int {
        get { record["reminderFrequency"] as? Int ?? 1 }
        set { record["reminderFrequency"] = newValue }
    }
    
    public var reminderTimes: [Date] {
        get { record["reminderTimes"] as? [Date] ?? [] }
        set { record["reminderTimes"] = newValue }
    }
    
    public var categoryReference: CKRecord.Reference? {
        get { record["category"] as? CKRecord.Reference }
        set { record["category"] = newValue }
    }

    init(name: String, date: Date, forWhom: String, category: SpecialDayCategory?, notes: String? = nil, recurrence: RecurrenceType = .yearly, isAllDay: Bool = true, reminderEnabled: Bool = false, reminderDaysBefore: Int = 1, reminderFrequency: Int = 1, reminderTimes: [Date] = []) {
        self.record = CKRecord(recordType: "SpecialDay")
        self.name = name
        self.date = date
        self.forWhom = forWhom
        if let category = category {
            self.categoryReference = CKRecord.Reference(recordID: category.id, action: .deleteSelf)
        }
        self.notes = notes
        self.recurrence = recurrence
        self.isAllDay = isAllDay
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.reminderFrequency = reminderFrequency
        self.reminderTimes = reminderTimes
    }
    
    init?(record: CKRecord) {
        guard record.recordType == "SpecialDay" else { return nil }
        self.record = record
    }

    public var nextOccurrenceDate: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        if isAllDay {
            components.hour = 0
            components.minute = 0
        }
        
        let now = Date()
        var nextDate = calendar.date(from: components) ?? date

        if recurrence == .oneTime {
            return nextDate
        }
        
        let componentToAdd: Calendar.Component
        switch recurrence {
        case .weekly: componentToAdd = .weekOfYear
        case .monthly: componentToAdd = .month
        case .yearly: componentToAdd = .year
        case .oneTime: return nextDate
        }

        while nextDate < now {
            nextDate = calendar.date(byAdding: componentToAdd, value: 1, to: nextDate) ?? nextDate
        }
        return nextDate
    }
    
    public var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: nextOccurrenceDate)).day ?? 0
    }

    public var daysUntilDescription: String {
        let days = daysUntil
        if days == 0 { return "Today!" }
        if days == 1 { return "Tomorrow!" }
        if days > 1 { return "\(days) days" }
        return "Passed"
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
