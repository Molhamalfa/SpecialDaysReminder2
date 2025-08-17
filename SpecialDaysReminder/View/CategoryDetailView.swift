//
//  CategoryDetailView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import CloudKit

struct CategoryDetailView: View {
    @StateObject private var categoryDetailViewModel: CategoryDetailViewModel
    @ObservedObject var specialDaysListViewModel: SpecialDaysListViewModel
    
    let category: SpecialDayCategory?
    @Binding var navigationPath: NavigationPath
    
    // NEW: Binding to control the premium sheet presentation.
    @Binding var showingPremiumSheet: Bool
    
    @State private var showingAddSpecialDaySheet = false
    @Environment(\.dismiss) var dismiss

    // UPDATED: The initializer now accepts the showingPremiumSheet binding.
    init(viewModel: SpecialDaysListViewModel, category: SpecialDayCategory?, navigationPath: Binding<NavigationPath>, showingPremiumSheet: Binding<Bool>) {
        _specialDaysListViewModel = ObservedObject(wrappedValue: viewModel)
        self.category = category
        _navigationPath = navigationPath
        _showingPremiumSheet = showingPremiumSheet
        _categoryDetailViewModel = StateObject(wrappedValue: CategoryDetailViewModel(category: category, specialDaysListViewModel: viewModel))
    }

    private var darkerThemeColor: Color {
        (category?.color ?? .purple).darker()
    }

    var body: some View {
        ZStack {
            (category?.color ?? .purple).opacity(0.15)
                .edgesIgnoringSafeArea(.all)

            List {
                ForEach(categoryDetailViewModel.specialDaysForCategory) { day in
                    NavigationLink(value: NavigationDestinationType.editSpecialDay(IdentifiableCKRecordID(id: day.id))) {
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundColor(darkerThemeColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddSpecialDaySheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(darkerThemeColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddSpecialDaySheet) {
                // FIXED: Pass the showingPremiumSheet binding to the AddSpecialDayView.
                AddSpecialDayView(viewModel: specialDaysListViewModel, initialCategory: category, showingPremiumSheet: $showingPremiumSheet)
            }
        }
    }
}

// Color extension remains unchanged.
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
