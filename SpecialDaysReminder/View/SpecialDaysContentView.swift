//
//  SpecialDaysContentView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct SpecialDaysContentView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel

    let allDaysCardOpacity: Double
    let allDaysCardOffset: CGFloat
    let categoryGridOpacity: Double
    let categoryGridOffset: CGFloat

    // Bindings and closures
    @Binding var showingAddCategorySheet: Bool
    @Binding var navigationPath: NavigationPath
    let onAddTapped: (SpecialDayCategory?) -> Void
    // ADDED: A closure to handle the share action.
    let onShareTapped: (SpecialDayCategory) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    AllSpecialDaysCardView(
                        viewModel: viewModel,
                        allDaysCardOpacity: allDaysCardOpacity,
                        allDaysCardOffset: allDaysCardOffset,
                        navigationPath: $navigationPath,
                        onAddTapped: {
                            onAddTapped(nil)
                        },
                        // The "All" category cannot be shared, so we provide an empty closure.
                        onShareTapped: {}
                    )

                    CategoryGridSectionView(
                        viewModel: viewModel,
                        categoryGridOpacity: categoryGridOpacity,
                        categoryGridOffset: categoryGridOffset,
                        onAddTapped: { category in
                            onAddTapped(category)
                        },
                        // UPDATED: Pass the share action down.
                        onShareTapped: { category in
                            onShareTapped(category)
                        },
                        navigationPath: $navigationPath
                    )
                }
                .padding(.top, 20)
                .padding(.bottom, 100)
            }

            AddButtonView {
                showingAddCategorySheet = true
            }
            .padding(.bottom, 20)
        }
    }
}
