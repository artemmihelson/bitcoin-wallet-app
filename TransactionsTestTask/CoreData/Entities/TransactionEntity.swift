//
//  TransactionEntity.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//

import CoreData
import Foundation

// MARK: - Transaction Type

enum TransactionType: String, CaseIterable, Codable {
    case topUp = "top_up"
    case expense = "expense"
    
    var displayName: String {
        switch self {
        case .topUp:
            return "Top Up"
        case .expense:
            return "Expense"
        }
    }
    
    var isPositive: Bool {
        self == .topUp
    }
}

// MARK: - Transaction Categories

enum TransactionCategory: String, CaseIterable, Codable {
    case groceries
    case taxi
    case electronics
    case restaurant
    case other
    
    var displayName: String {
        switch self {
        case .groceries:
            return "Groceries"
        case .taxi:
            return "Taxi"
        case .electronics:
            return "Electronics"
        case .restaurant:
            return "Restaurant"
        case .other:
            return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .groceries:
            return "🛒"
        case .taxi:
            return "🚕"
        case .electronics:
            return "📱"
        case .restaurant:
            return "🍽️"
        case .other:
            return "📝"
        }
    }
}

// MARK: - Core Data Entity

@objc(TransactionEntity)
final class TransactionEntity: NSManagedObject {
    @NSManaged internal var id: UUID
    @NSManaged private var amount: Double
    @NSManaged private var type: String
    @NSManaged private var category: String?
    @NSManaged private var date: Date
    @NSManaged private var createdAt: Date
}

// MARK: - Computed Properties

extension TransactionEntity {
    var transactionID: UUID {
        get { id }
        set { id = newValue }
    }
    
    var bitcoinAmount: Double {
        get { amount }
        set { amount = newValue }
    }
    
    var transactionType: TransactionType {
        get { TransactionType(rawValue: type) ?? .expense }
        set { type = newValue.rawValue }
    }
    
    var transactionCategory: TransactionCategory? {
        get {
            guard let category = category else { return nil }
            return TransactionCategory(rawValue: category)
        }
        set { category = newValue?.rawValue }
    }
    
    var transactionDate: Date {
        get { date }
        set { date = newValue }
    }
    
    var transactionCreatedAt: Date {
        get { createdAt }
        set { createdAt = newValue }
    }
    
    // Display formatted Bitcoin amount
    var displayBitcoinAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 8
        formatter.maximumFractionDigits = 8
        
        let formattedAmount = formatter.string(from: NSNumber(value: bitcoinAmount)) ?? "0.00000000"
        let prefix = transactionType == .topUp ? "+" : "-"
        
        return "\(prefix)\(formattedAmount) BTC"
    }
    
    // For balance calculations
    var signedAmount: Double {
        transactionType == .topUp ? bitcoinAmount : -bitcoinAmount
    }
    
    // Display time for transaction list
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: transactionDate)
    }
    
    // Display category with icon
    var displayCategory: String {
        if transactionType == .topUp {
            return "💰 Balance Top Up"
        }
        
        guard let category = transactionCategory else {
            return "📝 Other"
        }
        
        return "\(category.icon) \(category.displayName)"
    }
}

// MARK: - Convenience Initializers

extension TransactionEntity {
    @discardableResult
    static func createTopUp(
        in context: NSManagedObjectContext,
        bitcoinAmount: Double,
        date: Date = Date()
    ) -> TransactionEntity {
        let transaction = TransactionEntity(context: context)
        let now = Date()
        
        transaction.id = UUID()
        transaction.amount = abs(bitcoinAmount)
        transaction.type = TransactionType.topUp.rawValue
        transaction.category = nil
        transaction.date = date
        transaction.createdAt = now
        
        return transaction
    }
    
    @discardableResult
    static func createExpense(
        in context: NSManagedObjectContext,
        bitcoinAmount: Double,
        category: TransactionCategory,
        date: Date = Date()
    ) -> TransactionEntity {
        let transaction = TransactionEntity(context: context)
        let now = Date()
        
        transaction.id = UUID()
        transaction.amount = abs(bitcoinAmount) // Always positive
        transaction.type = TransactionType.expense.rawValue
        transaction.category = category.rawValue
        transaction.date = date
        transaction.createdAt = now
        
        return transaction
    }
}

// MARK: - Fetch Requests

extension TransactionEntity {
    static var entityName: String { "TransactionEntity" }
    
    @nonobjc static func fetchRequest() -> NSFetchRequest<TransactionEntity> {
        return NSFetchRequest<TransactionEntity>(entityName: entityName)
    }
    
    // Fetch all transactions sorted by date (newest first) for pagination
    static func fetchAllTransactionsSorted() -> NSFetchRequest<TransactionEntity> {
        let request = fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false),
            NSSortDescriptor(keyPath: \TransactionEntity.createdAt, ascending: false)
        ]
        return request
    }
    
    // Fetch transactions with pagination (20 per page by default)
    static func fetchTransactionsWithPagination(
        offset: Int = 0,
        limit: Int = 20
    ) -> NSFetchRequest<TransactionEntity> {
        let request = fetchAllTransactionsSorted()
        request.fetchOffset = offset
        request.fetchLimit = limit
        return request
    }
    
    // Calculate total balance
    static func calculateBalance(in context: NSManagedObjectContext) -> Double {
        let request = fetchRequest()
        
        do {
            let transactions = try context.fetch(request)
            return transactions.reduce(0.0) { total, transaction in
                total + transaction.signedAmount
            }
        } catch {
            print("Error calculating balance: \(error)")
            return 0.0
        }
    }
    
    // Fetch transactions grouped by date for display
    static func fetchTransactionsGroupedByDate(
        offset: Int = 0,
        limit: Int = 20
    ) -> NSFetchRequest<TransactionEntity> {
        let request = fetchTransactionsWithPagination(offset: offset, limit: limit)
        return request
    }
    
    // Get transactions for a specific date (for grouping)
    static func fetchTransactions(for date: Date) -> NSFetchRequest<TransactionEntity> {
        let request = fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)
        ]
        
        return request
    }
}

// MARK: - Entity Description

extension TransactionEntity {
    static var entityDescription: NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(TransactionEntity.self)
        
        // ID attribute
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        // Amount attribute (Bitcoin amount)
        let amountAttr = NSAttributeDescription()
        amountAttr.name = "amount"
        amountAttr.attributeType = .doubleAttributeType
        amountAttr.isOptional = false
        amountAttr.defaultValue = 0.0
        
        // Type attribute
        let typeAttr = NSAttributeDescription()
        typeAttr.name = "type"
        typeAttr.attributeType = .stringAttributeType
        typeAttr.isOptional = false
        typeAttr.defaultValue = TransactionType.expense.rawValue
        
        // Category attribute (only for expenses)
        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.isOptional = true
        
        // Date attribute
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        dateAttr.defaultValue = Date()
        
        // Created at attribute
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        createdAtAttr.defaultValue = Date()
        
        entity.properties = [
            idAttr, amountAttr, typeAttr, categoryAttr, dateAttr, createdAtAttr
        ]
        
        return entity
    }
}

// MARK: - Identifiable Conformance

extension TransactionEntity: Identifiable {
}

// MARK: - Helper Extensions for UI

extension TransactionEntity {
    // Group transactions by date for section headers
    static func groupTransactionsByDate(_ transactions: [TransactionEntity]) -> [(Date, [TransactionEntity])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.transactionDate)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    // Format date for section headers
    static func formatDateForSection(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
