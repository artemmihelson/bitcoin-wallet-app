//
//  BalanceTableViewCell.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//
import UIKit

final class BalanceTableViewCell: UITableViewCell {
    static let identifier = "BalanceTableViewCell"
    
    private let containerView = UIView()
    private let balanceTitleLabel = UILabel()
    private let balanceLabel = UILabel()
    private let bitcoinRateLabel = UILabel()
    
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
        
        containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        balanceTitleLabel.text = "Current Balance"
        balanceTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        balanceTitleLabel.textColor = .secondaryLabel
        balanceTitleLabel.textAlignment = .center
        balanceTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        balanceLabel.font = .boldSystemFont(ofSize: 36)
        balanceLabel.textAlignment = .center
        balanceLabel.textColor = .label
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.7
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bitcoinRateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bitcoinRateLabel.textColor = .secondaryLabel
        bitcoinRateLabel.textAlignment = .center
        bitcoinRateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(containerView)
        containerView.addSubview(balanceTitleLabel)
        containerView.addSubview(balanceLabel)
        containerView.addSubview(bitcoinRateLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            balanceTitleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            balanceTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            balanceTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            balanceLabel.topAnchor.constraint(equalTo: balanceTitleLabel.bottomAnchor, constant: 8),
            balanceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            balanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            bitcoinRateLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 8),
            bitcoinRateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            bitcoinRateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            bitcoinRateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    func configure(balance: Double) {
        balanceLabel.text = String(format: "₿ %.8f", balance)
    }
}
