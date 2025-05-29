//
//  PerformOnce.swift
//  TransactionsTestTask
//
//

import Foundation

final class PerformOnce<T> {
    private var result: T?
    private let closure: () -> T
    private let lock = NSLock()
    
    init(_ closure: @escaping () -> T) {
        self.closure = closure
    }
    
    func callAsFunction() -> T {
        lock.lock()
        defer { lock.unlock() }
        
        if let result = result {
            return result
        }
        
        let newResult = closure()
        result = newResult
        return newResult
    }
}
