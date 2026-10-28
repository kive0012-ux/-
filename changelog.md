# 更新日志

## v1.0（versionCode 100）— 全新重写

从零重写的第一个版本，不再沿用旧版结构。

### 新增 / 重做
- **音质优化**：外放重采样质量 + 扬声器增益（温和 +4% / 增强 +8%），只匹配 SPK/SPEAKER 的数值型 GAIN/VOLUME 控件，按控件 range 上限钳制，修改前备份。
- **杜比优化**：检测到 Dolby/DAX 组件才点亮，不覆盖 `dax-default.xml`，不修改 offload/蓝牙/编解码属性。
- **触控增强**：`windowsmgr.max_events_per_sec` 与滑动惯性两档（日常 180 / 竞技 300），不碰触控采样率硬件节点。
- **GMS / OPPO 推送深度保活**：Doze 白名单 + RUN_IN_BACKGROUND / RUN_ANY_IN_BACKGROUND / START_FOREGROUND / WAKE_LOCK / AUTO_START，深度模式再加 active 待机桶与数据节流白名单。
- **云控**：只做 hosts 域名屏蔽，不禁用任何 App、不冻结目录，避免 ocs「建议开启重要应用」弹窗。
- **全新 WebUI**：底部四页签（首页/推送/音质/更多），深色渐变主题、分段控件、开关与状态卡片；无 iframe、大图与模糊特效，滚动流畅。

### 移除（不再包含）
- 充电加速与 UFCS 二进制、CPU/GPU 调度与温控改动、云控目录冻结、广告 hosts、国际化/隐藏外观、文件级后台守护。

### 兼容
- 模块 ID 不变，可从旧版直接覆盖升级；首次启动自动还原旧版注入的音频/杜比/网络/动画属性并清理 UFCS 残留。
