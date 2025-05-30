//
//  ViewController.swift
//  TransactionsTestTask
//
//

import UIKit
import Combine

final class MainViewController: UIViewController {

    // MARK: - UI Components
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Services
    
    private let transactionStore: TransactionStoreProtocol
    private let bitcoinRateService: BitcoinRateService
    
    // MARK: - State
    
    private var transactionsByDate: [(Date, [TransactionEntity])] = []
    private var allTransactions: [TransactionEntity] = []
    private var currentOffset = 0
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    private var isLoadingMore = false
    private var hasMoreTransactions = true
    private var currentBalance: Double = 0.0
    private var currentBitcoinRate: Double = 0.0
    
    // Table view sections
    private enum Section: Int, CaseIterable {
        case balance = 0
        case actions = 1
    }
    
    // MARK: - Initialization
    
    init(
        transactionStore: TransactionStoreProtocol = TransactionStore(),
        bitcoinRateService: BitcoinRateService = ServicesAssembler.bitcoinRateService()
    ) {
        self.transactionStore = transactionStore
        self.bitcoinRateService = bitcoinRateService
        super.init(nibName: nil, bundle: nil)
        title = "Bitcoin Wallet"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupBindings()
        setupPullToRefresh()
        loadInitialData()
        bitcoinRateService.startUpdating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }
    
    deinit {
        bitcoinRateService.stopUpdating()
    }
}

// MARK: - UI Setup

private extension MainViewController {
    
    func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Bitcoin rate in navigation bar
        updateNavigationRate(currentBitcoinRate)
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .automatic
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        
        // Register cells
        tableView.register(BalanceTableViewCell.self, forCellReuseIdentifier: BalanceTableViewCell.identifier)
        tableView.register(ActionsTableViewCell.self, forCellReuseIdentifier: ActionsTableViewCell.identifier)
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.identifier)
        tableView.register(EmptyStateTableViewCell.self, forCellReuseIdentifier: EmptyStateTableViewCell.identifier)
        tableView.register(LoadingTableViewCell.self, forCellReuseIdentifier: LoadingTableViewCell.identifier)
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupPullToRefresh() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
}

// MARK: - Data Loading

private extension MainViewController {
    
    func loadInitialData() {
        allTransactions.removeAll()
        transactionsByDate.removeAll()
        currentOffset = 0
        hasMoreTransactions = true
        
        Task {
            await loadTransactions()
            await updateBalanceDisplay()
        }
    }
    
    @objc func refreshData() {
        Task {
            loadInitialData()
            await MainActor.run {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func loadTransactions() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        do {
            // Fetch raw transactions (not pre-grouped)
            let newTransactions = try transactionStore.fetchTransactions(
                offset: currentOffset,
                limit: pageSize
            )
            
            await MainActor.run {
                if self.currentOffset == 0 {
                    // First load - replace all data
                    self.allTransactions = newTransactions
                } else {
                    // Pagination - append new transactions
                    self.allTransactions.append(contentsOf: newTransactions)
                }
                
                // Group all transactions by date
                self.transactionsByDate = TransactionEntity.groupTransactionsByDate(self.allTransactions)
                
                self.currentOffset += self.pageSize
                self.hasMoreTransactions = newTransactions.count == self.pageSize
                
                print("🔍 loadTransactions result:")
                print("  - New transactions loaded: \(newTransactions.count)")
                print("  - Total transactions: \(self.allTransactions.count)")
                print("  - Date sections: \(self.transactionsByDate.count)")
                for (index, (date, transactions)) in self.transactionsByDate.enumerated() {
                    print("    Section \(index): \(TransactionEntity.formatDateForSection(date)) - \(transactions.count) transactions")
                }
                
                self.tableView.reloadData()
                self.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                self.showError("Failed to load transactions: \(error.localizedDescription)")
                self.isLoadingMore = false
            }
        }
    }
    
    func updateBalanceDisplay() async {
        let balance = transactionStore.getBalance()
        await MainActor.run {
            self.currentBalance = balance
            // Reload balance cell
            if self.tableView.numberOfSections > Section.balance.rawValue {
                self.tableView.reloadSections(IndexSet(integer: Section.balance.rawValue), with: .none)
            }
        }
    }
}

// MARK: - Reactive Bindings

private extension MainViewController {
    
    func setupBindings() {
        // Bitcoin rate updates
        bitcoinRateService.ratePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.currentBitcoinRate = rate
                self?.updateNavigationRate(rate)
                // Reload balance cell to show updated rate
                if let self = self, self.tableView.numberOfSections > Section.balance.rawValue {
                    self.tableView.reloadSections(IndexSet(integer: Section.balance.rawValue), with: .none)
                }
            }
            .store(in: &cancellables)
        
        // Transaction store balance updates (if using reactive store)
        if let reactiveStore = transactionStore as? TransactionStore {
            reactiveStore.balancePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] balance in
                    self?.currentBalance = balance
                    // Reload balance cell
                    if let self = self, self.tableView.numberOfSections > Section.balance.rawValue {
                        self.tableView.reloadSections(IndexSet(integer: Section.balance.rawValue), with: .none)
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    func updateNavigationRate(_ rate: Double) {
        guard rate > 0 else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Loading Bitcoin rate...",
                style: .plain,
                target: nil,
                action: nil
            )
            return
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "1 BTC = $\(String(format: "%.2f", rate)) USD",
            style: .plain,
            target: nil,
            action: nil
        )
    }
}

// MARK: - Actions

private extension MainViewController {
    
