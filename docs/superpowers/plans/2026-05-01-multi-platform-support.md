# 多平台支持实现计划

> **For agentic workers:** 使用 TDD 驱动开发，每步先写测试再实现。

**目标:** 将 MiniMaxBar 扩展为 QuotaBar，支持多平台配额跟踪

**架构:** 协议化平台抽象，每个平台独立实现 PlatformAPIService 协议

**技术栈:** Swift 5.9, SwiftUI + AppKit, XCTest

---

## 阶段 1: 核心模型与协议

### Task 1.1: 创建平台协议与数据模型

**文件:**
- Create: `Models/PlatformProtocol.swift`
- Create: `Tests/Models/PlatformProtocolTests.swift`

- [ ] 1. 写失败测试

```swift
// Tests/Models/PlatformProtocolTests.swift
import XCTest
@testable import minimax_bar

final class PlatformProtocolTests: XCTestCase {
    func testPlatformTypeDisplayNames() {
        XCTAssertEqual(PlatformType.minimax.displayName, "MiniMax")
        XCTAssertEqual(PlatformType.deepseek.displayName, "DeepSeek")
    }

    func testPlatformUsageDataEquality() {
        let metric = UsageMetric(label: "Balance", currentValue: 10, totalValue: nil, unit: "USD", resetTime: nil)
        let data1 = PlatformUsageData(platform: .deepseek, displayName: "DeepSeek", metrics: [metric], lastUpdated: Date(), isHealthy: true)
        let data2 = PlatformUsageData(platform: .deepseek, displayName: "DeepSeek", metrics: [metric], lastUpdated: Date(), isHealthy: true)
        XCTAssertEqual(data1.platform, data2.platform)
        XCTAssertEqual(data1.metrics, data2.metrics)
    }
}
```

- [ ] 2. 运行测试确认失败
- [ ] 3. 实现 `Models/PlatformProtocol.swift`

```swift
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
```

- [ ] 4. 运行测试确认通过
- [ ] 5. 提交

### Task 1.2: 创建配置模板

**文件:**
- Create: `Resources/ConfigTemplates/minimax.template.json`
- Create: `Resources/ConfigTemplates/deepseek.template.json`

- [ ] 1. 创建 minimax.template.json
- [ ] 2. 创建 deepseek.template.json
- [ ] 3. 提交

---

## 阶段 2: 配置服务

### Task 2.1: PlatformConfigStore

**文件:**
- Create: `Services/Platforms/PlatformConfigStore.swift`
- Create: `Tests/Services/PlatformConfigStoreTests.swift`

- [ ] 1. 写失败测试（加载模板、保存 API Key、迁移旧配置）
- [ ] 2. 运行测试确认失败
- [ ] 3. 实现 PlatformConfigStore
- [ ] 4. 运行测试确认通过
- [ ] 5. 提交

### Task 2.2: 重构 ConfigService

**文件:**
- Modify: `Services/ConfigService.swift`

- [ ] 1. 添加 activePlatform 属性
- [ ] 2. 添加 platformStores 管理
- [ ] 3. 保持向后兼容
- [ ] 4. 提交

---

## 阶段 3: 平台服务

### Task 3.1: MockNetworkService

**文件:**
- Create: `Tests/Mocks/MockNetworkService.swift`

- [ ] 1. 实现 MockNetworkService
- [ ] 2. 提交

### Task 3.2: MiniMaxAPIService 重构

**文件:**
- Modify: `Services/MiniMaxAPIService.swift` → `Services/Platforms/MiniMaxPlatform/MiniMaxAPIService.swift`
- Create: `Tests/Platforms/MiniMaxPlatformTests.swift`

- [ ] 1. 写失败测试（解析 API 响应、缓存、错误处理）
- [ ] 2. 运行测试确认失败
- [ ] 3. 重构 MiniMaxAPIService 实现 PlatformAPIService 协议
- [ ] 4. 运行测试确认通过
- [ ] 5. 提交

### Task 3.3: DeepSeekAPIService

**文件:**
- Create: `Services/Platforms/DeepSeekPlatform/DeepSeekAPIService.swift`
- Create: `Tests/Platforms/DeepSeekPlatformTests.swift`

- [ ] 1. 写失败测试（余额解析、错误处理）
- [ ] 2. 运行测试确认失败
- [ ] 3. 实现 DeepSeekAPIService
- [ ] 4. 运行测试确认通过
- [ ] 5. 提交

### Task 3.4: PlatformManager

**文件:**
- Create: `Services/Platforms/PlatformManager.swift`
- Create: `Tests/Services/PlatformManagerTests.swift`

- [ ] 1. 写失败测试（单平台获取、全部获取、部分失败）
- [ ] 2. 运行测试确认失败
- [ ] 3. 实现 PlatformManager
- [ ] 4. 运行测试确认通过
- [ ] 5. 提交

---

## 阶段 4: ViewModel

### Task 4.1: PlatformViewModel

**文件:**
- Create: `ViewModels/PlatformViewModel.swift`
- Create: `Tests/ViewModels/PlatformViewModelTests.swift`

- [ ] 1. 写失败测试（平台切换、配置流程、自动刷新）
- [ ] 2. 运行测试确认失败
- [ ] 3. 实现 PlatformViewModel
- [ ] 4. 运行测试确认通过
- [ ] 5. 提交

---

## 阶段 5: UI 更新

### Task 5.1: StatusBarView 更新

**文件:**
- Modify: `Views/StatusBarView.swift`

- [ ] 1. 支持 PlatformUsageData 输入
- [ ] 2. 自适应显示格式（百分比 vs 余额）
- [ ] 3. 提交

### Task 5.2: PopoverContentView 重新设计

**文件:**
- Modify: `Views/PopoverContentView.swift`

- [ ] 1. 平台导航标签页
- [ ] 2. 多平台指标卡片
- [ ] 3. 配置 UI
- [ ] 4. 提交

### Task 5.3: StatusBarController 更新

**文件:**
- Modify: `StatusBar/StatusBarController.swift`

- [ ] 1. 平台子菜单
- [ ] 2. 平台切换逻辑
- [ ] 3. 提交

### Task 5.4: AppDelegate 更新

**文件:**
- Modify: `App/AppDelegate.swift`

- [ ] 1. 使用 PlatformViewModel 替换 UsageViewModel
- [ ] 2. 提交

---

## 阶段 6: 应用重命名与迁移

### Task 6.1: 应用重命名

**文件:**
- Modify: `project.yml`
- Modify: I18n 文件

- [ ] 1. 更新 project.yml
- [ ] 2. 更新 I18n 字符串
- [ ] 3. 提交

### Task 6.2: 配置迁移

**文件:**
- Modify: `Services/Platforms/PlatformConfigStore.swift`

- [ ] 1. 实现旧配置迁移逻辑
- [ ] 2. 测试迁移
- [ ] 3. 提交

---

## 阶段 7: 集成与清理

### Task 7.1: 删除旧文件

- [ ] 1. 删除 `Services/MiniMaxAPIService.swift`（已移动）
- [ ] 2. 删除 `ViewModels/UsageViewModel.swift`（已替换）
- [ ] 3. 更新 project.yml 源路径
- [ ] 4. 提交

### Task 7.2: 最终测试

- [ ] 1. 运行完整测试套件
- [ ] 2. 构建验证
- [ ] 3. 提交
