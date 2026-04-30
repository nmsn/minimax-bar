# 多平台支持设计方案

**日期:** 2026-04-30
**状态:** 草稿
**应用重命名:** MiniMaxBar → QuotaBar

## 概述

将现有的 MiniMax 专用菜单栏应用扩展为多平台配额/用量跟踪工具 **QuotaBar**。支持多个 AI 平台（MiniMax、DeepSeek 及未来平台），采用统一的协议化架构。用户独立配置每个平台，状态栏一次显示一个平台（可切换），浮窗显示所有已配置平台的详细信息。

## 目标

1. 支持多个 AI 平台，适配不同数据模型（MiniMax：日/周配额，DeepSeek：余额）
2. 状态栏显示单个平台，支持右键菜单或浮窗点击切换
3. 浮窗显示所有已配置平台的详细用量
4. 每个平台独立配置文件，仅需填写 API Key（不扫描本地文件）
5. 内置配置模板，用户只需填写 Key 即可使用
6. 协议化架构，方便新增平台
7. TDD 驱动开发，全面测试覆盖
8. 应用从 MiniMaxBar 重命名为 QuotaBar

## 架构

### 目录结构

```
App/
  main.swift
  AppDelegate.swift
  Info.plist
Models/
  PlatformProtocol.swift        -- PlatformType 枚举、PlatformUsageData、UsageMetric、PlatformConfigData
  UsageData.swift               -- （保留，MiniMax 内部使用）
Services/
  ConfigService.swift           -- 全局配置（显示模式、当前平台、语言）
  NetworkService.swift          -- 网络协议 + URLSession 实现（可测试性）
  Platforms/
    PlatformConfigStore.swift   -- 单平台配置文件管理
    PlatformManager.swift       -- 平台服务编排
    MiniMaxPlatform/
      MiniMaxAPIService.swift   -- 从现有代码重构
    DeepSeekPlatform/
      DeepSeekAPIService.swift  -- 新增
  I18nService.swift
  UpdateService.swift
Resources/
  ConfigTemplates/
    minimax.template.json
    deepseek.template.json
  en.json
  zh-Hans.json
  Assets.xcassets/
StatusBar/
  StatusBarController.swift     -- 适配多平台
  RightClickStatusBarView.swift
ViewModels/
  PlatformViewModel.swift       -- 替换 UsageViewModel
Views/
  PopoverContentView.swift      -- 重新设计，支持多平台
  StatusBarView.swift           -- 适配 PlatformUsageData
  PasteableTextField.swift
Tests/
  Platforms/
    MiniMaxPlatformTests.swift
    DeepSeekPlatformTests.swift
  Services/
    ConfigServiceTests.swift
    PlatformManagerTests.swift
    PlatformConfigStoreTests.swift
    NetworkServiceTests.swift
  ViewModels/
    PlatformViewModelTests.swift
  Mocks/
    MockPlatformAPIService.swift
    MockPlatformConfigStore.swift
    MockNetworkService.swift
```

### 核心协议与数据模型

```swift
// 平台标识
enum PlatformType: String, Codable, CaseIterable {
    case minimax
    case deepseek

    var displayName: String {
        switch self {
        case .minimax: return "MiniMax"
        case .deepseek: return "DeepSeek"
        }
    }
}

// 类型化错误，便于 TDD 断言
enum PlatformError: Error, Equatable {
    case notConfigured(PlatformType)
    case invalidResponse(PlatformType)
    case networkError(PlatformType, String)
    case unauthorized(PlatformType)
    case decodingError(PlatformType, String)
}

// 统一用量数据 — 每个平台都产出此结构
struct PlatformUsageData: Equatable {
    let platform: PlatformType
    let displayName: String
    let metrics: [UsageMetric]
    let lastUpdated: Date
    let isHealthy: Bool
}

// 单条指标
struct UsageMetric: Equatable {
    let label: String           // "Daily Quota", "Balance"
    let currentValue: Double    // 45, 4.50
    let totalValue: Double?     // 100, 余额类为 nil
    let unit: String            // "requests", "USD"
    let resetTime: Date?        // 余额类为 nil
}

// 轻量配置快照，传递给 API 服务（与 PlatformConfigStore 解耦）
struct PlatformConfigData {
    let platformType: PlatformType
    let apiBaseURL: String
    let authHeader: String
    let authPrefix: String
    let apiKey: String
}

// 网络抽象层，便于测试
protocol NetworkService {
    func data(from request: URLRequest) async throws -> (Data, URLResponse)
}

// 默认实现，封装 URLSession
class URLSessionNetworkService: NetworkService {
    func data(from request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

// 平台 API 服务协议
protocol PlatformAPIService {
    var platformType: PlatformType { get }
    func fetchUsage(config: PlatformConfigData, network: NetworkService) async throws -> PlatformUsageData
    func clearCache()
}
```

