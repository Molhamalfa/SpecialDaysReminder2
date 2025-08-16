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
    
    // This closure is passed from the parent to handle the tap action
    let onAddTapped: (SpecialDayCategory) -> Void
    // NEW: A closure to handle the share button tap for a specific category.
    let onShareTapped: (SpecialDayCategory) -> Void
    @Binding var navigationPath: NavigationPath

    var body: some View {
        // Changed from LazyVGrid to VStack to make each card full-width
        VStack(spacing: 15) {
            ForEach(viewModel.categories, id: \.id) { category in
                NavigationLink(value: NavigationDestinationType.categoryDetail(category)) {
                    CategoryCardView(
                        category: category,
                        specialDays: viewModel.specialDays(for: category),
                        onAddTapped: {
                            onAddTapped(category)
                        },
                        // FIXED: Added the onShareTapped parameter.
                        // This will call the closure passed from the parent view.
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
