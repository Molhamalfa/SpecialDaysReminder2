//
//  PremiumFeaturesView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import StoreKit

// ADDED: An extension to format the subscription period
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
                Image("purchaseview-hero")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 150, alignment: .center)
                    .scaleEffect(shakeZoom)
                    .rotationEffect(.degrees(shakeDegrees))
                    .onAppear(perform: startShaking)
                
                VStack (spacing: 10) {
                    Text("Unlock Premium Access")
                        .font(.system(size: 30, weight: .semibold))
                        .multilineTextAlignment(.center)
                    VStack (alignment: .leading) {
                        PurchaseFeatureView(title: "Unlimited Categories", icon: "infinity.circle.fill", color: .purple)
                        PurchaseFeatureView(title: "Unlimited Events", icon: "calendar.badge.plus", color: .purple)
                        PurchaseFeatureView(title: "Home Screen Widgets", icon: "square.stack.3d.up.fill", color: .purple)
                    }
                    .font(.system(size: 19))
                    .padding(.top)
                }
                
                Spacer()
                
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

private struct PurchaseFeatureView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 27, height: 27, alignment: .center)
                .foregroundColor(color)
            Text(title)
        }
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
            withAnimation {
                selectedProductId = product.id
            }
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline.bold())
                    
                    // UPDATED: Use a ViewBuilder to create the price display
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
    
    // UPDATED: This is now a ViewBuilder property
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
            Task {
                await storeManager.restorePurchases()
            }
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }
}
