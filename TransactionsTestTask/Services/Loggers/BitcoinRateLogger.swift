//
//  BitcoinRateLogger.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//


import Combine
import os.log
import Foundation

final class BitcoinRateLogger {
    
    private var cancellable: AnyCancellable?
    private let analytics: AnalyticsService
    private let logger = Logger(subsystem: "BitcoinWallet", category: "BitcoinRateLogger")
    
    init(service: BitcoinRateService, analytics: AnalyticsService) {
        self.analytics = analytics
        
        logger.info("🎯 Bitcoin rate logger initialized")
        
        cancellable = service.ratePublisher
            .sink { [weak self] rate in
                self?.handleRateUpdate(rate)
            }
    }
    
    private func handleRateUpdate(_ rate: Double) {
        logger.info("📢 Bitcoin rate update received: $\(rate, format: .hybrid(precision: 2))")
        
        // Track the rate update event
        analytics.trackEvent(
            name: "bitcoin_rate_update",
            parameters: [
                "rate": String(format: "%.2f", rate),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
    }
}
