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
                    .foregroundColor(themeColor)
                
                Text(day.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        // Use a secondary system background for a subtle layered effect.
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        // Use a semantic color for the shadow that adapts.
        .shadow(color: .secondary.opacity(0.15), radius: 5, x: 0, y: 2)
        .padding(.vertical, 4)
    }
}
