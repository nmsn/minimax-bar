import SwiftUI

struct StatusBarView: View {
    let usageData: UsageData?

    private var dailyProgress: Double {
        guard let data = usageData else { return 1.0 }
        return 1.0 - data.dailyUsedPercentage
    }

    private var weeklyProgress: Double {
        guard let data = usageData else { return 1.0 }
        return 1.0 - data.weeklyUsedPercentage
    }

    private var dailyColor: Color {
        guard let data = usageData else { return .green }
        return colorForPercentage(data.dailyUsedPercentage)
    }

    private var weeklyColor: Color {
        guard let data = usageData else { return .green }
        return colorForPercentage(data.weeklyUsedPercentage)
    }

    private func colorForPercentage(_ percentage: Double) -> Color {
        if percentage >= 0.85 {
            return .red
        } else if percentage >= 0.60 {
            return .yellow
        } else {
            return .green
        }
    }

    var body: some View {
        NestedRingsView(
            dailyProgress: dailyProgress,
            weeklyProgress: weeklyProgress,
            dailyColor: dailyColor,
            weeklyColor: weeklyColor
        )
    }
}

#Preview {
    StatusBarView(usageData: nil)
}