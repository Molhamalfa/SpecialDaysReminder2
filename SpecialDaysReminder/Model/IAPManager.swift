//
//  IAPManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import Combine

@MainActor
class IAPManager: ObservableObject {
    @Published private(set) var isPremiumUser: Bool = false
    
    private let userDefaultsKey = "isPremiumUser"
    private var cancellables = Set<AnyCancellable>()
    private let storeManager: StoreManager

    init(storeManager: StoreManager) {
        self.storeManager = storeManager
        self.isPremiumUser = UserDefaults.standard.bool(forKey: userDefaultsKey)
        
        storeManager.$purchasedProductIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] purchasedIDs in
                self?.updatePremiumStatus(for: purchasedIDs)
            }
            .store(in: &cancellables)
    }

    private func updatePremiumStatus(for purchasedIDs: Set<String>) {
        // UPDATED: Check if the set of purchased IDs contains *any* of our subscription products.
        let hasPremium = !purchasedIDs.isDisjoint(with: ProductIdentifiers.all)
        
        if self.isPremiumUser != hasPremium {
            self.isPremiumUser = hasPremium
            UserDefaults.standard.set(hasPremium, forKey: userDefaultsKey)
            print("Premium status updated: \(hasPremium)")
        }
    }
}
