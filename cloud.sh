#!/system/bin/sh
# =============================================================
#  云控：只做域名屏蔽（systemless hosts）
#  不禁用任何 App、不冻结任何目录，避免 OCS/游戏助手类误伤与弹窗
# =============================================================

build_hosts() {
  HF="$MODDIR/system/etc/hosts"
  mkdir -p "${HF%/*}" 2>/dev/null
  {
    echo "127.0.0.1 localhost"
    echo "::1 localhost"
    if [ "$BLOCK_CLOUD" = "true" ]; then
      echo "# OPPO/一加 云控下发域名（ColorOS 日用增强）"
      for d in $CLOUD_DOMAINS; do echo "127.0.0.1 $d"; done
    fi
  } > "$HF" 2>/dev/null
  log cloud "hosts rebuilt block_cloud=$BLOCK_CLOUD"
}
