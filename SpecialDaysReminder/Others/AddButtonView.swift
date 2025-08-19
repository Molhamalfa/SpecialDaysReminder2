//
//  AddButtonView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct AddButtonView: View {
    // Access the color scheme to correctly set the text color.
    @Environment(\.colorScheme) var colorScheme

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                Text("Add Category")
            }
            .font(.headline)
            // UPDATED: The text color now adapts to be the opposite of the background.
            // It will be white in light mode and black in dark mode.
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .padding()
            .frame(maxWidth: .infinity)
            // UPDATED: The background now uses the primary system color, which adapts
            // to be black in light mode and white in dark mode.
            .background(Color.primary)
            .cornerRadius(15)
            // UPDATED: The shadow color is now adaptive.
            .shadow(color: .secondary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
}
