# Multi-Platform Support Design

**Date:** 2026-04-30
**Status:** Draft
**App Rename:** MiniMaxBar → QuotaBar

## Overview

Expand the existing MiniMax-only menu bar app into a multi-platform quota/usage tracker called **QuotaBar**. The app will support multiple AI platforms (MiniMax, DeepSeek, and future platforms) with a unified protocol-based architecture. Users configure each platform independently, the status bar shows one platform at a time (switchable), and the popover displays all configured platforms.

## Goals

1. Support multiple AI platforms with different data models (MiniMax: daily/weekly quotas, DeepSeek: monetary balance)
2. Status bar shows a single platform, switchable via right-click menu or popover click
3. Popover displays all configured platforms' detailed usage
4. Per-platform config files with simple API key configuration (no auto-scanning)
5. Ship config templates so users only need to fill in their API key
6. Protocol-based architecture for easy platform addition
7. TDD-driven development with comprehensive test coverage
8. Rename app from MiniMaxBar to QuotaBar

## Architecture

### Directory Structure

```
App/
  main.swift
  AppDelegate.swift
  Info.plist
Models/
  PlatformProtocol.swift        -- PlatformType enum, PlatformUsageData, UsageMetric, PlatformConfigData
  UsageData.swift               -- (kept for backward compatibility, used by MiniMax internally)
Services/
  ConfigService.swift           -- global config (display mode, active platform, locale)
  NetworkService.swift          -- protocol + URLSession implementation (for testability)
  Platforms/
    PlatformConfigStore.swift   -- per-platform config file management
    PlatformManager.swift       -- orchestrates all platform services
    MiniMaxPlatform/
      MiniMaxAPIService.swift   -- refactored from existing
    DeepSeekPlatform/
      DeepSeekAPIService.swift  -- new
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
  StatusBarController.swift     -- updated for multi-platform
  RightClickStatusBarView.swift
ViewModels/
  PlatformViewModel.swift       -- replaces UsageViewModel
Views/
  PopoverContentView.swift      -- redesigned for multi-platform
  StatusBarView.swift           -- updated for PlatformUsageData
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

### Core Protocols and Data Models

```swift
// Platform identifier
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

// Typed errors for TDD assertions
enum PlatformError: Error, Equatable {
    case notConfigured(PlatformType)
    case invalidResponse(PlatformType)
    case networkError(PlatformType, String)
    case unauthorized(PlatformType)
    case decodingError(PlatformType, String)
}

// Unified usage data — every platform produces this
struct PlatformUsageData: Equatable {
    let platform: PlatformType
    let displayName: String
    let metrics: [UsageMetric]
    let lastUpdated: Date
    let isHealthy: Bool
}

// A single metric row
struct UsageMetric: Equatable {
    let label: String           // "Daily Quota", "Balance"
    let currentValue: Double    // 45, 4.50
    let totalValue: Double?     // 100, nil for balance-only
    let unit: String            // "requests", "USD"
    let resetTime: Date?        // nil for balance
}

// Lightweight config snapshot passed to API services (decoupled from PlatformConfigStore)
struct PlatformConfigData {
    let platformType: PlatformType
    let apiBaseURL: String
    let authHeader: String
    let authPrefix: String
    let apiKey: String
}

// Network abstraction for testability
protocol NetworkService {
    func data(from request: URLRequest) async throws -> (Data, URLResponse)
}

