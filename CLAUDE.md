# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# MiniMaxBar

A macOS menu bar app displaying MiniMax API usage statistics. Built with SwiftUI + AppKit hybrid architecture.

## Build Commands

```bash
# Generate Xcode project
xcodegen generate

# Debug build
xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Debug build

# Release build
xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Release build

# Package as DMG
hdiutil create -volname MiniMaxBar -srcfolder build/Release/MiniMaxBar.app -ov -format UDZO -o MiniMaxBar.dmg
```

## Architecture

- **Menu bar app** (LSUIElement=true, no dock icon)
- **SwiftUI + AppKit hybrid**: SwiftUI views inside NSStatusItem via NSHostingController
- **Architecture pattern**: ViewModel + Services (similar to MVC)

### Directory Structure

| Directory | Purpose |
|-----------|---------|
| `App/` | Entry point (`main.swift`, `AppDelegate.swift`), Info.plist |
| `Models/` | Data models (`UsageData`) |
| `Services/` | Business logic - `ConfigService` (UserDefaults), `MiniMaxAPIService` (API calls), `I18nService` (localization), `UpdateService` (Sparkle) |
| `StatusBar/` | Menu bar UI - `StatusBarController` manages NSStatusItem, `RightClickStatusBarView` handles clicks |
| `ViewModels/` | `UsageViewModel` - bridges services and views |
| `Views/` | SwiftUI views - `PopoverContentView` (main popover), `StatusBarView` (menu bar icon) |

### Key Patterns

- **StatusBarController** creates NSStatusItem, adds subview via `button.addSubview(statusBarView)`
- **RightClickStatusBarView** intercepts clicks via override, emits callbacks for left/right click
- **Popover** shown relative to status bar button bounds with `.minY` edge
- **I18nService** uses JSON files in Resources (`en.json`, `zh-Hans.json`), locale stored in ConfigService

## Git Workflow

**main 分支受保护**，修改代码必须通过 PR 合入：
1. 创建新分支或使用临时分支
2. 提交更改并 push
3. 通过 `gh pr create` 创建 PR
4. 使用 squash merge 合入 main

```bash
# 创建 PR
gh pr create --title "description" --body "change details"

# Squash merge
gh pr merge <pr-number> --squash
```

## Sparkle Update Release Process

1. Update `appcast.xml` on `gh-pages` branch with new version, date, and DMG URL
2. Create and push GitHub Release with the `.dmg` file
3. Ensure `length` attribute in appcast.xml matches actual DMG file size

```bash
git checkout gh-pages
# Edit appcast.xml item node
git add appcast.xml && git commit -m "Release vX.X.X" && git push origin gh-pages
```

## Tech Stack

- Swift 5.9, macOS 14.0+
- SwiftUI (views) + AppKit (NSStatusItem, NSPopover)
- [Sparkle](https://github.com/sparkle-project/Sparkle) 2.6.0+ for auto-update
- XcodeGen for project generation
- EdDSA signing key for update verification (public key in project.yml)