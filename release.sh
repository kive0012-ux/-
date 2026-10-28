#!/usr/bin/env bash
# 用法：bash release.sh v1.0 100 kive0012-ux/-
set -e
ver="${1:?缺少版本号}"; code="${2:?缺少 versionCode}"; repo="${3:?缺少 owner/repo}"
cd "$(dirname "$0")"
[ -f META-INF/com/google/android/update-binary ] || { echo "缺少 META-INF"; exit 1; }
sed -i "s|^version=.*|version=$ver|" module.prop
sed -i "s|^versionCode=.*|versionCode=$code|" module.prop
raw="https://raw.githubusercontent.com/$repo/main"
cat > update.json <<EOF
{
  "version": "$ver",
  "versionCode": $code,
  "zipUrl": "$raw/GMS-Intl-Optimizer.zip",
  "changelog": "$raw/changelog.md"
}
EOF
sed -i "s|^updateJson=.*|updateJson=$raw/update.json|" module.prop
chmod 755 ./*.sh META-INF/com/google/android/update-binary 2>/dev/null
rm -f GMS-Intl-Optimizer.zip
zip -r -q GMS-Intl-Optimizer.zip . -x 'GMS-Intl-Optimizer.zip' 'release.sh' '*.DS_Store' '.git/*'
echo "已生成 update.json 与 GMS-Intl-Optimizer.zip ($(du -h GMS-Intl-Optimizer.zip | cut -f1))"
