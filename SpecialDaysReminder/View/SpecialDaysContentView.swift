//
//  SpecialDaysContentView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct SpecialDaysContentView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel

    // REMOVED: The animation states for the old header are no longer needed.
    let allDaysCardOpacity: Double
    let allDaysCardOffset: CGFloat
    let categoryGridOpacity: Double
    let categoryGridOffset: CGFloat

    // Bindings and closures
    @Binding var showingAddCategorySheet: Bool
    @Binding var navigationPath: NavigationPath
    let onAddTapped: (SpecialDayCategory?) -> Void
    // NEW: A closure to handle the share button tap from the grid.
    let onShareTapped: (SpecialDayCategory) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // The root view is a ScrollView.
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // REMOVED: The SpecialDaysHeaderView has been deleted from this VStack.
                    
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
                        // FIXED: Added the missing onShareTapped parameter.
                        onShareTapped: { category in
                            onShareTapped(category)
                        },
                        navigationPath: $navigationPath
                    )
                }
                // Added top padding to give space below the new navigation bar title.
                .padding(.top, 20)
                // Padding to ensure the last card isn't hidden by the floating button.
                .padding(.bottom, 100)
            }

            // The button remains in the ZStack, fixed at the bottom.
            AddButtonView {
                showingAddCategorySheet = true
            }
            .padding(.bottom, 20)
        }
    }
}
