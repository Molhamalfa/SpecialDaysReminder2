//
//  IAPManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import Combine

// UPDATED: Added @MainActor to ensure all properties and methods
// are accessed on the main thread, resolving the concurrency error.
@MainActor
class IAPManager: ObservableObject {
    @Published private(set) var isPremiumUser: Bool = false
    
    private let userDefaultsKey = "isPremiumUser"
    private var cancellables = Set<AnyCancellable>()
    private let storeManager: StoreManager

    init(storeManager: StoreManager) {
        self.storeManager = storeManager
        self.isPremiumUser = UserDefaults.standard.bool(forKey: userDefaultsKey)
        
        // Observe changes in purchased products from the StoreManager.
        storeManager.$purchasedProductIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] purchasedIDs in
                self?.updatePremiumStatus(for: purchasedIDs)
            }
            .store(in: &cancellables)
    }

    private func updatePremiumStatus(for purchasedIDs: Set<String>) {
        let hasPremium = purchasedIDs.contains(ProductIdentifiers.unlockPremium)
        
        if self.isPremiumUser != hasPremium {
            self.isPremiumUser = hasPremium
            UserDefaults.standard.set(hasPremium, forKey: userDefaultsKey)
            print("Premium status updated: \(hasPremium)")
        }
    }
}
