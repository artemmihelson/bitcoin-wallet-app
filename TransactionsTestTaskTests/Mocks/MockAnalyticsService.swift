//
//  MockAnalyticsService.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//
import XCTest
import Combine
@testable import TransactionsTestTask

final class MockAnalyticsService: AnalyticsService {
    private(set) var trackedEvents: [AnalyticsEvent] = []
    
    func trackEvent(name: String, parameters: [String: String]) {
        let event = AnalyticsEvent(
            name: name,
            parameters: parameters,
            date: Date()
        )
        trackedEvents.append(event)
    }
}
