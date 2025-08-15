//
//  EmojiTextField.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import Combine

// This is now a reusable view that can be used anywhere in the app.
struct EmojiTextField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        TextField(placeholder, text: $text)
            .multilineTextAlignment(.center)
            .onReceive(Just(text)) { newText in
                // Keep only the first emoji character
                if newText.count > 1 {
                    self.text = String(newText.prefix(1))
                }
            }
    }
}
