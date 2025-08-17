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
    // REMOVED: The onShareTapped closure has been removed.
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
                        // REMOVED: The onShareTapped parameter is no longer passed.
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
