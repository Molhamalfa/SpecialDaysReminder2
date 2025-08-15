//
//  SpecialDaysListView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct IdentifiableUUID: Identifiable, Equatable, Hashable {
    let id: UUID
}

enum NavigationDestinationType: Hashable {
    case allSpecialDaysDetail
    case categoryDetail(SpecialDayCategory)
    case editSpecialDay(IdentifiableUUID)
    case calendarImport
    case editCategories // New destination for editing categories
}

struct SpecialDaysListView: View {
    @StateObject var viewModel = SpecialDaysListViewModel()
    
    @State private var showingAddSpecialDaySheet: Bool = false
    @State private var showingAddCategorySheet: Bool = false
    @State private var selectedCategoryForAdd: SpecialDayCategory?
    @State private var navigationPath = NavigationPath()
    
    @Binding var deepLinkEventID: UUID?
    @Binding var deepLinkAddEvent: Bool

    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -20
    @State private var allDaysCardOpacity: Double = 0
    @State private var allDaysCardOffset: CGFloat = -20
    @State private var categoryGridOpacity: Double = 0
    @State private var categoryGridOffset: CGFloat = -20

    init(deepLinkEventID: Binding<UUID?>, deepLinkAddEvent: Binding<Bool>) {
        _deepLinkEventID = deepLinkEventID
        _deepLinkAddEvent = deepLinkAddEvent
    }

    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)

            NavigationStack(path: $navigationPath) {
                SpecialDaysContentView(
                    viewModel: viewModel,
                    headerOpacity: headerOpacity,
                    headerOffset: headerOffset,
                    allDaysCardOpacity: allDaysCardOpacity,
                    allDaysCardOffset: allDaysCardOffset,
                    categoryGridOpacity: categoryGridOpacity,
                    categoryGridOffset: categoryGridOffset,
                    showingAddCategorySheet: $showingAddCategorySheet,
                    navigationPath: $navigationPath,
                    onAddTapped: { category in
                        self.selectedCategoryForAdd = category
                        self.showingAddSpecialDaySheet = true
                    }
                )
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // UPDATED: This now navigates to the EditCategoriesView
                        NavigationLink(value: NavigationDestinationType.editCategories) {
                            Image(systemName: "pencil.circle.fill") // Edit icon
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            navigationPath.append(NavigationDestinationType.calendarImport)
                        } label: {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                    }
                }
                .sheet(isPresented: $showingAddCategorySheet) {
                    AddCategoryView(viewModel: viewModel)
                }
                .sheet(isPresented: $showingAddSpecialDaySheet) {
                    AddSpecialDayView(viewModel: viewModel, initialCategory: selectedCategoryForAdd)
                }
                .navigationDestination(for: NavigationDestinationType.self) { destination in
                    switch destination {
                    case .allSpecialDaysDetail:
                        CategoryDetailView(viewModel: viewModel, category: nil, navigationPath: $navigationPath)
                    case .categoryDetail(let category):
                        CategoryDetailView(viewModel: viewModel, category: category, navigationPath: $navigationPath)
                    case .editSpecialDay(let identifiableUUID):
                        if let dayToEdit = viewModel.specialDays.first(where: { $0.id == identifiableUUID.id }) {
                            EditSpecialDayView(viewModel: viewModel, specialDay: dayToEdit)
                        } else {
                            Text("Event not found.")
                        }
                    case .calendarImport:
                        CalendarImportView(specialDaysListViewModel: viewModel)
                    case .editCategories:
                        // New destination view
                        EditCategoriesView(specialDaysListViewModel: viewModel)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { headerOpacity = 1; headerOffset = 0 }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { allDaysCardOpacity = 1; allDaysCardOffset = 0 }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { categoryGridOpacity = 1; categoryGridOffset = 0 }
        }
        .onChange(of: deepLinkEventID) { _, newEventID in
            if let eventID = newEventID, let day = viewModel.specialDays.first(where: { $0.id == eventID }) {
                navigationPath = NavigationPath()
                if let category = viewModel.category(for: day) {
                    navigationPath.append(NavigationDestinationType.categoryDetail(category))
                }
                navigationPath.append(NavigationDestinationType.editSpecialDay(IdentifiableUUID(id: day.id)))
                deepLinkEventID = nil
            }
        }
        .onChange(of: deepLinkAddEvent) { _, newAddEvent in
            if newAddEvent {
                self.selectedCategoryForAdd = nil
                self.showingAddSpecialDaySheet = true
                deepLinkAddEvent = false
            }
        }
    }
}
