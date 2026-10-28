#!/system/bin/sh
# =============================================================
#  公共库：日志 / 属性备份还原 / 工具 / 旧版残留清理
# =============================================================

STATE_DIR="${STATE_DIR:-/data/adb/coloros_power}"
LOG="${LOG:-/data/local/tmp/coloros_power.log}"
LEGACY_DIR="/data/adb/gms_intl_opt"
PROPS="$STATE_DIR/props.list"
mkdir -p "$STATE_DIR" 2>/dev/null

if command -v resetprop >/dev/null 2>&1; then RP=resetprop; else RP=setprop; fi

log() { echo "$(date '+%m-%d %H:%M:%S') [$1] $2" >> "$LOG" 2>/dev/null; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- 属性：改前备份，还原只动自己改过的 ----------
prop_get() { getprop "$1" 2>/dev/null; }
prop_set() {
  if [ "$RP" = "resetprop" ]; then resetprop -n "$1" "$2" 2>/dev/null; else setprop "$1" "$2" 2>/dev/null; fi
}
prop_del() {
  if [ "$RP" = "resetprop" ]; then resetprop --delete "$1" 2>/dev/null; else setprop "$1" "" 2>/dev/null; fi
}
record_prop() {
  [ -f "$PROPS" ] && grep -q "^$1=" "$PROPS" 2>/dev/null && return 0
  echo "$1=$(prop_get "$1")" >> "$PROPS" 2>/dev/null
}
apply_prop() {
  record_prop "$1"
  if [ -n "$2" ]; then prop_set "$1" "$2"; else prop_del "$1"; fi
}
restore_prop() {
  [ -f "$PROPS" ] || return 0
  grep -q "^$1=" "$PROPS" 2>/dev/null || return 0
  _v=$(grep "^$1=" "$PROPS" | head -n1 | cut -d= -f2-)
  if [ -n "$_v" ]; then prop_set "$1" "$_v"; else prop_del "$1"; fi
  sed -i "\|^$1=|d" "$PROPS" 2>/dev/null
}
restore_all_props() {
  [ -f "$PROPS" ] || return 1
  for _k in $(grep -v '^$' "$PROPS" 2>/dev/null | cut -d= -f1); do restore_prop "$_k"; done
  return 0
}

find_tinymix() {
  if have tinymix; then command -v tinymix; return 0; fi
  for p in /vendor/bin/tinymix /system/bin/tinymix /odm/bin/tinymix; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

# ---------- 旧版（v3.x/v4.x）残留：属性 ----------
_restore_legacy_kv() {
  f="$1"; [ -f "$f" ] || return 0
  while IFS='=' read -r k v; do
    [ -z "$k" ] && continue
    if [ -z "$v" ] || [ "$v" = "__EMPTY__" ]; then prop_del "$k"; else prop_set "$k" "$v"; fi
  done < "$f"
  rm -f "$f" 2>/dev/null
  log legacy "restored ${f##*/}"
}

legacy_cleanup_props() {
  [ -f "$STATE_DIR/.legacy_props" ] && return 0
  [ -f "$LEGACY_DIR/prop_backup.list" ]  && _restore_legacy_kv "$LEGACY_DIR/prop_backup.list"
  [ -f "$LEGACY_DIR/dolby_backup.list" ] && _restore_legacy_kv "$LEGACY_DIR/dolby_backup.list"

  # 旧版注入过的音频/蓝牙属性：值等于注入值才删除（避免误伤用户自己的设置）
  for kv in \
    persist.vendor.audio.offload.multiple.enabled=true \
    persist.vendor.audio.spk.stereo=true \
    persist.vendor.audio.surround.support=true \
    persist.vendor.audio.sfx.spatial=true \
    persist.vendor.audio.sfx.scenario=true \
    persist.vendor.dolby.loglevel=0 \
    persist.vendor.dolby.mono_speaker=false \
    persist.vendor.btstack.enable.splita2dp=true \
    persist.vendor.btstack.enable.twsplus=true \
    persist.vendor.bt.a2dp.offload.supported=true \
    persist.bluetooth.a2dp_offload.disabled=false ; do
    k="${kv%%=*}"; v="${kv#*=}"
    [ "$(prop_get "$k")" = "$v" ] && prop_del "$k"
  done
  cur=$(prop_get persist.vendor.bt.a2dp_offload_cap)
  case "$cur" in *aptx*|*ldac*) prop_del persist.vendor.bt.a2dp_offload_cap ;; esac

  touch "$STATE_DIR/.legacy_props" 2>/dev/null
  log legacy "props cleaned"
}

# ---------- 旧版残留：settings / 混音器 / 目录 ----------
legacy_cleanup_late() {
  [ -f "$STATE_DIR/.legacy_late" ] && return 0

  if [ -f "$LEGACY_DIR/anim_backup.list" ]; then
    set -- $(cat "$LEGACY_DIR/anim_backup.list" 2>/dev/null)
    [ -n "$1" ] || set -- 1.0 "$2" "$3"
    [ -n "$2" ] || set -- "$1" 1.0 "$3"
    [ -n "$3" ] || set -- "$1" "$2" 1.0
    settings put global window_animation_scale "$1" 2>/dev/null
    settings put global transition_animation_scale "$2" 2>/dev/null
    settings put global animator_duration_scale "$3" 2>/dev/null
    rm -f "$LEGACY_DIR/anim_backup.list"
  fi
  if [ -f "$LEGACY_DIR/net_backup.list" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      p="${line%%=*}"; v="${line#*=}"
      [ -f "$p" ] && echo "$v" > "$p" 2>/dev/null
    done < "$LEGACY_DIR/net_backup.list"
    rm -f "$LEGACY_DIR/net_backup.list"
  fi
  if [ -f "$LEGACY_DIR/privdns_backup.list" ]; then
    m=$(sed -n '1p' "$LEGACY_DIR/privdns_backup.list" 2>/dev/null)
    s=$(sed -n '2p' "$LEGACY_DIR/privdns_backup.list" 2>/dev/null)
    [ -n "$m" ] && settings put global private_dns_mode "$m" 2>/dev/null
    settings put global private_dns_spec "$s" 2>/dev/null
    rm -f "$LEGACY_DIR/privdns_backup.list"
  fi
  if [ -f "$LEGACY_DIR/audio_backup.list" ]; then
    tm=$(find_tinymix)
    if [ -n "$tm" ]; then
      while IFS='|' read -r id name orig; do
        [ -n "$id" ] && [ -n "$orig" ] && "$tm" "$id" "$orig" >/dev/null 2>&1
      done < "$LEGACY_DIR/audio_backup.list"
    fi
    rm -f "$LEGACY_DIR/audio_backup.list"
  fi

  rm -f /dev/.ufcs_pid /dev/.ufcs_bk_loop /dev/.ufcs_starting /dev/.gms_intl_opt_wd 2>/dev/null
  if [ -f /data/adb/modules/UFCS/webroot/.managed_by_zzz ] && [ ! -f /data/adb/modules/UFCS/module.prop ]; then
    rm -rf /data/adb/modules/UFCS 2>/dev/null
  fi
  rm -rf /data/adb/ufcs_curve 2>/dev/null

  for d in /data/oplus/atlas /data/oplus/cota /data/oplus/cosa /data/oplus/ocs /data/system/cota /data/system/atlas /data/system/cosa; do
    grep -q " $d " /proc/mounts 2>/dev/null && umount "$d" 2>/dev/null
  done

  rm -rf "$LEGACY_DIR" 2>/dev/null
  touch "$STATE_DIR/.legacy_late" 2>/dev/null
  log legacy "late cleaned"
}
