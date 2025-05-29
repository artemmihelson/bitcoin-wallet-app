//
//  TransactionsTestTaskTests.swift
//  TransactionsTestTaskTests
//
//

import XCTest
import Combine
@testable import TransactionsTestTask

final class TransactionsTestTaskTests: XCTestCase {

    var mockRateService: MockBitcoinRateService!
    var mockAnalytics: MockAnalyticsService!
    var multiModuleLogger: TestMultiModuleLogger!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRateService = MockBitcoinRateService()
        mockAnalytics = MockAnalyticsService()
        multiModuleLogger = TestMultiModuleLogger(service: mockRateService, analytics: mockAnalytics)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        multiModuleLogger = nil
        mockAnalytics = nil
        mockRateService = nil
        super.tearDown()
    }
    
    func testMultipleModulesReceiveRateUpdates() {
        let testRate = 47234.56
        let expectedModuleCount = 22 // 21 test modules + 1 from multiModuleLogger
        
        mockRateService.simulateRateUpdate(testRate)
        
        let observers = multiModuleLogger.getObservers()
        XCTAssertEqual(observers.count, expectedModuleCount - 1) // -1 because multiModuleLogger itself is not counted in observers
        
        // Verify all observers received the update
        for observer in observers {
            XCTAssertEqual(observer.receivedUpdatesCount, 1, "\(observer.moduleName) should have received 1 update")
        }
        
        // Verify analytics tracked the event
        XCTAssertEqual(mockAnalytics.trackedEvents.count, 1)
        XCTAssertEqual(mockAnalytics.trackedEvents.first?.name, "bitcoin_rate_update")
        XCTAssertEqual(mockAnalytics.trackedEvents.first?.parameters["rate"], String(format: "%.2f", testRate))
    }
    
    func testMultipleRateUpdatesAreHandledCorrectly() {
        let testRates = [45000.0, 46000.0, 47000.0, 48000.0, 49000.0]
        
        for rate in testRates {
            mockRateService.simulateRateUpdate(rate)
        }
        
        let observers = multiModuleLogger.getObservers()
        
        // Each observer should have received all updates
        for observer in observers {
            XCTAssertEqual(observer.receivedUpdatesCount, testRates.count,
                          "\(observer.moduleName) should have received \(testRates.count) updates")
        }
        
        // Analytics should have tracked all events
        XCTAssertEqual(mockAnalytics.trackedEvents.count, testRates.count)
        
        // Total updates across all modules
        let totalUpdates = multiModuleLogger.getTotalUpdatesReceived()
        let expectedTotalUpdates = observers.count * testRates.count
        XCTAssertEqual(totalUpdates, expectedTotalUpdates)
    }
    
    func testAnalyticsTrackingForMultipleModules() {
        let testRate = 50000.0
        
        mockRateService.simulateRateUpdate(testRate)
        
        XCTAssertEqual(mockAnalytics.trackedEvents.count, 1)
        
        let event = mockAnalytics.trackedEvents.first!
        XCTAssertEqual(event.name, "bitcoin_rate_update")
        XCTAssertEqual(event.parameters["rate"], "50000.00")
        XCTAssertEqual(event.parameters["modules_notified"], "21") // 21 test module observers
        XCTAssertNotNil(event.parameters["timestamp"])
    }
    
    func testServicesAssemblerIntegration() {
        // Given - Real services from assembler
        let realService = ServicesAssembler.bitcoinRateService()
        let realAnalytics = ServicesAssembler.analyticsService()
        
        // When - Initialize the logger (this simulates the production scenario)
        let logger = BitcoinRateLogger(service: realService, analytics: realAnalytics)
        
        // Then - Services should be properly initialized
        XCTAssertNotNil(logger)
        XCTAssertNotNil(realService.ratePublisher)
        
        // Test with mock rate update if service allows it
        if let mockService = realService as? MockBitcoinRateService {
            mockService.simulateRateUpdate(45000.0)
        }
    }
}
