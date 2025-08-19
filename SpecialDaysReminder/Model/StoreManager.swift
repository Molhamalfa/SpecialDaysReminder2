//
//  StoreManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import StoreKit

// UPDATED: Product identifiers now only contain the annual subscription.
enum ProductIdentifiers {
    static let annual = "com.molham.SpecialDaysReminder.annual"
    static let all = [annual]
}

// Custom error for StoreKit operations.
enum StoreError: Error, LocalizedError {
    case failedVerification
    case unknown

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Your purchase could not be verified. Please try again."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// Main class to manage StoreKit interactions.
@MainActor
class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    
    private var transactionListener: Task<Void, Error>? = nil

    init() {
        transactionListener = listenForTransactions()
        
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // Fetches product definitions from the App Store.
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: ProductIdentifiers.all)
            self.products = storeProducts
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    // Initiates the purchase flow for a product.
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
    }

    // Listens for transaction updates from the App Store.
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await MainActor.run {
                    do {
                        let transaction = try self.checkVerified(result)
                        
                        if transaction.revocationDate == nil {
                            self.purchasedProductIDs.insert(transaction.productID)
                        } else {
                            self.purchasedProductIDs.remove(transaction.productID)
                        }
                        
                        Task {
                            await transaction.finish()
                        }
                        
                    } catch {
                        print("Transaction listener failed to process update: \(error)")
                    }
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // The logic here is robust. `currentEntitlements` automatically checks for active subscriptions.
    @MainActor
    private func updatePurchasedProducts() async {
        var updatedPurchasedIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    updatedPurchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify purchased product: \(error)")
            }
        }
        self.purchasedProductIDs = updatedPurchasedIDs
    }
}
