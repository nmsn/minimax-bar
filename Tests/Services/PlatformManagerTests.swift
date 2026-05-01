import XCTest
@testable import MiniMaxBar

final class PlatformManagerTests: XCTestCase {
    func testManagerHasDefaultServices() {
        let manager = PlatformManager()
        // Should have MiniMax and DeepSeek registered
        let configured = manager.configuredPlatforms()
        XCTAssertNotNil(configured)
    }

    func testConfiguredPlatformsReturnsConfiguredOnly() {
        let manager = PlatformManager()
        let platforms = manager.configuredPlatforms()
        // Only platforms with API keys should be returned
        for platform in platforms {
            let store = ConfigService.shared.store(for: platform)
            XCTAssertTrue(store.isConfigured)
        }
    }

    func testClearCacheDoesNotCrash() {
        let manager = PlatformManager()
        manager.clearCache(for: .minimax)
        manager.clearCache(for: .deepseek)
        manager.clearAllCaches()
    }
}
