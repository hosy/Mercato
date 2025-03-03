//
//  File.swift
//  
//
//  Created by Pavel Tikhonenko on 09.10.2021.
//

import Foundation
import StoreKit
import SwiftUI

class PurchaseController
{
#if os(visionOS)
	@Environment(\.purchase) var purchaseAction
#endif
	
	func makePurchase(product: Product, quantity: Int = 1, finishAutomatically: Bool = true, appAccountToken: UUID? = nil, simulatesAskToBuyInSandbox: Bool = false) async throws -> Purchase
	{
		var options: Set<Product.PurchaseOption> = []
		options.insert(Product.PurchaseOption.quantity(quantity))
		options.insert(Product.PurchaseOption.simulatesAskToBuyInSandbox(simulatesAskToBuyInSandbox))
		
		if let token = appAccountToken
		{
			options.insert(Product.PurchaseOption.appAccountToken(token))
		}
#if !os(visionOS)
		let result = try await product.purchase(options: options)
#else
		let result = try await purchaseAction(product)
#endif
		
		switch result
		{
		case .success(let verification):
			let transaction = try checkVerified(verification)
			
			if finishAutomatically
			{
				await transaction.finish()
			}
			
			return Purchase(product: product, transaction: transaction, needsFinishTransaction: !finishAutomatically)
		case .userCancelled:
			throw MercatoError.purchaseCanceledByUser
		case .pending:
			throw MercatoError.purchaseIsPending
		@unknown default:
			throw MercatoError.genericError
		}
	}
	
	
}
