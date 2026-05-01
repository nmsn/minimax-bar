import Foundation

enum PlatformType: String, Codable, CaseIterable, Hashable {
    case minimax
    case deepseek

    var displayName: String {
        switch self {
        case .minimax: return "MiniMax"
        case .deepseek: return "DeepSeek"
        }
    }
}

enum PlatformError: Error, Equatable {
    case notConfigured(PlatformType)
    case invalidResponse(PlatformType)
    case networkError(PlatformType, String)
    case unauthorized(PlatformType)
    case decodingError(PlatformType, String)
}

extension PlatformError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return I18nService.shared.translate("error.notConfigured")
        case .invalidResponse:
            return I18nService.shared.translate("error.invalidResponse")
        case .networkError(_, let message):
            return String(format: I18nService.shared.translate("error.networkError"), message)
        case .unauthorized:
            return I18nService.shared.translate("error.unauthorized")
        case .decodingError(_, let message):
            return String(format: I18nService.shared.translate("error.networkError"), message)
        }
    }
}

struct PlatformUsageData: Equatable {
    let platform: PlatformType
    let displayName: String
    let metrics: [UsageMetric]
    let lastUpdated: Date
    let isHealthy: Bool
}

struct UsageMetric: Equatable {
    let label: String
    let currentValue: Double
    let totalValue: Double?
    let unit: String
    let resetTime: Date?
}

struct PlatformConfigData {
    let platformType: PlatformType
    let apiBaseURL: String
    let authHeader: String
    let authPrefix: String
    let apiKey: String
}

protocol NetworkService {
    func data(from request: URLRequest) async throws -> (Data, URLResponse)
}

class URLSessionNetworkService: NetworkService {
    func data(from request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

protocol PlatformAPIService {
    var platformType: PlatformType { get }
    func fetchUsage(config: PlatformConfigData, network: NetworkService) async throws -> PlatformUsageData
    func clearCache()
}
