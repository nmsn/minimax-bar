# 百分比显示类型切换功能设计

## 概述

在右键菜单中添加"显示设置"子菜单，允许用户切换状态栏显示的百分比类型：
- 已使用百分比（默认，当前行为）
- 剩余百分比

## 改动范围

### 1. ConfigService
- 新增 `displayMode: DisplayMode` 属性
- `DisplayMode` 枚举：`used`（已使用，默认）/ `remaining`（剩余）
- 持久化到配置文件

### 2. StatusBarView
- 新增 `displayMode: DisplayMode` 参数
- 根据 `displayMode` 计算并显示对应百分比

### 3. StatusBarController
- 在右键菜单中添加 "显示设置" 子菜单
- 子菜单包含两个 NSMenuItem：
  - "显示已使用"（带勾选标记）
  - "显示剩余"（带勾选标记）
- 点击切换时：
  1. 更新 `ConfigService.displayMode`
  2. 更新 `StatusBarView` 显示

### 4. PopoverContentView / UsageViewModel（可选）
- 可在设置界面展示当前模式

## 数据流

```
ConfigService.displayMode (持久化)
       ↓
StatusBarController 读取配置
       ↓
StatusBarView 根据 displayMode 渲染
```

## 文件改动

| 文件 | 改动 |
|------|------|
| `Services/ConfigService.swift` | 新增 displayMode 属性和枚举 |
| `Views/StatusBarView.swift` | 新增 displayMode 参数 |
| `StatusBar/StatusBarController.swift` | 添加右键菜单子菜单 |

## 默认行为

首次安装时默认显示"已使用"百分比（向后兼容）
