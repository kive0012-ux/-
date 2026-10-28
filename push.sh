#!/system/bin/sh
# =============================================================
#  推送保活：GMS / OPPO
#  常规：Doze 白名单 + 后台 appops
#  深度：再加自动启动、active 待机桶、数据节流白名单
# =============================================================

push_log() { log push "$*"; }

pkg_uid() {
  cmd package list packages -U "$1" 2>/dev/null | sed -n 's/.*uid:\([0-9]*\).*/\1/p' | head -n1
}

apply_push_one() {
  p="$1"
  cmd deviceidle whitelist +"$p" >/dev/null 2>&1
  cmd appops set "$p" RUN_IN_BACKGROUND allow >/dev/null 2>&1
  cmd appops set "$p" RUN_ANY_IN_BACKGROUND allow >/dev/null 2>&1
  cmd appops set "$p" START_FOREGROUND allow >/dev/null 2>&1
  cmd appops set "$p" WAKE_LOCK allow >/dev/null 2>&1
  [ "$DEEP_PUSH" = "true" ] || return 0
  cmd appops set "$p" AUTO_START allow >/dev/null 2>&1
  cmd am set-standby-bucket "$p" active >/dev/null 2>&1
  uid=$(pkg_uid "$p")
  [ -n "$uid" ] && cmd netpolicy add restrict-background-whitelist "$uid" >/dev/null 2>&1
}

drop_push_one() {
  p="$1"
  cmd deviceidle whitelist -"$p" >/dev/null 2>&1
  cmd appops reset "$p" >/dev/null 2>&1
  uid=$(pkg_uid "$p")
  [ -n "$uid" ] && cmd netpolicy remove restrict-background-whitelist "$uid" >/dev/null 2>&1
}

apply_push() {
  build_pkg_list
  n=0
  for p in $PKG_LIST; do
    [ -z "$p" ] && continue
    apply_push_one "$p"
    n=$((n + 1))
  done
  push_log "keepalive applied: $n pkg(s), deep=$DEEP_PUSH"
}

drop_push_all() {
  for p in $(echo $ALL_PKGS $EXTRA_PKGS | tr ' ' '\n' | sort -u); do
    [ -z "$p" ] && continue
    drop_push_one "$p"
  done
  push_log "keepalive dropped"
}
