//
//  BitcoinRateService.swift
//  TransactionsTestTask
//
//

/// Rate Service should fetch data from https://api.coindesk.com/v1/bpi/currentprice.json

protocol BitcoinRateService: AnyObject {
    
    var onRateUpdate: ((Double) -> Void)? { get set }
}

final class BitcoinRateServiceImpl {
    
    var onRateUpdate: ((Double) -> Void)?
    
    // MARK: - Init
    
    init() {
        
    }
}

extension BitcoinRateServiceImpl: BitcoinRateService {
    
}
