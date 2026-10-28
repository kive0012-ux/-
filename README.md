# ColorOS 日用增强 v1.0

国行 ColorOS / 一加的日用增强模块，全套代码从零重写（v1.0）。

适用：已 Root 的 Magisk / KernelSU / APatch。
WebUI：KernelSU / APatch / MMRL（官方 Magisk App 没有 WebUI，可用 `action.sh`）。

---

## 功能

| 模块 | 说明 |
|---|---|
| **音质优化** | 外放重采样质量 + 扬声器增益（温和 +4% / 增强 +8%），自动按控件 range 钳制 |
| **杜比优化** | 检测到 Dolby/DAX 组件时点亮链路；不覆盖 `dax-default.xml`、不碰 offload/编解码 |
| **触控增强** | 事件吞吐与滑动惯性（日常 180 / 竞技 300），不改触控采样率硬件节点 |
| **GMS 推送** | Doze 白名单 + 后台 appops；深度模式再加自动启动、active 待机桶、数据节流白名单 |
| **OPPO 推送** | 同上，针对 HeyTap / ColorOS 推送通道 |
| **云控** | 仅 hosts 屏蔽下发域名；**禁用 0 个 App**、不冻结目录，不会触发「重要应用被关闭」弹窗 |

全部开关独立；属性修改前均备份，关闭或卸载即还原。

## 安全设计（针对旧版问题）

- 不写 `persist.vendor.audio.*`、不改 offload / 蓝牙 / 编解码，避免抖音等无声；
- 不 `pm disable/enable` 任何应用、不 bind-mount 冻结 `/data/oplus/*`，避免 ocs 弹窗；
- 无高频后台循环；看门狗默认关闭，开启后也只补缺失白名单（≥300 秒）；
- 安装无交互向导，刷入不会卡住。

## 从旧版升级

同一模块 ID，直接覆盖安装后**重启一次**即可。首次启动会自动清理旧版残留：

- 还原旧版注入的音频/杜比/蓝牙/动画/网络/Private DNS 属性与混音器增益；
- 删除旧版创建的 UFCS 运行时目录与 `/dev/.ufcs*`；
- 解绑旧版对云控目录的只读挂载。

## WebUI

底部四页签：首页（状态概览）/ 推送 / 音质 / 更多（触控、云控、恢复）。
轻量单页，无 iframe、无大图、无模糊特效，滚动与切换不卡顿。

命令行：

```sh
sh /data/adb/modules/zzz-gms-intl-optimizer/action.sh get
sh /data/adb/modules/zzz-gms-intl-optimizer/action.sh set AUDIO_LEVEL strong
sh /data/adb/modules/zzz-gms-intl-optimizer/action.sh apply
```

## 文件

```
module.prop     customize.sh   config.sh
post-fs-data.sh service.sh     action.sh   uninstall.sh
lib.sh          push.sh        audio.sh    touch.sh    cloud.sh
system/etc/hosts  webroot/index.html
update.json     changelog.md    release.sh
```

状态与备份：`/data/adb/coloros_power/`（卸载时清除）。

## 在线更新

`module.prop` 的 `updateJson` 指向
`https://raw.githubusercontent.com/kive0012-ux/-/main/update.json`。
发版：`bash release.sh v1.1 101 kive0012-ux/-`
