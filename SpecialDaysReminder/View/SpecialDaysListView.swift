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
    
    @Binding var deepLinkEventID: String?
    @Binding var deepLinkAddEvent: Bool

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
                contentView // The main content is now in a separate computed property.
                
                // An overlay to show the loading indicator when preparing a share.
                if viewModel.isPreparingShare {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Sharing Category...")
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                    .padding(30)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(15)
                }
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
            // Add a sheet modifier to present the sharing view.
            .sheet(isPresented: $viewModel.isShowingSharingView, onDismiss: {
                // UPDATED: Whenever the sharing sheet is dismissed, for any reason,
                // perform a silent refresh of the data from CloudKit. This ensures
                // the app has the latest share information and prevents state issues.
                viewModel.fetchCategoriesAndSpecialDays(isSilent: true)
            }) {
                if let share = viewModel.shareToShow, let category = viewModel.categoryToShare {
                    CloudKitSharingView(share: share, container: CloudKitManager.shared.container, categoryToShare: category) {
                        // When the sheet is dismissed, clear the share-related properties.
                        viewModel.isShowingSharingView = false
                        viewModel.shareToShow = nil
                        viewModel.categoryToShare = nil
                    }
                }
            }
            .navigationDestination(for: NavigationDestinationType.self) { destination in
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
            Color.white.edgesIgnoringSafeArea(.all)

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
                    },
                    // Connect the share button tap to the view model's new function.
                    onShareTapped: { category in
                        viewModel.shareCategory(category)
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
