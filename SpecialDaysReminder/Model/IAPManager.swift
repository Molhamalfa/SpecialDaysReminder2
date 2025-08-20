//
//  IAPManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class IAPManager: ObservableObject {
    @Published var isPremiumUser: Bool = false
    
    @Published var subscriptionLapsed: Bool = false
    
    #if DEBUG
    @Published var isDebugPremium: Bool = false {
        didSet {
            sharedUserDefaults?.set(isDebugPremium, forKey: debugUserDefaultsKey)
            updatePremiumStatus(purchasedIDs: storeManager.purchasedProductIDs, isDebugPremium: isDebugPremium)
        }
    }
    private let debugUserDefaultsKey = "isDebugPremium"
    #endif

    private let userDefaultsKey = "isPremiumUser"
    private let appGroupIdentifier = "group.com.molham.SpecialDaysReminder"
    private var sharedUserDefaults: UserDefaults?
    
    private var cancellables = Set<AnyCancellable>()
    private let storeManager: StoreManager

    init(storeManager: StoreManager) {
        self.storeManager = storeManager
        self.sharedUserDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        self.isPremiumUser = sharedUserDefaults?.bool(forKey: userDefaultsKey) ?? false
        
        #if DEBUG
        self.isDebugPremium = sharedUserDefaults?.bool(forKey: debugUserDefaultsKey) ?? false
        #endif
        
        let debugPublisher: AnyPublisher<Bool, Never>
        #if DEBUG
        debugPublisher = $isDebugPremium.eraseToAnyPublisher()
        #else
        debugPublisher = Just(false).eraseToAnyPublisher()
        #endif

        storeManager.$purchasedProductIDs
            .combineLatest(debugPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (purchasedIDs, isDebugPremium) in
                self?.updatePremiumStatus(purchasedIDs: purchasedIDs, isDebugPremium: isDebugPremium)
            }
            .store(in: &cancellables)
    }

    private func updatePremiumStatus(purchasedIDs: Set<String>, isDebugPremium: Bool) {
        let hasRealPurchase = !purchasedIDs.isDisjoint(with: ProductIdentifiers.all)
        
        var newStatus = hasRealPurchase
        #if DEBUG
        newStatus = hasRealPurchase || isDebugPremium
        #endif

        // Get the previous status before updating.
        let oldStatus = self.isPremiumUser

        if oldStatus != newStatus {
            self.isPremiumUser = newStatus
            sharedUserDefaults?.set(newStatus, forKey: userDefaultsKey)
            print("Premium status updated: \(self.isPremiumUser)")
            
            // UPDATED: Only trigger the lapsed alert if the status changes
            // from true (premium) to false (not premium).
            if oldStatus == true && newStatus == false {
                self.subscriptionLapsed = true
            }
        }
    }
}
