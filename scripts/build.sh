#!/usr/bin/env bash
set -euo pipefail

PROJECT="PauseNow.xcodeproj"
SCHEME="PauseNow"
SOURCE_APP_NAME="PauseNow"
DIST_APP_NAME="稍息"
DESTINATION="platform=macOS"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/dist"
DMG_ROOT="$OUT_DIR/dmg-root"
STAGING_DMG="$OUT_DIR/${DIST_APP_NAME}-staging.dmg"

log() {
  printf '[build] %s\n' "$*"
}

run() {
  log "$*"
  "$@"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "缺少命令: $1"
    exit 1
  fi
}

build_debug() {
  run xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug build
}

build_release() {
  run xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release build
}

test_standard() {
  run xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" test
}

test_nosign() {
  run xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test
}

find_release_app() {
  local app_path
  app_path="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/Release/${SOURCE_APP_NAME}.app" -print -quit)"
  if [[ -z "$app_path" ]]; then
    log "未找到 Release 产物：${SOURCE_APP_NAME}.app"
    log "请先运行: ./scripts/build.sh build-release"
    exit 1
  fi
  printf '%s\n' "$app_path"
}

package_dmg() {
  mkdir -p "$OUT_DIR"
  rm -rf "$DMG_ROOT"
  mkdir -p "$DMG_ROOT"
  mkdir -p "$DMG_ROOT/.background"

  local app_path
  app_path="$(find_release_app)"

  log "复制 app 到 DMG 临时目录"
  cp -R "$app_path" "$DMG_ROOT/${DIST_APP_NAME}.app"
  ln -s /Applications "$DMG_ROOT/Applications"

  log "生成 DMG 背景图"
  BG_IMAGE_PATH="$DMG_ROOT/.background/background.png" swift - <<'SWIFT'
import AppKit
import Foundation

let outputPath = ProcessInfo.processInfo.environment["BG_IMAGE_PATH"]!
let canvas = NSSize(width: 640, height: 360)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvas.width),
    pixelsHigh: Int(canvas.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("failed to create bitmap canvas\n", stderr)
    exit(1)
}

guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
    fputs("failed to create graphics context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx

let rect = NSRect(origin: .zero, size: canvas)
NSColor(calibratedRed: 0.96, green: 0.98, blue: 0.97, alpha: 1).setFill()
rect.fill()

let subtitle = "把稍息拖动到 Applications 文件夹"
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.20, alpha: 1),
    .paragraphStyle: paragraph
]

subtitle.draw(in: NSRect(x: 20, y: 34, width: 600, height: 40), withAttributes: subtitleAttrs)
NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to encode background image\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
SWIFT

  local dmg_path="$OUT_DIR/${DIST_APP_NAME}.dmg"
  rm -f "$dmg_path"
  rm -f "$STAGING_DMG"

  log "创建可写入的临时 DMG"
  hdiutil create -volname "$DIST_APP_NAME" -srcfolder "$DMG_ROOT" -ov -format UDRW "$STAGING_DMG" >/dev/null

  local attach_output
  attach_output="$(hdiutil attach -readwrite -noverify -noautoopen "$STAGING_DMG")"
  local device
  local mount_point
  local disk_name
  device="$(echo "$attach_output" | awk '/\/Volumes\// {print $1; exit}')"
  mount_point="$(echo "$attach_output" | awk 'match($0,/\/Volumes\/.*/){print substr($0,RSTART); exit}')"
  disk_name="$(basename "$mount_point")"

  if [[ -n "$mount_point" ]]; then
    log "设置 DMG Finder 布局"
    local bg_alias_path="$mount_point/.background/background.png"
    if ! osascript <<APPLESCRIPT
tell application "Finder"
  set bgAlias to POSIX file "$bg_alias_path" as alias
  tell disk "$disk_name"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 120, 760, 480}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 128
    set text size of opts to 13
    set background picture of opts to bgAlias
    set position of item "$DIST_APP_NAME.app" of container window to {180, 210}
    set position of item "Applications" of container window to {460, 210}
    update without registering applications
    delay 2
    close
  end tell
end tell
APPLESCRIPT
    then
      log "警告：Finder 布局设置失败，将继续生成可安装 DMG"
    fi
  else
    log "警告：未获取挂载点，跳过 Finder 布局设置"
  fi

  sync
  if [[ -n "$device" ]]; then
    hdiutil detach "$device" >/dev/null
  fi

  log "压缩生成发布 DMG: $dmg_path"
  hdiutil convert "$STAGING_DMG" -ov -format UDZO -o "$dmg_path" >/dev/null
  rm -f "$STAGING_DMG"

  log "DMG 已生成: $dmg_path"
}

clean() {
  rm -rf "$OUT_DIR"
  log "已清理 dist 目录"
}

all() {
  build_release
  package_dmg
}

usage() {
  cat <<USAGE
用法: ./scripts/build.sh <command>

常用命令:
  test          运行标准测试
  test-nosign   无签名模式运行测试（本机签名问题时使用）
  build-debug   Debug 编译
  build-release Release 编译
  package-dmg   生成 DMG（需先有 Release .app）
  all           Release 编译 + DMG 打包（一键打包）
  clean         清理 dist 目录
  help          显示帮助
USAGE
}

main() {
  cd "$ROOT_DIR"

  local cmd="${1:-help}"
  case "$cmd" in
    test) test_standard ;;
    test-nosign) test_nosign ;;
    build-debug) build_debug ;;
    build-release) build_release ;;
    package-dmg) package_dmg ;;
    all) all ;;
    clean) clean ;;
    help|-h|--help) usage ;;
    *)
      log "未知命令: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"
