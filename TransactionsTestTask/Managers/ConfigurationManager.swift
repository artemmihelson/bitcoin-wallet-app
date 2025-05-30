//
//  ConfigurationManager.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 30.05.2025.
//


import Foundation

// MARK: - Configuration Manager

final class ConfigurationManager {
    
    // MARK: - Singleton
    
    static let shared = ConfigurationManager()
    
    // MARK: - Properties
    
    private let configFileName = "Config"
    private let configFileExtension = "plist"
    private var configData: [String: Any] = [:]
    
    // MARK: - Public Configuration Properties
    
    var coincapApiKey: String {
        guard let apiKey = configData["CoincapApiKey"] as? String, !apiKey.isEmpty else {
            fatalError("❌ CoincapApiKey is missing or empty in Config.plist")
        }
        return apiKey
    }
    
    var coincapApiBaseUrl: String {
        guard let baseURL = configData["CoincapApiBaseUrl"] as? String, !baseURL.isEmpty else {
            fatalError("❌ CoincapApiBaseUrl is missing or empty in Config.plist")
        }
        return baseURL
    }
    
    // MARK: - Initialization
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        guard let configPath = Bundle.main.path(forResource: configFileName, ofType: configFileExtension) else {
            fatalError("❌ Config.plist file not found in app bundle. Please ensure Config.plist exists in your project.")
        }
        
        guard let configDict = NSDictionary(contentsOfFile: configPath) as? [String: Any] else {
            fatalError("❌ Failed to load Config.plist. Please ensure the file contains valid plist data.")
        }
        
        configData = configDict
        validateRequiredKeys()
        
        print("✅ Configuration loaded successfully from Config.plist")
    }
    
    private func validateRequiredKeys() {
        let requiredKeys = ["CoincapApiKey", "CoincapApiBaseUrl"]
        
        for key in requiredKeys {
            guard configData[key] != nil else {
                fatalError("❌ Required configuration key '\(key)' is missing from Config.plist")
            }
            
            if let stringValue = configData[key] as? String, stringValue.isEmpty {
                fatalError("❌ Required configuration key '\(key)' is empty in Config.plist")
            }
        }
    }
    
    // MARK: - Debug Helper
    
    #if DEBUG
    func printAllConfiguration() {
        print("Current Configuration:")
        for (key, value) in configData {
            // Don't print sensitive data like API keys in full
            if key.lowercased().contains("key") || key.lowercased().contains("secret") {
                print("  \(key): [REDACTED]")
            } else {
                print("  \(key): \(value)")
            }
        }
    }
    #endif
}
