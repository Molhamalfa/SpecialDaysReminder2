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
    
    @State private var showingAddSpecialDaySheet = false
    @Environment(\.dismiss) var dismiss

    init(viewModel: SpecialDaysListViewModel, category: SpecialDayCategory?, navigationPath: Binding<NavigationPath>) {
        _specialDaysListViewModel = ObservedObject(wrappedValue: viewModel)
        self.category = category
        _navigationPath = navigationPath
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
                    // Navigation now uses the IdentifiableCKRecordID wrapper.
                    NavigationLink(value: NavigationDestinationType.editSpecialDay(IdentifiableCKRecordID(id: day.id))) {
                        SpecialDayRowView(day: day, themeColor: category?.color ?? .purple)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions {
                        Button(role: .destructive) {
                            // Deletion now passes the CKRecord.ID.
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
                AddSpecialDayView(viewModel: specialDaysListViewModel, initialCategory: category)
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
