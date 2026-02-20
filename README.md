# PauseNow

PauseNow 是一个 macOS 菜单栏休息提醒应用（MVP）。

## 当前能力

- 20-20-20 护眼提醒（默认每 20 分钟，20 秒倒计时）
- 每 3 次护眼触发起身提醒（默认 180 秒）
- 全屏遮罩提醒（实时倒计时），支持跳过
- 智能模式基础能力：全屏延后、系统睡眠/唤醒联动
- 本地配置与本地统计
- 菜单栏动作已串联：开始 / 暂停 / 恢复

## 本地构建

```bash
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -configuration Debug build
```

## 默认文案

- 提示语：`现在稍息！`

后续可在设置页自定义。
