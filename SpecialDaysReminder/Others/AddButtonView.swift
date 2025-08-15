//
//  AddButtonView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct AddButtonView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                Text("Add Category")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            // UPDATED: Replaced the gradient with a simple, dark color
            // that matches the toolbar icons for a cleaner look.
            .background(Color.black.opacity(0.85))
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
}
