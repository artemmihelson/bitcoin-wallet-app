//
//  TestModuleObserver.swift
//  TransactionsTestTask
//
//  Created by Artem Mihelson on 29.05.2025.
//
import Foundation

protocol TestModuleObserver: AnyObject {
    var moduleName: String { get }
    var receivedUpdatesCount: Int { get }
    func handleRateUpdate(_ rate: Double)
}

final class TestWalletBalanceObserver: TestModuleObserver {
    let moduleName = "WalletBalanceModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestTransactionListObserver: TestModuleObserver {
    let moduleName = "TransactionListModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestDashboardObserver: TestModuleObserver {
    let moduleName = "DashboardModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestNotificationObserver: TestModuleObserver {
    let moduleName = "NotificationModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestWidgetObserver: TestModuleObserver {
    let moduleName = "WidgetModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

// Add more test observers to reach 20+ modules
final class TestChartObserver: TestModuleObserver {
    let moduleName = "ChartModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestCacheObserver: TestModuleObserver {
    let moduleName = "CacheModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestSecurityObserver: TestModuleObserver {
    let moduleName = "SecurityModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestAPIObserver: TestModuleObserver {
    let moduleName = "APIModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestDatabaseObserver: TestModuleObserver {
    let moduleName = "DatabaseModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestSyncObserver: TestModuleObserver {
    let moduleName = "SyncModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestReportsObserver: TestModuleObserver {
    let moduleName = "ReportsModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestBackupObserver: TestModuleObserver {
    let moduleName = "BackupModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestTradingObserver: TestModuleObserver {
    let moduleName = "TradingModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestWatchAppObserver: TestModuleObserver {
    let moduleName = "WatchAppModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestPortfolioObserver: TestModuleObserver {
    let moduleName = "PortfolioModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestHistoryObserver: TestModuleObserver {
    let moduleName = "HistoryModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestSettingsObserver: TestModuleObserver {
    let moduleName = "SettingsModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestExportObserver: TestModuleObserver {
    let moduleName = "ExportModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestImportObserver: TestModuleObserver {
    let moduleName = "ImportModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}

final class TestThemeObserver: TestModuleObserver {
    let moduleName = "ThemeModule"
    private(set) var receivedUpdatesCount = 0
    private(set) var lastReceivedRate: Double?
    
    func handleRateUpdate(_ rate: Double) {
        receivedUpdatesCount += 1
        lastReceivedRate = rate
        print("[\(moduleName)] Rate updated: $\(String(format: "%.2f", rate)) (Update #\(receivedUpdatesCount))")
    }
}
