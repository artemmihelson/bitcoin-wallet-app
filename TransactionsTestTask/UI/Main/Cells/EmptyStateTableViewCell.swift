//
//  EmptyStateTableViewCell.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//
import UIKit

final class EmptyStateTableViewCell: UITableViewCell {
    static let identifier = "EmptyStateTableViewCell"
    
    private let emptyLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    
    var onAddTransactionTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        emptyLabel.text = "No transactions yet\nStart by adding your first transaction or topping up your balance"
        emptyLabel.font = .systemFont(ofSize: 16)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        actionButton.setTitle("Add Your First Transaction", for: .normal)
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        actionButton.backgroundColor = .systemBlue
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.cornerRadius = 8
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(emptyLabel)
        contentView.addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            emptyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            emptyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            actionButton.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 20),
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionButton.heightAnchor.constraint(equalToConstant: 44),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    @objc private func actionTapped() {
        onAddTransactionTapped?()
    }
}
