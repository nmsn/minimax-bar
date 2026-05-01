import XCTest
@testable import MiniMaxBar

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
            "balance": "4.50",
            "currency": "USD"
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
        XCTAssertEqual(result.metrics[0].label, "Balance")
        XCTAssertEqual(result.metrics[0].currentValue, 4.5)
        XCTAssertNil(result.metrics[0].totalValue)
        XCTAssertEqual(result.metrics[0].unit, "USD")
        XCTAssertTrue(result.isHealthy)
    }

    func testFetchUsageZeroBalance() async throws {
        let json = """
        {
            "is_available": true,
            "balance": "0.00",
            "currency": "CNY"
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
        XCTAssertEqual(result.metrics[0].currentValue, 0)
        XCTAssertEqual(result.metrics[0].unit, "CNY")
    }

    func testFetchUsageNotAvailable() async throws {
        let json = """
        {
            "is_available": false,
            "balance": "10.00",
            "currency": "USD"
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
            "balance": "10.00",
            "currency": "USD"
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
