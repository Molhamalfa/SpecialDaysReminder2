//
//  CategoryDetailView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct CategoryDetailView: View {
    @StateObject private var categoryDetailViewModel: CategoryDetailViewModel
    @ObservedObject var specialDaysListViewModel: SpecialDaysListViewModel
    
    let category: SpecialDayCategory?
    @Binding var navigationPath: NavigationPath
    
    @State private var showingAddSpecialDaySheet = false
    @Environment(\.dismiss) var dismiss // To handle the custom back button action

    init(viewModel: SpecialDaysListViewModel, category: SpecialDayCategory?, navigationPath: Binding<NavigationPath>) {
        _specialDaysListViewModel = ObservedObject(wrappedValue: viewModel)
        self.category = category
        _navigationPath = navigationPath
        _categoryDetailViewModel = StateObject(wrappedValue: CategoryDetailViewModel(category: category, specialDaysListViewModel: viewModel))
    }

    // A computed property to get a darker version of the theme color
    private var darkerThemeColor: Color {
        (category?.color ?? .purple).darker()
    }

    var body: some View {
        ZStack {
            (category?.color ?? .purple).opacity(0.15)
                .edgesIgnoringSafeArea(.all)

            List {
                ForEach(categoryDetailViewModel.specialDaysForCategory) { day in
                    NavigationLink(value: NavigationDestinationType.editSpecialDay(IdentifiableUUID(id: day.id))) {
                        SpecialDayRowView(day: day, themeColor: category?.color ?? .purple)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions {
                        Button(role: .destructive) {
                            categoryDetailViewModel.deleteDay(id: day.id)
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(category?.displayName ?? "All Special Days")
            .navigationBarBackButtonHidden(true) // Hide the default back button
            .toolbar {
                // Custom back button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundColor(darkerThemeColor) // Apply darker color
                    }
                }
                // Custom add button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddSpecialDaySheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(darkerThemeColor) // Apply darker color
                    }
                }
            }
            .sheet(isPresented: $showingAddSpecialDaySheet) {
                AddSpecialDayView(viewModel: specialDaysListViewModel, initialCategory: category)
            }
        }
    }
}

// MARK: - Color Extension
// Helper extension to easily create a darker shade of any color.
extension Color {
    func darker(by percentage: CGFloat = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return Color(UIColor(hue: hue, saturation: saturation, brightness: max(brightness - percentage, 0), alpha: alpha))
        }
        return self
    }
}
