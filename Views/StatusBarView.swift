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

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "circle.fill")
                .font(.system(size: 9))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 0) {
                Text(dailyPercent)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                Text(weeklyPercent)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
            }
        }
        .padding(.horizontal, 6)
        .frame(width: 52, height: 22, alignment: .leading)
    }
}

#Preview {
    StatusBarView(usageData: nil)
}
