# MiniMaxBar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app showing nested ring progress for MiniMax daily (5hr) and weekly usage, with popover showing detailed stats.

**Architecture:** SwiftUI MenuBarExtra (macOS 14+) with MVVM pattern. Two main views: StatusBarView (rings) and PopoverContentView (detailed stats). API service handles MiniMax auth and data fetching.

**Tech Stack:** Swift 5.9+, SwiftUI, URLSession, XcodeGen

---

## File Structure

```
MiniMaxBar/
├── project.yml                      # XcodeGen configuration
├── MiniMaxBar/
│   ├── App/
│   │   └── MiniMaxBarApp.swift      # @main entry point
│   ├── Models/
│   │   └── UsageData.swift          # Usage data model
│   ├── Services/
│   │   ├── MiniMaxAPIService.swift  # API requests
│   │   └── ConfigService.swift      # Token config read/write
│   ├── ViewModels/
│   │   └── UsageViewModel.swift    # Business logic + state
│   ├── Views/
│   │   ├── StatusBarView.swift      # Menu bar ring view
│   │   ├── RingProgressView.swift   # Reusable ring component
│   │   └── PopoverContentView.swift # Popover detailed view
│   └── Resources/
│       └── Assets.xcassets/        # App icon
└── SPEC.md                          # Symlink to design spec
```

---

## Task 1: Project Setup

**Files:**
- Create: `MiniMaxBar/project.yml`
- Create: `MiniMaxBar/MiniMaxBar/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `MiniMaxBar/MiniMaxBar/Resources/Assets.xcassets/Contents.json`
- Create: `SPEC.md` (symlink to design spec)

- [ ] **Step 1: Create project.yml for XcodeGen**

```yaml
name: MiniMaxBar
options:
  bundleIdPrefix: com.minimax
  deploymentTarget:
    macOS: "14.0"
settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "14.0"
    CODE_SIGN_IDENTITY: "-"
    CODE_SIGNING_REQUIRED: NO
    CODE_SIGN_ENTITLEMENTS: ""

