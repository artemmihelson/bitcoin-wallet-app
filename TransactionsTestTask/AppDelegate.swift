//
//  AppDelegate.swift
//  TransactionsTestTask
//
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureGlobalAppearance()
        return true
    }
    
    private func configureGlobalAppearance() {
        // Set global tint color
        if #available(iOS 13.0, *) {
            UIView.appearance().tintColor = .systemBlue
        }
        
        // Configure table view appearance globally
        UITableView.appearance().backgroundColor = .systemGroupedBackground
        UITableViewCell.appearance().backgroundColor = .systemGroupedBackground
        
        // Configure navigation bar globally
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .systemGroupedBackground
            appearance.shadowColor = .clear
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        // See also applicationDidEnterBackground:.
        do {
            try CoreDataStack.shared.saveContext()
        } catch {
            print("Failed to save context on app termination: \(error)")
        }
    }
}
