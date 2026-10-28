#!/system/bin/sh
# =============================================================
#  音质：外放扬声器增益 + 重采样质量；杜比/DAX 链路
#  安全约束：
#   · 只匹配 SPK / SPEAKER 且含 GAIN/VOLUME 的数值型控件
#   · 排除耳机/听筒/蓝牙/USB/麦克风/录音/通话/开关类
#   · 只在原值 > 0 时按百分比提升，并读取 (range a->b) 上限钳制
#   · 所有修改前备份，关闭即还原
# =============================================================

MIX_BAK="$STATE_DIR/mixer.list"

aud_log() { log audio "$*"; }

detect_spk() {
  tm=$(find_tinymix) || return 1
  "$tm" 2>/dev/null \
    | grep -iE 'SPK|SPEAKER' \
    | grep -iE 'GAIN|VOLUME|VOL' \
    | grep -viE 'HPH|HEAD|EARPIECE|EAR_|HANDSET|HEADSET|BT|A2DP|USB|MIC|CAPTURE|REC|VOICE|RX_|LINE|SWITCH|MAX|LIMIT|THRESH|MIN|CEILING' \
    | awk '{
        id=$1; gsub(/[^0-9]/,"",id);
        sep=0; for(i=1;i<=NF;i++) if($i ~ /^\(/) {sep=i;break}
        val=(sep>0)?$(sep-1):$NF;
        if(id!="" && val ~ /^[0-9]+$/) print id"|"val
      }'
}

backup_mixer() {
  [ -f "$MIX_BAK" ] && return 0
  tm=$(find_tinymix) || return 0
  detect_spk 2>/dev/null | while IFS='|' read -r id orig; do
    [ -n "$id" ] && [ "$orig" -gt 0 ] 2>/dev/null && echo "$id|$orig" >> "$MIX_BAK"
  done
  aud_log "mixer backup $(wc -l < "$MIX_BAK" 2>/dev/null) controls"
}

ctrl_max() {
  "$1" 2>/dev/null | grep -E "^[[:space:]]*$2[[:space:]]" | grep -oE 'range [0-9]+->[0-9]+' | tail -1 | sed 's/.*->//'
}

apply_speaker() {
  tm=$(find_tinymix) || { aud_log "no tinymix"; return 0; }
  backup_mixer
  [ -s "$MIX_BAK" ] || { aud_log "no speaker gain control"; return 0; }

  pct=4
  [ "$AUDIO_LEVEL" = "strong" ] && pct=8

  n=0
  while IFS='|' read -r id orig; do
    [ -n "$id" ] || continue
    [ "$orig" -gt 0 ] 2>/dev/null || continue
    nv=$(( orig + orig * pct / 100 ))
    [ "$nv" -le "$orig" ] && nv=$(( orig + 1 ))
    max=$(ctrl_max "$tm" "$id")
    if [ -n "$max" ] && [ "$max" -gt 0 ] && [ "$nv" -gt "$max" ]; then nv=$max; fi
    [ "$nv" -eq "$orig" ] && continue   # 已到上限，无需写入
    "$tm" "$id" "$nv" >/dev/null 2>&1 && n=$((n + 1))
  done < "$MIX_BAK"
  aud_log "speaker gain +${pct}% on $n control(s)"
}

restore_speaker() {
  tm=$(find_tinymix) || return 0
  [ -f "$MIX_BAK" ] || return 0
  while IFS='|' read -r id orig; do
    [ -n "$id" ] && [ -n "$orig" ] && "$tm" "$id" "$orig" >/dev/null 2>&1
  done < "$MIX_BAK"
  rm -f "$MIX_BAK" 2>/dev/null
  aud_log "speaker gain restored"
}

# ---------- 杜比 ----------
dolby_present() {
  for p in /vendor/etc/dolby /vendor/etc/dolby/dax-default.xml \
           /vendor/lib64/soundfx/libdax.so /vendor/lib/soundfx/libdax.so \
           /vendor/lib64/libdapdap.so /vendor/lib/libdapdap.so; do
    [ -e "$p" ] && return 0
  done
  ls /vendor/bin/hw 2>/dev/null | grep -qiE 'dolby|dms' && return 0
  getprop 2>/dev/null | grep -qiE 'dolby|dax' && return 0
  return 1
}

apply_dolby() {
  if [ "$DOLBY_ENHANCE" != "true" ]; then
    restore_prop persist.vendor.dolby.enable
    restore_prop persist.vendor.dolby.dax.enable
    return 0
  fi
  if ! dolby_present; then
    echo "0" > "$STATE_DIR/dolby.detected"
    aud_log "dolby components not found, skipped"
    return 0
  fi
  echo "1" > "$STATE_DIR/dolby.detected"
  # 只点亮两枚开关，不碰任何音频通路/编解码/offload 属性
  apply_prop persist.vendor.dolby.enable true
  apply_prop persist.vendor.dolby.dax.enable true
  aud_log "dolby/dax enabled"
}

# post-fs-data 阶段只做属性；混音器需等音频 HAL 就绪（service 阶段）
apply_audio_props() {
  if [ "$AUDIO_ENHANCE" = "true" ]; then
    apply_prop af.resampler.quality 4
  else
    restore_prop af.resampler.quality
  fi
  apply_dolby
}

apply_audio() {
  apply_audio_props
  if [ "$AUDIO_ENHANCE" = "true" ]; then apply_speaker; else restore_speaker; fi
}
