# Display Mode Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add right-click menu option to toggle status bar percentage display between "used" and "remaining"

**Architecture:** Add `DisplayMode` enum to `ConfigService`, pass display mode to `StatusBarView`, update `StatusBarController` right-click menu with submenu items.

**Tech Stack:** Swift, AppKit, SwiftUI

---

## File Structure

| File | Responsibility |
|------|----------------|
| `Services/ConfigService.swift` | Add `DisplayMode` enum and `displayMode` property with persistence |
| `Views/StatusBarView.swift` | Accept `displayMode` parameter, compute correct percentage string |
| `StatusBar/StatusBarController.swift` | Build right-click menu with submenu, sync display mode with ConfigService |

---

## Task 1: Add DisplayMode to ConfigService

**Files:**
- Modify: `Services/ConfigService.swift`

- [ ] **Step 1: Add DisplayMode enum and property**

```swift
enum DisplayMode: String, Codable {
    case used
    case remaining
}

private var cachedDisplayMode: DisplayMode = .used

var displayMode: DisplayMode {
    get { cachedDisplayMode }
    set {
        cachedDisplayMode = newValue
        saveConfig()
    }
}
```

- [ ] **Step 2: Update loadConfig to read displayMode**

Add to the JSON parsing in `loadConfig()`:
```swift
if let modeString = json["displayMode"] as? String,
   let mode = DisplayMode(rawValue: modeString) {
    cachedDisplayMode = mode
}
```

- [ ] **Step 3: Update saveConfig to write displayMode**

Add to the json dictionary:
```swift
json["displayMode"] = cachedDisplayMode.rawValue
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add Services/ConfigService.swift
git commit -m "feat: add DisplayMode enum and displayMode property to ConfigService"
```

---

## Task 2: Update StatusBarView to Accept DisplayMode

**Files:**
- Modify: `Views/StatusBarView.swift`

- [ ] **Step 1: Add displayMode parameter and update percentage computation**

```swift
struct StatusBarView: View {
    let usageData: UsageData?
    var displayMode: DisplayMode = .used  // Add this parameter

    private var dailyPercent: String {
        guard let data = usageData else { return "70%" }
        let percentage: Double
        switch displayMode {
        case .used:
            percentage = data.dailyUsedPercentage
        case .remaining:
            percentage = 1.0 - data.dailyUsedPercentage
        }
        return "\(Int(percentage * 100))%"
    }

    private var weeklyPercent: String {
        guard let data = usageData else { return "90%" }
        let percentage: Double
        switch displayMode {
        case .used:
            percentage = data.weeklyUsedPercentage
        case .remaining:
            percentage = 1.0 - data.weeklyUsedPercentage
        }
        return "\(Int(percentage * 100))%"
    }
    // ... rest of file unchanged
}
```

- [ ] **Step 2: Update Preview**

```swift
#Preview {
    StatusBarView(usageData: nil, displayMode: .used)
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Views/StatusBarView.swift
git commit -m "feat: add displayMode parameter to StatusBarView"
```

---

## Task 3: Update StatusBarController Right-Click Menu

**Files:**
- Modify: `StatusBar/StatusBarController.swift`

- [ ] **Step 1: Add showDisplaySettingsSubmenu method**

Add this method to the class:
```swift
private func showDisplaySettingsSubmenu() {
    closePopoverIfNeeded()

    let menu = NSMenu()

    // 子菜单项
    let usedItem = NSMenuItem(title: "显示已使用", action: #selector(setDisplayModeUsed), keyEquivalent: "")
    usedItem.target = self
    usedItem.state = ConfigService.shared.displayMode == .used ? .on : .off
    menu.addItem(usedItem)

    let remainingItem = NSMenuItem(title: "显示剩余", action: #selector(setDisplayModeRemaining), keyEquivalent: "")
    remainingItem.target = self
    remainingItem.state = ConfigService.shared.displayMode == .remaining ? .on : .off
    menu.addItem(remainingItem)

    // 主菜单项
    let displaySettingsItem = NSMenuItem(title: "显示设置", action: "", keyEquivalent: "")
    displaySettingsItem.submenu = menu

    let rootMenu = NSMenu()
    rootMenu.addItem(displaySettingsItem)
    rootMenu.addItem(NSMenuItem.separator())

    let checkUpdateItem = NSMenuItem(title: "检查更新", action: #selector(checkUpdateAction), keyEquivalent: "")
    checkUpdateItem.target = self
    rootMenu.addItem(checkUpdateItem)

    rootMenu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: "退出", action: #selector(quitAction), keyEquivalent: "q")
    quitItem.target = self
    rootMenu.addItem(quitItem)

    statusItem.menu = rootMenu
    statusItem.button?.performClick(nil)
    statusItem.menu = nil
}
```

- [ ] **Step 2: Add action methods for switching display mode**

```swift
@objc private func setDisplayModeUsed() {
    ConfigService.shared.displayMode = .used
    updateStatusBarView()
}

@objc private func setDisplayModeRemaining() {
    ConfigService.shared.displayMode = .remaining
    updateStatusBarView()
}

private func updateStatusBarView() {
    statusBarView.update(rootView: StatusBarView(
        usageData: viewModel.usageData,
        displayMode: ConfigService.shared.displayMode
    ))
    statusBarView.layoutSubtreeIfNeeded()
}
```

- [ ] **Step 3: Update showContextMenu to call showDisplaySettingsSubmenu**

Replace the `showContextMenu` method call in `statusBarView.onRightClick`:

```swift
statusBarView.onRightClick = { [weak self] in
    self?.showDisplaySettingsSubmenu()
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add StatusBar/StatusBarController.swift
git commit -m "feat: add display mode toggle to right-click menu"
```

---

## Verification

After all tasks completed:

1. Run release build:
```bash
xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Release build 2>&1 | tail -3
```

2. Right-click the status bar icon, verify:
   - "显示设置" menu item appears
   - Submenu shows "显示已使用" and "显示剩余"
   - Clicking each toggles the checkmark and updates the display

3. Restart the app, verify preference persists
