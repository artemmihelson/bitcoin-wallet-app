//
//  CoreDataStack.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//


import CoreData
import os.log

protocol CoreDataStackProtocol {
    var context: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
    func saveContext() throws
    func saveBackgroundContext() throws
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T
}

final class CoreDataStack: CoreDataStackProtocol {
    static let shared = CoreDataStack()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WalletApp", category: "CoreData")
    private let modelName: String
    
    // MARK: - Initialization
    
    private init(modelName: String = "WalletModel") {
        self.modelName = modelName
    }
    
    // For testing purposes
    internal init(modelName: String, storeType: String) {
        self.modelName = modelName
        self.storeType = storeType
    }
    
    private var storeType: String = NSSQLiteStoreType
    
    // MARK: - Core Data Stack
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        
        container.persistentStoreDescriptions.first?.type = storeType
        container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true
        
        let group = DispatchGroup()
        group.enter()
        
        var loadError: Error?
        container.loadPersistentStores { [weak self] _, error in
            defer { group.leave() }
            
            if let error = error {
                self?.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                loadError = error
            } else {
                self?.logger.info("Successfully loaded persistent store")
            }
        }
        
        group.wait()
        
        if let error = loadError {
            fatalError("💥 Failed to load Core Data store: \(error)")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [
            TransactionEntity.entityDescription
        ]
        return model
    }()
    
    // MARK: - Contexts
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save Operations
    
    func saveContext() throws {
        try saveContext(context)
    }
    
    func saveBackgroundContext() throws {
        let bgContext = backgroundContext
        try saveContext(bgContext)
    }
    
    private func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else {
            logger.debug("No changes to save in context")
            return
        }
        
        do {
            try context.save()
            logger.debug("Successfully saved context")
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
            throw CoreDataError.saveFailed(error)
        }
    }
    
    // MARK: - Utility Methods
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = backgroundContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func reset() {
        context.reset()
        logger.info("Core Data context reset")
    }
}

// MARK: - Error Handling

enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        }
    }
}

// MARK: - Testing Support

#if DEBUG
extension CoreDataStack {
    static func inMemoryStack() -> CoreDataStack {
        return CoreDataStack(modelName: "WalletModel", storeType: NSInMemoryStoreType)
    }
}
#endif
