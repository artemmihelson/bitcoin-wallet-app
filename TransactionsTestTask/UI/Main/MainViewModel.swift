//
//  MainViewModel.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 30.05.2025.
//
import Combine
import Foundation

final class MainViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentBalance: Double = 0.0
    @Published var currentBitcoinRate: Double = 0.0
    @Published var transactionsByDate: [(Date, [TransactionEntity])] = []
    @Published var isLoading: Bool = false
    @Published var hasMoreTransactions: Bool = true
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let transactionStore: TransactionStoreProtocol
    private let bitcoinRateService: BitcoinRateService
    weak var coordinator: MainCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    private var allTransactions: [TransactionEntity] = []
    private var currentOffset = 0
    private let pageSize = 20
    
    // MARK: - Initialization
    
    init(
        transactionStore: TransactionStoreProtocol,
        bitcoinRateService: BitcoinRateService
    ) {
        self.transactionStore = transactionStore
        self.bitcoinRateService = bitcoinRateService
        
        setupBindings()
        loadInitialData()
        bitcoinRateService.startUpdating()
    }
    
    deinit {
        bitcoinRateService.stopUpdating()
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() {
        allTransactions.removeAll()
        transactionsByDate.removeAll()
        currentOffset = 0
        hasMoreTransactions = true
        
        Task {
            await loadTransactions()
            await updateBalance()
        }
    }
    
    func loadMoreTransactions() {
        guard !isLoading && hasMoreTransactions else { return }
        
        Task {
            await loadTransactions()
        }
    }
    
    func refreshData() {
        Task {
            loadInitialData()
        }
    }
    
    func didTapTopUp() {
        coordinator?.showTopUp()
    }
    
    func didTapAddTransaction() {
        coordinator?.showAddTransaction()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bitcoin rate updates
        bitcoinRateService.ratePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.currentBitcoinRate = rate
            }
            .store(in: &cancellables)
        
        // Transaction store balance updates
        if let reactiveStore = transactionStore as? TransactionStore {
            reactiveStore.balancePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] balance in
                    self?.currentBalance = balance
                }
                .store(in: &cancellables)
            reactiveStore.transactionsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] transactions in
                    self?.allTransactions = transactions
                    self?.transactionsByDate = TransactionEntity.groupTransactionsByDate(transactions)
                    self?.currentOffset = transactions.count
                    self?.hasMoreTransactions = true
                }
                .store(in: &cancellables)
        }
    }
    
    private func loadTransactions() async {
        guard !isLoading else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let newTransactions = try transactionStore.fetchTransactions(
                offset: currentOffset,
                limit: pageSize
            )
            
            await MainActor.run {
                if self.currentOffset == 0 {
                    self.allTransactions = newTransactions
                } else {
                    self.allTransactions.append(contentsOf: newTransactions)
                }
                
                self.transactionsByDate = TransactionEntity.groupTransactionsByDate(self.allTransactions)
                self.currentOffset += self.pageSize
                self.hasMoreTransactions = newTransactions.count == self.pageSize
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load transactions: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func updateBalance() async {
        let balance = transactionStore.getBalance()
        await MainActor.run {
            self.currentBalance = balance
        }
    }
}
