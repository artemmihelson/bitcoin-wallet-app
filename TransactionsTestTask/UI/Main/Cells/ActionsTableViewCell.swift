//
//  ActionsTableViewCell.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//
import UIKit

final class ActionsTableViewCell: UITableViewCell {
    static let identifier = "ActionsTableViewCell"
    
    private let stackView = UIStackView()
    private let topUpButton = UIButton(type: .system)
    private let addTransactionButton = UIButton(type: .system)
    
    var onTopUpTapped: (() -> Void)?
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
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        setupButton(topUpButton, title: "💰 Top Up", backgroundColor: .systemGreen, action: #selector(topUpTapped))
        setupButton(addTransactionButton, title: "📝 Add Transaction", backgroundColor: .systemBlue, action: #selector(addTransactionTapped))
        
        stackView.addArrangedSubview(topUpButton)
        stackView.addArrangedSubview(addTransactionButton)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupButton(_ button: UIButton, title: String, backgroundColor: UIColor, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.backgroundColor = backgroundColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    @objc private func topUpTapped() {
        onTopUpTapped?()
    }
    
    @objc private func addTransactionTapped() {
        onAddTransactionTapped?()
    }
}
