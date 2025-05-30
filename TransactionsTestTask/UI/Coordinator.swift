//
//  Coordinator.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 30.05.2025.
//
import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}
