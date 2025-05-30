//
//  AddTransactionViewModel.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 30.05.2025.
//


import Foundation
import Combine

// MARK: - Add Transaction View Model

final class AddTransactionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var enteredAmount: String = ""
    @Published var selectedCategory: TransactionCategory?
    @Published var notes: String = ""
    @Published var currentBalance: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var isFormValid: Bool = false
    @Published var amountError: String?
    @Published var balanceWarning: String?
    @Published var successMessage: String?
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var enteredAmountAsDouble: Double? {
        return Double(enteredAmount)
    }
    
    var canAffordTransaction: Bool {
        guard let amount = enteredAmountAsDouble else { return true }
        return amount <= currentBalance
    }
    
    var formattedBalance: String {
        return String(format: "Current Balance: ₿%.8f", currentBalance)
    }
    
    // MARK: - Private Properties
    
    private let transactionStore: TransactionStoreProtocol
    private weak var coordinator: MainCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(transactionStore: TransactionStoreProtocol, coordinator: MainCoordinator) {
        self.transactionStore = transactionStore
        self.coordinator = coordinator
        
        setupBindings()
        loadCurrentBalance()
    }
    
    // MARK: - Public Methods
    
    func didChangeAmount(_ newAmount: String) {
        enteredAmount = newAmount
        validateAmount()
    }
    
    func didSelectCategory(_ category: TransactionCategory) {
        selectedCategory = category
    }
    
    func didChangeNotes(_ newNotes: String) {
        notes = newNotes
    }
    
    func addTransaction() {
        guard validateForm() else { return }
        
        guard let amount = enteredAmountAsDouble,
              let category = selectedCategory else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                _ = try transactionStore.addExpense(
                    amount: amount,
                    category: category,
                    date: Date()
                )
                
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = "Successfully added ₿\(String(format: "%.8f", amount)) \(category.displayName) expense"
                }
                
                // Notify coordinator to dismiss and refresh
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.coordinator?.navigationController.dismiss(animated: true) {
                        // Trigger refresh in main view
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to add transaction: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func cancel() {
        coordinator?.navigationController.dismiss(animated: true)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Validate form whenever amount or category changes
        Publishers.CombineLatest($enteredAmount, $selectedCategory)
            .map { [weak self] amount, category in
                return self?.isValidAmount(amount) == true && category != nil
            }
            .assign(to: \.isFormValid, on: self)
            .store(in: &cancellables)
        
        // Update balance warning when amount changes
        $enteredAmount
            .sink { [weak self] _ in
                self?.updateBalanceWarning()
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentBalance() {
        currentBalance = transactionStore.getBalance()
    }
    
    private func validateAmount() {
        guard !enteredAmount.isEmpty else {
            amountError = nil
            return
        }
        
        if !isValidAmount(enteredAmount) {
            amountError = "Please enter a valid amount greater than 0"
        } else {
            amountError = nil
        }
    }
    
    private func isValidAmount(_ amount: String) -> Bool {
        guard let doubleAmount = Double(amount) else { return false }
        return doubleAmount > 0
    }
    
    private func updateBalanceWarning() {
        guard let amount = enteredAmountAsDouble else {
            balanceWarning = nil
            return
        }
        
        if amount > currentBalance {
            balanceWarning = "⚠️ This transaction exceeds your current balance"
        } else {
            balanceWarning = nil
        }
    }
    
    private func validateForm() -> Bool {
        validateAmount()
        
        guard amountError == nil else { return false }
        guard selectedCategory != nil else {
            errorMessage = "Please select a category"
            return false
        }
        
        guard canAffordTransaction else {
            errorMessage = "Insufficient balance for this transaction"
            return false
        }
        
        return true
    }
}

// MARK: - Input Formatting Extension

extension AddTransactionViewModel {
    
    func formatBitcoinInput(_ input: String) -> String {
        var text = input
        
        // Remove any non-numeric characters except decimal point
        text = text.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        
        // Handle multiple decimal points
        let components = text.components(separatedBy: ".")
        if components.count > 2 {
            text = components[0] + "." + components[1...].joined()
        }
        
        // Limit total length
        let maxLength = 16
        if text.count > maxLength {
            text = String(text.prefix(maxLength))
        }
        
        // Limit decimal places to 8
        if let decimalIndex = text.firstIndex(of: ".") {
            let decimalPart = text[text.index(after: decimalIndex)...]
            if decimalPart.count > 8 {
                let integerPart = text[..<decimalIndex]
                let limitedDecimalPart = String(decimalPart.prefix(8))
                text = String(integerPart) + "." + limitedDecimalPart
            }
        }
        
        // Prevent leading zeros (except for "0.")
        if text.hasPrefix("0") && text.count > 1 && !text.hasPrefix("0.") {
            text = String(text.dropFirst())
        }
        
        // Prevent starting with decimal point
        if text.hasPrefix(".") {
            text = "0" + text
        }
        
        return text
    }
}