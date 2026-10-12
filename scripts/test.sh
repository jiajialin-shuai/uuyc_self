#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

# XCTest 随完整 Xcode 提供；仅为本次命令选择工具链，不修改系统 xcode-select。
if [[ -z "${DEVELOPER_DIR:-}" && "$(xcode-select -p)" == "/Library/Developer/CommandLineTools" ]]; then
  for candidate in /Applications/Xcode.app/Contents/Developer /Applications/Xcode-beta.app/Contents/Developer; do
    if [[ -d "$candidate" ]]; then
      export DEVELOPER_DIR="$candidate"
      break
    fi
  done
fi

swift test --build-system native --jobs 2
