//
//  PremiumFeaturesView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import StoreKit

struct PremiumFeaturesView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                Text("Unlock Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 5)

                FeatureRow(icon: "infinity.circle.fill", text: "Unlimited Categories")
                FeatureRow(icon: "calendar.badge.plus", text: "Unlimited Events")
                FeatureRow(icon: "square.stack.3d.up.fill", text: "Home Screen Widgets")

                Spacer()

                // UPDATED: Replaced ForEach with a simple check for the first (and only) product.
                if let annualProduct = storeManager.products.first {
                    PurchaseButton(product: annualProduct)
                } else {
                    ProgressView("Loading Offer...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                }
                
                RestoreButton()
                
                Button("Not Now") {
                    dismiss()
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 10)
            }
            .padding(30)
        }
    }
}

// Helper view for feature rows
private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

// Helper view for the purchase button
private struct PurchaseButton: View {
    @EnvironmentObject var storeManager: StoreManager
    let product: Product
    @State private var isPurchasing = false

    var body: some View {
        Button(action: {
            Task {
                isPurchasing = true
                _ = try? await storeManager.purchase(product)
                isPurchasing = false
            }
        }) {
            if isPurchasing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
            } else {
                VStack {
                    Text("\(product.displayName) - \(product.displayPrice)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let introOffer = product.subscription?.introductoryOffer,
                       introOffer.paymentMode == .freeTrial {
                        Text("Starts with a \(introOffer.period.value)-day free trial")
                            .font(.caption)
                            .foregroundColor(.purple.opacity(0.8))
                    }
                }
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
        .disabled(isPurchasing)
    }
}

// Helper view for the restore button
private struct RestoreButton: View {
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        Button("Restore Purchases") {
            Task {
                await storeManager.restorePurchases()
            }
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.top, 10)
    }
}
