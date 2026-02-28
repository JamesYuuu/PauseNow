#!/usr/bin/env bash
set -euo pipefail

PROJECT="PauseNow.xcodeproj"
SCHEME="PauseNow"
APP_NAME="PauseNow"
DESTINATION="platform=macOS"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/dist"
DMG_ROOT="$OUT_DIR/dmg-root"

log() {
  printf '[build] %s\n' "$*"
}

run() {
  log "$*"
  "$@"
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
  app_path="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/Release/${APP_NAME}.app" -print -quit)"
  if [[ -z "$app_path" ]]; then
    log "未找到 Release 产物：${APP_NAME}.app"
    log "请先运行: ./scripts/build.sh build-release"
    exit 1
  fi
  printf '%s\n' "$app_path"
}

package_dmg() {
  mkdir -p "$OUT_DIR"
  rm -rf "$DMG_ROOT"
  mkdir -p "$DMG_ROOT"

  local app_path
  app_path="$(find_release_app)"

  log "复制 app 到 DMG 临时目录"
  cp -R "$app_path" "$DMG_ROOT/"

  local dmg_path="$OUT_DIR/${APP_NAME}.dmg"
  log "生成 DMG: $dmg_path"
  hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_ROOT" -ov -format UDZO "$dmg_path" >/dev/null

  log "DMG 已生成: $dmg_path"
}

clean() {
  rm -rf "$OUT_DIR"
  log "已清理 dist 目录"
}

all() {
  test_standard
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
  all           测试 + Release 编译 + DMG 打包
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
