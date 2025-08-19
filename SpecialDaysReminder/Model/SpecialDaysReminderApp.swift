//
//  SpecialDaysReminderApp.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
}

@main
struct SpecialDaysReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var deepLinkEventID: String? = nil
    @State private var deepLinkAddEvent: Bool = false

    // Create instances of the store and IAP managers.
    @StateObject private var storeManager: StoreManager
    @StateObject private var iapManager: IAPManager

    init() {
        // Initialize the managers.
        let storeManager = StoreManager()
        _storeManager = StateObject(wrappedValue: storeManager)
        _iapManager = StateObject(wrappedValue: IAPManager(storeManager: storeManager))
    }

    var body: some Scene {
        WindowGroup {
            // Pass the iapManager to the list view's initializer.
            SpecialDaysListView(iapManager: iapManager, deepLinkEventID: $deepLinkEventID, deepLinkAddEvent: $deepLinkAddEvent)
                .preferredColorScheme(.light)
                // Provide the managers to the entire view hierarchy.
                .environmentObject(storeManager)
                .environmentObject(iapManager)
                .onOpenURL { url in
                    guard url.scheme == "specialdaysreminder" else {
                        return
                    }

                    self.deepLinkEventID = nil
                    self.deepLinkAddEvent = false

                    if url.host == "event",
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let queryItems = components.queryItems,
                       let eventIDString = queryItems.first(where: { $0.name == "id" })?.value {
                        self.deepLinkEventID = eventIDString
                    } else if url.host == "add" {
                        self.deepLinkAddEvent = true
                    }
                }
        }
    }
}