### 配置模板

应用内置默认模板，位于 `Resources/ConfigTemplates/`：

**minimax.template.json：**
```json
{
  "api_base_url": "https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains",
  "auth_header": "Authorization",
  "auth_prefix": "Bearer ",
  "api_key": ""
}
```

**deepseek.template.json：**
```json
{
  "api_base_url": "https://api.deepseek.com",
  "auth_header": "Authorization",
  "auth_prefix": "Bearer ",
  "api_key": ""
}
```

### 配置服务

**全局配置**（`ConfigService`）：
- `displayMode: DisplayMode`（.used / .remaining）
- `activePlatform: PlatformType`（状态栏当前显示的平台）
- `locale: String`（"en" / "zh-Hans"）
- 持久化到 `UserDefaults`

**单平台配置**（`PlatformConfigStore`）：
- 配置文件路径：`~/.quotabar-{platform}.json`
- 字段：`apiBaseURL`、`authHeader`、`authPrefix`、`apiKey`
- 首次访问时从 bundle 复制模板到配置路径
- `isConfigured`：`apiKey` 非空时为 true
- `toConfigData() -> PlatformConfigData`：创建轻量快照供 API 服务使用
- 迁移：`~/.minimax-config.json` → `~/.quotabar-minimax.json`（读取旧 JSON 中的 `"token"` 字段，映射为 `api_key`）

### 平台服务

**MiniMaxAPIService**（从现有代码重构）：
- 通过 `fetchUsage()` 接收 `PlatformConfigData` 和 `NetworkService`
- 保留现有 API 调用逻辑
- 将 `APIResponse` 映射为 `PlatformUsageData`，包含指标：
  - `UsageMetric("Daily", usedCount, totalCount, "requests", resetTime)`
  - `UsageMetric("Weekly", usedCount, totalCount, "requests", resetTime)`

**DeepSeekAPIService**（新增）：

DeepSeek 余额 API：
- **接口：** `GET https://api.deepseek.com/user/balance`
- **认证：** `Authorization: Bearer <api_key>`
- **响应结构：**
  ```json
  {
    "is_available": true,
    "balance": "4.50",
    "currency": "USD"
  }
  ```
- **字段说明：**
  - `is_available`（布尔）：账户是否仍可调用 API
  - `balance`（字符串）：剩余余额，十进制字符串
  - `currency`（字符串）：货币代码，如 "USD" 或 "CNY"
- 映射为 `PlatformUsageData`，包含指标：
  - `UsageMetric("Balance", balance, nil, currency, nil)`
- `isHealthy` = `is_available && balance > 0`

**PlatformManager**：
- `static let shared` 单例
- 持有所有 `PlatformAPIService` 实例，按 `PlatformType` 索引
- 持有 `NetworkService` 实例（默认 `URLSessionNetworkService`）
- 依赖注入：`init(networkService: NetworkService)` 用于测试
- `fetchUsage(for:)` — 单平台，从 `PlatformConfigStore` 读取配置
- `fetchAllUsage()` — 使用 `async let` 并行获取所有已配置平台；通过 `TaskGroup` 收集结果
- `configuredPlatforms()` — 返回已配置 API Key 的平台列表
- 取消机制：`fetchAllUsage()` 使用 `Task`，调用方可在切换平台时通过 `task.cancel()` 取消

### ViewModel

`PlatformViewModel` 替换 `UsageViewModel`：

```swift
@MainActor class PlatformViewModel: ObservableObject {
    @Published var platformData: [PlatformType: PlatformUsageData] = [:]
    @Published var platformErrors: [PlatformType: PlatformError] = [:]
    @Published var isLoading: [PlatformType: Bool] = [:]
    @Published var activePlatform: PlatformType
    @Published var showingConfig: Bool = false
    @Published var configPlatform: PlatformType?
    @Published var apiKeyInput: String = ""

    // 依赖注入，便于测试
    private let platformManager: PlatformManager
    private let configService: ConfigService

    init(platformManager: PlatformManager = .shared, configService: ConfigService = .shared)

    func startAutoRefresh()     // 30 秒定时器，获取所有已配置平台
    func stopAutoRefresh()
    func fetchAllUsage()        // 内部使用 TaskGroup
    func fetchUsage(for: PlatformType)
    func switchActivePlatform(_ platform: PlatformType)
    func configureAPIKey(for platform: PlatformType)
    func saveAPIKey(for platform: PlatformType)
    func cancelConfig()
    func cleanup()              // 取消进行中的任务 + 停止定时器
}
```

