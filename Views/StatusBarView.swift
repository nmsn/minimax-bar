import SwiftUI

struct StatusBarView: View {
    let usageData: UsageData?

    private var dailyPercent: String {
        guard let data = usageData else { return "70%" }
        return "\(Int(data.dailyUsedPercentage * 100))%"
    }

    private var weeklyPercent: String {
        guard let data = usageData else { return "90%" }
        return "\(Int(data.weeklyUsedPercentage * 100))%"
    }

    private var statusColor: Color {
        guard let data = usageData, data.dailyTotal > 0 else { return .green }
        let remainingRatio = Double(data.dailyRemaining) / Double(data.dailyTotal)
        if remainingRatio < 0.1 {
            return .red
        } else if remainingRatio < 0.5 {
            return .yellow
        } else {
            return .green
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "circle.fill")
                .font(.system(size: 12))
                .frame(width: 12)
                .foregroundColor(statusColor)

            VStack(alignment: .leading, spacing: 0) {
                Text(dailyPercent)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                Text(weeklyPercent)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 4)
        .frame(width: 40, height: 22, alignment: .leading)
    }
}

#Preview {
    StatusBarView(usageData: nil)
}
