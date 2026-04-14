# MiniMaxBar

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/github/v/release/nmsn/minimax-bar)
![Downloads](https://img.shields.io/github/downloads/nmsn/minimax-bar/total)

A macOS menu bar app displaying MiniMax API usage statistics.

## Features

- Real-time daily/weekly usage percentage in menu bar
- Dynamic icon color indicating usage status
  - Green: remaining ≥ 50%
  - Yellow: remaining 10% ~ 50%
  - Red: remaining < 10%
- Left-click to open details popover
- Right-click context menu for quick actions
- Token configuration and management
- Sparkle auto-update support

## Requirements

- macOS 14.0 or later

## Installation

1. Download the latest `.dmg` from [Releases](https://github.com/nmsn/minimax-bar/releases)
2. Double-click to open the DMG
3. Drag `MiniMaxBar` into the Applications folder
4. On first run, right-click the app and select "Open"

## Usage

1. Click the menu bar icon after launching
2. Click the button in the top-right corner to get Token
3. Visit [MiniMax Platform](https://platform.minimaxi.com/user-center/payment/coding-plan) to get your Token
4. Paste and save the Token
5. The menu bar will display usage statistics in real-time

## Development

### Build

```bash
# Install dependencies
xcodegen generate

# Debug build
xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Debug build

# Release build
xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Release build
```

### Package

```bash
hdiutil create -volname MiniMaxBar -srcfolder build/Release/MiniMaxBar.app -ov -format UDZO -o MiniMaxBar.dmg
```

## Tech Stack

- Swift + SwiftUI
- AppKit (NSStatusItem, NSPopover)
- Sparkle (Auto-update)
- XcodeGen (Project generation)

## License

MIT
