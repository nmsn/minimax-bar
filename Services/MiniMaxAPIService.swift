import Foundation

// Legacy wrapper for backward compatibility
// Will be removed when UsageViewModel is replaced with PlatformViewModel

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

    private let platformService = MiniMaxPlatformAPIService()

    private init() {}

    func fetchUsage(forceRefresh: Bool = false) async throws -> UsageData {
        if forceRefresh {
            platformService.clearCache()
        }

        let store = ConfigService.shared.store(for: .minimax)
        guard store.isConfigured else {
            throw APIError.notConfigured
        }

        let platformData = try await platformService.fetchUsage(
            config: store.toConfigData(),
            network: URLSessionNetworkService()
        )

        return convertToUsageData(platformData)
    }

    func clearCache() {
        platformService.clearCache()
    }

    private func convertToUsageData(_ data: PlatformUsageData) -> UsageData {
        let dailyMetric = data.metrics.first { $0.label == "Daily" }
        let weeklyMetric = data.metrics.first { $0.label == "Weekly" }

        let dailyUsed = Int(dailyMetric?.currentValue ?? 0)
        let dailyTotal = Int(dailyMetric?.totalValue ?? 0)
        let dailyRemaining = dailyTotal - dailyUsed
        let dailyPercentage = dailyTotal > 0 ? Double(dailyRemaining) / Double(dailyTotal) : 0

        let weeklyUsed = Int(weeklyMetric?.currentValue ?? 0)
        let weeklyTotal = Int(weeklyMetric?.totalValue ?? 0)
        let weeklyRemaining = weeklyTotal - weeklyUsed
        let weeklyPercentage = weeklyTotal > 0 ? Double(weeklyRemaining) / Double(weeklyTotal) : 0

        var dailyResetMs = 0
        if let resetTime = dailyMetric?.resetTime {
            dailyResetMs = Int(resetTime.timeIntervalSinceNow * 1000)
            if dailyResetMs < 0 { dailyResetMs = 0 }
        }

        var weeklyResetMs = 0
        if let resetTime = weeklyMetric?.resetTime {
            weeklyResetMs = Int(resetTime.timeIntervalSinceNow * 1000)
            if weeklyResetMs < 0 { weeklyResetMs = 0 }
        }

        return UsageData(
            modelName: "MiniMax",
            dailyRemaining: dailyRemaining,
            dailyTotal: dailyTotal,
            dailyPercentage: dailyPercentage,
            dailyResetTime: "",
            dailyResetMs: dailyResetMs,
            weeklyRemaining: weeklyRemaining,
            weeklyTotal: weeklyTotal,
            weeklyPercentage: weeklyPercentage,
            weeklyResetTime: "",
            weeklyResetMs: weeklyResetMs,
            expiryDate: nil,
            isHealthy: data.isHealthy
        )
    }
}
