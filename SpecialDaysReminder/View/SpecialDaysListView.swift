//
//  SpecialDaysListView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import CloudKit

// A wrapper to make CKRecord.ID conform to Identifiable, Equatable, and Hashable for navigation.
struct IdentifiableCKRecordID: Identifiable, Equatable, Hashable {
    let id: CKRecord.ID
}

enum NavigationDestinationType: Hashable {
    case allSpecialDaysDetail
    case categoryDetail(SpecialDayCategory)
    case editSpecialDay(IdentifiableCKRecordID)
    case calendarImport
    case editCategories
}

struct SpecialDaysListView: View {
    @EnvironmentObject var iapManager: IAPManager
    
    @StateObject var viewModel: SpecialDaysListViewModel
    
    @State private var showingAddSpecialDaySheet: Bool = false
    @State private var showingAddCategorySheet: Bool = false
    @State private var selectedCategoryForAdd: SpecialDayCategory?
    @State private var navigationPath = NavigationPath()
    
    @State private var showingPremiumSheet = false
    
    @Binding var deepLinkEventID: String?
    @Binding var deepLinkAddEvent: Bool

    @State private var allDaysCardOpacity: Double = 0
    @State private var allDaysCardOffset: CGFloat = -20
    @State private var categoryGridOpacity: Double = 0
    @State private var categoryGridOffset: CGFloat = -20

    init(iapManager: IAPManager, deepLinkEventID: Binding<String?>, deepLinkAddEvent: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: SpecialDaysListViewModel(iapManager: iapManager))
        _deepLinkEventID = deepLinkEventID
        _deepLinkAddEvent = deepLinkAddEvent
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                contentView
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .loaded = viewModel.cloudKitState {
                    ToolbarItem(placement: .principal) {
                        Text("Your Special Days")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                navigationPath.append(NavigationDestinationType.editCategories)
                            } label: {
                                Label("Edit Categories", systemImage: "pencil")
                            }
                            
                            Button {
                                navigationPath.append(NavigationDestinationType.calendarImport)
                            } label: {
                                Label("Import from Calendar", systemImage: "square.and.arrow.down")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                // Use .primary color to adapt to light/dark mode.
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCategorySheet) {
                AddCategoryView(viewModel: viewModel, showingPremiumSheet: $showingPremiumSheet)
            }
            .sheet(isPresented: $showingAddSpecialDaySheet) {
                AddSpecialDayView(viewModel: viewModel, initialCategory: selectedCategoryForAdd, showingPremiumSheet: $showingPremiumSheet)
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumFeaturesView()
            }
            .navigationDestination(for: NavigationDestinationType.self) { destination in
                switch destination {
                case .allSpecialDaysDetail:
                    CategoryDetailView(viewModel: viewModel, category: nil, navigationPath: $navigationPath, showingPremiumSheet: $showingPremiumSheet)
                case .categoryDetail(let category):
                    CategoryDetailView(viewModel: viewModel, category: category, navigationPath: $navigationPath, showingPremiumSheet: $showingPremiumSheet)
                case .editSpecialDay(let identifiableRecordID):
                    if let dayToEdit = viewModel.specialDays.first(where: { $0.id == identifiableRecordID.id }) {
                        EditSpecialDayView(viewModel: viewModel, specialDay: dayToEdit)
                    } else {
                        Text("Event not found.")
                    }
                case .calendarImport:
                    CalendarImportView(specialDaysListViewModel: viewModel)
                case .editCategories:
                    EditCategoriesView(specialDaysListViewModel: viewModel)
                }
            }
        }
        .onAppear {
            if case .loaded = viewModel.cloudKitState {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) { allDaysCardOpacity = 1; allDaysCardOffset = 0 }
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) { categoryGridOpacity = 1; categoryGridOffset = 0 }
            }
        }
        .onChange(of: viewModel.cloudKitState) { _, newState in
            if case .loaded = newState {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) { allDaysCardOpacity = 1; allDaysCardOffset = 0 }
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) { categoryGridOpacity = 1; categoryGridOffset = 0 }
            }
        }
        .onChange(of: deepLinkEventID) { _, newEventIDString in
            if let eventIDString = newEventIDString, let day = viewModel.specialDays.first(where: { $0.id.recordName == eventIDString }) {
                navigationPath = NavigationPath()
                if let category = viewModel.category(for: day) {
                    navigationPath.append(NavigationDestinationType.categoryDetail(category))
                }
                navigationPath.append(NavigationDestinationType.editSpecialDay(IdentifiableCKRecordID(id: day.id)))
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
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            // UPDATED: Use a system background color that adapts to dark mode.
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            switch viewModel.cloudKitState {
            case .loading, .idle:
                ProgressView("Loading Your Special Days...")
            
            case .loaded:
                SpecialDaysContentView(
                    viewModel: viewModel,
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
            
            case .error(let error):
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.icloud.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Error Loading Data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        viewModel.fetchCategoriesAndSpecialDays()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// Equatable conformance for CloudKitState to be used in onChange.
extension CloudKitState: Equatable {
    public static func == (lhs: CloudKitState, rhs: CloudKitState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.loaded, .loaded): return true
        case (.error, .error): return true // Simplified for state change detection
        default: return false
        }
    }
}
