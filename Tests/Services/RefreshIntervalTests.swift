import XCTest
@testable import QuotaBar

final class RefreshIntervalTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "quotabar.refreshInterval")
    }

    func testAllCasesCount() {
        XCTAssertEqual(RefreshInterval.allCases.count, 5)
    }

    func testTimeIntervals() {
        XCTAssertEqual(RefreshInterval.thirtySeconds.timeInterval, 30)
        XCTAssertEqual(RefreshInterval.oneMinute.timeInterval, 60)
        XCTAssertEqual(RefreshInterval.threeMinutes.timeInterval, 180)
        XCTAssertEqual(RefreshInterval.fiveMinutes.timeInterval, 300)
        XCTAssertEqual(RefreshInterval.tenMinutes.timeInterval, 600)
    }

    func testDefaultIsOneMinute() {
        XCTAssertEqual(RefreshInterval.default, .oneMinute)
    }

    func testI18nKeys() {
        XCTAssertEqual(RefreshInterval.thirtySeconds.i18nKey, "menu.refresh.30s")
        XCTAssertEqual(RefreshInterval.oneMinute.i18nKey, "menu.refresh.1m")
        XCTAssertEqual(RefreshInterval.threeMinutes.i18nKey, "menu.refresh.3m")
        XCTAssertEqual(RefreshInterval.fiveMinutes.i18nKey, "menu.refresh.5m")
        XCTAssertEqual(RefreshInterval.tenMinutes.i18nKey, "menu.refresh.10m")
    }

    func testConfigServiceDefaultRefreshInterval() {
        let service = ConfigService.shared
        XCTAssertEqual(service.refreshInterval, .default)
    }

    func testConfigServiceSetRefreshInterval() {
        let service = ConfigService.shared
        service.refreshInterval = .fiveMinutes
        XCTAssertEqual(service.refreshInterval, .fiveMinutes)
    }

    func testConfigServiceRefreshIntervalPersistence() {
        let service = ConfigService.shared
        service.refreshInterval = .threeMinutes

        // Simulate re-creation by clearing cached instance
        // Note: ConfigService is a singleton, so we verify via UserDefaults
        let raw = UserDefaults.standard.string(forKey: "quotabar.refreshInterval")
        XCTAssertEqual(raw, RefreshInterval.threeMinutes.rawValue)
    }

    func testRawValues() {
        XCTAssertEqual(RefreshInterval.thirtySeconds.rawValue, "thirtySeconds")
        XCTAssertEqual(RefreshInterval.oneMinute.rawValue, "oneMinute")
    }
}
