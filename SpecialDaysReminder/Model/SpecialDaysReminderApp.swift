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

@main
struct SpecialDaysReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var deepLinkEventID: String? = nil
    @State private var deepLinkAddEvent: Bool = false
    
    // ADDED: State to hold the incoming shared event info
    @State private var sharedEventInfo: SharedEventInfo? = nil

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
            // UPDATED: Pass the new binding to the list view
            SpecialDaysListView(iapManager: iapManager, viewModel: viewModel, deepLinkEventID: $deepLinkEventID, deepLinkAddEvent: $deepLinkAddEvent, sharedEventInfo: $sharedEventInfo)
                .environmentObject(storeManager)
                .environmentObject(iapManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    // ADDED: A function to parse the incoming URL
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "specialdaysreminder" else { return }

        // Reset deep links
        self.deepLinkEventID = nil
        self.deepLinkAddEvent = false
        self.sharedEventInfo = nil

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        if url.host == "event", let queryItems = components.queryItems {
            self.deepLinkEventID = queryItems.first(where: { $0.name == "id" })?.value
        } else if url.host == "add" {
            self.deepLinkAddEvent = true
        } else if url.host == "share", let queryItems = components.queryItems {
            // Parse the event details from the query items
            let name = queryItems.first(where: { $0.name == "name" })?.value ?? "Untitled Event"
            let forWhom = queryItems.first(where: { $0.name == "forWhom" })?.value ?? ""
            let dateString = queryItems.first(where: { $0.name == "date" })?.value ?? ""
            let icon = queryItems.first(where: { $0.name == "icon" })?.value
            let colorHex = queryItems.first(where: { $0.name == "colorHex" })?.value
            
            let dateFormatter = ISO8601DateFormatter()
            let date = dateFormatter.date(from: dateString) ?? Date()
            
            // Create the info object to trigger the sheet
            self.sharedEventInfo = SharedEventInfo(name: name, date: date, forWhom: forWhom, icon: icon, colorHex: colorHex)
        }
    }
}
