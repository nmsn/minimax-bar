import Foundation

struct UsageData {
    let modelName: String
    let dailyRemaining: Int
    let dailyTotal: Int
    let dailyPercentage: Double
    let dailyResetTime: String
    let dailyResetMs: Int
    let weeklyRemaining: Int
    let weeklyTotal: Int
    let weeklyPercentage: Double
    let weeklyResetTime: String
    let expiryDate: Date?
    let isHealthy: Bool

    var dailyUsedPercentage: Double {
        guard dailyTotal > 0 else { return 0 }
        return Double(dailyTotal - dailyRemaining) / Double(dailyTotal)
    }

    var weeklyUsedPercentage: Double {
        guard weeklyTotal > 0 else { return 0 }
        return Double(weeklyTotal - weeklyRemaining) / Double(weeklyTotal)
    }

    var statusColor: String {
        let maxPercentage = max(dailyUsedPercentage, weeklyUsedPercentage)
        if maxPercentage >= 0.85 {
            return "red"
        } else if maxPercentage >= 0.60 {
            return "yellow"
        } else {
            return "green"
        }
    }

    var dailyResetFormatted: String {
        let hours = dailyResetMs / (1000 * 60 * 60)
        let minutes = (dailyResetMs % (1000 * 60 * 60)) / (1000 * 60)
        if hours > 0 {
            return "还剩\(hours)小时\(minutes)分"
        } else {
            return "还剩\(minutes)分"
        }
    }

    var weeklyResetFormatted: String {
        let days = dailyResetMs / (1000 * 60 * 60 * 24)
        let hours = (dailyResetMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
        if days > 0 {
            return "\(days)天\(hours)小时后重置"
        } else {
            return "\(hours)小时后重置"
        }
    }

    var statusText: String {
        switch statusColor {
        case "red": return "⚠️ 使用量紧张"
        case "yellow": return "⚡ 注意使用"
        default: return "✓ 正常使用"
        }
    }
}

struct APIResponse: Codable {
    let modelRemains: [ModelRemain]?

    enum CodingKeys: String, CodingKey {
        case modelRemains = "model_remains"
    }
}

struct ModelRemain: Codable {
    let modelName: String?
    let startTime: Int?
    let endTime: Int?
    let remainsTime: Int?
    let currentIntervalUsageCount: Int?
    let currentIntervalTotalCount: Int?
    let currentWeeklyUsageCount: Int?
    let currentWeeklyTotalCount: Int?
    let weeklyRemainsTime: Int?

    enum CodingKeys: String, CodingKey {
        case modelName = "model_name"
        case startTime = "start_time"
        case endTime = "end_time"
        case remainsTime = "remains_time"
        case currentIntervalUsageCount = "current_interval_usage_count"
        case currentIntervalTotalCount = "current_interval_total_count"
        case currentWeeklyUsageCount = "current_weekly_usage_count"
        case currentWeeklyTotalCount = "current_weekly_total_count"
        case weeklyRemainsTime = "weekly_remains_time"
    }
}