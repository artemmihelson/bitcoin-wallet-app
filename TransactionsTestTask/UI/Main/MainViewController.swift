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
    
    // Table view sections
    private enum Section: Int, CaseIterable {
        case balance = 0
        case actions = 1
    }
    
    // MARK: - Properties
    
    private let viewModel: MainViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
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

// MARK: - Reactive Bindings

private extension MainViewController {
    
    func setupBindings() {
        // Bitcoin rate updates
        viewModel.$currentBitcoinRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.updateNavigationRate(rate)
            }
            .store(in: &cancellables)
        
        // Transactions updates
        viewModel.$transactionsByDate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        // Loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        // Error handling
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showError(errorMessage)
            }
            .store(in: &cancellables)
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
    
    private func reloadBalanceSection() {
        if tableView.numberOfSections > 0 {
            tableView.reloadSections(IndexSet(integer: 0), with: .none)
        }
    }
    
    @objc private func refreshData() {
        viewModel.refreshData()
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Actions

private extension MainViewController {
    
    @objc func didTapTopUp() {
        viewModel.didTapTopUp()
    }
    
    @objc func didTapAddTransaction() {
        viewModel.didTapAddTransaction()
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
        let dateSections = viewModel.transactionsByDate.count
        let totalSections = baseSections + dateSections
        return max(totalSections, 3)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.balance.rawValue, Section.actions.rawValue:
            return 1
        default:
            let dateIndex = section - Section.allCases.count
            if dateIndex < viewModel.transactionsByDate.count {
                let transactions = viewModel.transactionsByDate[dateIndex].1
                return transactions.count + (shouldShowLoadingCell(for: dateIndex) ? 1 : 0)
            } else {
                // Empty state section
                return viewModel.transactionsByDate.isEmpty ? 1 : 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section >= Section.allCases.count { // Transaction sections
            let dateIndex = section - Section.allCases.count
            if dateIndex < viewModel.transactionsByDate.count {
                let date = viewModel.transactionsByDate[dateIndex].0
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
        
        cell.configure(balance: viewModel.currentBalance)
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
        let dateIndex = indexPath.section - 2
        
        if viewModel.transactionsByDate.isEmpty {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: EmptyStateTableViewCell.identifier,
                for: indexPath
            ) as? EmptyStateTableViewCell else {
                return UITableViewCell()
            }
            
            cell.onAddTransactionTapped = { [weak self] in
                self?.viewModel.didTapAddTransaction()
            }
            
            return cell
        }
        
        guard dateIndex >= 0 && dateIndex < viewModel.transactionsByDate.count else {
            return UITableViewCell()
        }
        
        let (_, transactions) = viewModel.transactionsByDate[dateIndex]
        
        if indexPath.row == transactions.count && shouldShowLoadingCell(for: dateIndex) {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: LoadingTableViewCell.identifier,
                for: indexPath
            ) as? LoadingTableViewCell else {
                return UITableViewCell()
            }
            
            viewModel.loadMoreTransactions()
            return cell
        }
        
        guard indexPath.row < transactions.count else {
            return UITableViewCell()
        }
        
        let transaction = transactions[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TransactionTableViewCell.identifier,
            for: indexPath
        ) as? TransactionTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: transaction)
        return cell
    }
    
    private func shouldShowLoadingCell(for dateIndex: Int) -> Bool {
        return dateIndex == viewModel.transactionsByDate.count - 1 && viewModel.hasMoreTransactions
    }
}

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case Section.actions.rawValue, Section.balance.rawValue:
            return 0
        default:
            return viewModel.transactionsByDate.isEmpty ? 0 : UITableView.automaticDimension
        }
    }
}
