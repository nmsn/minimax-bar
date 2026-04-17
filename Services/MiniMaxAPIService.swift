import Foundation

enum APIError: Error, LocalizedError {
    case notConfigured
    case invalidResponse
    case networkError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return I18nService.shared.translate("error.notConfigured")
        case .invalidResponse:
            return I18nService.shared.translate("error.invalidResponse")
        case .networkError(let msg):
            return String(format: I18nService.shared.translate("error.networkError"), msg)
        case .unauthorized:
            return I18nService.shared.translate("error.unauthorized")
        }
    }
}

final class MiniMaxAPIService {
    static let shared = MiniMaxAPIService()

    private let baseURL = "https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains"
    private let cacheTimeout: TimeInterval = 8

    private var cache: (data: UsageData, timestamp: Date)?

    private init() {}

    func fetchUsage(forceRefresh: Bool = false) async throws -> UsageData {
        if !forceRefresh, let cached = cache, Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.data
        }

        guard let token = ConfigService.shared.token else {
            throw APIError.notConfigured
        }

        guard let url = URL(string: baseURL) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "unable to decode"
            throw APIError.networkError("HTTP \(httpResponse.statusCode): \(responseString.prefix(200))")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)

        guard let modelData = apiResponse.modelRemains?.first else {
            throw APIError.invalidResponse
        }

        let usageData = parseUsageData(from: modelData)
        cache = (usageData, Date())

        return usageData
    }

    private func parseUsageData(from model: ModelRemain) -> UsageData {
        let dailyTotal = model.currentIntervalTotalCount ?? 0
        let dailyRemaining = model.currentIntervalUsageCount ?? 0
        let dailyPercentage = dailyTotal > 0 ? Double(dailyTotal - dailyRemaining) / Double(dailyTotal) : 0

        let weeklyTotal = model.currentWeeklyTotalCount ?? 0
        let weeklyRemaining = model.currentWeeklyUsageCount ?? 0
        let weeklyPercentage = weeklyTotal > 0 ? Double(weeklyTotal - weeklyRemaining) / Double(weeklyTotal) : 0

        let resetMs = model.remainsTime ?? 0

        return UsageData(
            modelName: model.modelName ?? "MiniMax-M2",
            dailyRemaining: dailyRemaining,
            dailyTotal: dailyTotal,
            dailyPercentage: dailyPercentage,
            dailyResetTime: "",
            dailyResetMs: resetMs,
            weeklyRemaining: weeklyRemaining,
            weeklyTotal: weeklyTotal,
            weeklyPercentage: weeklyPercentage,
            weeklyResetTime: "",
            expiryDate: nil,
            isHealthy: dailyPercentage < 0.85
        )
    }

    func clearCache() {
        cache = nil
    }
}