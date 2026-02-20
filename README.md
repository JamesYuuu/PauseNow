# PauseNow

PauseNow 是一个 macOS 菜单栏休息提醒应用（MVP）。

## 当前能力

- 20-20-20 护眼提醒（默认每 20 分钟，20 秒倒计时）
- 每 3 次护眼触发起身提醒（默认 180 秒）
- 全屏遮罩提醒（实时倒计时），支持跳过
- 智能模式基础能力：全屏延后、系统睡眠/唤醒联动
- 本地配置与本地统计
- 菜单栏显示：图标 + 状态文案（`休息中` / `mm:ss` / `已暂停 mm:ss`）
- 菜单栏动作已串联：开始 / 暂停 / 恢复 / 退出
- App 图标资源已配置（Asset Catalog）

## 本地构建

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -configuration Debug build
```

## 本地测试

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' test
```

如果本机遇到签名阶段失败，可用下面命令做功能回归验证：

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test
```

## 默认文案

- 提示语：`现在稍息！`

后续可在设置页自定义。
