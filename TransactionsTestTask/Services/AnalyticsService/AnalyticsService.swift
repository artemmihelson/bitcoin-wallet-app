//
//  AnalyticsService.swift
//  TransactionsTestTask
//
//

import Foundation

protocol AnalyticsService: AnyObject {
    
    func trackEvent(name: String, parameters: [String: String])
}

final class AnalyticsServiceImpl {
    
    private var events: [AnalyticsEvent] = []
    
    // MARK: - Init
    
    init() {
        
    }
}

extension AnalyticsServiceImpl: AnalyticsService {
    
    func trackEvent(name: String, parameters: [String: String]) {
        let event = AnalyticsEvent(
            name: name,
            parameters: parameters,
            date: .now
        )
        
        events.append(event)
    }
}
