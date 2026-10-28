#!/system/bin/sh
# 卸载：撤销推送改动、还原音质/触控属性、清空 hosts、清理状态
MODDIR=${0%/*}
case "$MODDIR" in ""|"$0") MODDIR=. ;; esac

. "$MODDIR/config.sh"
. "$MODDIR/lib.sh"
. "$MODDIR/cloud.sh"
. "$MODDIR/audio.sh"
. "$MODDIR/touch.sh"
. "$MODDIR/push.sh"

# 停看门狗
stop_watchdog

drop_push_all
restore_speaker
restore_all_props >/dev/null 2>&1
BLOCK_CLOUD=false build_hosts
legacy_cleanup_late

rm -rf "$STATE_DIR" 2>/dev/null
rm -f "$LOG" 2>/dev/null
echo "已卸载并恢复：推送/音质/触控/云控 均已撤销"
