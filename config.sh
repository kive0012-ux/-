#!/system/bin/sh
# =============================================================
#  ColorOS 日用增强 v1.0 — 配置
#  所有值仅 true/false 或短标识，WebUI / action.sh 读写本文件
# =============================================================

STATE_DIR="/data/adb/coloros_power"
LOG="/data/local/tmp/coloros_power.log"

# ---------- 包名 ----------
GMS_PKGS="com.google.android.gms com.google.android.gms.persistent com.google.android.gsf com.google.android.gsf.login com.android.vending"
OPPO_PKGS="com.heytap.mcs com.coloros.mcs com.coloros.push com.heytap.push com.coloros.oppopush com.oppo.push com.oplus.mcs"
EXTRA_PKGS=""

# ---------- 推送 ----------
PUSH_GMS=true          # GMS / FCM 深度保活
PUSH_OPPO=true         # OPPO / ColorOS 推送通道保活
DEEP_PUSH=true         # 深度：appops + 待机桶 + 数据节流白名单
WATCHDOG=false         # 仅补白名单的轻量看门狗（默认关）
WATCHDOG_INTERVAL=900

# ---------- 音质 ----------
AUDIO_ENHANCE=true     # 外放音质（扬声器增益 + 重采样质量）
AUDIO_LEVEL=soft       # soft(温和) / strong(增强)
DOLBY_ENHANCE=true     # 杜比/DAX 链路（仅检测到杜比组件时生效）

# ---------- 触控 ----------
TOUCH_ENHANCE=true     # 触控跟手增强
TOUCH_LEVEL=soft       # soft(日常) / strong(竞技)

# ---------- 云控 ----------
BLOCK_CLOUD=true       # 屏蔽云控下发域名（仅 hosts，不冻结目录、不禁用 App）
CLOUD_DOMAINS="atlas.heytap.com atlas.oppo.cn cota.heytap.com cota.coloros.com ocs.oppo.cn ocs.heytap.com config.oppo.com cloud.oppo.com innerconfig.heytap.com"

# 本模块可能动过白名单/待机桶的包
ALL_PKGS="$GMS_PKGS $OPPO_PKGS"

build_pkg_list() {
  PKG_LIST=""
  [ "$PUSH_GMS" = "true" ]  && PKG_LIST="$PKG_LIST $GMS_PKGS"
  [ "$PUSH_OPPO" = "true" ] && PKG_LIST="$PKG_LIST $OPPO_PKGS"
  PKG_LIST="$PKG_LIST $EXTRA_PKGS"
}
