//
//  SpecialDaysContentView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct SpecialDaysContentView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel

    // Animation states
    let headerOpacity: Double
    let headerOffset: CGFloat
    let allDaysCardOpacity: Double
    let allDaysCardOffset: CGFloat
    let categoryGridOpacity: Double
    let categoryGridOffset: CGFloat

    // Bindings and closures
    @Binding var showingAddCategorySheet: Bool
    @Binding var navigationPath: NavigationPath
    let onAddTapped: (SpecialDayCategory?) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // UPDATED: The root view is now a VStack
            VStack(spacing: 20) {
                // The header is now outside the ScrollView, so it will stay fixed at the top.
                SpecialDaysHeaderView()
                    .opacity(headerOpacity)
                    .offset(y: headerOffset)
                    .padding(.top, 20)

                // This ScrollView now only contains the list of cards.
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        AllSpecialDaysCardView(
                            viewModel: viewModel,
                            allDaysCardOpacity: allDaysCardOpacity,
                            allDaysCardOffset: allDaysCardOffset,
                            navigationPath: $navigationPath,
                            onAddTapped: {
                                onAddTapped(nil)
                            }
                        )

                        CategoryGridSectionView(
                            viewModel: viewModel,
                            categoryGridOpacity: categoryGridOpacity,
                            categoryGridOffset: categoryGridOffset,
                            onAddTapped: { category in
                                onAddTapped(category)
                            },
                            navigationPath: $navigationPath
                        )
                    }
                    // Padding to ensure the last card isn't hidden by the floating button
                    .padding(.bottom, 100)
                }
            }

            // The button remains in the ZStack, fixed at the bottom
            AddButtonView {
                showingAddCategorySheet = true
            }
            .padding(.bottom, 20)
        }
    }
}
