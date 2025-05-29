//
//  ServicesAssembler.swift
//  TransactionsTestTask
//
//
enum ServicesAssembler {
    static let bitcoinRateService: PerformOnce<BitcoinRateService> = PerformOnce {
        BitcoinRateServiceImpl()
    }
    
    static let analyticsService: PerformOnce<AnalyticsService> = PerformOnce {
        AnalyticsServiceImpl()
    }
    
    static let bitcoinLogger: PerformOnce<BitcoinRateLogger> = PerformOnce {
        BitcoinRateLogger(
            service: bitcoinRateService(),
            analytics: analyticsService()
        )
    }
    
    static func initialize() {
        let service = bitcoinRateService()
        let _ = bitcoinLogger()
        
        // Start updating rates
        service.startUpdating()
    }
}
