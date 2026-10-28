#!/system/bin/sh
ui_print " "
ui_print "*****************************"
ui_print " ColorOS 日用增强  v1.0"
ui_print " 音质 / 杜比 / 触控 / 推送 / 云控"
ui_print "*****************************"
ui_print " "
ui_print "- 安装后重启一次生效"
ui_print "- 开关请在 KernelSU / APatch / MMRL 的 WebUI 中调整"
ui_print "- 官方 Magisk App 无 WebUI，可用 action.sh"
ui_print "- 不禁用任何系统 App；所有属性先备份，可一键还原"
ui_print " "

chmod 755 "$MODPATH"/*.sh 2>/dev/null
chmod 644 "$MODPATH"/webroot/index.html "$MODPATH"/system/etc/hosts 2>/dev/null
