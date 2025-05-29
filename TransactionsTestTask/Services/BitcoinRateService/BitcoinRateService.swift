//
//  BitcoinRateService.swift
//  TransactionsTestTask
//
//

import Combine
import Foundation
import os.log

/// Rate Service should fetch data from https://api.coindesk.com/v1/bpi/currentprice.json

protocol BitcoinRateService: AnyObject {
    var ratePublisher: AnyPublisher<Double, Never> { get }
    var currentRate: Double? { get }
    
    func startUpdating()
    func stopUpdating()
}

final class BitcoinRateServiceImpl: BitcoinRateService {
    
    private let rateSubject = CurrentValueSubject<Double?, Never>(nil)
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let cacheKey = "cached_btc_rate"
    private let logger = Logger(subsystem: "BitcoinWallet", category: "BitcoinRateService")
    
    private(set) var currentRate: Double? {
        didSet {
            if let rate = currentRate {
                logger.info("💱 Bitcoin rate updated: $\(rate, format: .hybrid(precision: 2))")
                rateSubject.send(rate)
                saveRateToCache(rate)
            }
        }
    }
    
    var ratePublisher: AnyPublisher<Double, Never> {
        rateSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    init() {
        self.currentRate = loadRateFromCache()
        if let cachedRate = currentRate {
            logger.info("📱 Loaded cached Bitcoin rate: $\(cachedRate, format: .hybrid(precision: 2))")
        }
    }
    
    func startUpdating() {
        logger.info("🚀 Starting Bitcoin rate updates (every 5 minutes)")
        
        fetchRate()
        
        // Update every 5 minutes
        timer = Timer
            .publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchRate()
            }
    }
    
    func stopUpdating() {
        logger.info("⏹️ Stopping Bitcoin rate updates")
        timer?.cancel()
        timer = nil
    }
    
    private func fetchRate() {
        guard let url = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json") else {
            logger.error("❌ Invalid API URL")
            return
        }
        
        logger.debug("🌐 Fetching Bitcoin rate from API...")
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: BTCResponse.self, decoder: JSONDecoder())
            .map { response in
                response.bpi.usd.rate_float
            }
            .catch { [weak self] error -> Just<Double> in
                self?.logger.error("❌ Failed to fetch Bitcoin rate: \(error.localizedDescription)")
                // Return cached rate or 0 if no cache
                return Just(self?.currentRate ?? 0.0)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                if rate > 0 {
                    self?.currentRate = rate
                }
            }
            .store(in: &cancellables)
    }
    
    private func saveRateToCache(_ rate: Double) {
        UserDefaults.standard.set(rate, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: "\(cacheKey)_timestamp")
        logger.debug("💾 Cached Bitcoin rate: $\(rate, format: .hybrid(precision: 2))")
    }
    
    private func loadRateFromCache() -> Double? {
        let rate = UserDefaults.standard.value(forKey: cacheKey) as? Double
        let timestamp = UserDefaults.standard.value(forKey: "\(cacheKey)_timestamp") as? Date
        
        // Check if cache is not too old (e.g., less than 1 hour)
        if let timestamp = timestamp, Date().timeIntervalSince(timestamp) > 3600 {
            logger.debug("⏰ Cached rate is too old, will refresh")
            return nil
        }
        
        return rate
    }
}
