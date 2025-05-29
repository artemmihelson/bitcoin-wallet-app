//
//  TransactionStore.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//


import Foundation
import CoreData
import Combine
import os.log

// MARK: - Transaction Store Protocol

protocol TransactionStoreProtocol {
    func addTopUp(amount: Double, date: Date) async throws -> TransactionEntity
    func addExpense(amount: Double, category: TransactionCategory, date: Date) async throws -> TransactionEntity
    func fetchTransactions(offset: Int, limit: Int) async throws -> [TransactionEntity]
    func fetchGroupedByDate(offset: Int, limit: Int) async throws -> [(Date, [TransactionEntity])]
    func fetchTransactions(for date: Date) async throws -> [TransactionEntity]
    func getBalance() async throws -> Double
    func getTotalTransactionCount() async throws -> Int
    func deleteTransaction(_ transaction: TransactionEntity) async throws
}

// MARK: - Transaction Store Errors

enum TransactionStoreError: LocalizedError {
    case invalidAmount
    case fetchFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case contextNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Transaction amount must be greater than 0"
        case .fetchFailed(let error):
            return "Failed to fetch transactions: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save transaction: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete transaction: \(error.localizedDescription)"
        case .contextNotAvailable:
            return "Core Data context is not available"
        }
    }
}

// MARK: - Transaction Store Implementation

final class TransactionStore: TransactionStoreProtocol {
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStackProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WalletApp", category: "TransactionStore")
    
    // Publishers for reactive updates
    @Published private(set) var currentBalance: Double = 0.0
    @Published private(set) var transactionCount: Int = 0
    
    // MARK: - Initialization
    
    init(coreDataStack: CoreDataStackProtocol = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        
        Task {
            await updateBalance()
            await updateTransactionCount()
        }
    }
    
    // MARK: - Create Operations
    
    @discardableResult
    func addTopUp(amount: Double, date: Date = Date()) async throws -> TransactionEntity {
        try validateAmount(amount)
        
        return try await coreDataStack.performBackgroundTask { context in
            let entity = TransactionEntity.createTopUp(
                in: context,
                bitcoinAmount: amount,
                date: date
            )
            
            try context.save()
            
            Task { @MainActor in
                self.logger.info("✅ Top-up added: \(amount) BTC")
            }
            
            return entity
        }
    }
    
    @discardableResult
    func addExpense(
        amount: Double,
        category: TransactionCategory,
        date: Date = Date()
    ) async throws -> TransactionEntity {
        try validateAmount(amount)
        
        return try await coreDataStack.performBackgroundTask { context in
            let entity = TransactionEntity.createExpense(
                in: context,
                bitcoinAmount: amount,
                category: category,
                date: date
            )
            
            try context.save()
            
            Task { @MainActor in
                self.logger.info("✅ Expense added: \(amount) BTC, category: \(category.displayName)")
            }
            
            return entity
        }
    }
    
    // MARK: - Fetch Operations
    
    func fetchTransactions(
        offset: Int = 0,
        limit: Int = 20
    ) async throws -> [TransactionEntity] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = TransactionEntity.fetchTransactionsWithPagination(
                offset: offset,
                limit: limit
            )
            