### UI 设计

**StatusBarView**：
- 接收 `PlatformUsageData?` 替代 `UsageData?`
- 根据平台类型显示首个指标的百分比或余额
- 自适应显示格式：配额类显示百分比，余额类显示金额

**PopoverContentView**（280 x 动态高度）：
- 头部："QuotaBar" + 刷新旋转图标
- 平台导航：标签页显示所有已配置平台，当前平台高亮
- 每个平台区域：指标卡片（与现有 MiniMax 风格一致）
- 未配置平台：显示"配置 API Key"按钮
- 底部：刷新 + 设置齿轮

**右键菜单**：
- 显示设置子菜单（显示已使用 / 显示剩余）
- 平台子菜单：
  - 当前平台打勾
  - 列出已配置平台
  - "配置..."选项
- 语言子菜单（English / 简体中文）
- 检查更新
- 退出

### 平台切换

- **右键菜单**：选择平台 → 更新 `ConfigService.activePlatform` → 状态栏刷新
- **浮窗点击**：点击平台标签 → 同右键菜单效果
- 两个路径都经过 `PlatformViewModel.switchActivePlatform()`
- 切换时取消前一个平台的进行中请求

### 应用重命名

- `project.yml`：target `quota-bar`，product `QuotaBar`，bundle ID `com.quota.statusbar`
- 所有 I18n 字符串："MiniMax Usage" → "QuotaBar"
- 配置路径：`~/.quotabar-*.json`
- README 更新
- Git 仓库重命名（可选，用户决定）

## 数据流

1. **应用启动**：AppDelegate 创建 `PlatformViewModel`，加载所有平台配置，启动自动刷新
2. **自动刷新（30 秒）**：`PlatformViewModel.fetchAllUsage()` → `PlatformManager.fetchAllUsage()` → 通过 `TaskGroup` 并行获取每个已配置平台
3. **状态栏更新**：委托回调 → `StatusBarController.update()` 传入当前平台数据
4. **平台切换**：用户操作 → `switchActivePlatform()` → 取消进行中的任务 → 更新 `ConfigService.activePlatform` → 立即刷新状态栏
5. **配置流程**：用户点击配置 → 显示 API Key 输入框 → 保存到 `PlatformConfigStore` → 触发获取

## 迁移方案

1. 首次启动时检测 `~/.minimax-config.json`
2. 读取现有 `"token"` 字段（JSON key 为 `"token"`，已从当前 `ConfigService.loadConfig()` 确认）
3. 创建 `~/.quotabar-minimax.json`，将 token 映射为 `api_key`，并填入模板默认的 `api_base_url`、`auth_header`、`auth_prefix`
4. 删除旧配置文件（或重命名为 `.bak`）

## 测试策略

TDD 方式 — 先写测试再实现：

1. **PlatformConfigStore 测试**：加载/保存 API Key、模板复制、旧格式迁移
2. **MiniMaxAPIService 测试**：响应解析、缓存、错误处理（使用 `MockNetworkService`）
3. **DeepSeekAPIService 测试**：余额解析、错误处理（使用 `MockNetworkService`）
4. **PlatformManager 测试**：单平台/全部获取、部分失败、平台注册（注入 `MockNetworkService`）
5. **PlatformViewModel 测试**：平台切换、配置 UI 状态、自动刷新（注入 `MockPlatformManager`）
6. **ConfigService 测试**：全局设置持久化
7. **NetworkService 测试**：验证 `URLSessionNetworkService` 正确封装 URLSession

**Mock 方案：**
- `MockNetworkService` 实现 `NetworkService`，返回预配置的 `Data`/`URLResponse`
- `MockPlatformAPIService` 实现 `PlatformAPIService`，返回预构建的 `PlatformUsageData`
- `MockPlatformConfigStore` 提供轻量配置，不依赖文件系统
- 所有 mock 通过初始化器注入（测试中无全局状态）

## 新增平台指南

添加新平台的步骤：
1. 在 `PlatformType` 枚举中添加新 case
2. 创建 `Resources/ConfigTemplates/{platform}.template.json`
3. 创建 `Services/Platforms/{Platform}Platform/{Platform}APIService.swift` 实现 `PlatformAPIService`
4. 在 `PlatformManager` 中注册
5. 添加 I18n 字符串
6. 先写测试（TDD）
