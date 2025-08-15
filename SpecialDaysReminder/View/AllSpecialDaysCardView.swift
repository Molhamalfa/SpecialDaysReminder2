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
            
            CategoryCardView(
                category: displayCategory,
                specialDays: viewModel.specialDays,
                onAddTapped: {
                    onAddTapped()
                },
                onDayTapped: { day in
                    navigationPath.append(NavigationDestinationType.editSpecialDay(IdentifiableUUID(id: day.id)))
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
