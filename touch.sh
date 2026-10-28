#!/system/bin/sh
# =============================================================
#  触控跟手增强（只改安全的输入/滚动属性，不碰触控采样率硬件节点）
#  soft  = 日常：事件吞吐 180、滑动惯性略增
#  strong = 竞技：事件吞吐 300、滑动惯性更跟手
# =============================================================

touch_log() { log touch "$*"; }

apply_touch() {
  if [ "$TOUCH_ENHANCE" != "true" ]; then
    for k in windowsmgr.max_events_per_sec view.maximum_fling_velocity ro.max.fling_velocity view.minimum_fling_velocity ro.min.fling_velocity; do
      restore_prop "$k"
    done
    echo "off" > "$STATE_DIR/touch.level"
    return 0
  fi

  if [ "$TOUCH_LEVEL" = "strong" ]; then
    apply_prop windowsmgr.max_events_per_sec 300
    apply_prop view.maximum_fling_velocity 12000
    apply_prop ro.max.fling_velocity 12000
    apply_prop view.minimum_fling_velocity 60
    apply_prop ro.min.fling_velocity 60
    echo "strong" > "$STATE_DIR/touch.level"
  else
    apply_prop windowsmgr.max_events_per_sec 180
    apply_prop view.maximum_fling_velocity 8000
    apply_prop ro.max.fling_velocity 8000
    apply_prop view.minimum_fling_velocity 50
    apply_prop ro.min.fling_velocity 50
    echo "soft" > "$STATE_DIR/touch.level"
  fi
  touch_log "touch applied level=${TOUCH_LEVEL}"
}
