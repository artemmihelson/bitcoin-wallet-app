//
//  MainCoordinator.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 30.05.2025.
//
import UIKit

final class MainCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let transactionStore: TransactionStoreProtocol
    private let bitcoinRateService: BitcoinRateService
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.transactionStore = TransactionStore()
        self.bitcoinRateService = ServicesAssembler.bitcoinRateService()
    }
    
    func start() {
        let viewModel = MainViewModel(
            transactionStore: transactionStore,
            bitcoinRateService: bitcoinRateService
        )
        viewModel.coordinator = self
        let mainViewController = MainViewController(viewModel: viewModel)
        navigationController.pushViewController(mainViewController, animated: false)
    }
    
    func showAddTransaction() {
        let viewModel = AddTransactionViewModel(
            transactionStore: transactionStore,
            coordinator: self
        )
        let addTransactionVC = AddTransactionViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: addTransactionVC)
        navigationController.present(navController, animated: true)
    }
    
    func showTopUp() {
        let alert = UIAlertController(
            title: "Top Up Balance",
            message: "Enter the amount of Bitcoin to add to your wallet",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "0.00000000"
            textField.keyboardType = .decimalPad
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let text = textField.text,
                  let amount = Double(text.replacingOccurrences(of: ",", with: ".")),
                  amount > 0 else {
                self?.showError("Please enter a valid amount")
                return
            }
            
            self?.performTopUp(amount: amount)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        navigationController.present(alert, animated: true)
    }
    
    private func performTopUp(amount: Double) {
        Task {
            do {
                _ = try transactionStore.addTopUp(amount: amount, date: Date())
                await MainActor.run {
                    self.showSuccess("Successfully added ₿\(String(format: "%.8f", amount)) to your wallet")
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to add funds: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.present(alert, animated: true)
    }
}
