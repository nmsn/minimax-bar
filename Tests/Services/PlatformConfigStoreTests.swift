import XCTest
@testable import QuotaBar

final class PlatformConfigStoreTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testNewStoreIsNotConfigured() {
        let configPath = tempDir.appendingPathComponent("test.json")
        let store = PlatformConfigStore(platformType: .deepseek, configPath: configPath)
        XCTAssertFalse(store.isConfigured)
        XCTAssertNil(store.apiKey)
    }

    func testSetAPIKey() {
        let configPath = tempDir.appendingPathComponent("test.json")
        let store = PlatformConfigStore(platformType: .deepseek, configPath: configPath)
        store.setAPIKey("sk-test123")
        XCTAssertTrue(store.isConfigured)
        XCTAssertEqual(store.apiKey, "sk-test123")
    }

    func testResetAPIKey() {
        let configPath = tempDir.appendingPathComponent("test.json")
        let store = PlatformConfigStore(platformType: .deepseek, configPath: configPath)
        store.setAPIKey("sk-test123")
        store.resetAPIKey()
        XCTAssertFalse(store.isConfigured)
    }

    func testPersistence() {
        let configPath = tempDir.appendingPathComponent("test.json")
        let store1 = PlatformConfigStore(platformType: .deepseek, configPath: configPath)
        store1.setAPIKey("sk-persist-test")

        let store2 = PlatformConfigStore(platformType: .deepseek, configPath: configPath)
        XCTAssertEqual(store2.apiKey, "sk-persist-test")
        XCTAssertTrue(store2.isConfigured)
    }

    func testToConfigData() {
        let configPath = tempDir.appendingPathComponent("test.json")
        let store = PlatformConfigStore(platformType: .deepseek, configPath: configPath)
        store.setAPIKey("sk-test")

        let configData = store.toConfigData()
        XCTAssertEqual(configData.platformType, .deepseek)
        XCTAssertEqual(configData.apiKey, "sk-test")
        XCTAssertEqual(configData.authHeader, "Authorization")
        XCTAssertEqual(configData.authPrefix, "Bearer ")
    }

    func testDefaultValues() {
        let configPath = tempDir.appendingPathComponent("test.json")
        let store = PlatformConfigStore(platformType: .minimax, configPath: configPath)
        XCTAssertEqual(store.authHeader, "Authorization")
        XCTAssertEqual(store.authPrefix, "Bearer ")
    }

    func testWhitespaceOnlyKeyIsNotConfigured() {
        let configPath = tempDir.appendingPathComponent("test.json")
        let store = PlatformConfigStore(platformType: .deepseek, configPath: configPath)
        store.setAPIKey("   ")
        XCTAssertFalse(store.isConfigured)
    }
}
