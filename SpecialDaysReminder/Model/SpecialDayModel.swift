//
//  SpecialDayModel.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import SwiftUI

public enum RecurrenceType: String, Codable, CaseIterable, Hashable {
    case oneTime = "One Time"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var displayName: String {
        return self.rawValue
    }
}

public struct SpecialDayCategory: Codable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    public var icon: String

    public init(id: UUID = UUID(), name: String, color: Color, icon: String) {
        self.id = id
        self.name = name
        self.colorHex = color.toHex() ?? "#800080"
        self.icon = icon
    }

    public var color: Color {
        get { Color(hex: colorHex) ?? .purple }
        set { self.colorHex = newValue.toHex() ?? "#800080" }
    }
    
    public var displayName: String {
        return name
    }
}

public struct SpecialDayModel: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var date: Date
    public var forWhom: String
    public var categoryID: UUID?
    public var notes: String?
    public var recurrence: RecurrenceType
    // NEW: This property tracks if the event is for the whole day or has a specific time.
    public var isAllDay: Bool
    
    public var reminderEnabled: Bool
    public var reminderDaysBefore: Int
    public var reminderFrequency: Int
    public var reminderTimes: [Date]

    public init(id: UUID = UUID(), name: String, date: Date, forWhom: String, categoryID: UUID?, notes: String? = nil, recurrence: RecurrenceType = .yearly, isAllDay: Bool = true, reminderEnabled: Bool = false, reminderDaysBefore: Int = 1, reminderFrequency: Int = 1, reminderTimes: [Date] = []) {
        self.id = id
        self.name = name
        self.date = date
        self.forWhom = forWhom
        self.categoryID = categoryID
        self.notes = notes
        self.recurrence = recurrence
        self.isAllDay = isAllDay
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.reminderFrequency = reminderFrequency
        self.reminderTimes = reminderTimes
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
