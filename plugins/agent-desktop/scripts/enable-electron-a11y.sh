#!/usr/bin/env bash
# Enable an Electron/Chromium app's full accessibility tree on macOS so
# agent-desktop sees more than the ~3-ref stub. Sets AXManualAccessibility=YES
# on the app's AX element (the documented Electron opt-in). Idempotent.
#
# Usage: enable-electron-a11y.sh <app-name|bundle-id|pid>
# Then re-snapshot, e.g.: agent-desktop snapshot --app Slack -i --compact
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo '{"ok":false,"error":"usage: enable-electron-a11y.sh <app-name|bundle-id|pid>"}' >&2
  exit 2
fi

# Locate the Swift source: prefer the plugin root, fall back to this script's dir.
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/enable-electron-a11y.swift" ]; then
  SWIFT_SRC="${CLAUDE_PLUGIN_ROOT}/scripts/enable-electron-a11y.swift"
else
  SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SWIFT_SRC="${SELF_DIR}/enable-electron-a11y.swift"
fi

if ! command -v swift >/dev/null 2>&1; then
  echo '{"ok":false,"error":"swift not found (install Xcode or Command Line Tools)"}' >&2
  exit 1
fi

exec swift "$SWIFT_SRC" "$@"