targets:
  MiniMaxBar:
    type: application
    platform: macOS
    sources:
      - path: MiniMaxBar
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.minimax.statusbar
        INFOPLIST_GENERATION_MODE: GeneratedFile
        INFOPLIST_KEY_CFBASEDisplayName: MiniMaxBar
        INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.utilities
        GENERATE_INFOPLIST_FILE: YES
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
```

- [ ] **Step 2: Create Assets.xcassets Contents.json**

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 3: Create AppIcon.appiconset Contents.json**

```json
{
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Create SPEC.md symlink**

Run: `ln -s docs/superpowers/specs/2026-04-12-minimax-status-bar-design.md SPEC.md`

- [ ] **Step 5: Generate Xcode project**

Run: `cd MiniMaxBar && xcodegen generate`

- [ ] **Step 6: Commit**

```bash
git add MiniMaxBar/project.yml MiniMaxBar/MiniMaxBar/Resources SPEC.md
git commit -m "feat: scaffold MiniMaxBar project with XcodeGen

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: UsageData Model

**Files:**
- Create: `MiniMaxBar/MiniMaxBar/Models/UsageData.swift`

- [ ] **Step 1: Write UsageData model**

```swift
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
    let startTime: String?
    let endTime: String?
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
```

- [ ] **Step 2: Commit**

```bash
git add MiniMaxBar/MiniMaxBar/Models/UsageData.swift
git commit -m "feat: add UsageData model and API response types

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: ConfigService

**Files:**
- Create: `MiniMaxBar/MiniMaxBar/Services/ConfigService.swift`

- [ ] **Step 1: Write ConfigService**

```swift
import Foundation

final class ConfigService {
    static let shared = ConfigService()

    private let configPath: URL
    private var cachedToken: String?
    private var cachedGroupId: String?

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configPath = home.appendingPathComponent(".minimax-config.json")
        loadConfig()
    }

    var token: String? {
        get { cachedToken }
        set {
            cachedToken = newValue
            saveConfig()
        }
    }

    var groupId: String? {
        get { cachedGroupId }
        set {
            cachedGroupId = newValue
            saveConfig()
        }
    }

    var isConfigured: Bool {
        cachedToken != nil
    }

    private func loadConfig() {
        guard FileManager.default.fileExists(atPath: configPath.path) else { return }

        do {
            let data = try Data(contentsOf: configPath)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                cachedToken = json["token"] as? String
                cachedGroupId = json["groupId"] as? String
            }
        } catch {
            print("ConfigService: Failed to load config: \(error)")
        }
    }

    private func saveConfig() {
        var json: [String: Any] = [:]
        if let token = cachedToken {
            json["token"] = token
        }
        if let groupId = cachedGroupId {
            json["groupId"] = groupId
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try data.write(to: configPath)
        } catch {
            print("ConfigService: Failed to save config: \(error)")
        }
    }

    func setCredentials(token: String, groupId: String?) {
        self.cachedToken = token
        self.cachedGroupId = groupId
        saveConfig()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MiniMaxBar/MiniMaxBar/Services/ConfigService.swift
git commit -m "feat: add ConfigService for token storage

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: MiniMaxAPIService

**Files:**
- Create: `MiniMaxBar/MiniMaxBar/Services/MiniMaxAPIService.swift`

- [ ] **Step 1: Write MiniMaxAPIService**

```swift
import Foundation

enum APIError: Error, LocalizedError {
    case notConfigured
    case invalidResponse
    case networkError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "未配置 Token，请先配置"
        case .invalidResponse:
            return "无效的响应数据"
        case .networkError(let msg):
            return "网络错误: \(msg)"
        case .unauthorized:
            return "认证失败，请检查 Token"
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
            throw APIError.networkError("HTTP \(httpResponse.statusCode)")
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
        let hours = resetMs / (1000 * 60 * 60)
        let minutes = (resetMs % (1000 * 60 * 60)) / (1000 * 60)

        var resetTimeFormatted = "\(hours)小时\(minutes)分后重置"
        if hours == 0 && minutes == 0 {
            resetTimeFormatted = "即将重置"
        }

        return UsageData(
            modelName: model.modelName ?? "MiniMax-M2",
            dailyRemaining: dailyRemaining,
            dailyTotal: dailyTotal,
            dailyPercentage: dailyPercentage,
            dailyResetTime: resetTimeFormatted,
            dailyResetMs: resetMs,
            weeklyRemaining: weeklyRemaining,
            weeklyTotal: weeklyTotal,
            weeklyPercentage: weeklyPercentage,
            weeklyResetTime: "周日 00:00",
            expiryDate: nil,
            isHealthy: dailyPercentage < 0.85
        )
    }

    func clearCache() {
        cache = nil
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MiniMaxBar/MiniMaxBar/Services/MiniMaxAPIService.swift
git commit -m "feat: add MiniMaxAPIService for fetching usage data

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: UsageViewModel

**Files:**
- Create: `MiniMaxBar/MiniMaxBar/ViewModels/UsageViewModel.swift`

- [ ] **Step 1: Write UsageViewModel**

```swift
import Foundation
import SwiftUI

@MainActor
@Observable
final class UsageViewModel {
    var usageData: UsageData?
    var errorMessage: String?
    var isLoading: Bool = false
    var isConfigured: Bool = false

    private var timer: Timer?

    init() {
        isConfigured = ConfigService.shared.isConfigured
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchUsage()
            }
        }
        Task {
            await fetchUsage()
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    func fetchUsage() async {
        guard ConfigService.shared.isConfigured else {
            isConfigured = false
            errorMessage = "未配置 Token"
            return
        }

        isConfigured = true
        isLoading = true
        errorMessage = nil

        do {
            let data = try await MiniMaxAPIService.shared.fetchUsage()
            self.usageData = data
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await fetchUsage()
    }

    deinit {
        timer?.invalidate()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MiniMaxBar/MiniMaxBar/ViewModels/UsageViewModel.swift
git commit -m "feat: add UsageViewModel with auto-refresh

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: RingProgressView

**Files:**
- Create: `MiniMaxBar/MiniMaxBar/Views/RingProgressView.swift`

- [ ] **Step 1: Write RingProgressView**

```swift
import SwiftUI

struct RingProgressView: View {
    let progress: Double  // 0.0 = empty, 1.0 = full
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
```

- [ ] **Step 2: Commit**

```bash
git add MiniMaxBar/MiniMaxBar/Views/RingProgressView.swift
git commit -m "feat: add RingProgressView reusable component

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: StatusBarView

**Files:**
- Create: `MiniMaxBar/MiniMaxBar/Views/StatusBarView.swift`

- [ ] **Step 1: Write StatusBarView**

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add MiniMaxBar/MiniMaxBar/Views/StatusBarView.swift
git commit -m "feat: add StatusBarView for menu bar rings

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: PopoverContentView

**Files:**
- Create: `MiniMaxBar/MiniMaxBar/Views/PopoverContentView.swift`

- [ ] **Step 1: Write PopoverContentView**

```swift
import SwiftUI

struct PopoverContentView: View {
    @Bindable var viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection

            if let error = viewModel.errorMessage {
                errorSection(error)
            } else if let data = viewModel.usageData {
                usageSection(data)
            } else if viewModel.isLoading {
                loadingSection
            } else {
                emptySection
            }

            Spacer()

            footerSection
        }
        .padding()
        .frame(width: 280, height: 240)
    }

    private var headerSection: some View {
        HStack {
            Text("MiniMax 使用状态")
                .font(.headline)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("⚠️ 错误")
                .foregroundColor(.red)
                .font(.subheadline.bold())
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private func usageSection(_ data: UsageData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前模型: \(data.modelName)")
                .font(.subheadline)

            Divider()

            dailySection(data)
            weeklySection(data)

            if let expiry = data.expiryDate {
                expirySection(expiry)
            }

            statusSection(data)
        }
    }

    private func dailySection(_ data: UsageData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("日 (5小时窗口)", systemImage: "sun.max")
                .font(.caption.bold())
                .foregroundColor(.orange)

            HStack {
                Text("剩余: \(data.dailyRemaining)/\(data.dailyTotal) 次")
                    .font(.caption)
                Spacer()
            }

            Text("重置: \(data.dailyResetTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }

    private func weeklySection(_ data: UsageData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("周", systemImage: "calendar")
                .font(.caption.bold())
                .foregroundColor(.blue)

            HStack {
                Text("剩余: \(data.weeklyRemaining)/\(data.weeklyTotal) 次")
                    .font(.caption)
                Spacer()
            }

            Text("重置: \(data.weeklyResetTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }

    private func expirySection(_ date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"

        return HStack {
            Text("套餐到期: \(formatter.string(from: date))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func statusSection(_ data: UsageData) -> some View {
        HStack {
            Text(data.statusText)
                .font(.caption.bold())
                .foregroundColor(data.isHealthy ? .green : .red)
            Spacer()
        }
    }

    private var loadingSection: some View {
        VStack {
            Spacer()
            ProgressView("加载中...")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("未配置")
                .font(.subheadline.bold())
            Text("请先配置 MiniMax Token")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var footerSection: some View {
        HStack {
            Button(action: {
                Task {
                    await viewModel.refresh()
                }
            }) {
                Label("刷新", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Spacer()

            if !viewModel.isConfigured {
                Button(action: openConfig) {
                    Label("设置 Token", systemImage: "gear")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func openConfig() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configPath = home.appendingPathComponent(".minimax-config.json")

        let message = """
        请在 ~/.minimax-config.json 配置 Token:

        {
            "token": "your_token_here"
        }

        获取 Token: https://platform.minimaxi.com/user-center/payment/coding-plan
        """

        let alert = NSAlert()
        alert.messageText = "配置 MiniMax Token"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开配置目录")
        alert.addButton(withTitle: "好的")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.selectFile(configPath.path, inFileViewerRootedAtPath: home.path)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MiniMaxBar/MiniMaxBar/Views/PopoverContentView.swift
git commit -m "feat: add PopoverContentView with detailed stats

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: MiniMaxBarApp

**Files:**
- Create: `MiniMaxBar/MiniMaxBar/App/MiniMaxBarApp.swift`

- [ ] **Step 1: Write MiniMaxBarApp**

```swift
import SwiftUI

@main
struct MiniMaxBarApp: App {
    @State private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(viewModel: viewModel)
        } label: {
            StatusBarView(usageData: viewModel.usageData)
        }
        .menuBarExtraStyle(.window)
        .onAppear {
            viewModel.startAutoRefresh()
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MiniMaxBar/MiniMaxBar/App/MiniMaxBarApp.swift
git commit -m "feat: add MiniMaxBarApp entry point with MenuBarExtra

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 10: Build Verification

**Files:**
- Verify build succeeds

- [ ] **Step 1: Generate project and build**

Run: `cd MiniMaxBar && xcodegen generate && xcodebuild -project MiniMaxBar.xcodeproj -scheme MiniMaxBar -configuration Debug build 2>&1 | tail -30`

Expected: BUILD SUCCEEDED

- [ ] **Step 2: If build fails, diagnose and fix**

Common issues:
- macOS 14.0 not available → check deployment target
- Missing imports → add missing SwiftUI/Foundation imports

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: complete MiniMaxBar implementation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Self-Review Checklist

- [x] All 10 tasks defined with exact file paths
- [x] Each step includes actual code (no placeholders)
- [x] Uses `@Observable` macro (iOS 17/macOS 14+ pattern)
- [x] API endpoint matches reference project
- [x] Ring progress shows remaining (1 - usedPercentage)
- [x] Color logic matches spec (85%/60% thresholds)
- [x] Auto-refresh every 30 seconds
- [x] Manual refresh button in popover
- [x] Token config path matches reference (~/.minimax-config.json)
