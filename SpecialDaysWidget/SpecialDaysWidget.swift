//
//  SpecialDaysWidget.swift
//  SpecialDaysWidget
//
//  Created by YourName on Date.
//

import WidgetKit
import SwiftUI
import Foundation

// MARK: - Widget Entry
struct SpecialDaysWidgetEntry: TimelineEntry {
    let date: Date
    let specialDays: [SpecialDayModel]
    let categories: [SpecialDayCategory]

    var deepLinkURL: URL? {
        guard let day = specialDays.first else { return nil }
        return URL(string: "specialdaysreminder://event?id=\(day.id.uuidString)")
    }

    var addDayDeepLinkURL: URL? {
        return URL(string: "specialdaysreminder://add")
    }
}

// MARK: - Timeline Provider
struct SpecialDaysTimelineProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.molham.SpecialDaysReminder"
    private let specialDaysKey = "specialDays"
    private let categoriesKey = "specialDayCategories"

    private var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    func placeholder(in context: Context) -> SpecialDaysWidgetEntry {
        let sampleCategory = SpecialDayCategory(name: "Sample", color: .blue, icon: "🎉")
        let sampleDay = SpecialDayModel(name: "Sample Event", date: Date().addingTimeInterval(86400 * 5), forWhom: "Preview", categoryID: sampleCategory.id)
        return SpecialDaysWidgetEntry(date: Date(), specialDays: [sampleDay], categories: [sampleCategory])
    }

    func getSnapshot(in context: Context, completion: @escaping (SpecialDaysWidgetEntry) -> Void) {
        let entry = fetchNextUpcomingDayEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpecialDaysWidgetEntry>) -> Void) {
        let currentEntry = fetchNextUpcomingDayEntry()
        let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
        completion(timeline)
    }

    private func fetchNextUpcomingDayEntry() -> SpecialDaysWidgetEntry {
        guard let userDefaults = sharedUserDefaults else {
            return SpecialDaysWidgetEntry(date: Date(), specialDays: [], categories: [])
        }

        var allCategories: [SpecialDayCategory] = []
        if let categoriesData = userDefaults.data(forKey: categoriesKey),
           let decodedCategories = try? JSONDecoder().decode([SpecialDayCategory].self, from: categoriesData) {
            allCategories = decodedCategories
        }

        var allDays: [SpecialDayModel] = []
        if let daysData = userDefaults.data(forKey: specialDaysKey),
           let decodedDays = try? JSONDecoder().decode([SpecialDayModel].self, from: daysData) {
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

// MARK: - Widget View
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
                    MultiEventHorizontalView(entry: entry, limit: 4) // Increased limit
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

// MARK: - Helper Views for Widget Layout

private struct SmallWidgetView: View {
    let day: SpecialDayModel
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
    let day: SpecialDayModel
    let category: SpecialDayCategory?
    
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
    let day: SpecialDayModel
    let category: SpecialDayCategory?
    
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
    let day: SpecialDayModel
    let category: SpecialDayCategory?
    
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
            // ADDED: Display the time if the event is not all-day
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
