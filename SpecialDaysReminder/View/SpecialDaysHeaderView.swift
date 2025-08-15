//
//  SpecialDaysHeaderView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

// MARK: - SpecialDaysHeaderView
// A dedicated view for the main title and subtitle of the app.
struct SpecialDaysHeaderView: View {
    // Environment variable to detect current color scheme (light/dark mode)
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("Your Special Days")
                .font(.largeTitle)
                .fontWeight(.bold)
                // Dynamically set text color based on color scheme for main title
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.bottom, 2)
            Text("Never miss an important moment.")
                .font(.subheadline)
                // Dynamically set text color based on color scheme for subtitle
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : .gray) // Slightly less opaque white for subtitle
        }
        .padding(.horizontal)
        // Removed specific top padding here; it will be handled by the parent view
        .frame(maxWidth: .infinity) // Ensure it takes full width for consistent padding
    }
}

// MARK: - Preview Provider
struct SpecialDaysHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SpecialDaysHeaderView()
            .previewLayout(.sizeThatFits)
            .padding()
            .environment(\.colorScheme, .light) // Preview in light mode
            .previewDisplayName("Light Mode")

        SpecialDaysHeaderView()
            .previewLayout(.sizeThatFits)
            .padding()
            .environment(\.colorScheme, .dark) // Preview in dark mode
            .previewDisplayName("Dark Mode")
            .background(Color(red: 0.15, green: 0.15, blue: 0.17)) // Simulate dark background for preview
    }
}
