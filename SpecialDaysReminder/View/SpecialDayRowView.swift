//
//  SpecialDayRowView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct SpecialDayRowView: View {
    let day: SpecialDayModel
    let themeColor: Color

    var body: some View {
        // Main container for the card-like appearance
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(day.forWhom)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(day.daysUntilDescription)
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundColor(themeColor) // Use the category color for emphasis
                
                Text(day.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        // Use the system background color for adaptability to light/dark mode
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.vertical, 4) // Add vertical space between each card
    }
}
