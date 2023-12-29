//
//  SwiftUIView.swift
//  
//
//  Created by Olaf Neumann on 11.08.23.
//

#if os(iOS)

import SwiftUI
import StoreKit
import os.log

fileprivate let logger = Logger(category: "PurchaseProductView")

public struct PurchaseProductView: View {
    @Environment(\.dismiss) var dismiss
    @ScaledMetric(relativeTo: .body) private var progressSize: CGFloat = 20
    @Environment(\.layoutDirection) var direction
    
    var purchaseManager: PurchaseManager
    var product: Product
    var adTexts: [String]
    var paymentInfoText: LocalizedStringKey
    var purchaseErrorHandler: (Error, Product) -> Void = { error, product in
        logger.error("Error purchasing product '\(product.id)': \(error.localizedDescription)")
    }
    var actionOnPurchaseSuccess: () -> Void = {}
    
    @State private var showProgress = false
    
    public init(purchaseManager: PurchaseManager, product: Product, adTexts: [String], paymentInfoText: LocalizedStringKey = "Payment will be charged to your iTunes account at confirmation of purchase.") {
        self.purchaseManager = purchaseManager
        self.product = product
        self.adTexts = adTexts
        self.paymentInfoText = paymentInfoText
    }
        
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
        ?? "Application Name"
    }
    
    public var body: some View {
        VStack(spacing: 30) {
            VStack(alignment: .center) {
                Text(appName)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                Text(product.displayName)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 1)
                Text(product.description)
                    .bold()
            }
            
            if !adTexts.isEmpty {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 15) {
                    ForEach(adTexts, id: \.self) { text in
                        GridRow {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                            Text(text)
                        }
                    }
                }
                .font(.title3)
            }
                                            
            Button(action: {
                triggerPurchase()
            }, label: {
                HStack(spacing: 20) {
                    if showProgress {
                        ProgressView()
                            .frame(height: progressSize)
                    }
                    if !showProgress && direction == .rightToLeft {
                        Image(systemName: "arrow.forward")
                            .imageScale(.large)
                    }
                    Label("Continue - \(product.displayPrice)", systemImage: "purchased.circle.fill")
                    if !showProgress && direction == .leftToRight {
                        Image(systemName: "arrow.forward")
                            .imageScale(.large)
                    }
                }
                .frame(maxWidth: .infinity)
            })
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            
            Button(action: {
                triggerRestore()
            }, label: {
                Label("Restore purchases", systemImage: "purchased")
            })
            
            Text(paymentInfoText)
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .labelStyle(.titleOnly)
    }
    
    private func triggerPurchase() {
        showProgress = true
        Task {
            do {
                try await purchaseManager.purchase(product, withActionOnSuccess: actionOnPurchaseSuccess)
            } catch {
                purchaseErrorHandler(error, product)
            }
            showProgress = false
            dismiss()
        }
    }
    
    private func triggerRestore() {
        Task {
            await purchaseManager.syncWithAppStore()
            dismiss()
        }
    }
}

struct PurchaseProductView_Previews: PreviewProvider {
    static var previews: some View {
        CloseableView(imageName: "PurchaseBackground") {
            Text("Preview not possible")
//            PurchaseProductView(purchaseManager: PurchaseManager(productIds: []), product: nil, adTexts: [])
        }
    }
}

#endif
