# PauseNow

PauseNow 是一个 macOS 菜单栏休息提醒应用（MVP）。

## 当前能力

- 20-20-20 护眼提醒（默认每 20 分钟，20 秒倒计时）
- 每 3 次护眼触发起身提醒（默认 180 秒）
- 全屏遮罩提醒（实时倒计时），支持跳过
- 智能模式基础能力：系统睡眠/唤醒联动（全屏延后接线待补）
- 本地配置（统计存储层已预置，主流程接线待补）
- 菜单栏显示：图标 + 统一倒计时（始终 `mm:ss`）
- 未开始时显示配置的初始时长；暂停时显示冻结的剩余时间
- 菜单栏图标与倒计时字体已放大（中等档）
- 菜单栏宽度自适应（不再固定长度）
- 打开设置时会激活应用并将设置窗口置于前台
- 设置修改立即生效；仅修改“单次休息间隔（分钟）”时会重置倒计时
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

可在设置页修改提示语（当前仅保存配置，提醒文案接线待补）。
