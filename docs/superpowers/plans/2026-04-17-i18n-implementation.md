# Internationalization (i18n) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add language switcher to right-click menu and internationalize all hardcoded Chinese text to support English/Chinese.

**Architecture:** Use a lightweight i18n approach with JSON translation files (en.json, zh-Hans.json) and a shared `I18nService` singleton. SwiftUI Text views get localized strings via `Text()` with static keys. AppKit menu items use `I18nService.shared.translate("key")`.

**Tech Stack:** Swift, SwiftUI, AppKit, JSON-based translation files

---

## File Structure

```
MiniMaxBar/
├── Services/
│   └── I18nService.swift       # NEW: Translation service singleton
├── Resources/
│   ├── en.json                 # NEW: English translations
│   ├── zh-Hans.json            # NEW: Simplified Chinese translations
│   └── translations.json       # NEW: Combined translations loader
├── StatusBar/
│   └── StatusBarController.swift  # MODIFY: i18n in right-click menu
├── Views/
│   └── PopoverContentView.swift  # MODIFY: i18n in popover UI
├── Models/
│   └── UsageData.swift         # MODIFY: i18n in status text
├── App/
│   └── AppDelegate.swift       # MODIFY: inject I18nService setup
```

## Translation Keys (all text to internationalize)

| Key | Chinese | English |
|-----|---------|---------|
| `app.name` | MiniMax 使用状态 | MiniMax Usage |
| `menu.displaySettings` | 显示设置 | Display Settings |
| `menu.showUsed` | 显示已使用 | Show Used |
| `menu.showRemaining` | 显示剩余 | Show Remaining |
| `menu.checkUpdate` | 检查更新 | Check for Updates |
| `menu.quit` | 退出 | Quit |
| `menu.language` | 语言 | Language |
| `menu.lang.en` | English | English |
| `menu.lang.zh` | 简体中文 | 简体中文 |
| `popover.configureToken` | 配置 MiniMax Token | Configure MiniMax Token |
| `popover.tokenConfigured` | Token 已配置 | Token Configured |
| `popover.inputPlaceholder` | 输入你的 Token | Enter your Token |
| `popover.error` | 错误 | Error |
| `popover.notConfigured` | 未配置 | Not Configured |
| `popover.configureFirst` | 请先配置 MiniMax Token | Please configure MiniMax Token first |
| `popover.daily` | 日 (5小时窗口) | Daily (5-hour window) |
| `popover.remaining` | 剩余 | Remaining |
| `popover.reset` | 重置 | Reset |
| `popover.weekly` | 周 | Weekly |
| `popover.expiry` | 套餐到期 | Plan Expiry |
| `popover.normal` | 正常使用 | Normal |
| `popover.low` | 使用量紧张 | Running Low |
| `status.healthy` | 正常使用 | Normal |
| `status.warning` | 注意使用 | Attention |
| `status.critical` | 使用量紧张 | Running Low |
| `reset.hours` | 还剩{hours}小时{minutes}分 | {hours}h {minutes}m remaining |
| `reset.days` | {days}天{hours}小时后重置 | Resets in {days}d {hours}h |

---

## Task 1: Create i18n Infrastructure

**Files:**
- Create: `Services/I18nService.swift`
- Create: `Resources/en.json`
- Create: `Resources/zh-Hans.json`

- [ ] **Step 1: Write failing test**

```swift
// Tests/I18nServiceTests.swift
import XCTest
@testable import MiniMaxBar

final class I18nServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        I18nService.shared.reset()
    }

    func testTranslateReturnsChineseByDefault() {
        I18nService.shared.loadTranslations()
        XCTAssertEqual(I18nService.shared.translate("app.name"), "MiniMax 使用状态")
    }

    func testTranslateReturnsEnglishWhenLocaleIsEn() {
        I18nService.shared.loadTranslations()
        I18nService.shared.currentLocale = "en"
        XCTAssertEqual(I18nService.shared.translate("app.name"), "MiniMax Usage")
    }

    func testLocalePersistsAfterReload() {
        I18nService.shared.loadTranslations()
        I18nService.shared.currentLocale = "en"
        I18nService.shared.saveLocale()
        I18nService.shared.reset()
        I18nService.shared.loadTranslations()
        XCTAssertEqual(I18nService.shared.currentLocale, "en")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter I18nServiceTests` or build-based test verification
Expected: FAIL - I18nService not defined

- [ ] **Step 3: Write minimal I18nService implementation**

