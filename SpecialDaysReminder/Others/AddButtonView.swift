//
//  AddButtonView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct AddButtonView: View {
    @Environment(\.colorScheme) var colorScheme

    let action: () -> Void

    var body: some View {
        Button(action: {
            // ADDED: Play a light impact haptic on tap.
            HapticManager.shared.playLightImpact()
            action()
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Category")
            }
            .font(.headline)
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.primary)
            .cornerRadius(15)
            .shadow(color: .secondary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
}
