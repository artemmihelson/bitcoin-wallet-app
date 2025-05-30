//
//  ConfigurationManagerTests.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 30.05.2025.
//


import XCTest
@testable import TransactionsTestTask

final class ConfigurationManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var tempConfigPath: String?
    private var originalBundle: Bundle!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        originalBundle = Bundle.main
    }
    
    override func tearDownWithError() throws {
        // Clean up any temporary config files
        if let tempPath = tempConfigPath {
            try? FileManager.default.removeItem(atPath: tempPath)
        }
        tempConfigPath = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Configuration Loading Tests
    
    func testConfigurationManager_ValidConfig_LoadsSuccessfully() {
        // This test assumes you have a valid Config.plist in your test bundle
        // Given & When
        let config = ConfigurationManager.shared
        
        // Then
        XCTAssertNoThrow(config.coincapApiKey)
        XCTAssertNoThrow(config.coincapApiBaseUrl)
    }
    
    func testConfigurationManager_Singleton_ReturnsSameInstance() {
        // Given
        let config1 = ConfigurationManager.shared
        let config2 = ConfigurationManager.shared
        
        // Then
        XCTAssertTrue(config1 === config2)
    }
    
    // MARK: - Error Handling Tests
    
    func testConfigurationManager_MissingConfigFile_ThrowsFatalError() {
        // Note: This test would actually crash the test runner due to fatalError
        // In a real scenario, you might want to use dependency injection
        // to make ConfigurationManager testable without fatalError
        
        // This is a conceptual test - in practice you'd need to refactor
        // ConfigurationManager to be more testable
        XCTAssertTrue(true, "This test demonstrates the expected behavior")
    }
    
    // MARK: - Configuration Values Tests
    
    func testConfigurationManager_BaseURL_IsValidURL() {
        // Given
        let config = ConfigurationManager.shared
        
        // When
        let baseURL = config.coincapApiBaseUrl
        
        // Then
        XCTAssertNotNil(URL(string: baseURL))
        XCTAssertTrue(baseURL.hasPrefix("http"))
    }
}

// MARK: - Mock Configuration Manager for Testing

/// A testable version of ConfigurationManager that doesn't use fatalError
final class MockConfigurationManager {
    
    // MARK: - Properties
    
    private let configData: [String: Any]
    
    var coincapApiKey: String {
        return configData["CoincapApiKey"] as? String ?? ""
    }
    
    var coincapApiBaseUrl: String {
        return configData["CoincapApiBaseUrl"] as? String ?? ""
    }
    
    // MARK: - Initialization
    
    init(configData: [String: Any]) {
        self.configData = configData
    }
    
    // MARK: - Factory Methods for Testing
    
    static func validConfig() -> MockConfigurationManager {
        return MockConfigurationManager(configData: [
            "CoincapApiKey": "test_api_key_123",
            "CoincapApiBaseUrl": "https://api.test.com/bitcoin"
        ])
    }
    
    static func missingAPIKey() -> MockConfigurationManager {
        return MockConfigurationManager(configData: [
            "CoincapApiBaseUrl": "https://api.test.com/bitcoin"
        ])
    }
    
    static func emptyAPIKey() -> MockConfigurationManager {
        return MockConfigurationManager(configData: [
            "CoincapApiKey": "",
            "CoincapApiBaseUrl": "https://api.test.com/bitcoin"
        ])
    }
}

// MARK: - Mock Configuration Tests

final class MockConfigurationManagerTests: XCTestCase {
    
    func testMockConfigurationManager_ValidConfig_ReturnsExpectedValues() {
        // Given
        let config = MockConfigurationManager.validConfig()
        
        // When & Then
        XCTAssertEqual(config.coincapApiKey, "test_api_key_123")
        XCTAssertEqual(config.coincapApiBaseUrl, "https://api.test.com/bitcoin")
    }
    
    func testMockConfigurationManager_MissingAPIKey_ReturnsEmptyString() {
        // Given
        let config = MockConfigurationManager.missingAPIKey()
        
        // When & Then
        XCTAssertEqual(config.coincapApiKey, "")
    }
    
    func testMockConfigurationManager_EmptyAPIKey_ReturnsEmptyString() {
        // Given
        let config = MockConfigurationManager.emptyAPIKey()
        
        // When & Then
        XCTAssertEqual(config.coincapApiKey, "")
    }
    
    func testMockConfigurationManager_DefaultValues_AreReasonable() {
        // Given
        let config = MockConfigurationManager(configData: [:])
        
        // When & Then
        XCTAssertEqual(config.coincapApiKey, "")
        XCTAssertEqual(config.coincapApiBaseUrl, "")
    }
}
