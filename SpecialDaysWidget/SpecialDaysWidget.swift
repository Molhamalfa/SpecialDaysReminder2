//
//  SpecialDaysWidget.swift
//  SpecialDaysWidget
//
//  Created by YourName on Date.
//

import WidgetKit
import SwiftUI
import Foundation

// MARK: - Widget-Specific Data Models
// These are simple, Codable structs for the widget to decode from UserDefaults.
// The main app will be responsible for creating and saving these.

struct WidgetCategory: Codable, Hashable, Identifiable {
    let id: String // Using the recordName as the ID
    let name: String
    let colorHex: String
    let icon: String
    
    var color: Color { Color(hex: colorHex) ?? .purple }
}

struct WidgetSpecialDay: Codable, Hashable, Identifiable {
    let id: String // Using the recordName as the ID
    let name: String
    let date: Date
    let forWhom: String
    let notes: String?
    let recurrenceRawValue: String
    let isAllDay: Bool
    let categoryID: String?
    
    // Computed properties to calculate countdowns, similar to the main app model.
    var nextOccurrenceDate: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        if isAllDay {
            components.hour = 0
            components.minute = 0
        }
        var nextDate = calendar.date(from: components) ?? date
        let now = Date()
        
        guard let recurrence = RecurrenceType(rawValue: recurrenceRawValue), recurrence != .oneTime else {
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
    
    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: nextOccurrenceDate)).day ?? 0
    }

    var daysUntilDescription: String {
        let days = daysUntil
        if days == 0 { return "Today!" }
        if days == 1 { return "Tomorrow!" }
        if days > 1 { return "\(days) days" }
        return "Passed"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


// MARK: - Widget Entry
struct SpecialDaysWidgetEntry: TimelineEntry {
    let date: Date
    // The entry now uses our new widget-specific models.
    let specialDays: [WidgetSpecialDay]
    let categories: [WidgetCategory]

    var deepLinkURL: URL? {
        guard let day = specialDays.first else { return nil }
        // The deep link now uses the 'id' (recordName) property.
        return URL(string: "specialdaysreminder://event?id=\(day.id)")
    }

    var addDayDeepLinkURL: URL? {
        return URL(string: "specialdaysreminder://add")
    }
}

// MARK: - Timeline Provider
struct SpecialDaysTimelineProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.molham.SpecialDaysReminder"
    // Using new keys to avoid conflicts with any old, stale data.
    private let specialDaysKey = "widgetSpecialDays"
    private let categoriesKey = "widgetCategories"

    private var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    func placeholder(in context: Context) -> SpecialDaysWidgetEntry {
        let sampleCategory = WidgetCategory(id: "sampleCategory", name: "Sample", colorHex: "#0000FF", icon: "🎉")
        let sampleDay = WidgetSpecialDay(id: "sampleDay", name: "Sample Event", date: Date().addingTimeInterval(86400 * 5), forWhom: "Preview", notes: nil, recurrenceRawValue: "Yearly", isAllDay: true, categoryID: sampleCategory.id)
        return SpecialDaysWidgetEntry(date: Date(), specialDays: [sampleDay], categories: [sampleCategory])
    }

    func getSnapshot(in context: Context, completion: @escaping (SpecialDaysWidgetEntry) -> Void) {
        let entry = fetchNextUpcomingDayEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpecialDaysWidgetEntry>) -> Void) {
        let currentEntry = fetchNextUpcomingDayEntry()
        // FIXED: Added the 'to: Date()' parameter to specify the date to add the hour to.
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
        completion(timeline)
    }

    private func fetchNextUpcomingDayEntry() -> SpecialDaysWidgetEntry {
        guard let userDefaults = sharedUserDefaults else {
            return SpecialDaysWidgetEntry(date: Date(), specialDays: [], categories: [])
        }

        var allCategories: [WidgetCategory] = []
        if let categoriesData = userDefaults.data(forKey: categoriesKey),
           let decodedCategories = try? JSONDecoder().decode([WidgetCategory].self, from: categoriesData) {
            allCategories = decodedCategories
        }

        var allDays: [WidgetSpecialDay] = []
        if let daysData = userDefaults.data(forKey: specialDaysKey),
           let decodedDays = try? JSONDecoder().decode([WidgetSpecialDay].self, from: daysData) {
            allDays = decodedDays
        }

        allDays.sort {
            let isUpcoming0 = $0.daysUntil >= 0; let isUpcoming1 = $1.daysUntil >= 0
            if isUpcoming0 != isUpcoming1 { return isUpcoming0 }
            if isUpcoming0 { return $0.daysUntil < $1.daysUntil }
            return $0.daysUntil > $1.daysUntil
        }

        guard let firstUpcomingDay = allDays.first(where: { $0.daysUntil >= 0 }) else {
            return SpecialDaysWidgetEntry(date: Date(), specialDays: [], categories: [])
        }

        let daysForTimeline = allDays.filter {
            Calendar.current.isDate($0.nextOccurrenceDate, inSameDayAs: firstUpcomingDay.nextOccurrenceDate)
        }

        return SpecialDaysWidgetEntry(date: Date(), specialDays: daysForTimeline, categories: allCategories)
    }
}

// MARK: - Widget View (and its helper views)
// All views are updated to work with the new WidgetSpecialDay and WidgetCategory models.

