//
//  AddCategoryView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import Combine

struct AddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SpecialDaysListViewModel
    
    @Binding var showingPremiumSheet: Bool

    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = ""

    var body: some View {
        NavigationView {
            Form {
                CategoryDetailsSection(name: $name)
                CategoryColorSection(selectedColor: $selectedColor)
                
                Section(header: Text("Icon")) {
                    EmojiTextField(text: $selectedIcon, placeholder: "Add Emoji")
                        .font(.largeTitle)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // ADDED: Play success haptic on save.
                        HapticManager.shared.playSuccess()
                        
                        if !viewModel.isPremiumUser && viewModel.categories.count >= 1 {
                            showingPremiumSheet = true
                            dismiss()
                        } else {
                            let iconToSave = selectedIcon.isEmpty ? "⭐️" : selectedIcon
                            let newCategory = SpecialDayCategory(name: name, color: selectedColor, icon: iconToSave)
                            viewModel.addCategory(newCategory)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Helper Views

private struct CategoryDetailsSection: View {
    @Binding var name: String
    
    var body: some View {
        Section(header: Text("Category Details")) {
            TextField("Category Name", text: $name)
        }
    }
}

private struct CategoryColorSection: View {
    @Binding var selectedColor: Color
    
    var body: some View {
        Section(header: Text("Color")) {
            ColorPicker("Select a color", selection: $selectedColor, supportsOpacity: false)
        }
    }
}
