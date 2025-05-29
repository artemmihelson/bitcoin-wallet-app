//
//  TestMultiModuleLogger.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//
import XCTest
import Combine
@testable import TransactionsTestTask

final class TestMultiModuleLogger {
    private var cancellables = Set<AnyCancellable>()
    private let observers: [TestModuleObserver]
    private let analytics: MockAnalyticsService
    
    init(service: BitcoinRateService, analytics: MockAnalyticsService) {
        self.analytics = analytics
        
        self.observers = [
            TestWalletBalanceObserver(),
            TestTransactionListObserver(),
            TestDashboardObserver(),
            TestNotificationObserver(),
            TestWidgetObserver(),
            TestChartObserver(),
            TestCacheObserver(),
            TestSecurityObserver(),
            TestAPIObserver(),
            TestDatabaseObserver(),
            TestSyncObserver(),
            TestReportsObserver(),
            TestBackupObserver(),
            TestTradingObserver(),
            TestWatchAppObserver(),
            TestPortfolioObserver(),
            TestHistoryObserver(),
            TestSettingsObserver(),
            TestExportObserver(),
            TestImportObserver(),
            TestThemeObserver()
        ]
        
        print("Test logger initialized with \(observers.count) module observers")
        
        service.ratePublisher
            .sink { [weak self] rate in
                self?.handleRateUpdate(rate)
            }
            .store(in: &cancellables)
    }
    
    private func handleRateUpdate(_ rate: Double) {
        print("Broadcasting rate update to \(observers.count) test modules: $\(String(format: "%.2f", rate))")
        
        // Analytics tracking
        analytics.trackEvent(
            name: "bitcoin_rate_update",
            parameters: [
                "rate": String(format: "%.2f", rate),
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "modules_notified": String(observers.count)
            ]
        )
        
        // Notify all observers
        for observer in observers {
            observer.handleRateUpdate(rate)
        }
    }
    
    // Test helpers
    func getObservers() -> [TestModuleObserver] {
        return observers
    }
    
    func getTotalUpdatesReceived() -> Int {
        return observers.reduce(0) { $0 + $1.receivedUpdatesCount }
    }
}