struct SpecialDaysWidgetView: View {
    let entry: SpecialDaysWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let firstDay = entry.specialDays.first {
            let singleEventCategory = entry.categories.first { $0.id == firstDay.categoryID }

            switch family {
            case .systemSmall:
                SmallWidgetView(day: firstDay, eventCount: entry.specialDays.count)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding()
                    .widgetURL(entry.deepLinkURL)
                    .containerBackground(for: .widget) { singleEventCategory?.color ?? .gray }

            case .systemMedium:
                if entry.specialDays.count == 1 {
                    MediumSingleEventView(day: firstDay, category: singleEventCategory)
                } else {
                    MultiEventHorizontalView(entry: entry, limit: 4)
                }
            
            case .systemLarge:
                MultiEventVerticalView(entry: entry, limit: 4)

            default:
                EmptyView()
            }
        } else {
            NoEventsView()
        }
    }
}

private struct SmallWidgetView: View {
    let day: WidgetSpecialDay
    let eventCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(day.name).font(.headline).fontWeight(.bold).lineLimit(1)
            Text(day.forWhom).font(.caption).opacity(0.8)
            Spacer()
            Text(day.daysUntilDescription).font(.title).fontWeight(.heavy).minimumScaleFactor(0.5).lineLimit(1)
            if eventCount > 1 {
                Text("+\(eventCount - 1) more").font(.caption2).fontWeight(.bold)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.black.opacity(0.2)).clipShape(Capsule())
            } else {
                Text(day.formattedDate).font(.caption2).opacity(0.8)
            }
        }.foregroundColor(.white)
    }
}

private struct MediumSingleEventView: View {
    let day: WidgetSpecialDay
    let category: WidgetCategory?
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category?.icon ?? "🗓️").font(.largeTitle)
                Spacer()
                Text(day.name).font(.headline).fontWeight(.bold).lineLimit(2).minimumScaleFactor(0.8)
                Text(day.forWhom).font(.caption).lineLimit(1).minimumScaleFactor(0.8)
                Divider().background(Color.white.opacity(0.5))
                Text(day.nextOccurrenceDate, style: .date).font(.caption).minimumScaleFactor(0.8)
                if !day.isAllDay {
                    Text(day.nextOccurrenceDate, style: .time).font(.caption).minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let notes = day.notes, !notes.isEmpty {
                VStack {
                    Text(notes)
                        .font(.caption)
                        .italic()
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            category?.color ?? .gray
        }
    }
}

private struct MultiEventHorizontalView: View {
    let entry: SpecialDaysWidgetEntry
    let limit: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.specialDays.first!.daysUntilDescription)
                    .font(.title3).fontWeight(.bold).lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
                Text(entry.specialDays.first!.nextOccurrenceDate, style: .date)
                    .font(.subheadline).lineLimit(1).minimumScaleFactor(0.7)
            }.foregroundColor(.primary)
            Divider()
            HStack(spacing: 10) {
                ForEach(entry.specialDays.prefix(limit)) { day in
                    let category = entry.categories.first { $0.id == day.categoryID }
                    EventCompactView(day: day, category: category)
                }
            }
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) { Color(.systemGray6) }
    }
}

private struct MultiEventVerticalView: View {
    let entry: SpecialDaysWidgetEntry
    let limit: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.specialDays.first!.daysUntilDescription)
                    .font(.title3).fontWeight(.bold).lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
                Text(entry.specialDays.first!.nextOccurrenceDate, style: .date)
                    .font(.subheadline).lineLimit(1).minimumScaleFactor(0.7)
            }.foregroundColor(.primary)
            Divider()
            VStack(spacing: 8) {
                ForEach(entry.specialDays.prefix(limit)) { day in
                    let category = entry.categories.first { $0.id == day.categoryID }
                    EventRowView(day: day, category: category)
                }
            }
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) { Color(.systemGray6) }
    }
}

private struct EventCompactView: View {
    let day: WidgetSpecialDay
    let category: WidgetCategory?
    
    var body: some View {
        VStack(spacing: 6) {
            Text(category?.icon ?? "🗓️")
                .font(.title2)
            Text(day.name)
                .font(.caption2)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(.white)
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(category?.color ?? .gray)
        .cornerRadius(15)
    }
}

private struct EventRowView: View {
    let day: WidgetSpecialDay
    let category: WidgetCategory?
    
    var body: some View {
        HStack {
            Text(category?.icon ?? "🗓️").font(.title)
            VStack(alignment: .leading) {
                Text(day.name).fontWeight(.bold)
                Text(day.forWhom).font(.caption)
                if let notes = day.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .italic()
                        .lineLimit(1)
                }
            }
            Spacer()
            if !day.isAllDay {
                Text(day.nextOccurrenceDate, style: .time)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(.white)
        .padding(10)
        .background(category?.color ?? .gray)
        .cornerRadius(10)
    }
}

private struct NoEventsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "calendar.badge.plus").font(.largeTitle).opacity(0.7)
            Text("No Upcoming Special Days").font(.headline).multilineTextAlignment(.center)
            Text("Add new events in the app!").font(.caption).opacity(0.8)
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(for: .widget) { Color(.systemGray6) }
    }
}

@main
struct SpecialDaysWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpecialDaysWidget()
    }
}

struct SpecialDaysWidget: Widget {
    let kind: String = "SpecialDaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpecialDaysTimelineProvider()) { entry in
            SpecialDaysWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Event")
        .description("View your next upcoming special day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
