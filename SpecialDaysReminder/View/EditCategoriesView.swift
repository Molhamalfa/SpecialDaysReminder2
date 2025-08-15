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
                    .onDelete(perform: { indexSet in
                        viewModel.categories.remove(atOffsets: indexSet)
                    })
                }
            }
            .navigationTitle("Edit Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
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
