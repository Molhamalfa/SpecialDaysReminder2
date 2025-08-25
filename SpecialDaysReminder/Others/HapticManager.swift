//
//  HapticManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import UIKit

// A simple manager to play haptic feedback.
class HapticManager {
    // A shared instance to use across the app.
    static let shared = HapticManager()
    
    // Private initializer to ensure it's a singleton.
    private init() {}

    /// Plays a success haptic feedback.
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // ADDED: A new function to play a light impact haptic, perfect for button taps.
    func playLightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
