import Foundation

struct DeepSeekBalanceResponse: Codable {
    let isAvailable: Bool
    let balance: String
    let currency: String

    enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case balance
        case currency
    }
}

final class DeepSeekPlatformAPIService: PlatformAPIService {
    let platformType: PlatformType = .deepseek

    private let cacheTimeout: TimeInterval = 8
    private var cache: (data: PlatformUsageData, timestamp: Date)?

    func fetchUsage(config: PlatformConfigData, network: NetworkService) async throws -> PlatformUsageData {
        if let cached = cache, Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.data
        }

        guard !config.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PlatformError.notConfigured(.deepseek)
        }

        let urlString = config.apiBaseURL.hasSuffix("/") ? config.apiBaseURL + "user/balance" : config.apiBaseURL + "/user/balance"
        guard let url = URL(string: urlString) else {
            throw PlatformError.invalidResponse(.deepseek)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("\(config.authPrefix)\(config.apiKey)", forHTTPHeaderField: config.authHeader)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await network.data(from: request)
        } catch {
            throw PlatformError.networkError(.deepseek, error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlatformError.invalidResponse(.deepseek)
        }

        if httpResponse.statusCode == 401 {
            throw PlatformError.unauthorized(.deepseek)
        }

        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "unable to decode"
            throw PlatformError.networkError(.deepseek, "HTTP \(httpResponse.statusCode): \(responseString.prefix(200))")
        }

        let balanceResponse: DeepSeekBalanceResponse
        do {
            balanceResponse = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: data)
        } catch {
            throw PlatformError.decodingError(.deepseek, error.localizedDescription)
        }

        let balance = Double(balanceResponse.balance) ?? 0
        let isHealthy = balanceResponse.isAvailable && balance > 0

        let usageData = PlatformUsageData(
            platform: .deepseek,
            displayName: "DeepSeek",
            metrics: [
                UsageMetric(label: "Balance", currentValue: balance, totalValue: nil, unit: balanceResponse.currency, resetTime: nil)
            ],
            lastUpdated: Date(),
            isHealthy: isHealthy
        )

        cache = (usageData, Date())
        return usageData
    }

    func clearCache() {
        cache = nil
    }
}
