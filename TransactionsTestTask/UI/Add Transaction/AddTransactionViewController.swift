//
//  AddTransactionViewController.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//


import UIKit
import Combine

protocol AddTransactionDelegate: AnyObject {
    func transactionWasAdded(amount: Double, category: TransactionCategory)
    func transactionAdditionFailed(error: Error)
}

final class AddTransactionViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Amount Section
    private let amountSectionView = UIView()
    private let amountTitleLabel = UILabel()
    private let amountTextField = UITextField()
    private let bitcoinSymbolLabel = UILabel()
    private let amountErrorLabel = UILabel()
    
    // Category Section
    private let categorySectionView = UIView()
    private let categoryTitleLabel = UILabel()
    private let categoryStackView = UIStackView()
    private var categoryButtons: [CategoryButton] = []
    
    // Balance Check Section
    private let balanceCheckView = UIView()
    private let currentBalanceLabel = UILabel()
    private let balanceWarningLabel = UILabel()
    
    // Action Button
    private let addButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Properties
    
    private let viewModel: AddTransactionViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewModel: AddTransactionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardHandling()
        setupBindings()
        
        // Focus on amount field
        amountTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
}

// MARK: - UI Setup

private extension AddTransactionViewController {
    
    func setupUI() {
        view.backgroundColor = .systemBackground
        
        setupScrollView()
        setupAmountSection()
        setupCategorySection()
        setupBalanceSection()
        setupActionButton()
        setupConstraints()
    }
    
