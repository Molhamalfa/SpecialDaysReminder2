//
//  SpecialDaysReminderApp.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import UIKit
import CloudKit

extension Notification.Name {
    static let cloudKitShareAccepted = Notification.Name("cloudKitShareAccepted")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        NotificationCenter.default.post(name: .cloudKitShareAccepted, object: metadata)
    }
}

struct SharedCategoryInfo: Identifiable {
    let id = UUID()
    let name: String
    let colorHex: String
    let icon: String
    let events: [SharedEvent]
}

struct SharedEvent: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let forWhom: String
    let isAllDay: Bool
    let recurrence: RecurrenceType
    let reminderEnabled: Bool
    let reminderDaysBefore: Int
    let reminderFrequency: Int
    let reminderTimes: [Date]
}

@main
struct SpecialDaysReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var deepLinkEventID: String? = nil
    @State private var deepLinkAddEvent: Bool = false
    
    @State private var sharedEventInfo: SharedEventInfo? = nil
    
    @State private var sharedCategoryInfo: SharedCategoryInfo? = nil

    @StateObject private var storeManager: StoreManager
    @StateObject private var iapManager: IAPManager
    @StateObject private var viewModel: SpecialDaysListViewModel

    init() {
        let storeManager = StoreManager()
        _storeManager = StateObject(wrappedValue: storeManager)
        let iapManager = IAPManager(storeManager: storeManager)
        _iapManager = StateObject(wrappedValue: iapManager)
        _viewModel = StateObject(wrappedValue: SpecialDaysListViewModel(iapManager: iapManager))
    }

    var body: some Scene {
        WindowGroup {
            SpecialDaysListView(
                iapManager: iapManager,
                viewModel: viewModel,
                deepLinkEventID: $deepLinkEventID,
                deepLinkAddEvent: $deepLinkAddEvent,
                sharedEventInfo: $sharedEventInfo,
                sharedCategoryInfo: $sharedCategoryInfo
            )
            .environmentObject(storeManager)
            .environmentObject(iapManager)
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "specialdaysreminder" else { return }

        self.deepLinkEventID = nil
        self.deepLinkAddEvent = false
        self.sharedEventInfo = nil
        self.sharedCategoryInfo = nil

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        if url.host == "event", let queryItems = components.queryItems {
            self.deepLinkEventID = queryItems.first(where: { $0.name == "id" })?.value
        } else if url.host == "add" {
            self.deepLinkAddEvent = true
        } else if url.host == "share", let queryItems = components.queryItems {
            let name = queryItems.first(where: { $0.name == "name" })?.value ?? "Untitled Event"
            let forWhom = queryItems.first(where: { $0.name == "forWhom" })?.value ?? ""
            let dateString = queryItems.first(where: { $0.name == "date" })?.value ?? ""
            let icon = queryItems.first(where: { $0.name == "icon" })?.value
            let colorHex = queryItems.first(where: { $0.name == "colorHex" })?.value
            
            let isAllDay = Bool(queryItems.first(where: { $0.name == "isAllDay" })?.value ?? "true") ?? true
            let recurrenceRaw = queryItems.first(where: { $0.name == "recurrence" })?.value ?? RecurrenceType.yearly.rawValue
            let recurrence = RecurrenceType(rawValue: recurrenceRaw) ?? .yearly
            let reminderEnabled = Bool(queryItems.first(where: { $0.name == "reminderEnabled" })?.value ?? "false") ?? false
            let reminderDaysBefore = Int(queryItems.first(where: { $0.name == "reminderDaysBefore" })?.value ?? "1") ?? 1
            let reminderFrequency = Int(queryItems.first(where: { $0.name == "reminderFrequency" })?.value ?? "1") ?? 1
            
            let reminderTimesString = queryItems.first(where: { $0.name == "reminderTimes" })?.value ?? ""
            let reminderTimestamps = reminderTimesString.split(separator: ",").compactMap { Double($0) }
            let reminderTimes = reminderTimestamps.map { Date(timeIntervalSince1970: $0) }
            
            let dateFormatter = ISO8601DateFormatter()
            let date = dateFormatter.date(from: dateString) ?? Date()
            
            self.sharedEventInfo = SharedEventInfo(name: name, date: date, forWhom: forWhom, icon: icon, colorHex: colorHex, isAllDay: isAllDay, recurrence: recurrence, reminderEnabled: reminderEnabled, reminderDaysBefore: reminderDaysBefore, reminderFrequency: reminderFrequency, reminderTimes: reminderTimes)
        } else if url.host == "shareCategory", let queryItems = components.queryItems {
            if let dataString = queryItems.first(where: { $0.name == "data" })?.value,
               let data = dataString.data(using: .utf8) {
                do {
                    let payload = try JSONDecoder().decode(SharedCategoryPayload.self, from: data)
                    let sharedEvents = payload.events.map {
                        SharedEvent(
                            name: $0.name,
                            date: $0.date,
                            forWhom: $0.forWhom,
                            isAllDay: $0.isAllDay,
                            recurrence: RecurrenceType(rawValue: $0.recurrence) ?? .yearly,
                            reminderEnabled: $0.reminderEnabled,
                            reminderDaysBefore: $0.reminderDaysBefore,
                            reminderFrequency: $0.reminderFrequency,
                            reminderTimes: $0.reminderTimes
                        )
                    }
                    self.sharedCategoryInfo = SharedCategoryInfo(
                        name: payload.name,
                        colorHex: payload.colorHex,
                        icon: payload.icon,
                        events: sharedEvents
                    )
                } catch {
                    print("Error decoding shared category: \(error)")
                }
            }
        }
    }
}
