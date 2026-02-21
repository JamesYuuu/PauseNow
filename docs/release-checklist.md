# PauseNow 发布检查清单

## 1) 开源发布前预检（Repository Hygiene）

- [ ] `git status` 工作区干净
- [ ] 未跟踪或已忽略的隐私文件不进入提交（`**/xcuserdata/`, `*.xcuserstate`, `.DS_Store` 等）
- [ ] `docs/plans/` 仅保留本地，不进入发布提交
- [ ] 提交中不包含凭据、密钥、令牌等敏感信息

## 2) 核心功能检查

- [ ] 菜单栏图标与主页面入口可用（开始/暂停/恢复/休息/重置/退出）
- [ ] 菜单栏始终显示统一倒计时（`mm:ss`）
- [ ] 未开始时菜单栏显示初始时长（来自设置）
- [ ] 暂停后菜单栏显示冻结剩余时间，恢复后继续递减
- [ ] 菜单栏宽度为自适应（不固定长度）
- [ ] 菜单栏图标与字体放大后无截断
- [ ] 设置窗口打开后在前台可直接交互
- [ ] 修改“单次休息间隔（分钟）”后倒计时立即重置为新值
- [ ] 修改其他设置项时不重置当前倒计时
- [ ] 护眼提醒倒计时可自动完成
- [ ] 起身提醒倒计时可自动完成
- [ ] 提醒遮罩支持跳过
- [ ] 同时到期时仅触发起身
- [ ] 起身完成后按新一轮护眼重新计数
- [ ] App 图标显示正确（Dock/Finder）

## 3) 智能模式与已知待接线项

- [ ] 睡眠后暂停提醒
- [ ] 唤醒后恢复提醒
- [ ] （待接线）全屏场景会延后提醒
- [ ] （待接线）退出全屏后可恢复提醒

## 4) 配置与数据检查

- [ ] 默认配置值正确（20/20/3/180）
- [ ] 自定义提示语可保存并重启后回显（提醒文案接线待补）
- [ ] 今日完成/跳过统计正确（统计接线后验证）

## 5) 构建与测试

- [ ] Debug 构建通过
  - `xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -configuration Debug build`
- [ ] 标准测试通过
  - `xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' test`
- [ ] 无签名回归测试通过（如本机签名不稳定）
  - `xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test`

## 6) 文档一致性

- [ ] `README.md`（英文）与 `README.zh-CN.md`（中文）内容一致
- [ ] `docs/feature-status.md` 中的状态与 README 描述一致
- [ ] `docs/repository-structure.md` 的链路描述与代码实现一致
- [ ] `docs/development.md` 的命令和排障说明可复现
