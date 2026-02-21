# PauseNow

[English README (README.md)](README.md)

PauseNow 是一个面向 macOS 菜单栏的休息提醒应用，核心场景是 20-20-20 护眼节奏。

## 功能亮点

- 菜单栏统一倒计时显示（`mm:ss`）+ 沙漏弹层交互
- 主动作单键切换：开始 -> 暂停 -> 恢复
- 弹层支持“休息”与“重置”快捷操作
- 使用官方 macOS Settings 场景
- 设置修改可实时生效（仅间隔变化会立即重置计时）
- 全屏遮罩提醒，支持实时倒计时与跳过

## 当前功能状态

### 已实现

- 护眼提醒节奏（默认每 20 分钟提醒，提醒时长 20 秒）
- 每 N 次护眼触发起身提醒（默认每 3 次，提醒时长 180 秒）
- 运行态显示映射统一：`stopped/running/paused` 均映射为菜单栏倒计时
- 菜单栏字体与图标放大，字体回退链路：`font-maple-mono-nf-cn` -> `Monaco` -> 系统回退
- 设置项持久化：提示语、间隔、提醒时长、起身触发频次
- 系统睡眠/唤醒联动暂停能力（通过 `SmartModeMonitor`）

### 部分接线 / 待接线

- `SmartModeMonitor` 已提供全屏延后开关，但全屏信号接线尚未完成
- 提示语可保存，但遮罩标题仍使用固定文案
- `RecordStore` 与当日统计 API 已存在，但尚未完整接入运行时事件

详见 [docs/feature-status.md](docs/feature-status.md)。

## 快速开始

### 环境要求

- macOS
- Xcode 26.x 或更高版本

### 在 Xcode 中运行

1. 打开 `PauseNow.xcodeproj`
2. 选择 scheme `PauseNow`
3. 在 `My Mac` 上运行

## 本地构建

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -configuration Debug build
```

## 本地测试

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' test
```

若本机签名导致测试失败，可使用无签名回归命令：

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test
```

## 文档导航

- [README.md](README.md)：英文 README
- [docs/release-checklist.md](docs/release-checklist.md)：发布前检查清单
- [docs/repository-structure.md](docs/repository-structure.md)：仓库结构与核心链路说明
- [docs/development.md](docs/development.md)：本地开发与排障指南
- [docs/feature-status.md](docs/feature-status.md)：功能状态矩阵

## 仓库卫生约定

- `PauseNow.xcodeproj` 需要保留并提交，保证他人可直接构建。
- 不提交用户私有 Xcode 文件（`xcuserdata`、`*.xcuserstate` 等）。
- 本地计划文档放在 `docs/plans/`，该目录默认忽略提交。
