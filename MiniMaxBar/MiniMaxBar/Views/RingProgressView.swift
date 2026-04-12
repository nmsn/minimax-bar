import SwiftUI

struct RingProgressView: View {
    let progress: Double  // 0.0 = empty, 1.0 = full (remaining percentage)
    let lineWidth: CGFloat
    let radius: CGFloat
    let color: Color

    init(progress: Double, radius: CGFloat, lineWidth: CGFloat, color: Color = .green) {
        self.progress = min(max(progress, 0), 1)
        self.radius = radius
        self.lineWidth = lineWidth
        self.color = color
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
            .frame(width: radius * 2, height: radius * 2)
    }
}

struct NestedRingsView: View {
    let dailyProgress: Double  // daily remaining percentage
    let weeklyProgress: Double  // weekly remaining percentage
    let dailyColor: Color
    let weeklyColor: Color

    private let dailyRadius: CGFloat = 6
    private let weeklyRadius: CGFloat = 9
    private let dailyLineWidth: CGFloat = 2
    private let weeklyLineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            // Outer ring (weekly)
            RingProgressView(
                progress: weeklyProgress,
                radius: weeklyRadius,
                lineWidth: weeklyLineWidth,
                color: weeklyColor
            )

            // Inner ring (daily)
            RingProgressView(
                progress: dailyProgress,
                radius: dailyRadius,
                lineWidth: dailyLineWidth,
                color: dailyColor
            )

            // Center icon placeholder
            Circle()
                .fill(Color.primary.opacity(0.7))
                .frame(width: 4, height: 4)
        }
        .frame(width: 24, height: 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        NestedRingsView(
            dailyProgress: 0.7,
            weeklyProgress: 0.5,
            dailyColor: .green,
            weeklyColor: .blue
        )

        NestedRingsView(
            dailyProgress: 0.3,
            weeklyProgress: 0.15,
            dailyColor: .red,
            weeklyColor: .orange
        )
    }
    .padding()
}