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
    @StateObject var viewModel = SpecialDaysListViewModel()
    
    @State private var showingAddSpecialDaySheet: Bool = false
    @State private var showingAddCategorySheet: Bool = false
    @State private var selectedCategoryForAdd: SpecialDayCategory?
    @State private var navigationPath = NavigationPath()
    
    // The deep link now uses CKRecord.ID's recordName which is a String.
    @Binding var deepLinkEventID: String?
    @Binding var deepLinkAddEvent: Bool

    // Animation states remain the same.
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -20
    @State private var allDaysCardOpacity: Double = 0
    @State private var allDaysCardOffset: CGFloat = -20
    @State private var categoryGridOpacity: Double = 0
    @State private var categoryGridOffset: CGFloat = -20

    init(deepLinkEventID: Binding<String?>, deepLinkAddEvent: Binding<Bool>) {
        _deepLinkEventID = deepLinkEventID
        _deepLinkAddEvent = deepLinkAddEvent
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)

                // Main UI now switches based on the CloudKit state.
                switch viewModel.cloudKitState {
                case .loading, .idle:
                    ProgressView("Loading Your Special Days...")
                
                case .loaded:
                    // The content view is only shown when data is successfully loaded.
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
                
                case .error(let error):
                    // A dedicated view for showing errors.
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Toolbar is only shown when data is loaded.
                if case .loaded = viewModel.cloudKitState {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(value: NavigationDestinationType.editCategories) {
                            Image(systemName: "pencil.circle.fill")
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
            }
            .sheet(isPresented: $showingAddCategorySheet) {
                AddCategoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddSpecialDaySheet) {
                AddSpecialDayView(viewModel: viewModel, initialCategory: selectedCategoryForAdd)
            }
            .navigationDestination(for: NavigationDestinationType.self) { destination in
                // Navigation destinations updated to use new models and IDs.
                switch destination {
                case .allSpecialDaysDetail:
                    CategoryDetailView(viewModel: viewModel, category: nil, navigationPath: $navigationPath)
                case .categoryDetail(let category):
                    CategoryDetailView(viewModel: viewModel, category: category, navigationPath: $navigationPath)
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
            // Animations now trigger when the state becomes .loaded.
            if case .loaded = viewModel.cloudKitState {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) { headerOpacity = 1; headerOffset = 0 }
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) { allDaysCardOpacity = 1; allDaysCardOffset = 0 }
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) { categoryGridOpacity = 1; categoryGridOffset = 0 }
            }
        }
        .onChange(of: viewModel.cloudKitState) { _, newState in
             // Trigger animation when data is loaded.
            if case .loaded = newState {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) { headerOpacity = 1; headerOffset = 0 }
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) { allDaysCardOpacity = 1; allDaysCardOffset = 0 }
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) { categoryGridOpacity = 1; categoryGridOffset = 0 }
            }
        }
        .onChange(of: deepLinkEventID) { _, newEventIDString in
            // Deep link logic updated for CKRecord.ID's recordName.
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