    @objc func didTapTopUp() {
        showTopUpAlert()
    }
    
    @objc func didTapAddTransaction() {
        let addTransactionVC = AddTransactionViewController(transactionStore: transactionStore)
        addTransactionVC.delegate = self
        let navController = UINavigationController(rootViewController: addTransactionVC)
        present(navController, animated: true)
    }
    
    func showTopUpAlert() {
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
        
        present(alert, animated: true)
    }
    
    func performTopUp(amount: Double) {
        Task {
            do {
                _ = try transactionStore.addTopUp(amount: amount, date: Date())
                await MainActor.run {
                    self.showSuccess("Successfully added ₿\(String(format: "%.8f", amount)) to your wallet")
                    self.refreshData()
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to add funds: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension MainViewController: AddTransactionDelegate {
    func transactionWasAdded(amount: Double, category: TransactionCategory) {
        DispatchQueue.main.async {
            self.refreshData()
        }
    }
    
    func transactionAdditionFailed(error: Error) {
        DispatchQueue.main.async {
            self.showError("Failed to add transaction: \(error.localizedDescription)")
        }
    }
    
}

// MARK: - UITableViewDataSource

extension MainViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let baseSections = Section.allCases.count
        let dateSections = transactionsByDate.count
        let totalSections = baseSections + dateSections
        return max(totalSections, 3)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.balance.rawValue, Section.actions.rawValue:
            return 1
        default:
            let dateIndex = section - Section.allCases.count
            if dateIndex < transactionsByDate.count {
                let transactions = transactionsByDate[dateIndex].1
                return transactions.count + (shouldShowLoadingCell(for: dateIndex) ? 1 : 0)
            } else {
                // Empty state section
                return transactionsByDate.isEmpty ? 1 : 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section >= Section.allCases.count { // Transaction sections
            let dateIndex = section - Section.allCases.count
            if dateIndex < transactionsByDate.count {
                let date = transactionsByDate[dateIndex].0
                return TransactionEntity.formatDateForSection(date)
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.balance.rawValue:
            return configureBalanceCell(at: indexPath)
        case Section.actions.rawValue:
            return configureActionsCell(at: indexPath)
        default:
            return configureTransactionCell(at: indexPath)
        }
    }
    
    private func configureBalanceCell(at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BalanceTableViewCell.identifier,
            for: indexPath
        ) as? BalanceTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(balance: currentBalance)
        return cell
    }
    
    private func configureActionsCell(at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ActionsTableViewCell.identifier,
            for: indexPath
        ) as? ActionsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.onTopUpTapped = { [weak self] in
            self?.didTapTopUp()
        }
        
        cell.onAddTransactionTapped = { [weak self] in
            self?.didTapAddTransaction()
        }
        
        return cell
    }
    
    private func configureTransactionCell(at indexPath: IndexPath) -> UITableViewCell {
        if transactionsByDate.isEmpty {
            // Empty state
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: EmptyStateTableViewCell.identifier,
                for: indexPath
            ) as? EmptyStateTableViewCell else {
                return UITableViewCell()
            }
            
            cell.onAddTransactionTapped = { [weak self] in
                self?.didTapAddTransaction()
            }
            
            return cell
        }
        
        // Calculate which transaction this row represents
        var currentRow = 0
        var targetTransaction: TransactionEntity?
        
        for (date, transactions) in transactionsByDate {
            if currentRow + transactions.count > indexPath.row {
                let transactionIndex = indexPath.row - currentRow
                targetTransaction = transactions[transactionIndex]
                break
            }
            currentRow += transactions.count
        }
        
        if let transaction = targetTransaction {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TransactionTableViewCell.identifier,
                for: indexPath
            ) as? TransactionTableViewCell else {
                return UITableViewCell()
            }
            
            cell.configure(with: transaction)
            return cell
        } else if hasMoreTransactions && indexPath.row == currentRow {
            // Loading cell
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: LoadingTableViewCell.identifier,
                for: indexPath
            ) as? LoadingTableViewCell else {
                return UITableViewCell()
            }
            
            // Trigger loading more data
            Task {
                await loadTransactions()
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    private func shouldShowLoadingCell(for dateIndex: Int) -> Bool {
        return dateIndex == transactionsByDate.count - 1 && hasMoreTransactions
    }
}

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case Section.actions.rawValue, Section.balance.rawValue:
            return 0
        default:
            return transactionsByDate.isEmpty ? 0 : UITableView.automaticDimension
        }
    }
}
