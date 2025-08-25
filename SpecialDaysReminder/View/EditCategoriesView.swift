//
//  EditCategoriesView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import Combine

struct EditCategoriesView: View {
    @ObservedObject var viewModel: SpecialDaysListViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var iapManager: IAPManager

    init(specialDaysListViewModel: SpecialDaysListViewModel) {
        _viewModel = ObservedObject(wrappedValue: specialDaysListViewModel)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Category")) {
                    HStack {
                        Text("🗓️")
                            .font(.largeTitle)
                            .frame(width: 50, height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        Text("All Special Days")
                            .font(.headline)
                    }
                    ColorPicker("Color", selection: $viewModel.allDaysCategoryColor, supportsOpacity: false)
                }
                
                Section(header: Text("Your Categories")) {
                    ForEach($viewModel.categories) { $category in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                EmojiTextField(text: $category.icon, placeholder: "⭐️")
                                    .font(.largeTitle)
                                    .frame(width: 50, height: 50)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                
                                TextField("Category Name", text: $category.name)
                                    .font(.headline)
                            }
                            ColorPicker("Color", selection: $category.color, supportsOpacity: false)
                        }
                        .padding(.vertical, 5)
                    }
                    .onDelete(perform: { indexSet in
                        // ADDED: Play success haptic on delete.
                        HapticManager.shared.playSuccess()
                        viewModel.deleteCategory(at: indexSet)
                    })
                    .onMove(perform: { indices, newOffset in
                        viewModel.moveCategory(from: indices, to: newOffset)
                    })
                }
                
                #if DEBUG
                Section(header: Text("Debug Settings")) {
                    Toggle("Simulate Premium Status", isOn: $iapManager.isDebugPremium)
                }
                #endif
            }
            .navigationTitle("Edit Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        viewModel.updateCategories(viewModel.categories)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
}
