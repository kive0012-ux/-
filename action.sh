#!/system/bin/sh
# =============================================================
#  WebUI 命令桥
#  get | set <K> <V> [quiet] | apply | status | log | restore | factory_reset
# =============================================================

MODDIR=${0%/*}
case "$MODDIR" in ""|"$0") MODDIR=. ;; esac

. "$MODDIR/config.sh"
. "$MODDIR/lib.sh"
. "$MODDIR/cloud.sh"
. "$MODDIR/audio.sh"
. "$MODDIR/touch.sh"
. "$MODDIR/push.sh"

ALLOWED="PUSH_GMS PUSH_OPPO DEEP_PUSH WATCHDOG WATCHDOG_INTERVAL AUDIO_ENHANCE AUDIO_LEVEL DOLBY_ENHANCE TOUCH_ENHANCE TOUCH_LEVEL BLOCK_CLOUD EXTRA_PKGS"

valid_val() {
  [ -z "$1" ] && return 0
  printf '%s\n' "$1" | grep -qE '^[A-Za-z0-9 ._:/,@+-]*$' || return 1
  [ "${#1}" -le 256 ] || return 1
  return 0
}

# 按 key 做枚举/数值校验，避免写入无意义的值（例如 AUDIO_LEVEL=abc、间隔=sleep）
valid_pair() {
  case "$1" in
    PUSH_GMS|PUSH_OPPO|DEEP_PUSH|WATCHDOG|AUDIO_ENHANCE|DOLBY_ENHANCE|TOUCH_ENHANCE|BLOCK_CLOUD)
      case "$2" in true|false) return 0 ;; *) return 1 ;; esac ;;
    AUDIO_LEVEL|TOUCH_LEVEL)
      case "$2" in soft|strong) return 0 ;; *) return 1 ;; esac ;;
    WATCHDOG_INTERVAL)
      case "$2" in ''|*[!0-9]*) return 1 ;; esac
      [ "$2" -ge 300 ] 2>/dev/null && [ "$2" -le 86400 ] 2>/dev/null || return 1
      return 0 ;;
    EXTRA_PKGS) return 0 ;;
  esac
  return 1
}

cmd="$1"; shift
case "$cmd" in
  get)
    cat <<EOF
{"PUSH_GMS":"$PUSH_GMS","PUSH_OPPO":"$PUSH_OPPO","DEEP_PUSH":"$DEEP_PUSH","WATCHDOG":"$WATCHDOG","WATCHDOG_INTERVAL":"$WATCHDOG_INTERVAL","AUDIO_ENHANCE":"$AUDIO_ENHANCE","AUDIO_LEVEL":"$AUDIO_LEVEL","DOLBY_ENHANCE":"$DOLBY_ENHANCE","TOUCH_ENHANCE":"$TOUCH_ENHANCE","TOUCH_LEVEL":"$TOUCH_LEVEL","BLOCK_CLOUD":"$BLOCK_CLOUD","EXTRA_PKGS":"$EXTRA_PKGS","status":"ok"}
EOF
    ;;

  set)
    key="$1"; val="$2"
    echo "$ALLOWED" | tr ' ' '\n' | grep -qx "$key" || { echo '{"status":"error","msg":"未知键"}'; exit 1; }
    valid_val "$val" || { echo '{"status":"error","msg":"值含非法字符"}'; exit 1; }
    valid_pair "$key" "$val" || { echo '{"status":"error","msg":"值不符合该开关的允许范围"}'; exit 1; }
    awk -v k="$key" -v v="$val" '$0 ~ "^"k"=" {print k"=\""v"\""; next} {print}' \
      "$MODDIR/config.sh" > "$MODDIR/config.sh.tmp" && mv "$MODDIR/config.sh.tmp" "$MODDIR/config.sh"
    . "$MODDIR/config.sh"
    [ "${3:-}" = "quiet" ] && { echo '{"status":"ok","msg":"已保存"}'; exit 0; }
    build_hosts
    apply_touch
    apply_audio_props
    sh "$MODDIR/service.sh" once >/dev/null 2>&1
    echo '{"status":"ok","msg":"已应用"}'
    ;;

  apply)
    sh "$MODDIR/service.sh" once >/dev/null 2>&1
    echo '{"status":"ok","msg":"已应用"}'
    ;;

  status)
    boot=$(getprop sys.boot_completed 2>/dev/null)
    wl=$(cmd deviceidle whitelist 2>/dev/null | grep -cE 'gms|gsf|vending|mcs|coloros|heytap|oppo|push')
    tl=$(cat "$STATE_DIR/touch.level" 2>/dev/null)
    [ -n "$tl" ] || tl=off
    mix=0
    [ -f "$STATE_DIR/mixer.list" ] && mix=$(grep -c . "$STATE_DIR/mixer.list" 2>/dev/null)
    dol=$(cat "$STATE_DIR/dolby.detected" 2>/dev/null)
    [ -n "$dol" ] || dol=0
    cat <<EOF
{"status":"ok","boot":"${boot:-0}","whitelist":"${wl:-0}","touch":"$tl","mixer":"${mix:-0}","dolby":"$dol","cloud":"$BLOCK_CLOUD","version":"1.0"}
EOF
    ;;

  log) cat "$LOG" 2>/dev/null || echo "(无日志)" ;;

  restore)
    restore_speaker >/dev/null 2>&1
    restore_all_props >/dev/null 2>&1
    rm -f "$STATE_DIR/mixer.list" "$STATE_DIR/touch.level" "$STATE_DIR/dolby.detected" 2>/dev/null
    echo '{"status":"ok","msg":"属性/音质/触控已还原，建议重启"}'
    ;;

  factory_reset)
    build_pkg_list
    KEEP="$PKG_LIST $ALL_PKGS"
    DEFAULTS="PUSH_GMS:false PUSH_OPPO:false DEEP_PUSH:false WATCHDOG:false WATCHDOG_INTERVAL:900 AUDIO_ENHANCE:false AUDIO_LEVEL:soft DOLBY_ENHANCE:false TOUCH_ENHANCE:false TOUCH_LEVEL:soft BLOCK_CLOUD:false EXTRA_PKGS:"
    for kv in $DEFAULTS; do
      k="${kv%%:*}"; v="${kv#*:}"
      awk -v k="$k" -v v="$v" '$0 ~ "^"k"=" {print k"=\""v"\""; next} {print}' \
        "$MODDIR/config.sh" > "$MODDIR/config.sh.tmp" 2>/dev/null && mv "$MODDIR/config.sh.tmp" "$MODDIR/config.sh" 2>/dev/null
    done
    . "$MODDIR/config.sh"

    # 撤销推送改动
    for p in $(echo $KEEP | tr ' ' '\n' | sort -u); do
      [ -z "$p" ] && continue
      drop_push_one "$p"
    done

    # 还原属性 / 混音器 / hosts
    tm=$(find_tinymix)
    if [ -n "$tm" ] && [ -f "$STATE_DIR/mixer.list" ]; then
      while IFS='|' read -r id orig; do
        [ -n "$id" ] && [ -n "$orig" ] && "$tm" "$id" "$orig" >/dev/null 2>&1
      done < "$STATE_DIR/mixer.list"
    fi
    rm -f "$STATE_DIR/mixer.list" "$STATE_DIR/touch.level" "$STATE_DIR/dolby.detected" 2>/dev/null
    restore_all_props >/dev/null 2>&1
    BLOCK_CLOUD=false build_hosts

    # 停看门狗
    stop_watchdog
    echo '{"status":"ok","msg":"已恢复正常（建议重启一次）"}'
    ;;

  *) echo '{"status":"error","msg":"未知命令"}' ;;
esac
