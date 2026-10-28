#!/bin/bash
# 매크로 키보드 앱 2개 빌드: app/ 폴더에서 ./build.sh
#   매크로 키보드 설정.app  (MacroPad.swift)  — 키 배치 바꾸고 키보드에 올리기
#   매크로 키보드 실행기.app (Launcher.swift) — 메뉴 막대에서 F13~F20 받아 앱 실행
set -e
cd "$(dirname "$0")"

# 앱 아이콘: make-icon.swift가 그린 1024 PNG → AppIcon.icns (두 앱이 같이 씀)
ICONTMP="$(mktemp -d)"
swift make-icon.swift "$ICONTMP/icon.png" >/dev/null
mkdir "$ICONTMP/AppIcon.iconset"
for s in 16 32 128 256 512; do
  sips -z $s $s "$ICONTMP/icon.png" --out "$ICONTMP/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$ICONTMP/icon.png" --out "$ICONTMP/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONTMP/AppIcon.iconset" -o "$ICONTMP/AppIcon.icns"

# build <앱 이름> <소스> <실행 파일 이름> <번들 ID> <추가 plist 줄>
build() {
  local APP="../$1.app"
  rm -rf "$APP"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
  cp "$ICONTMP/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
  swiftc -O -swift-version 5 -parse-as-library "$2" -o "$APP/Contents/MacOS/$3"
  cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>$3</string>
  <key>CFBundleIdentifier</key><string>$4</string>
  <key>CFBundleName</key><string>$1</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  $5
</dict></plist>
PLIST
  xattr -cr "$APP"
  codesign --force --sign - "$APP"
  echo "BUILD_OK: $APP"
}

build "매크로 키보드 설정" MacroPad.swift MacroPad com.ethan.macropad \
  '<key>NSAppleEventsUsageDescription</key><string>키보드에 설정을 올릴 때 관리자 권한을 요청합니다.</string>'
build "매크로 키보드 실행기" Launcher.swift MacroPadLauncher com.ethan.macropad.launcher \
  '<key>LSUIElement</key><true/>'
