//
//  CategoryCardView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct CategoryCardView: View {
    let category: SpecialDayCategory
    let specialDays: [SpecialDayModel]
    
    let onAddTapped: () -> Void
    // NEW: A closure to handle the share button tap.
    let onShareTapped: () -> Void
    let onDayTapped: (SpecialDayModel) -> Void

    var customTitle: String?
    var customIcon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(customIcon ?? category.icon)
                    .font(.title)
                
                Text(customTitle ?? category.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()
                
                // NEW: Added a share button next to the add button.
                Button(action: onShareTapped) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: onAddTapped) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 5)

            if specialDays.isEmpty {
                Text("No special days yet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(specialDays.prefix(2), id: \.id) { day in
                        VStack(alignment: .leading) {
                            Text(day.daysUntilDescription)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            HStack {
                                Text(day.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(day.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    if specialDays.count > 2 {
                        Text("(\(specialDays.count - 2) more...)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 4)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .aspectRatio(1.75, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(category.color.gradient)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
