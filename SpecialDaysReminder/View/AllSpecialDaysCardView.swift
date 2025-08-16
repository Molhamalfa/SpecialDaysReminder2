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
            let displayCategory = SpecialDayCategory(name: "All Special Days", color: viewModel.allDaysCategoryColor, icon: "🗓️")
            
            // FIXED: The onShareTapped parameter has been removed from this call.
            // This fixes the compiler error and hides the share button for this card.
            CategoryCardView(
                category: displayCategory,
                specialDays: viewModel.specialDays,
                onAddTapped: {
                    onAddTapped()
                },
                onDayTapped: { day in
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
