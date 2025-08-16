//
//  SpecialDaysReminderApp.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import UIKit // Import UIKit to access UIApplication

// Create a delegate to handle app lifecycle events.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Move the registration call here. This is the correct place to
        // perform tasks on app launch.
        application.registerForRemoteNotifications()
        return true
    }
    
    // Optional: Handle successful registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Successfully registered for remote notifications.")
    }
    
    // Optional: Handle failed registration
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

@main
struct SpecialDaysReminderApp: App {
    // Use the @UIApplicationDelegateAdaptor property wrapper to connect the delegate.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var deepLinkEventID: String? = nil
    @State private var deepLinkAddEvent: Bool = false

    @StateObject private var calendarManager = CalendarManager()

    // The problematic init() has been removed.
    
    var body: some Scene {
        WindowGroup {
            SpecialDaysListView(deepLinkEventID: $deepLinkEventID, deepLinkAddEvent: $deepLinkAddEvent)
                .preferredColorScheme(.light)
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
                .onAppear {
                    calendarManager.requestCalendarAuthorization { granted, error in
                        if granted {
                            print("Initial calendar authorization request granted.")
                        } else {
                            print("Initial calendar authorization request denied or failed: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
        }
    }
}
