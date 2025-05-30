//
//  SceneDelegate.swift
//  TransactionsTestTask
//
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private var mainCoordinator: MainCoordinator?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Initialize services first
        ServicesAssembler.initialize()
        
        // Create main view controller
        let navigationController = UINavigationController()
        configureNavigationController(navigationController)
        mainCoordinator = MainCoordinator(navigationController: navigationController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        mainCoordinator?.start()
    }
    
    private func configureNavigationController(_ navigationController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemGroupedBackground
        appearance.shadowColor = .clear // Remove shadow to prevent visual separation
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        
        // Ensure navigation bar is not translucent to prevent content overlap
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = .systemBlue
        
        // Set proper background color
        navigationController.view.backgroundColor = .systemGroupedBackground
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        do {
            try CoreDataStack.shared.saveContext()
        } catch {
            print("Failed to save context when entering background: \(error)")
        }
    }
}