// Default implementation wraps URLSession
class URLSessionNetworkService: NetworkService {
    func data(from request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

// Per-platform API service protocol
protocol PlatformAPIService {
    var platformType: PlatformType { get }
    func fetchUsage(config: PlatformConfigData, network: NetworkService) async throws -> PlatformUsageData
    func clearCache()
}
```

### Config Templates

Ship default templates in `Resources/ConfigTemplates/`:

**minimax.template.json:**
```json
{
  "api_base_url": "https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains",
  "auth_header": "Authorization",
  "auth_prefix": "Bearer ",
  "api_key": ""
}
```

**deepseek.template.json:**
```json
{
  "api_base_url": "https://api.deepseek.com",
  "auth_header": "Authorization",
  "auth_prefix": "Bearer ",
  "api_key": ""
}
```

### Config Service

**Global config** (`ConfigService`):
- `displayMode: DisplayMode` (.used / .remaining)
- `activePlatform: PlatformType` (currently shown in status bar)
- `locale: String` ("en" / "zh-Hans")
- Persists to `UserDefaults`

**Per-platform config** (`PlatformConfigStore`):
- Config file: `~/.quotabar-{platform}.json`
- Fields: `apiBaseURL`, `authHeader`, `authPrefix`, `apiKey`
- On first access: copies template from bundle to config path
- `isConfigured`: true when `apiKey` is non-empty
- `toConfigData() -> PlatformConfigData` — creates lightweight snapshot for API services
- Migration: `~/.minimax-config.json` → `~/.quotabar-minimax.json` (reads `"token"` field from old JSON, maps to `api_key`)

### Platform Services

**MiniMaxAPIService** (refactored from existing):
- Receives `PlatformConfigData` and `NetworkService` via `fetchUsage()`
- Existing API call logic preserved
- Maps `APIResponse` → `PlatformUsageData` with metrics:
  - `UsageMetric("Daily", usedCount, totalCount, "requests", resetTime)`
  - `UsageMetric("Weekly", usedCount, totalCount, "requests", resetTime)`

**DeepSeekAPIService** (new):

The DeepSeek balance API:
- **Endpoint:** `GET https://api.deepseek.com/user/balance`
- **Auth:** `Authorization: Bearer <api_key>`
- **Response schema:**
  ```json
  {
    "is_available": true,
    "balance": "4.50",
    "currency": "USD"
  }
  ```
- **Field details:**
  - `is_available` (bool): whether the account can still make API calls
  - `balance` (string): remaining balance as a decimal string
  - `currency` (string): currency code, e.g. "USD" or "CNY"
- Maps to `PlatformUsageData` with metrics:
  - `UsageMetric("Balance", balance, nil, currency, nil)`
- `isHealthy` = `is_available && balance > 0`

**PlatformManager**:
- `static let shared` singleton
- Holds all `PlatformAPIService` instances keyed by `PlatformType`
- Holds a `NetworkService` instance (defaults to `URLSessionNetworkService`)
- Dependency injection: `init(networkService: NetworkService)` for testing
- `fetchUsage(for:)` — single platform, reads config from `PlatformConfigStore`
- `fetchAllUsage()` — parallel fetch using `async let` for all configured platforms; results collected via `TaskGroup`
- `configuredPlatforms()` — list of platforms with non-empty API keys
- Cancellation: on `fetchAllUsage()`, a `Task` is used; callers can cancel via `task.cancel()` when switching platforms

### ViewModel

`PlatformViewModel` replaces `UsageViewModel`:

```swift
@MainActor class PlatformViewModel: ObservableObject {
    @Published var platformData: [PlatformType: PlatformUsageData] = [:]
    @Published var platformErrors: [PlatformType: PlatformError] = [:]
    @Published var isLoading: [PlatformType: Bool] = [:]
    @Published var activePlatform: PlatformType
    @Published var showingConfig: Bool = false
    @Published var configPlatform: PlatformType?
    @Published var apiKeyInput: String = ""

    // Injected dependencies for testability
    private let platformManager: PlatformManager
    private let configService: ConfigService

    init(platformManager: PlatformManager = .shared, configService: ConfigService = .shared)

    func startAutoRefresh()     // 30s timer, fetches all configured platforms
    func stopAutoRefresh()
    func fetchAllUsage()        // uses TaskGroup internally
    func fetchUsage(for: PlatformType)
    func switchActivePlatform(_ platform: PlatformType)
    func configureAPIKey(for platform: PlatformType)
    func saveAPIKey(for platform: PlatformType)
    func cancelConfig()
    func cleanup()              // cancels in-flight tasks + stops timer
}
```

### UI

**StatusBarView**:
- Takes `PlatformUsageData?` instead of `UsageData?`
- Shows first metric's percentage/balance based on platform type
- Adapts display format: percentage for quota-based, dollar amount for balance-based

**PopoverContentView** (280 x dynamic height):
- Header: "QuotaBar" + refresh spinner
- Platform navigator: tabs showing all configured platforms, active platform highlighted
- Each platform section: metric cards (same style as current MiniMax)
- Unconfigured platforms: "Configure API Key" button
- Footer: refresh + settings gear

**Right-click menu**:
- Display Settings submenu (Show Used / Show Remaining)
- Platform submenu:
  - Checkmark on active platform
  - List of configured platforms
  - "Configure..." option
- Language submenu (English / 简体中文)
- Check for Updates
- Quit

### Platform Switching

- **Right-click menu**: Select platform → updates `ConfigService.activePlatform` → status bar refreshes
- **Popover click**: Click platform tab → same as right-click menu selection
- Both paths go through `PlatformViewModel.switchActivePlatform()`
- On switch: cancel any in-flight fetch for the previous active platform

### App Rename

- `project.yml`: target `quota-bar`, product `QuotaBar`, bundle ID `com.quota.statusbar`
- All I18n strings: "MiniMax Usage" → "QuotaBar"
- Config path: `~/.quotabar-*.json`
- README updates
- Git repo rename (optional, user's choice)

## Data Flow

1. **App Launch**: AppDelegate creates `PlatformViewModel`, loads all platform configs, starts auto-refresh
2. **Auto-refresh (30s)**: `PlatformViewModel.fetchAllUsage()` → `PlatformManager.fetchAllUsage()` → parallel `fetchUsage()` per configured platform via `TaskGroup`
3. **Status bar update**: Delegate callback → `StatusBarController.update()` with active platform's data
4. **Platform switch**: User action → `switchActivePlatform()` → cancel in-flight tasks → update `ConfigService.activePlatform` → immediate status bar refresh
5. **Config flow**: User clicks configure → shows API key input → saves to `PlatformConfigStore` → triggers fetch

## Migration

1. Detect `~/.minimax-config.json` on first launch
2. Read existing `"token"` field (JSON key is `"token"`, confirmed from current `ConfigService.loadConfig()`)
3. Create `~/.quotabar-minimax.json` with token as `api_key` and template defaults for `api_base_url`, `auth_header`, `auth_prefix`
4. Delete old config file (or rename to `.bak`)

## Testing Strategy

TDD approach — write tests before implementation:

1. **PlatformConfigStore tests**: load/save API key, template copying, migration from old format
2. **MiniMaxAPIService tests**: response parsing, cache, error handling (using `MockNetworkService`)
3. **DeepSeekAPIService tests**: balance parsing, error handling (using `MockNetworkService`)
4. **PlatformManager tests**: single/all fetch, partial failures, platform registration (inject `MockNetworkService`)
5. **PlatformViewModel tests**: platform switching, config UI state, auto-refresh (inject `MockPlatformManager`)
6. **ConfigService tests**: global settings persistence
7. **NetworkService tests**: verify `URLSessionNetworkService` wraps URLSession correctly

**Mocking approach:**
- `MockNetworkService` implements `NetworkService`, returns pre-configured `Data`/`URLResponse` pairs
- `MockPlatformAPIService` implements `PlatformAPIService`, returns pre-built `PlatformUsageData`
- `MockPlatformConfigStore` implements a lightweight config for testing without filesystem
- All mocks injected via initializer parameters (no global state in tests)

## Platform Addition Guide

To add a new platform:
1. Add case to `PlatformType` enum
2. Create `Resources/ConfigTemplates/{platform}.template.json`
3. Create `Services/Platforms/{Platform}Platform/{Platform}APIService.swift` implementing `PlatformAPIService`
4. Register in `PlatformManager`
5. Add I18n strings
6. Write tests first (TDD)