    func setupNavigationBar() {
        title = "Add Transaction"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Add",
            style: .done,
            target: self,
            action: #selector(didTapAdd)
        )
        
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    func setupAmountSection() {
        // Container
        amountSectionView.backgroundColor = .secondarySystemBackground
        amountSectionView.layer.cornerRadius = 12
        amountSectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        amountTitleLabel.text = "Transaction Amount"
        amountTitleLabel.font = .boldSystemFont(ofSize: 18)
        amountTitleLabel.textColor = .label
        amountTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Text field
        amountTextField.placeholder = "0.00000000"
        amountTextField.font = .monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        amountTextField.textAlignment = .center
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .none
        amountTextField.backgroundColor = .systemBackground
        amountTextField.layer.cornerRadius = 8
        amountTextField.layer.borderWidth = 1
        amountTextField.layer.borderColor = UIColor.separator.cgColor
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.addTarget(self, action: #selector(amountTextFieldDidChange), for: .editingChanged)
        
        // Bitcoin symbol
        bitcoinSymbolLabel.text = "₿"
        bitcoinSymbolLabel.font = .boldSystemFont(ofSize: 28)
        bitcoinSymbolLabel.textColor = .systemOrange
        bitcoinSymbolLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Error label
        amountErrorLabel.font = .systemFont(ofSize: 14)
        amountErrorLabel.textColor = .systemRed
        amountErrorLabel.numberOfLines = 0
        amountErrorLabel.isHidden = true
        amountErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        amountSectionView.addSubview(amountTitleLabel)
        amountSectionView.addSubview(bitcoinSymbolLabel)
        amountSectionView.addSubview(amountTextField)
        amountSectionView.addSubview(amountErrorLabel)
    }
    
    func setupCategorySection() {
        // Container
        categorySectionView.backgroundColor = .secondarySystemBackground
        categorySectionView.layer.cornerRadius = 12
        categorySectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        categoryTitleLabel.text = "Category"
        categoryTitleLabel.font = .boldSystemFont(ofSize: 18)
        categoryTitleLabel.textColor = .label
        categoryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view for category buttons
        categoryStackView.axis = .vertical
        categoryStackView.spacing = 8
        categoryStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create category buttons
        createCategoryButtons()
        
        categorySectionView.addSubview(categoryTitleLabel)
        categorySectionView.addSubview(categoryStackView)
    }
    
    func createCategoryButtons() {
        let categories = TransactionCategory.allCases
        
        // Create rows of 2 buttons each
        var currentRowStack: UIStackView?
        
        for (index, category) in categories.enumerated() {
            if index % 2 == 0 {
                // Create new row
                currentRowStack = UIStackView()
                currentRowStack?.axis = .horizontal
                currentRowStack?.distribution = .fillEqually
                currentRowStack?.spacing = 8
                currentRowStack?.translatesAutoresizingMaskIntoConstraints = false
                categoryStackView.addArrangedSubview(currentRowStack!)
            }
            
            let button = CategoryButton(category: category)
            button.addTarget(self, action: #selector(didTapCategory(_:)), for: .touchUpInside)
            categoryButtons.append(button)
            currentRowStack?.addArrangedSubview(button)
        }
    }
    
    func setupBalanceSection() {
        // Container
        balanceCheckView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        balanceCheckView.layer.cornerRadius = 12
        balanceCheckView.layer.borderWidth = 1
        balanceCheckView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        balanceCheckView.translatesAutoresizingMaskIntoConstraints = false
        
        // Current balance label
        currentBalanceLabel.font = .systemFont(ofSize: 16)
        currentBalanceLabel.textColor = .label
        currentBalanceLabel.textAlignment = .center
        currentBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Warning label
        balanceWarningLabel.font = .systemFont(ofSize: 14)
        balanceWarningLabel.textColor = .systemRed
        balanceWarningLabel.textAlignment = .center
        balanceWarningLabel.numberOfLines = 0
        balanceWarningLabel.isHidden = true
        balanceWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        
        balanceCheckView.addSubview(currentBalanceLabel)
        balanceCheckView.addSubview(balanceWarningLabel)
    }
    
    func setupActionButton() {
        addButton.setTitle("Add Transaction", for: .normal)
        addButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.setTitleColor(.lightGray, for: .disabled)
        addButton.layer.cornerRadius = 12
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        addButton.addSubview(loadingIndicator)
    }
    
    func setupConstraints() {
        contentView.addSubview(amountSectionView)
        contentView.addSubview(categorySectionView)
        contentView.addSubview(balanceCheckView)
        contentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Amount Section
            amountSectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            amountSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            amountSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            amountTitleLabel.topAnchor.constraint(equalTo: amountSectionView.topAnchor, constant: 16),
            amountTitleLabel.leadingAnchor.constraint(equalTo: amountSectionView.leadingAnchor, constant: 16),
            amountTitleLabel.trailingAnchor.constraint(equalTo: amountSectionView.trailingAnchor, constant: -16),
            
            bitcoinSymbolLabel.topAnchor.constraint(equalTo: amountTitleLabel.bottomAnchor, constant: 16),
            bitcoinSymbolLabel.leadingAnchor.constraint(equalTo: amountSectionView.leadingAnchor, constant: 16),
            
            amountTextField.centerYAnchor.constraint(equalTo: bitcoinSymbolLabel.centerYAnchor),
            amountTextField.leadingAnchor.constraint(equalTo: bitcoinSymbolLabel.trailingAnchor, constant: 8),
            amountTextField.trailingAnchor.constraint(equalTo: amountSectionView.trailingAnchor, constant: -16),
            amountTextField.heightAnchor.constraint(equalToConstant: 50),
            
            amountErrorLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 8),
            amountErrorLabel.leadingAnchor.constraint(equalTo: amountSectionView.leadingAnchor, constant: 16),
            amountErrorLabel.trailingAnchor.constraint(equalTo: amountSectionView.trailingAnchor, constant: -16),
            amountErrorLabel.bottomAnchor.constraint(equalTo: amountSectionView.bottomAnchor, constant: -16),
            
            // Category Section
            categorySectionView.topAnchor.constraint(equalTo: amountSectionView.bottomAnchor, constant: 16),
            categorySectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categorySectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            categoryTitleLabel.topAnchor.constraint(equalTo: categorySectionView.topAnchor, constant: 16),
            categoryTitleLabel.leadingAnchor.constraint(equalTo: categorySectionView.leadingAnchor, constant: 16),
            categoryTitleLabel.trailingAnchor.constraint(equalTo: categorySectionView.trailingAnchor, constant: -16),
            
            categoryStackView.topAnchor.constraint(equalTo: categoryTitleLabel.bottomAnchor, constant: 16),
            categoryStackView.leadingAnchor.constraint(equalTo: categorySectionView.leadingAnchor, constant: 16),
            categoryStackView.trailingAnchor.constraint(equalTo: categorySectionView.trailingAnchor, constant: -16),
            categoryStackView.bottomAnchor.constraint(equalTo: categorySectionView.bottomAnchor, constant: -16),
            
            // Balance Section
            balanceCheckView.topAnchor.constraint(equalTo: categorySectionView.bottomAnchor, constant: 16),
            balanceCheckView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            balanceCheckView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            currentBalanceLabel.topAnchor.constraint(equalTo: balanceCheckView.topAnchor, constant: 16),
            currentBalanceLabel.leadingAnchor.constraint(equalTo: balanceCheckView.leadingAnchor, constant: 16),
            currentBalanceLabel.trailingAnchor.constraint(equalTo: balanceCheckView.trailingAnchor, constant: -16),
            
            balanceWarningLabel.topAnchor.constraint(equalTo: currentBalanceLabel.bottomAnchor, constant: 8),
            balanceWarningLabel.leadingAnchor.constraint(equalTo: balanceCheckView.leadingAnchor, constant: 16),
            balanceWarningLabel.trailingAnchor.constraint(equalTo: balanceCheckView.trailingAnchor, constant: -16),
            balanceWarningLabel.bottomAnchor.constraint(equalTo: balanceCheckView.bottomAnchor, constant: -16),
            
            // Add Button
            addButton.topAnchor.constraint(equalTo: balanceCheckView.bottomAnchor, constant: 24),
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 54),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: addButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: addButton.centerYAnchor)
        ])
    }
}