            do {
                let transactions = try context.fetch(request)
                Task { @MainActor in
                    self.logger.debug("📊 Fetched \(transactions.count) transactions (offset: \(offset))")
                }
                return transactions
            } catch {
                Task { @MainActor in
                    self.logger.error("❌ Failed to fetch transactions: \(error.localizedDescription)")
                }
                throw TransactionStoreError.fetchFailed(error)
            }
        }
    }
    
    func fetchGroupedByDate(
        offset: Int = 0,
        limit: Int = 20
    ) async throws -> [(Date, [TransactionEntity])] {
        let transactions = try await fetchTransactions(offset: offset, limit: limit)
        return TransactionEntity.groupTransactionsByDate(transactions)
    }
    
    func fetchTransactions(for date: Date) async throws -> [TransactionEntity] {
        return try await coreDataStack.performBackgroundTask { context in
            let request = TransactionEntity.fetchTransactions(for: date)
            
            do {
                let transactions = try context.fetch(request)
                Task { @MainActor in
                    self.logger.debug("📊 Fetched \(transactions.count) transactions for date: \(date)")
                }
                return transactions
            } catch {
                Task { @MainActor in
                    self.logger.error("❌ Failed to fetch transactions for date: \(error.localizedDescription)")
                }
                throw TransactionStoreError.fetchFailed(error)
            }
        }
    }
    
    // MARK: - Balance Operations
    
    func getBalance() async throws -> Double {
        return try await coreDataStack.performBackgroundTask { context in
            let balance = TransactionEntity.calculateBalance(in: context)
            
            Task { @MainActor in
                self.currentBalance = balance
                self.logger.debug("💰 Current balance: \(balance) BTC")
            }
            
            return balance
        }
    }
    
    // MARK: - Count Operations
    
    func getTotalTransactionCount() async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let request = TransactionEntity.fetchRequest()
            
            do {
                let count = try context.count(for: request)
                
                Task { @MainActor in
                    self.transactionCount = count
                    self.logger.debug("📊 Total transaction count: \(count)")
                }
                
                return count
            } catch {
                Task { @MainActor in
                    self.logger.error("❌ Failed to get transaction count: \(error.localizedDescription)")
                }
                throw TransactionStoreError.fetchFailed(error)
            }
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteTransaction(_ transaction: TransactionEntity) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Find the transaction in this context
            guard let objectID = transaction.objectID.uriRepresentation().absoluteString as String?,
                  let managedObject = try? context.existingObject(with: transaction.objectID) else {
                throw TransactionStoreError.deleteFailed(NSError(domain: "TransactionStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Transaction not found"]))
            }
            
            context.delete(managedObject)
            
            do {
                try context.save()
                Task { @MainActor in
                    self.logger.info("🗑️ Transaction deleted successfully")
                }
            } catch {
                Task { @MainActor in
                    self.logger.error("❌ Failed to delete transaction: \(error.localizedDescription)")
                }
                throw TransactionStoreError.deleteFailed(error)
            }
        }
        
        // Update balance and count after deletion
        await updateBalance()
        await updateTransactionCount()
    }
    
    // MARK: - Convenience Methods
    
    func hasTransactions() async throws -> Bool {
        let count = try await getTotalTransactionCount()
        return count > 0
    }
    
    func canAfford(amount: Double) async throws -> Bool {
        let balance = try await getBalance()
        return balance >= amount
    }
    
    // MARK: - Private Helpers
    
    private func validateAmount(_ amount: Double) throws {
        guard amount > 0 else {
            logger.error("❌ Invalid amount: \(amount)")
            throw TransactionStoreError.invalidAmount
        }
    }
    
    private func updateBalance() async {
        do {
            _ = try await getBalance()
        } catch {
            logger.error("❌ Failed to update balance: \(error.localizedDescription)")
        }
    }
    
    private func updateTransactionCount() async {
        do {
            _ = try await getTotalTransactionCount()
        } catch {
            logger.error("❌ Failed to update transaction count: \(error.localizedDescription)")
        }
    }
}

// MARK: - Reactive Extensions

extension TransactionStore {
    var balancePublisher: Published<Double>.Publisher {
        $currentBalance
    }
    
    var transactionCountPublisher: Published<Int>.Publisher {
        $transactionCount
    }
}

// MARK: - Testing Support

#if DEBUG
extension TransactionStore {
    func addTestData() async throws {
        let categories: [TransactionCategory] = [.groceries, .taxi, .electronics, .restaurant, .other]
        let calendar = Calendar.current
        
        // Add some test top-ups
        try await addTopUp(amount: 1.0, date: calendar.date(byAdding: .day, value: -5, to: Date())!)
        try await addTopUp(amount: 0.5, date: calendar.date(byAdding: .day, value: -3, to: Date())!)
        
        // Add some test expenses
        for i in 0..<10 {
            let category = categories.randomElement()!
            let amount = Double.random(in: 0.001...0.1)
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            
            try await addExpense(amount: amount, category: category, date: date)
        }
    }
    
    func clearAllData() async throws {
        let transactions = try await fetchTransactions(offset: 0, limit: 1000)
        
        for transaction in transactions {
            try await deleteTransaction(transaction)
        }
    }
}
#endif
