#!/system/bin/sh
# =============================================================
#  开机完成后应用：推送保活 / 音质混音器 / 旧版 late 清理
#  用法：service.sh        开机
#        service.sh once   WebUI「立即应用」
# =============================================================

MODDIR=${0%/*}
case "$MODDIR" in ""|"$0") MODDIR=. ;; esac
WD_MARK=/dev/.coloros_power_wd

. "$MODDIR/config.sh"
. "$MODDIR/lib.sh"
. "$MODDIR/cloud.sh"
. "$MODDIR/audio.sh"
. "$MODDIR/touch.sh"
. "$MODDIR/push.sh"

wait_boot() {
  i=0
  while [ "$i" -lt 120 ]; do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
    sleep 2; i=$((i + 1))
  done
}

start_watchdog() {
  [ "$WATCHDOG" = "true" ] || return 0
  if [ -e "$WD_MARK" ]; then
    old=$(cat "$WD_MARK" 2>/dev/null)
    [ -n "$old" ] && kill -0 "$old" 2>/dev/null && return 0
  fi
  iv=${WATCHDOG_INTERVAL:-900}
  [ "$iv" -lt 300 ] 2>/dev/null && iv=300
  (
    while true; do
      sleep "$iv"
      . "$MODDIR/config.sh" 2>/dev/null
      iv=${WATCHDOG_INTERVAL:-900}
      [ "$iv" -lt 300 ] 2>/dev/null && iv=300
      build_pkg_list
      wl=$(dumpsys deviceidle whitelist 2>/dev/null)
      for p in $PKG_LIST; do
        [ -z "$p" ] && continue
        echo "$wl" | grep -q "$p" || cmd deviceidle whitelist +"$p" >/dev/null 2>&1
      done
    done
  ) &
  echo $! > "$WD_MARK"
  log svc "watchdog started ${iv}s"
}

apply_all() {
  legacy_cleanup_late
  build_hosts
  apply_touch
  apply_audio
  apply_push
  start_watchdog
  log svc "apply done"
}

case "${1:-}" in
  once) : > "$LOG" 2>/dev/null; wait_boot; apply_all; exit 0 ;;
  *)    : > "$LOG" 2>/dev/null; log svc "boot"; wait_boot; apply_all ;;
esac
