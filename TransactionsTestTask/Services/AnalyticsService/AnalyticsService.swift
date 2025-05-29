//
//  AnalyticsService.swift
//  TransactionsTestTask
//
//

import Foundation
import os.log

protocol AnalyticsService: AnyObject {
    
    func trackEvent(name: String, parameters: [String: String])
}

final class AnalyticsServiceImpl {
    
    private var events: [AnalyticsEvent] = []
    private let logger = Logger(subsystem: "BitcoinWallet", category: "Analytics")
    private let eventsLock = NSLock()
    
    init() {
        logger.info("📈 Analytics service initialized")
    }
    
    // For unit testing access
    internal func getEvents() -> [AnalyticsEvent] {
        eventsLock.lock()
        defer { eventsLock.unlock() }
        return events
    }
}

extension AnalyticsServiceImpl: AnalyticsService {
    
    func trackEvent(name: String, parameters: [String: String]) {
        eventsLock.lock()
        defer { eventsLock.unlock() }
        
        let event = AnalyticsEvent(
            name: name,
            parameters: parameters,
            date: Date()
        )
        
        events.append(event)
        
        // Log the event for debugging
        let parametersString = parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        logger.info("📊 Analytics Event: \(name) | \(parametersString)")
        
        // Keep only last 1000 events to prevent memory issues
        if events.count > 1000 {
            events.removeFirst(events.count - 1000)
        }
    }
}
