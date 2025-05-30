//
//  BTCResponse.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//
import Foundation

struct BTCResponse: Decodable {
    let data: BitcoinData
    let timestamp: Int64
}

struct BitcoinData: Decodable {
    let id: String
    let rank: String
    let symbol: String
    let name: String
    let supply: String
    let maxSupply: String?
    let marketCapUsd: String
    let volumeUsd24Hr: String
    let priceUsd: String
    let changePercent24Hr: String
    let vwap24Hr: String?
    let explorer: String?
    
    // Computed property to get price as Double
    var price: Double {
        return Double(priceUsd) ?? 0.0
    }
    
    // Computed property to get change percentage as Double
    var changePercent: Double {
        return Double(changePercent24Hr) ?? 0.0
    }
    
    // Computed property to check if price is increasing
    var isPriceIncreasing: Bool {
        return changePercent >= 0
    }
    
    // Formatted price string
    var formattedPrice: String {
        return String(format: "$%.2f", price)
    }
    
    // Formatted change percentage
    var formattedChangePercent: String {
        let prefix = changePercent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", prefix, changePercent)
    }
}
