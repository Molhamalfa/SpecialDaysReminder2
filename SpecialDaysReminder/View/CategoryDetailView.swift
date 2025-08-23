//
//  CategoryDetailView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import CloudKit

// ADDED: These structs are now here
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


struct CategoryDetailView: View {
    @StateObject private var categoryDetailViewModel: CategoryDetailViewModel
    @ObservedObject var specialDaysListViewModel: SpecialDaysListViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    let category: SpecialDayCategory?
    @Binding var navigationPath: NavigationPath
    
    @Binding var showingPremiumSheet: Bool
    
    @State private var showingAddSpecialDaySheet = false
    @Environment(\.dismiss) var dismiss
    
    // ADDED: State for the share sheet
    @State private var shareableURL: IdentifiableURL?

    init(viewModel: SpecialDaysListViewModel, category: SpecialDayCategory?, navigationPath: Binding<NavigationPath>, showingPremiumSheet: Binding<Bool>) {
        _specialDaysListViewModel = ObservedObject(wrappedValue: viewModel)
        self.category = category
        _navigationPath = navigationPath
        _showingPremiumSheet = showingPremiumSheet
        _categoryDetailViewModel = StateObject(wrappedValue: CategoryDetailViewModel(category: category, specialDaysListViewModel: viewModel))
    }

    private var themeColor: Color {
        category?.color ?? specialDaysListViewModel.allDaysCategoryColor
    }
    
    private var adaptiveBackgroundColor: Color {
        let baseColor = category?.color ?? specialDaysListViewModel.allDaysCategoryColor
        if colorScheme == .dark {
            return baseColor.darker(by: 0.6).opacity(0.4)
        } else {
            return baseColor.opacity(0.15)
        }
    }

    var body: some View {
        List {
            ForEach(categoryDetailViewModel.specialDaysForCategory) { day in
                NavigationLink(value: NavigationDestinationType.editSpecialDay(IdentifiableCKRecordID(id: day.id))) {
                    SpecialDayRowView(day: day, themeColor: themeColor)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions {
                    Button(role: .destructive) {
                        categoryDetailViewModel.deleteDay(id: day.id)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    
                    // ADDED: Share button as a swipe action
                    Button {
                        shareEvent(for: day)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(adaptiveBackgroundColor.edgesIgnoringSafeArea(.all))
        .navigationTitle(category?.displayName ?? "All Special Days")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeColor)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddSpecialDaySheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeColor)
                }
            }
        }
        .sheet(isPresented: $showingAddSpecialDaySheet) {
            AddSpecialDayView(viewModel: specialDaysListViewModel, initialCategory: category, showingPremiumSheet: $showingPremiumSheet)
        }
        // ADDED: Sheet modifier for sharing
        .sheet(item: $shareableURL) { identifiableURL in
            ShareSheet(activityItems: [identifiableURL.url])
        }
    }
    
    // ADDED: Share event function
    private func shareEvent(for day: SpecialDayModel) {
        if let url = specialDaysListViewModel.generateICSFile(for: day) {
            shareableURL = IdentifiableURL(url: url)
        }
    }
}

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
