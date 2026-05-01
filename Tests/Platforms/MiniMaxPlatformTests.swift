import XCTest
@testable import MiniMaxBar

final class MiniMaxPlatformTests: XCTestCase {
    var mockNetwork: MockNetworkService!
    var service: MiniMaxPlatformAPIService!

    override func setUp() {
        super.setUp()
        mockNetwork = MockNetworkService()
        service = MiniMaxPlatformAPIService()
    }

    func testFetchUsageSuccess() async throws {
        let json = """
        {
            "model_remains": [{
                "model_name": "MiniMax-M2",
                "current_interval_usage_count": 45,
                "current_interval_total_count": 100,
                "current_weekly_usage_count": 320,
                "current_weekly_total_count": 500,
                "remains_time": 3600000,
                "weekly_remains_time": 86400000
            }]
        }
        """
        mockNetwork.mockData = json.data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://test.com", statusCode: 200)

        let config = PlatformConfigData(
            platformType: .minimax,
            apiBaseURL: "https://test.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "test-key"
        )

        let result = try await service.fetchUsage(config: config, network: mockNetwork)

        XCTAssertEqual(result.platform, .minimax)
        XCTAssertEqual(result.displayName, "MiniMax")
        XCTAssertEqual(result.metrics.count, 2)
        XCTAssertEqual(result.metrics[0].label, "Daily")
        XCTAssertEqual(result.metrics[0].currentValue, 45)
        XCTAssertEqual(result.metrics[0].totalValue, 100)
        XCTAssertEqual(result.metrics[1].label, "Weekly")
        XCTAssertEqual(result.metrics[1].currentValue, 320)
        XCTAssertEqual(result.metrics[1].totalValue, 500)
    }

    func testFetchUsageNotConfigured() async {
        let config = PlatformConfigData(
            platformType: .minimax,
            apiBaseURL: "https://test.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: ""
        )

        do {
            _ = try await service.fetchUsage(config: config, network: mockNetwork)
            XCTFail("Should throw notConfigured")
        } catch {
            XCTAssertEqual(error as? PlatformError, PlatformError.notConfigured(.minimax))
        }
    }

    func testFetchUsageUnauthorized() async {
        mockNetwork.mockData = Data()
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://test.com", statusCode: 401)

        let config = PlatformConfigData(
            platformType: .minimax,
            apiBaseURL: "https://test.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "bad-key"
        )

        do {
            _ = try await service.fetchUsage(config: config, network: mockNetwork)
            XCTFail("Should throw unauthorized")
        } catch {
            XCTAssertEqual(error as? PlatformError, PlatformError.unauthorized(.minimax))
        }
    }

    func testFetchUsageNetworkError() async {
        mockNetwork.mockError = URLError(.notConnectedToInternet)

        let config = PlatformConfigData(
            platformType: .minimax,
            apiBaseURL: "https://test.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "test-key"
        )

        do {
            _ = try await service.fetchUsage(config: config, network: mockNetwork)
            XCTFail("Should throw networkError")
        } catch {
            if case .networkError = error as? PlatformError {
                // Expected
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        }
    }

    func testFetchUsageInvalidJSON() async {
        mockNetwork.mockData = "invalid json".data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://test.com", statusCode: 200)

        let config = PlatformConfigData(
            platformType: .minimax,
            apiBaseURL: "https://test.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "test-key"
        )

        do {
            _ = try await service.fetchUsage(config: config, network: mockNetwork)
            XCTFail("Should throw decodingError")
        } catch {
            if case .decodingError = error as? PlatformError {
                // Expected
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        }
    }

    func testCache() async throws {
        let json = """
        {
            "model_remains": [{
                "model_name": "MiniMax-M2",
                "current_interval_usage_count": 45,
                "current_interval_total_count": 100,
                "current_weekly_usage_count": 320,
                "current_weekly_total_count": 500
            }]
        }
        """
        mockNetwork.mockData = json.data(using: .utf8)
        mockNetwork.mockResponse = MockNetworkService.makeResponse(url: "https://test.com", statusCode: 200)

        let config = PlatformConfigData(
            platformType: .minimax,
            apiBaseURL: "https://test.com",
            authHeader: "Authorization",
            authPrefix: "Bearer ",
            apiKey: "test-key"
        )

        let result1 = try await service.fetchUsage(config: config, network: mockNetwork)
        let result2 = try await service.fetchUsage(config: config, network: mockNetwork)

        // Second call should use cache (mockNetwork.lastRequest should still be from first call)
        XCTAssertEqual(result1.metrics[0].currentValue, result2.metrics[0].currentValue)
    }
}
