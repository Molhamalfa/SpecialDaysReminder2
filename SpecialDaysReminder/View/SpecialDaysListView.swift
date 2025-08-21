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
    
    @State private var showingLapsedSubscriptionAlert = false
    
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
        // UPDATED: The body is now simpler. The complex view modifiers have been moved
        // to separate computed properties to help the compiler.
        navigationStackView
            .applyOnChangeModifiers(
                viewModel: viewModel,
                iapManager: iapManager,
                navigationPath: $navigationPath,
                showingLapsedSubscriptionAlert: $showingLapsedSubscriptionAlert,
                showingAddSpecialDaySheet: $showingAddSpecialDaySheet,
                selectedCategoryForAdd: $selectedCategoryForAdd,
                deepLinkEventID: $deepLinkEventID,
                deepLinkAddEvent: $deepLinkAddEvent,
                allDaysCardOpacity: $allDaysCardOpacity,
                allDaysCardOffset: $allDaysCardOffset,
                categoryGridOpacity: $categoryGridOpacity,
                categoryGridOffset: $categoryGridOffset
            )
    }
    
    // This new computed property contains the main navigation stack and its direct modifiers.
    private var navigationStackView: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                contentView
                
                if showingLapsedSubscriptionAlert {
                    LapsedSubscriptionView(
                        onReturnToFree: {
                            viewModel.deleteAllUserData()
                            iapManager.subscriptionLapsed = false
                            showingLapsedSubscriptionAlert = false
                        },
                        onContinueWithPremium: {
                            showingLapsedSubscriptionAlert = false
                            showingPremiumSheet = true
                        }
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .applySheetModifiers(
                showingAddCategorySheet: $showingAddCategorySheet,
                showingAddSpecialDaySheet: $showingAddSpecialDaySheet,
                showingPremiumSheet: $showingPremiumSheet,
                iapManager: iapManager,
                showingLapsedSubscriptionAlert: $showingLapsedSubscriptionAlert,
                viewModel: viewModel,
                selectedCategoryForAdd: selectedCategoryForAdd
            )
            .navigationDestination(for: NavigationDestinationType.self) { destination in
                navigationDestinationView(for: destination)
            }
        }
    }
    
    // The main content of the screen.
    @ViewBuilder
    private var contentView: some View {
        ZStack {
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
                errorView(error)
            }
        }
    }
    
    // The content for the toolbar.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // A helper to build the navigation destination views.
    @ViewBuilder
    private func navigationDestinationView(for destination: NavigationDestinationType) -> some View {
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
    
    // A helper to build the error view.
    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
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

// This new View extension groups the sheet modifiers together.
fileprivate extension View {
    @ViewBuilder
    func applySheetModifiers(
        showingAddCategorySheet: Binding<Bool>,
        showingAddSpecialDaySheet: Binding<Bool>,
        showingPremiumSheet: Binding<Bool>,
        iapManager: IAPManager,
        showingLapsedSubscriptionAlert: Binding<Bool>,
        viewModel: SpecialDaysListViewModel,
        selectedCategoryForAdd: SpecialDayCategory?
    ) -> some View {
        self
            .sheet(isPresented: showingAddCategorySheet) {
                AddCategoryView(viewModel: viewModel, showingPremiumSheet: showingPremiumSheet)
            }
            .sheet(isPresented: showingAddSpecialDaySheet) {
                AddSpecialDayView(viewModel: viewModel, initialCategory: selectedCategoryForAdd, showingPremiumSheet: showingPremiumSheet)
            }
            .sheet(isPresented: showingPremiumSheet, onDismiss: {
                if !iapManager.isPremiumUser && iapManager.subscriptionLapsed {
                    showingLapsedSubscriptionAlert.wrappedValue = true
                }
            }) {
                PremiumFeaturesView()
            }
    }
}

// This new View extension groups the onChange modifiers together.
fileprivate extension View {
    @ViewBuilder
    func applyOnChangeModifiers(
        viewModel: SpecialDaysListViewModel,
        iapManager: IAPManager,
        navigationPath: Binding<NavigationPath>,
        showingLapsedSubscriptionAlert: Binding<Bool>,
        showingAddSpecialDaySheet: Binding<Bool>,
        selectedCategoryForAdd: Binding<SpecialDayCategory?>,
        deepLinkEventID: Binding<String?>,
        deepLinkAddEvent: Binding<Bool>,
        allDaysCardOpacity: Binding<Double>,
        allDaysCardOffset: Binding<CGFloat>,
        categoryGridOpacity: Binding<Double>,
        categoryGridOffset: Binding<CGFloat>
    ) -> some View {
        self
            .onAppear {
                if case .loaded = viewModel.cloudKitState {
                    withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                        allDaysCardOpacity.wrappedValue = 1
                        allDaysCardOffset.wrappedValue = 0
                    }
                    withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                        categoryGridOpacity.wrappedValue = 1
                        categoryGridOffset.wrappedValue = 0
                    }
                }
            }
            .onChange(of: viewModel.cloudKitState) { _, newState in
                if case .loaded = newState {
                    withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                        allDaysCardOpacity.wrappedValue = 1
                        allDaysCardOffset.wrappedValue = 0
                    }
                    withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                        categoryGridOpacity.wrappedValue = 1
                        categoryGridOffset.wrappedValue = 0
                    }
                    
                    let categoryLimit = 1
                    let eventLimit = 3
                    if !viewModel.isPremiumUser && (viewModel.categories.count > categoryLimit || viewModel.specialDays.count > eventLimit) {
                        showingLapsedSubscriptionAlert.wrappedValue = true
                    }
                }
            }
            .onChange(of: iapManager.subscriptionLapsed) { _, hasLapsed in
                if hasLapsed {
                    showingLapsedSubscriptionAlert.wrappedValue = true
                }
            }
            .onChange(of: deepLinkEventID.wrappedValue) { _, newEventIDString in
                if let eventIDString = newEventIDString, let day = viewModel.specialDays.first(where: { $0.id.recordName == eventIDString }) {
                    navigationPath.wrappedValue = NavigationPath()
                    if let category = viewModel.category(for: day) {
                        navigationPath.wrappedValue.append(NavigationDestinationType.categoryDetail(category))
                    }
                    navigationPath.wrappedValue.append(NavigationDestinationType.editSpecialDay(IdentifiableCKRecordID(id: day.id)))
                    deepLinkEventID.wrappedValue = nil
                }
            }
            .onChange(of: deepLinkAddEvent.wrappedValue) { _, newAddEvent in
                if newAddEvent {
                    selectedCategoryForAdd.wrappedValue = nil
                    showingAddSpecialDaySheet.wrappedValue = true
                    deepLinkAddEvent.wrappedValue = false
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
