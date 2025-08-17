//
//  StoreManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import StoreKit

// Define the identifiers for your in-app purchases.
// These must match what you set up in App Store Connect.
enum ProductIdentifiers {
    static let unlockPremium = "com.molham.SpecialDaysReminder.unlockPremium"
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
    
    // Listener for transaction updates.
    private var transactionListener: Task<Void, Error>? = nil

    init() {
        // Start listening for transaction changes as soon as the manager is initialized.
        transactionListener = listenForTransactions()
        
        // Fetch products from the App Store.
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
            let storeProducts = try await Product.products(for: [ProductIdentifiers.unlockPremium])
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
            // Verify the transaction.
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
    
    // Restores previously purchased non-consumable products.
    func restorePurchases() async {
        try? await AppStore.sync()
    }

    // Listens for transaction updates from the App Store.
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    // UPDATED: Switched to MainActor to safely update published properties.
                    await MainActor.run {
                        do {
                            let transaction = try self.checkVerified(result)
                            self.purchasedProductIDs.insert(transaction.productID)
                            Task {
                                await transaction.finish()
                            }
                        } catch {
                            print("Transaction failed verification inside MainActor run: \(error)")
                        }
                    }
                }
            }
        }
    }

    // Checks if a transaction is valid and verified.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // Updates the set of purchased product IDs.
    @MainActor
    private func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                print("Failed to verify purchased product: \(error)")
            }
        }
    }
}
