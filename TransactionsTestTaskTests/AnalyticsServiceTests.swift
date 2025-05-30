//
//  AnalyticsServiceTests.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 30.05.2025.
//

import XCTest
import os.log
@testable import TransactionsTestTask

final class AnalyticsServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var analyticsService: AnalyticsServiceImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        analyticsService = AnalyticsServiceImpl()
    }
    
    override func tearDownWithError() throws {
        analyticsService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testTrackEvent_SingleEvent_EventIsRecorded() {
        // Given
        let eventName = "user_login"
        let parameters = ["method": "email", "user_id": "123"]
        
        // When
        analyticsService.trackEvent(name: eventName, parameters: parameters)
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1)
        
        let recordedEvent = events.first!
        XCTAssertEqual(recordedEvent.name, eventName)
        XCTAssertEqual(recordedEvent.parameters, parameters)
        XCTAssertTrue(recordedEvent.date.timeIntervalSinceNow < 1.0) // Event was recorded recently
    }
    
    func testTrackEvent_MultipleEvents_AllEventsAreRecorded() {
        // Given
        let events = [
            ("user_login", ["method": "email"]),
            ("transaction_created", ["type": "topup", "amount": "0.5"]),
            ("screen_view", ["screen_name": "main"])
        ]
        
        // When
        events.forEach { name, params in
            analyticsService.trackEvent(name: name, parameters: params)
        }
        
        // Then
        let recordedEvents = analyticsService.getEvents()
        XCTAssertEqual(recordedEvents.count, 3)
        
        // Verify events are in correct order
        XCTAssertEqual(recordedEvents[0].name, "user_login")
        XCTAssertEqual(recordedEvents[1].name, "transaction_created")
        XCTAssertEqual(recordedEvents[2].name, "screen_view")
    }
    
    func testTrackEvent_EmptyParameters_EventIsRecordedWithEmptyParams() {
        // Given
        let eventName = "app_launched"
        let emptyParameters: [String: String] = [:]
        
        // When
        analyticsService.trackEvent(name: eventName, parameters: emptyParameters)
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first!.name, eventName)
        XCTAssertTrue(events.first!.parameters.isEmpty)
    }
    
    func testTrackEvent_EmptyEventName_EventIsRecorded() {
        // Given
        let emptyEventName = ""
        let parameters = ["key": "value"]
        
        // When
        analyticsService.trackEvent(name: emptyEventName, parameters: parameters)
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first!.name, "")
        XCTAssertEqual(events.first!.parameters, parameters)
    }
    
    // MARK: - Memory Management Tests
    
    func testTrackEvent_MemoryLimit_OldEventsAreRemoved() {
        // Given: Track more than 1000 events
        let totalEvents = 1200
        
        // When
        for i in 0..<totalEvents {
            analyticsService.trackEvent(
                name: "event_\(i)",
                parameters: ["index": "\(i)"]
            )
        }
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1000, "Should keep only 1000 most recent events")
        
        // Verify oldest events were removed and newest are kept
        XCTAssertEqual(events.first!.name, "event_200") // First kept event (1200 - 1000 = 200)
        XCTAssertEqual(events.last!.name, "event_1199") // Last event
    }
    
    func testTrackEvent_ExactlyAtLimit_NoEventsRemoved() {
        // Given: Track exactly 1000 events
        let exactLimit = 1000
        
        // When
        for i in 0..<exactLimit {
            analyticsService.trackEvent(
                name: "event_\(i)",
                parameters: ["index": "\(i)"]
            )
        }
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1000)
        XCTAssertEqual(events.first!.name, "event_0")
        XCTAssertEqual(events.last!.name, "event_999")
    }
    
    func testTrackEvent_OneBeyondLimit_OneEventRemoved() {
        // Given: Track 1001 events
        let oneBeyondLimit = 1001
        
        // When
        for i in 0..<oneBeyondLimit {
            analyticsService.trackEvent(
                name: "event_\(i)",
                parameters: ["index": "\(i)"]
            )
        }
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1000)
        XCTAssertEqual(events.first!.name, "event_1") // First event was removed
        XCTAssertEqual(events.last!.name, "event_1000")
    }
    
    // MARK: - Thread Safety Tests
    
    func testTrackEvent_ConcurrentAccess_ThreadSafe() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent tracking completed")
        let numberOfThreads = 10
        let eventsPerThread = 100
        var completedThreads = 0
        let completionQueue = DispatchQueue(label: "completion")
        
        // When: Track events from multiple threads concurrently
        for threadIndex in 0..<numberOfThreads {
            DispatchQueue.global().async {
                for eventIndex in 0..<eventsPerThread {
                    self.analyticsService.trackEvent(
                        name: "thread_\(threadIndex)_event_\(eventIndex)",
                        parameters: ["thread": "\(threadIndex)", "event": "\(eventIndex)"]
                    )
                }
                
                completionQueue.async {
                    completedThreads += 1
                    if completedThreads == numberOfThreads {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, numberOfThreads * eventsPerThread)
        
        // Verify no data corruption occurred
        let uniqueEventNames = Set(events.map { $0.name })
        XCTAssertEqual(uniqueEventNames.count, numberOfThreads * eventsPerThread)
    }
    
    func testGetEvents_ConcurrentReadWrite_ThreadSafe() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent read/write completed")
        var readResults: [[AnalyticsEvent]] = []
        let resultsQueue = DispatchQueue(label: "results")
        let numberOfReads = 50
        let numberOfWrites = 50
        var completedOperations = 0
        
        // When: Read and write concurrently
        for i in 0..<numberOfWrites {
            DispatchQueue.global().async {
                self.analyticsService.trackEvent(
                    name: "concurrent_event_\(i)",
                    parameters: ["index": "\(i)"]
                )
                
                resultsQueue.async {
                    completedOperations += 1
                    if completedOperations == numberOfReads + numberOfWrites {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        for _ in 0..<numberOfReads {
            DispatchQueue.global().async {
                let events = self.analyticsService.getEvents()
                resultsQueue.async {
                    readResults.append(events)
                    completedOperations += 1
                    if completedOperations == numberOfReads + numberOfWrites {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        
        // Verify no crashes occurred and final state is consistent
        let finalEvents = analyticsService.getEvents()
        XCTAssertEqual(finalEvents.count, numberOfWrites)
        XCTAssertEqual(readResults.count, numberOfReads)
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testAnalyticsServiceProtocol_CanBeUsedAsProtocol() {
        // Given
        let service: AnalyticsService = analyticsService
        
        // When
        service.trackEvent(name: "protocol_test", parameters: ["test": "value"])
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first!.name, "protocol_test")
    }
    
    // MARK: - Edge Cases Tests
    
    func testTrackEvent_SpecialCharacters_HandledCorrectly() {
        // Given
        let eventName = "event_with_special_chars_!@#$%^&*()"
        let parameters = [
            "emoji": "😀🎉",
            "unicode": "ñáéíóú",
            "symbols": "!@#$%^&*()",
            "newlines": "line1\nline2\nline3"
        ]
        
        // When
        analyticsService.trackEvent(name: eventName, parameters: parameters)
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first!.name, eventName)
        XCTAssertEqual(events.first!.parameters, parameters)
    }
    
    func testTrackEvent_VeryLongStrings_HandledCorrectly() {
        // Given
        let longEventName = String(repeating: "a", count: 10000)
        let longValue = String(repeating: "b", count: 10000)
        let parameters = ["long_value": longValue]
        
        // When
        analyticsService.trackEvent(name: longEventName, parameters: parameters)
        
        // Then
        let events = analyticsService.getEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first!.name, longEventName)
        XCTAssertEqual(events.first!.parameters["long_value"], longValue)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceTrackingManyEvents() {
        measure {
            for i in 0..<1000 {
                analyticsService.trackEvent(
                    name: "performance_test_\(i)",
                    parameters: ["index": "\(i)", "data": "some_test_data"]
                )
            }
        }
    }
    
    func testPerformanceGettingEvents() {
        // Given: Populate with events first
        for i in 0..<1000 {
            analyticsService.trackEvent(
                name: "event_\(i)",
                parameters: ["index": "\(i)"]
            )
        }
        
        // When/Then: Measure getting events
        measure {
            _ = analyticsService.getEvents()
        }
    }
}

// MARK: - Test Helpers

extension AnalyticsServiceTests {
    
    private func createTestEvent(name: String = "test_event", parameters: [String: String] = [:]) -> (String, [String: String]) {
        return (name, parameters)
    }
    
    private func trackMultipleEvents(count: Int, prefix: String = "event") {
        for i in 0..<count {
            analyticsService.trackEvent(
                name: "\(prefix)_\(i)",
                parameters: ["index": "\(i)"]
            )
        }
    }
}
