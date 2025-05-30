//
//  TransactionTableViewCell.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//


import UIKit

final class TransactionTableViewCell: UITableViewCell {
    
    static let identifier = "TransactionTableViewCell"
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let categoryIconLabel = UILabel()
    private let categoryLabel = UILabel()
    private let timeLabel = UILabel()
    private let amountLabel = UILabel()
    private let typeIndicatorView = UIView()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        setupContainerView()
        setupCategorySection()
        setupAmountSection()
        setupConstraints()
    }
    
    private func setupContainerView() {
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowRadius = 3
        containerView.layer.shadowOpacity = 0.1
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(containerView)
    }
    
    private func setupCategorySection() {
        // Category icon
        categoryIconLabel.font = .systemFont(ofSize: 24)
        categoryIconLabel.textAlignment = .center
        categoryIconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Category name
        categoryLabel.font = .boldSystemFont(ofSize: 16)
        categoryLabel.textColor = .label
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Time
        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(categoryIconLabel)
        containerView.addSubview(categoryLabel)
        containerView.addSubview(timeLabel)
    }
    
    private func setupAmountSection() {
        // Type indicator
        typeIndicatorView.layer.cornerRadius = 4
        typeIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // Amount
        amountLabel.font = .boldSystemFont(ofSize: 16)
        amountLabel.textAlignment = .right
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(typeIndicatorView)
        containerView.addSubview(amountLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),
            
            // Category icon
            categoryIconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            categoryIconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            categoryIconLabel.widthAnchor.constraint(equalToConstant: 32),
            categoryIconLabel.heightAnchor.constraint(equalToConstant: 32),
            
            // Category label
            categoryLabel.leadingAnchor.constraint(equalTo: categoryIconLabel.trailingAnchor, constant: 12),
            categoryLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: typeIndicatorView.leadingAnchor, constant: -8),
            
            // Time label
            timeLabel.leadingAnchor.constraint(equalTo: categoryLabel.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: typeIndicatorView.leadingAnchor, constant: -8),
            
            // Type indicator
            typeIndicatorView.trailingAnchor.constraint(equalTo: amountLabel.leadingAnchor, constant: -8),
            typeIndicatorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            typeIndicatorView.widthAnchor.constraint(equalToConstant: 8),
            typeIndicatorView.heightAnchor.constraint(equalToConstant: 8),
            
            // Amount label
            amountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            amountLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            amountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with transaction: TransactionEntity) {
        configureCategory(transaction)
        configureAmount(transaction)
        configureTime(transaction)
        configureTypeIndicator(transaction)
    }
    
    private func configureCategory(_ transaction: TransactionEntity) {
        if transaction.transactionType == .topUp {
            categoryIconLabel.text = "💰"
            categoryLabel.text = "Balance Top Up"
        } else if let category = transaction.transactionCategory {
            categoryIconLabel.text = category.icon
            categoryLabel.text = category.displayName
        } else {
            categoryIconLabel.text = "📝"
            categoryLabel.text = "Other"
        }
    }
    
    private func configureAmount(_ transaction: TransactionEntity) {
        let amount = transaction.bitcoinAmount
        let formattedAmount = String(format: "%.8f", amount)
        
        if transaction.transactionType == .topUp {
            amountLabel.text = "+₿\(formattedAmount)"
            amountLabel.textColor = .systemGreen
        } else {
            amountLabel.text = "-₿\(formattedAmount)"
            amountLabel.textColor = .systemRed
        }
    }
    
    private func configureTime(_ transaction: TransactionEntity) {
        timeLabel.text = transaction.displayTime
    }
    
    private func configureTypeIndicator(_ transaction: TransactionEntity) {
        if transaction.transactionType == .topUp {
            typeIndicatorView.backgroundColor = .systemGreen
        } else {
            typeIndicatorView.backgroundColor = .systemRed
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        categoryIconLabel.text = nil
        categoryLabel.text = nil
        timeLabel.text = nil
        amountLabel.text = nil
        amountLabel.textColor = .label
        typeIndicatorView.backgroundColor = .clear
    }
}