//
//  SpecialDaysReminderApp.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

@main
struct SpecialDaysReminderApp: App {
    // FIXED: The deepLinkEventID is now a String? to match the CKRecord.ID's recordName.
    @State private var deepLinkEventID: String? = nil
    @State private var deepLinkAddEvent: Bool = false

    @StateObject private var calendarManager = CalendarManager()

    var body: some Scene {
        WindowGroup {
            // Pass the binding of the corrected type.
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
                       // FIXED: We now directly use the eventIDString without converting it to a UUID.
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
