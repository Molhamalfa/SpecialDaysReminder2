//
//  LapsedSubscriptionView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI

struct LapsedSubscriptionView: View {
    // These closures will be provided by the parent view to handle button taps.
    let onReturnToFree: () -> Void
    let onContinueWithPremium: () -> Void
    
    var body: some View {
        ZStack {
            // A semi-transparent background to dim the underlying content.
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Title and message
                Text("Subscription Expired")
                    .font(.headline)
                    .padding()
                
                Text("Your premium subscription has ended. To stay within the free limits, all existing data will be deleted if you return to the free plan. Your data is safe if you continue with premium.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom)
                
                Divider()
                
                // Custom buttons
                HStack(spacing: 0) {
                    Button(action: onReturnToFree) {
                        Text("Return to Free")
                            .bold()
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    Divider()
                    
                    Button(action: onContinueWithPremium) {
                        Text("Continue with Premium")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 44)
            }
            .background(Color(.systemGray6))
            .cornerRadius(14)
            .shadow(radius: 10)
            .padding(40)
        }
    }
}
