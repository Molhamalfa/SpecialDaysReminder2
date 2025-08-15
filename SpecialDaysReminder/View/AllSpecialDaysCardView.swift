//
//  AllSpecialDaysCardView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct AllSpecialDaysCardView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel
    let allDaysCardOpacity: Double
    let allDaysCardOffset: CGFloat
    @Binding var navigationPath: NavigationPath
    
    let onAddTapped: () -> Void

    var body: some View {
        NavigationLink(value: NavigationDestinationType.allSpecialDaysDetail) {
            // This logic for creating a display-only category remains valid.
            let displayCategory = SpecialDayCategory(name: "All Special Days", color: viewModel.allDaysCategoryColor, icon: "🗓️")
            
            CategoryCardView(
                category: displayCategory,
                specialDays: viewModel.specialDays,
                onAddTapped: {
                    onAddTapped()
                },
                onDayTapped: { day in
                    // FIXED: Replaced the old IdentifiableUUID with the new IdentifiableCKRecordID.
                    navigationPath.append(NavigationDestinationType.editSpecialDay(IdentifiableCKRecordID(id: day.id)))
                },
                customTitle: "All Special Days",
                customIcon: "🗓️"
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(allDaysCardOpacity)
        .offset(y: allDaysCardOffset)
        .padding(.horizontal)
    }
}
