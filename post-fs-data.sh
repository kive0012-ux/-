#!/system/bin/sh
# post-fs-data：旧版属性清理 -> hosts -> 触控/音质(属性层)
MODDIR=${0%/*}
case "$MODDIR" in ""|"$0") MODDIR=. ;; esac

. "$MODDIR/config.sh"
. "$MODDIR/lib.sh"
. "$MODDIR/cloud.sh"
. "$MODDIR/audio.sh"
. "$MODDIR/touch.sh"

legacy_cleanup_props
build_hosts
apply_audio_props
apply_touch
exit 0
