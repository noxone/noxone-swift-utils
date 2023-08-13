//
//  PurchaseManager.swift
//  VideoPreRecorder
//
//  Created by Olaf Neumann on 06.07.23.
//

// https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/

import Foundation
import SwiftUI
import StoreKit
import os.log

fileprivate let logger = Logger(category: "PurchaseManager")

@MainActor
public class PurchaseManager: ObservableObject {
    private let productIds: [String]
    
    @Published
    private(set) var products: [Product] = []
    @Published
    private(set) var productsLoaded = false
    
    @PostPublished
    private(set) var purchasedProductIDs = Set<String>()
    
    private var updates: Task<Void, Never>? = nil
    
    private var actionsForRequestedPurchases: [String:()->Void] = [:]

    public init(productIds: [String]) {
        self.productIds = [] + productIds
        updates = observeTransactionUpdates()
    }

    deinit {
        updates?.cancel()
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ /*verificationResult*/ in Transaction.updates {
                // Using verificationResult directly would be better
                // but this way works for this tutorial
                await self.updatePurchasedProducts()
            }
        }
    }
    
    func hasUnlocked(_ id: String) -> Bool {
        let isUnlocked = purchasedProductIDs.contains(id)
        logger.info("Checking \(id): \(isUnlocked)")
        return isUnlocked
    }
    
    public func getProduct(for id: String) -> Product? {
        return products.first { $0.id == id }
    }
    
    public func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        self.products = try await Product.products(for: productIds)
        self.productsLoaded = true
        logger.info("Loaded products: \(self.products.map {$0.id})")
    }
    
    public func purchase(_ product: Product, withActionOnSuccess action: @escaping () -> Void) async throws {
        let result = try await product.purchase(/*options: [.simulatesAskToBuyInSandbox(true)]*/)
        
        switch result {
        case let .success(.verified(transaction)):
            logger.info("Successful purchase")
            DispatchQueue.main.async { action() }
            await transaction.finish()
            await self.updatePurchasedProducts()
        case let .success(.unverified(_, error)):
            logger.warning("Unverified success: \(error.localizedDescription)")
            break
        case .pending:
            logger.info("Purchase pending")
            actionsForRequestedPurchases[product.id] = action
            break
        case .userCancelled:
            logger.info("Purchase cancelled by user")
            break
        @unknown default:
            logger.warning("Unknown result: \(String(describing: result))")
            break
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
                runAction(for: transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
    
    private func runAction(for productID: String) {
        let action = actionsForRequestedPurchases[productID]
        actionsForRequestedPurchases[productID] = nil
        if let action {
            DispatchQueue.main.async {
                action()
            }
        }
    }
    
    public func syncWithAppStore() async {
        do {
            try await AppStore.sync()
        } catch {
            logger.error("Unable to sync with AppStore: \(error.localizedDescription)")
        }
    }
}
