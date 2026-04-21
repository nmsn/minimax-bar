# MiniMax Status Bar - 设计文档

## 项目概述

**项目名称**: MiniMaxBar
**项目类型**: macOS 菜单栏常驻工具
**核心功能**: 实时显示 MiniMax 5小时剩余用量和周剩余用量
**目标用户**: 使用 MiniMax API 的开发者

---

## 视觉规格

### 菜单栏图标

- **尺寸**: 40×20 pt
- **布局**: 双环嵌套 + 圆心

| 元素 | 规格 |
|------|------|
| 外环 (周) | 半径 8pt, 线宽 2pt |
| 内环 (日/5小时) | 半径 5pt, 线宽 1.5pt |
| 圆心 | MiniMax 图标/文字 |

### 圆环样式

- **填充方向**: 从完整圆环开始，随使用量增加，剩余量减少，环段减少（逆时针减少）
- **配色逻辑**:
  - 使用率 ≥85% → 红色 `#FF3B30`
  - 使用率 60-85% → 黄色 `#FFCC00`
  - 使用率 <60% → 绿色 `#34C759`

### 浮窗面板

- **尺寸**: 280×220 pt
- **技术**: SwiftUI MenuBarExtra

```
┌────────────────────────────────┐
│  MiniMax 使用状态               │
│                                │
│  当前模型: MiniMax-M2           │
│                                │
│  ▌日 (5小时窗口)                │
│    剩余: 3000/4500 次           │
│    重置: 20:00 (还剩2小时30分)   │
│                                │
│  ▌周                           │
│    剩余: 15000/20000 次         │
│    重置: 周日 00:00             │
│                                │
│  套餐到期: 2026/05/01           │
│  状态: ✓ 正常使用               │
│                                │
│  [刷新]                        │
└────────────────────────────────┘
```

---

## 数据规格

### API 端点

- **URL**: `https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains`
- **认证**: Bearer Token
- **缓存**: 8 秒

### 响应数据映射

```swift
struct UsageData {
    let modelName: String           // model_name
    let dailyRemaining: Int         // current_interval_usage_count (剩余次数)
    let dailyTotal: Int            // current_interval_total_count
    let dailyPercentage: Double    // 基于已用计算
    let dailyResetTime: String     // end_time 格式化 "HH:mm"
    let dailyResetMs: Int          // remains_time
    let weeklyRemaining: Int       // current_weekly_usage_count
    let weeklyTotal: Int            // current_weekly_total_count
    let weeklyPercentage: Double   // 基于已用计算
    let weeklyResetTime: String    // 周重置时间
    let expiryDate: Date?          // 套餐到期日
    let isHealthy: Bool            // 使用率 < 85%
}
```

### 鉴权存储

- **路径**: `~/.minimax-config.json`
- **格式**: `{"token": "your_token", "groupId": "optional"}`

---

## 技术架构

### 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI (macOS 14+)
- **网络**: URLSession
- **架构模式**: MVVM

### 项目结构

```
MiniMaxBar/
├── App/
│   └── MiniMaxBarApp.swift       # @main 入口
├── Views/
│   ├── StatusBarView.swift       # 菜单栏双环视图
│   └── PopoverContentView.swift  # 浮窗详细内容
├── ViewModels/
│   └── UsageViewModel.swift      # 数据逻辑
├── Models/
│   └── UsageData.swift           # 数据模型
├── Services/
│   ├── MiniMaxAPIService.swift   # API 请求
│   └── ConfigService.swift       # 鉴权配置
└── Resources/
    └── Assets.xcassets           # 图标资源
```

### 自动刷新

- **频率**: 每 30 秒轮询一次
- **手动刷新**: 浮窗内刷新按钮

---

## 颜色系统

| 状态 | 色值 | 用途 |
|------|------|------|
| 绿色 | `#34C759` | 使用率 < 60% |
| 黄色 | `#FFCC00` | 使用率 60-85% |
| 红色 | `#FF3B30` | 使用率 ≥ 85% |

---

## 功能清单

- [x] 菜单栏显示双环进度（实时变化）
- [x] 内环: 5小时窗口剩余用量
- [x] 外环: 周剩余用量
- [x] 点击弹出浮窗
- [x] 浮窗显示详细文本数据
- [x] 自动30秒刷新
- [x] 手动刷新按钮
- [x] Token 配置读取
- [x] 颜色状态指示

---

## 依赖关系

无外部依赖，纯 Swift/SwiftUI 实现

---

## 参考项目

MiniMax API 集成逻辑参考: https://github.com/JochenYang/minimax-status