```swift
// Services/I18nService.swift
import Foundation

final class I18nService {
    static let shared = I18nService()

    private var translations: [String: [String: String]] = [:]
    private(set) var currentLocale: String = "zh-Hans"

    private init() {}

    func loadTranslations() {
        let locales = ["en", "zh-Hans"]
        for locale in locales {
            if let url = Bundle.main.url(forResource: locale, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                translations[locale] = dict
            }
        }
        loadSavedLocale()
    }

    func translate(_ key: String) -> String {
        return translations[currentLocale]?[key] ?? translations["zh-Hans"]?[key] ?? key
    }

    func setLocale(_ locale: String) {
        currentLocale = locale
        saveLocale()
    }

    private func loadSavedLocale() {
        currentLocale = UserDefaults.standard.string(forKey: "app.locale") ?? "zh-Hans"
    }

    private func saveLocale() {
        UserDefaults.standard.set(currentLocale, forKey: "app.locale")
    }

    func reset() {
        translations = [:]
        currentLocale = "zh-Hans"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Write en.json**

```json
{
    "app.name": "MiniMax Usage",
    "menu.displaySettings": "Display Settings",
    "menu.showUsed": "Show Used",
    "menu.showRemaining": "Show Remaining",
    "menu.checkUpdate": "Check for Updates",
    "menu.quit": "Quit",
    "menu.language": "Language",
    "menu.lang.en": "English",
    "menu.lang.zh": "简体中文",
    "popover.configureToken": "Configure MiniMax Token",
    "popover.tokenConfigured": "Token Configured",
    "popover.inputPlaceholder": "Enter your Token",
    "popover.error": "Error",
    "popover.notConfigured": "Not Configured",
    "popover.configureFirst": "Please configure MiniMax Token first",
    "popover.daily": "Daily (5-hour window)",
    "popover.remaining": "Remaining",
    "popover.reset": "Reset",
    "popover.weekly": "Weekly",
    "popover.expiry": "Plan Expiry",
    "popover.normal": "Normal",
    "popover.low": "Running Low"
}
```

- [ ] **Step 6: Write zh-Hans.json**

```json
{
    "app.name": "MiniMax 使用状态",
    "menu.displaySettings": "显示设置",
    "menu.showUsed": "显示已使用",
    "menu.showRemaining": "显示剩余",
    "menu.checkUpdate": "检查更新",
    "menu.quit": "退出",
    "menu.language": "语言",
    "menu.lang.en": "English",
    "menu.lang.zh": "简体中文",
    "popover.configureToken": "配置 MiniMax Token",
    "popover.tokenConfigured": "Token 已配置",
    "popover.inputPlaceholder": "输入你的 Token",
    "popover.error": "错误",
    "popover.notConfigured": "未配置",
    "popover.configureFirst": "请先配置 MiniMax Token",
    "popover.daily": "日 (5小时窗口)",
    "popover.remaining": "剩余",
    "popover.reset": "重置",
    "popover.weekly": "周",
    "popover.expiry": "套餐到期",
    "popover.normal": "正常使用",
    "popover.low": "使用量紧张"
}
```

- [ ] **Step 7: Update AppDelegate to load I18nService**

```swift
// In AppDelegate.applicationDidFinishLaunching
I18nService.shared.loadTranslations()
```

- [ ] **Step 8: Commit**

---

## Task 2: Add Language Switcher to Right-Click Menu

**Files:**
- Modify: `StatusBar/StatusBarController.swift:100-137`

- [ ] **Step 1: Write failing test**

Verify right-click menu shows "Language" option with EN/ZH sub-items.

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Modify showDisplaySettingsSubmenu to add language submenu**

Replace hardcoded Chinese strings with `I18nService.shared.translate()` calls. Add language submenu.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

---

## Task 3: Internationalize PopoverContentView

**Files:**
- Modify: `Views/PopoverContentView.swift`

- [ ] **Step 1: Write failing test**

Verify all hardcoded Chinese text is replaced with `I18nService.shared.translate()` calls.

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Replace all hardcoded Chinese strings with translate() calls**

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

---

## Task 4: Internationalize UsageData Model

**Files:**
- Modify: `Models/UsageData.swift`

- [ ] **Step 1: Write failing test**

Verify status text methods return localized strings.

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Replace hardcoded strings with I18nService.translate() calls**

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

---

## Task 5: Verify Build and Integration

- [ ] **Step 1: Build project with `swift build` or xcodebuild**
- [ ] **Step 2: Verify no hardcoded Chinese text remains (search for Chinese characters)**
- [ ] **Step 3: Run all tests**
- [ ] **Step 4: Commit with all i18n changes**

---

## Verification Steps

1. **Test right-click menu**: Right-click status bar item → verify "Language" menu appears with English/Chinese options
2. **Test language switch**: Switch to English → verify all UI text changes
3. **Test persistence**: Restart app → verify language preference persists
4. **Test Chinese fallback**: With missing translation key → verify Chinese fallback works
5. **Build**: `swift build` or `xcodebuild` succeeds with no errors

---

## Risks / Open Questions

1. **AppKit menu vs SwiftUI Text**: Menu items use AppKit (NSMenuItem) - need to use `I18nService.shared.translate()` not `Text()`
2. **UsageData model**: Has computed properties returning formatted strings - need to call I18nService at usage time, not at model creation
3. **StatusBarView**: Shows percentage text, no i18n needed for numbers but status colors use text labels
4. **Date formatting**: `expirySection` uses DateFormatter - already locale-aware, no change needed

## Files to Change

| File | Change |
|------|--------|
| `Services/I18nService.swift` | Create - translation service |
| `Resources/en.json` | Create - English translations |
| `Resources/zh-Hans.json` | Create - Chinese translations |
| `App/AppDelegate.swift` | Modify - load I18nService on launch |
| `StatusBar/StatusBarController.swift` | Modify - i18n menu strings + language submenu |
| `Views/PopoverContentView.swift` | Modify - i18n all hardcoded strings |
| `Models/UsageData.swift` | Modify - i18n status text strings |
