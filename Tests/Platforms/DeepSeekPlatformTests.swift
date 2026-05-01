import XCTest
@testable import QuotaBar

final class DeepSeekPlatformTests: XCTestCase {
    var mockNetwork: MockNetworkService!
    var service: DeepSeekPlatformAPIService!

    override func setUp() {
        super.setUp()
        mockNetwork = MockNetworkService()
        service = DeepSeekPlatformAPIService()
    }

    func testFetchUsageSuccess() async throws {
        let json = """
        {
            "is_available": true,
            "balance_infos": [
                {
                    "currency": "CNY",
                    "total_balance": "3.77",
                    "granted_balance": "0.00",
                    "topped_up_balance": "3.77"
                }
            ]
        }
        """
        mockNetwork.mockData = json.data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://api.deepseek.com/user/balance", statusCode: 200)

        let config = PlatformConfigData(
            platformType: .deepseek,
            apiBaseURL: "https://api.deepseek.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "sk-test123"
        )

        let result = try await service.fetchUsage(config: config, network: mockNetwork)

        XCTAssertEqual(result.platform, .deepseek)
        XCTAssertEqual(result.displayName, "DeepSeek")
        XCTAssertEqual(result.metrics.count, 1)
        XCTAssertEqual(result.metrics[0].label, "CNY")
        XCTAssertEqual(result.metrics[0].currentValue, 3.77, accuracy: 0.001)
        XCTAssertNil(result.metrics[0].totalValue)
        XCTAssertEqual(result.metrics[0].unit, "CNY")
        XCTAssertTrue(result.isHealthy)
    }

    func testFetchUsageZeroBalance() async throws {
        let json = """
        {
            "is_available": true,
            "balance_infos": [
                {
                    "currency": "CNY",
                    "total_balance": "0.00",
                    "granted_balance": "0.00",
                    "topped_up_balance": "0.00"
                }
            ]
        }
        """
        mockNetwork.mockData = json.data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://api.deepseek.com/user/balance", statusCode: 200)

        let config = PlatformConfigData(
            platformType: .deepseek,
            apiBaseURL: "https://api.deepseek.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "sk-test123"
        )

        let result = try await service.fetchUsage(config: config, network: mockNetwork)

        XCTAssertFalse(result.isHealthy)
        XCTAssertEqual(result.metrics[0].currentValue, 0, accuracy: 0.001)
        XCTAssertEqual(result.metrics[0].unit, "CNY")
    }

    func testFetchUsageMultipleCurrencies() async throws {
        let json = """
        {
            "is_available": true,
            "balance_infos": [
                {
                    "currency": "CNY",
                    "total_balance": "10.50",
                    "granted_balance": "5.00",
                    "topped_up_balance": "5.50"
                },
                {
                    "currency": "USD",
                    "total_balance": "2.30",
                    "granted_balance": "0.00",
                    "topped_up_balance": "2.30"
                }
            ]
        }
        """
        mockNetwork.mockData = json.data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://api.deepseek.com/user/balance", statusCode: 200)

        let config = PlatformConfigData(
            platformType: .deepseek,
            apiBaseURL: "https://api.deepseek.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "sk-test123"
        )

        let result = try await service.fetchUsage(config: config, network: mockNetwork)

        XCTAssertEqual(result.metrics.count, 2)
        XCTAssertEqual(result.metrics[0].label, "CNY")
        XCTAssertEqual(result.metrics[0].currentValue, 10.50, accuracy: 0.001)
        XCTAssertEqual(result.metrics[1].label, "USD")
        XCTAssertEqual(result.metrics[1].currentValue, 2.30, accuracy: 0.001)
        XCTAssertTrue(result.isHealthy)
    }

    func testFetchUsageNotAvailable() async throws {
        let json = """
        {
            "is_available": false,
            "balance_infos": [
                {
                    "currency": "CNY",
                    "total_balance": "10.00",
                    "granted_balance": "0.00",
                    "topped_up_balance": "10.00"
                }
            ]
        }
        """
        mockNetwork.mockData = json.data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://api.deepseek.com/user/balance", statusCode: 200)

        let config = PlatformConfigData(
            platformType: .deepseek,
            apiBaseURL: "https://api.deepseek.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "sk-test123"
        )

        let result = try await service.fetchUsage(config: config, network: mockNetwork)

        XCTAssertFalse(result.isHealthy)
    }

    func testFetchUsageEmptyBalanceInfos() async throws {
        let json = """
        {
            "is_available": true,
            "balance_infos": []
        }
        """
        mockNetwork.mockData = json.data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://api.deepseek.com/user/balance", statusCode: 200)

        let config = PlatformConfigData(
            platformType: .deepseek,
            apiBaseURL: "https://api.deepseek.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "sk-test123"
        )

        let result = try await service.fetchUsage(config: config, network: mockNetwork)

        XCTAssertEqual(result.metrics.count, 0)
        XCTAssertFalse(result.isHealthy)
    }

    func testFetchUsageNotConfigured() async {
        let config = PlatformConfigData(
            platformType: .deepseek,
            apiBaseURL: "https://api.deepseek.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: ""
        )

        do {
            _ = try await service.fetchUsage(config: config, network: mockNetwork)
            XCTFail("Should throw notConfigured")
        } catch {
            XCTAssertEqual(error as? PlatformError, PlatformError.notConfigured(.deepseek))
        }
    }

    func testFetchUsageUnauthorized() async {
        mockNetwork.mockData = Data()
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://api.deepseek.com/user/balance", statusCode: 401)

        let config = PlatformConfigData(
            platformType: .deepseek,
            apiBaseURL: "https://api.deepseek.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "bad-key"
        )

        do {
            _ = try await service.fetchUsage(config: config, network: mockNetwork)
            XCTFail("Should throw unauthorized")
        } catch {
            XCTAssertEqual(error as? PlatformError, PlatformError.unauthorized(.deepseek))
        }
    }

    func testFetchUsageURLConstruction() async throws {
        let json = """
        {
            "is_available": true,
            "balance_infos": [
                {
                    "currency": "CNY",
                    "total_balance": "10.00",
                    "granted_balance": "0.00",
                    "topped_up_balance": "10.00"
                }
            ]
        }
        """
        mockNetwork.mockData = json.data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://api.deepseek.com/user/balance", statusCode: 200)

        // Test with trailing slash
        let config = PlatformConfigData(
            platformType: .deepseek,
            apiBaseURL: "https://api.deepseek.com/",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "sk-test"
        )

        _ = try await service.fetchUsage(config: config, network: mockNetwork)
        XCTAssertEqual(mockNetwork.lastRequest?.url?.absoluteString, "https://api.deepseek.com/user/balance")
    }
}
