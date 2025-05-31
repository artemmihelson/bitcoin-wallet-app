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
    func addTopUp(amount: Double, date: Date) throws -> TransactionEntity
    func addExpense(amount: Double, category: TransactionCategory, date: Date) throws -> TransactionEntity
    func fetchTransactions(offset: Int, limit: Int) throws -> [TransactionEntity]
    func fetchGroupedByDate(offset: Int, limit: Int) throws -> [(Date, [TransactionEntity])]
    func fetchTransactions(for date: Date) throws -> [TransactionEntity]
    func getBalance() -> Double
    func getTotalTransactionCount() throws -> Int
    func deleteTransaction(_ transaction: TransactionEntity) throws
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
    
    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WalletApp", category: "TransactionStore")
    
    // Publishers for reactive updates
    @Published private(set) var currentBalance: Double = 0.0
    @Published private(set) var transactionCount: Int = 0
    @Published private(set) var allTransactions: [TransactionEntity] = []
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        updateBalance()
        updateTransactionCount()
    }
    
    // MARK: - Create Operations
    
    @discardableResult
    func addTopUp(amount: Double, date: Date = Date()) throws -> TransactionEntity {
        try validateAmount(amount)
        
        let entity = TransactionEntity.createTopUp(
            in: context,
            bitcoinAmount: amount,
            date: date
        )
        
        try saveContext()
        logger.info("Top-up added: \(amount) BTC")
        
        // Update reactive properties
        updateBalance()
        updateTransactionCount()
        updateTransactions()
        
        return entity
    }
    
    @discardableResult
    func addExpense(
        amount: Double,
        category: TransactionCategory,
        date: Date = Date()
    ) throws -> TransactionEntity {
        try validateAmount(amount)
        
        let entity = TransactionEntity.createExpense(
            in: context,
            bitcoinAmount: amount,
            category: category,
            date: date
        )
        
        try saveContext()
        logger.info("Expense added: \(amount) BTC, category: \(category.displayName)")
        
        // Update reactive properties
        updateBalance()
        updateTransactionCount()
        updateTransactions()
        
        return entity
    }
    
    // MARK: - Fetch Operations
    
    func fetchTransactions(
        offset: Int = 0,
        limit: Int = 20
    ) throws -> [TransactionEntity] {
        let request = TransactionEntity.fetchTransactionsWithPagination(
            offset: offset,
            limit: limit
        )
        
        do {
            let transactions = try context.fetch(request)
            logger.debug("Fetched \(transactions.count) transactions (offset: \(offset))")
            return transactions
        } catch {
            logger.error("Failed to fetch transactions: \(error.localizedDescription)")
            throw TransactionStoreError.fetchFailed(error)
        }
    }
    
    func fetchGroupedByDate(
        offset: Int = 0,
        limit: Int = 20
    ) throws -> [(Date, [TransactionEntity])] {
        let transactions = try fetchTransactions(offset: offset, limit: limit)
        let grouped = TransactionEntity.groupTransactionsByDate(transactions)
        
        return grouped
    }
    
    func fetchTransactions(for date: Date) throws -> [TransactionEntity] {
        let request = TransactionEntity.fetchTransactions(for: date)
        
        do {
            let transactions = try context.fetch(request)
            logger.debug("Fetched \(transactions.count) transactions for date: \(date)")
            return transactions
        } catch {
            logger.error("Failed to fetch transactions for date: \(error.localizedDescription)")
            throw TransactionStoreError.fetchFailed(error)
        }
    }
    
    // MARK: - Balance Operations
    
    func getBalance() -> Double {
        let balance = TransactionEntity.calculateBalance(in: context)
        currentBalance = balance
        logger.debug("Current balance: \(balance) BTC")
        return balance
    }
    
    // MARK: - Count Operations
    
    func getTotalTransactionCount() throws -> Int {
        let request = TransactionEntity.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            transactionCount = count
            logger.debug("Total transaction count: \(count)")
            return count
        } catch {
            logger.error("Failed to get transaction count: \(error.localizedDescription)")
            throw TransactionStoreError.fetchFailed(error)
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteTransaction(_ transaction: TransactionEntity) throws {
        context.delete(transaction)
        
        do {
            try saveContext()
            logger.info("Transaction deleted successfully")
            
            // Update reactive properties
            updateBalance()
            updateTransactionCount()
        } catch {
            logger.error("Failed to delete transaction: \(error.localizedDescription)")
            throw TransactionStoreError.deleteFailed(error)
        }
    }
    
    // MARK: - Convenience Methods
    
    func hasTransactions() throws -> Bool {
        let count = try getTotalTransactionCount()
        return count > 0
    }
    
    func canAfford(amount: Double) -> Bool {
        let balance = getBalance()
        return balance >= amount
    }
    
    // MARK: - Private Helpers
    
    private func validateAmount(_ amount: Double) throws {
        guard amount > 0 else {
            logger.error("Invalid amount: \(amount)")
            throw TransactionStoreError.invalidAmount
        }
    }
    
    private func saveContext() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
            throw TransactionStoreError.saveFailed(error)
        }
    }
    
    private func updateBalance() {
        currentBalance = getBalance()
    }
    
    private func updateTransactionCount() {
        do {
            transactionCount = try getTotalTransactionCount()
        } catch {
            logger.error("Failed to update transaction count: \(error.localizedDescription)")
        }
    }
    
    private func updateTransactions() {
        do {
            allTransactions = try fetchTransactions(offset: 0, limit: 20)
        } catch {
            logger.error("Failed to update transactions: \(error.localizedDescription)")
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
    
    var transactionsPublisher: Published<[TransactionEntity]>.Publisher {
        $allTransactions
    }
}