// MARK: - Bindings

private extension AddTransactionViewController {
    func setupBindings() {
        // Balance updates
        viewModel.$currentBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balance in
                self?.currentBalanceLabel.text = "Current Balance: ₿\(String(format: "%.8f", balance))"
            }
            .store(in: &cancellables)
        
        // Form validation
        viewModel.$isFormValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isValid in
                self?.navigationItem.rightBarButtonItem?.isEnabled = isValid
                self?.addButton.isEnabled = isValid
                self?.addButton.backgroundColor = isValid ? .systemBlue : .systemGray
            }
            .store(in: &cancellables)
        
        // Amount error
        viewModel.$amountError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.showAmountError(errorMessage)
                } else {
                    self?.hideAmountError()
                }
            }
            .store(in: &cancellables)
        
        // Balance warning
        viewModel.$balanceWarning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] warningMessage in
                if let warningMessage = warningMessage {
                    self?.balanceWarningLabel.text = warningMessage
                    self?.balanceWarningLabel.isHidden = false
                } else {
                    self?.balanceWarningLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
        
        // Loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.addButton.setTitle("", for: .normal)
                    self?.addButton.isEnabled = false
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.addButton.setTitle("Add Transaction", for: .normal)
                    self?.addButton.isEnabled = self?.viewModel.isFormValid ?? false
                }
            }
            .store(in: &cancellables)
        
        // Selected category updates
        viewModel.$selectedCategory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedCategory in
                self?.updateCategorySelection(selectedCategory)
            }
            .store(in: &cancellables)
        
        // Success message
        viewModel.$successMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showSuccessAndDismiss(message: message)
            }
            .store(in: &cancellables)
        
        // Error message
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showError(message)
            }
            .store(in: &cancellables)
    }
}


// MARK: - Actions

private extension AddTransactionViewController {
    
    @objc func didTapCancel() {
        viewModel.cancel()
    }
    
    @objc func didTapAdd() {
        viewModel.addTransaction()
    }
    
    @objc func didTapCategory(_ sender: CategoryButton) {
        viewModel.didSelectCategory(sender.category)
    }
    
    @objc func amountTextFieldDidChange() {
        guard let text = amountTextField.text else { return }
        
        // Apply input formatting through ViewModel
        let formattedText = viewModel.formatBitcoinInput(text)
        
        if formattedText != text {
            amountTextField.text = formattedText
        }
        
        // Update ViewModel with the formatted amount
        viewModel.didChangeAmount(formattedText)
    }
}

// MARK: - UI Updates

private extension AddTransactionViewController {
    
    func updateCategorySelection(_ selectedCategory: TransactionCategory?) {
        for button in categoryButtons {
            button.isSelected = button.category == selectedCategory
        }
    }
    
    func showAmountError(_ message: String) {
        amountErrorLabel.text = message
        amountErrorLabel.isHidden = false
        amountTextField.layer.borderColor = UIColor.systemRed.cgColor
    }
    
    func hideAmountError() {
        amountErrorLabel.isHidden = true
        amountTextField.layer.borderColor = UIColor.separator.cgColor
    }
}

// MARK: - Helper Methods

private extension AddTransactionViewController {
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showSuccessAndDismiss(message: String) {
        let alert = UIAlertController(
            title: "Transaction Added",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.viewModel.cancel()
        })
        
        present(alert, animated: true)
    }
    
    func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

// MARK: - Category Button

final class CategoryButton: UIButton {
    
    let category: TransactionCategory
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    init(category: TransactionCategory) {
        self.category = category
        super.init(frame: .zero)
        setupButton()
        updateAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        setTitle("\(category.icon) \(category.displayName)", for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = 8
        layer.borderWidth = 2
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func updateAppearance() {
        if isSelected {
            backgroundColor = .systemBlue
            setTitleColor(.white, for: .normal)
            layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            backgroundColor = .systemBackground
            setTitleColor(.label, for: .normal)
            layer.borderColor = UIColor.separator.cgColor
        }
    }
}
