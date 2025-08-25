//
//  PremiumFeaturesView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import StoreKit

extension Product.SubscriptionPeriod {
    var localizedDescription: String {
        let unitString: String
        switch self.unit {
        case .day:
            unitString = self.value == 1 ? "day" : "days"
        case .week:
            unitString = self.value == 1 ? "week" : "weeks"
        case .month:
            unitString = self.value == 1 ? "month" : "months"
        case .year:
            unitString = self.value == 1 ? "year" : "years"
        @unknown default:
            return ""
        }
        return "\(self.value) \(unitString)"
    }
}

struct PremiumFeaturesView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedProductId: String = ""
    
    @State private var shakeDegrees = 0.0
    @State private var shakeZoom = 0.9
    
    var body: some View {
        ZStack (alignment: .top) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "multiply")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, alignment: .center)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            VStack (spacing: 20) {
                // UPDATED: Replaced the image with a styled system icon.
                Image(systemName: "crown.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150, alignment: .center)
                    .scaleEffect(shakeZoom)
                    .rotationEffect(.degrees(shakeDegrees))
                    .onAppear(perform: startShaking)
                
                Text("Unlock Premium Access")
                    .font(.system(size: 30, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                FeatureComparisonView()
                
                VStack (spacing: 10) {
                    if storeManager.products.isEmpty {
                        ProgressView("Loading Offers...")
                    } else {
                        ForEach(storeManager.products) { product in
                            SubscriptionOptionButton(product: product, selectedProductId: $selectedProductId)
                        }
                    }
                }
                
                Spacer()
                
                VStack {
                    if let selectedProduct = storeManager.products.first(where: { $0.id == selectedProductId }) {
                        PurchaseButton(product: selectedProduct)
                    }
                    
                    RestoreButton()
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
        }
        .onAppear {
            if let firstProduct = storeManager.products.first {
                selectedProductId = firstProduct.id
            }
        }
    }
    
    private func startShaking() {
        let totalDuration = 0.7
        let numberOfShakes = 3
        let initialAngle: Double = 10
        
        withAnimation(.easeInOut(duration: totalDuration / 2)) {
            self.shakeZoom = 0.95
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration / 2) {
                withAnimation(.easeInOut(duration: totalDuration / 2)) {
                    self.shakeZoom = 0.9
                }
            }
        }

        for i in 0..<numberOfShakes {
            let delay = (totalDuration / Double(numberOfShakes)) * Double(i)
            let angle = initialAngle - (initialAngle / Double(numberOfShakes)) * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(Animation.easeInOut(duration: totalDuration / Double(numberOfShakes * 2))) {
                    self.shakeDegrees = angle
                }
                withAnimation(Animation.easeInOut(duration: totalDuration / Double(numberOfShakes * 2)).delay(totalDuration / Double(numberOfShakes * 2))) {
                    self.shakeDegrees = -angle
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            withAnimation {
                self.shakeDegrees = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                startShaking()
            }
        }
    }
}

// MARK: - Subviews

private struct FeatureComparisonView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Feature").bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text("Free").bold()
                    .frame(width: 80)
                Text("Premium").bold()
                    .foregroundColor(.purple)
                    .frame(width: 80)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Divider()
            
            FeatureComparisonRow(featureName: "Categories", freeLimit: "1", premiumBenefit: "Unlimited")
            Divider()
            FeatureComparisonRow(featureName: "Events", freeLimit: "5", premiumBenefit: "Unlimited")
            Divider()
            FeatureComparisonRow(featureName: "Widgets", freeLimit: "No", premiumBenefit: "Yes")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

private struct FeatureComparisonRow: View {
    let featureName: String
    let freeLimit: String
    let premiumBenefit: String
    
    var body: some View {
        HStack {
            Text(featureName)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(freeLimit)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80)
            
            if premiumBenefit == "Yes" {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.purple)
                    .frame(width: 80)
            } else if premiumBenefit == "No" {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 80)
            } else {
                Text(premiumBenefit)
                    .font(.subheadline.bold())
                    .foregroundColor(.purple)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct SubscriptionOptionButton: View {
    let product: Product
    @Binding var selectedProductId: String
    
    var isSelected: Bool {
        product.id == selectedProductId
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playLightImpact()
            withAnimation {
                selectedProductId = product.id
            }
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline.bold())
                    
                    priceDescriptionView
                        .font(.caption)
                        .opacity(0.8)
                }
                Spacer()
                
                Image(systemName: isSelected ? "circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .primary.opacity(0.15))
                    .font(.title3.bold())
            }
            .padding()
            .background(isSelected ? Color.purple.opacity(0.05) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? .purple : Color.clear, lineWidth: 2)
            )
        }
        .accentColor(.primary)
    }
    
    @ViewBuilder
    private var priceDescriptionView: some View {
        if let subscription = product.subscription,
           let introOffer = subscription.introductoryOffer,
           introOffer.paymentMode == .payUpFront {
            
            HStack(spacing: 4) {
                Text(product.displayPrice)
                    .strikethrough()
                Text("\(introOffer.displayPrice) for the first \(introOffer.period.localizedDescription)")
            }
            
        } else if let subscription = product.subscription,
                  let introOffer = subscription.introductoryOffer,
                  introOffer.paymentMode == .freeTrial {
            Text("Starts with a \(introOffer.period.value)-day free trial, then \(product.displayPrice) per year.")
        } else {
            Text("\(product.displayPrice) per year")
        }
    }
}

private struct PurchaseButton: View {
    @EnvironmentObject var storeManager: StoreManager
    @State private var isPurchasing = false
    let product: Product
    
    var callToActionText: String {
        if let introOffer = product.subscription?.introductoryOffer, introOffer.paymentMode == .freeTrial {
            return "Start Free Trial"
        } else {
            return "Unlock Now"
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.playLightImpact()
            Task {
                isPurchasing = true
                _ = try? await storeManager.purchase(product)
                isPurchasing = false
            }
        }) {
            ZStack {
                if isPurchasing {
                    ProgressView()
                }
                
                HStack {
                    Spacer()
                    Text(callToActionText)
                    Image(systemName: "chevron.right")
                    Spacer()
                }
                .padding()
                .foregroundColor(.white)
                .font(.title3.bold())
                .opacity(isPurchasing ? 0 : 1)
            }
        }
        .background(Color.purple)
        .cornerRadius(10)
        .disabled(isPurchasing)
    }
}

private struct RestoreButton: View {
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        Button("Restore Purchases") {
            HapticManager.shared.playLightImpact()
            Task {
                await storeManager.restorePurchases()
            }
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }
}
