//
//  CategoryGridSectionView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct CategoryGridSectionView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel
    let categoryGridOpacity: Double
    let categoryGridOffset: CGFloat
    
    let onAddTapped: (SpecialDayCategory) -> Void
    // ADDED: A closure to handle the share action.
    let onShareTapped: (SpecialDayCategory) -> Void
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 15) {
            ForEach(viewModel.categories, id: \.id) { category in
                NavigationLink(value: NavigationDestinationType.categoryDetail(category)) {
                    CategoryCardView(
                        category: category,
                        specialDays: viewModel.specialDays(for: category),
                        onAddTapped: {
                            onAddTapped(category)
                        },
                        // UPDATED: Pass the share action for the specific category.
                        onShareTapped: {
                            onShareTapped(category)
                        },
                        onDayTapped: { day in
                            navigationPath.append(NavigationDestinationType.editSpecialDay(IdentifiableCKRecordID(id: day.id)))
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .opacity(categoryGridOpacity)
        .offset(y: categoryGridOffset)
        .padding(.horizontal)
    }
}
