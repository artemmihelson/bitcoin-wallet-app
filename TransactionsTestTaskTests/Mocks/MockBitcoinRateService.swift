//
//  MockBitcoinRateService.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//


import XCTest
import Combine
@testable import TransactionsTestTask

// MARK: - Mock Services for Testing

final class MockBitcoinRateService: BitcoinRateService {
    private let rateSubject = CurrentValueSubject<Double?, Never>(nil)
    
    var currentRate: Double? {
        didSet {
            if let rate = currentRate {
                rateSubject.send(rate)
            }
        }
    }
    
    var ratePublisher: AnyPublisher<Double, Never> {
        rateSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    func startUpdating() {
        // Mock implementation
    }
    
    func stopUpdating() {
        // Mock implementation
    }
    
    // Test helper to simulate rate updates
    func simulateRateUpdate(_ rate: Double) {
        currentRate = rate
    }
}
