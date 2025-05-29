//
//  BTCResponse.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//


struct BTCResponse: Decodable {
    let bpi: BPI
    struct BPI: Decodable {
        let usd: Currency
        enum CodingKeys: String, CodingKey {
            case usd = "USD"
        }
    }
    
    struct Currency: Decodable {
        let rate_float: Double
    }
}
