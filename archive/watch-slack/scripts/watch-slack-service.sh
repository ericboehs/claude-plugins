#!/usr/bin/env bash

# watch-slack-service.sh — install / manage the shared slack-noti-listen
# launchd LaunchAgent (macOS).
#
# ONE shared, untargeted listener holds the single Slack Socket Mode connection
# and writes every #notifications message (pre-tagged by pane) to a shared log.
# Per-pane consumers (watch-pane.sh) grep that log. Running N *targeted*
# listeners would make Slack round-robin each event to exactly one connection
# and starve the others — hence a single supervised service.
#
# Subcommands:
#   install     Generate the plist, (re)bootstrap, and start it. (default)
#   status      Show launchd state + tail the log.
#   restart     Kickstart the running service.
#   log         Tail -f the shared stream log.
#   uninstall   Bootout the service and remove the plist.
#
# Overridable via env:
#   WATCH_SLACK_LABEL   launchd label   (default com.boehs.slack-noti-listen)
#   WATCH_SLACK_LOG     stream log path (default ~/.local/state/slack-noti/stream.log)

set -euo pipefail

LABEL="${WATCH_SLACK_LABEL:-com.boehs.slack-noti-listen}"
LOG="${WATCH_SLACK_LOG:-$HOME/.local/state/slack-noti/stream.log}"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_NUM="$(id -u)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LISTENER="$SCRIPT_DIR/slack-noti-listen"   # bundled source of truth

die() { echo "watch-slack-service: $*" >&2; exit 1; }

# Build the launchd PATH: mise shims first (so the listener's `#!/usr/bin/env
# ruby` resolves to a mise-managed ruby, not system 2.6), then homebrew + system.
build_path() {
  local p=""
  [[ -d "$HOME/.local/share/mise/shims" ]] && p="$HOME/.local/share/mise/shims"
  for d in /opt/homebrew/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin; do
    [[ -d "$d" ]] && p="${p:+$p:}$d"
  done
  printf '%s' "$p"
}

# ProgramArguments: wrap with `fnox exec --` if fnox is on PATH (injects the
# BOEHS_SLACK_NOTI_* tokens from the keychain); otherwise run the listener
# directly and rely on the environment already carrying the tokens.
program_args_xml() {
  local fnox_bin
  if fnox_bin="$(command -v fnox 2>/dev/null)"; then
    cat <<XML
    <string>$fnox_bin</string>
    <string>exec</string>
    <string>--</string>
    <string>$LISTENER</string>
XML
  else
    echo "    <string>$LISTENER</string>"
  fi
}

write_plist() {
  mkdir -p "$(dirname "$PLIST")" "$(dirname "$LOG")"
  cat > "$PLIST" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>

  <!-- One shared, untargeted listener holds the single Socket Mode connection
       and writes every #notifications message (pre-tagged by pane) to the
       shared log. Per-pane consumers grep that log; running N targeted
       listeners would make Slack round-robin events and starve each pane. -->
  <key>ProgramArguments</key>
  <array>
$(program_args_xml)
  </array>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$(build_path)</string>
  </dict>

  <key>WorkingDirectory</key>
  <string>$HOME</string>

  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>10</integer>
  <key>ProcessType</key>
  <string>Background</string>

  <key>StandardOutPath</key>
  <string>$LOG</string>
  <key>StandardErrorPath</key>
  <string>$LOG</string>
</dict>
</plist>
XML
}

cmd_install() {
  [[ -x "$LISTENER" ]] || die "bundled listener not executable: $LISTENER"
  command -v plutil >/dev/null 2>&1 || die "this installer targets macOS (plutil not found)"
  write_plist
  plutil -lint "$PLIST" >/dev/null || die "generated plist failed validation"
  # Clean any prior instance, then bootstrap fresh so path/arg changes take hold.
  # bootout is async — wait for the label to actually unload before bootstrapping,
  # else launchd returns "5: Input/output error" (still-loaded race).
  launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    launchctl print "gui/$UID_NUM/$LABEL" >/dev/null 2>&1 || break
    sleep 1
  done
  launchctl bootstrap "gui/$UID_NUM" "$PLIST"
  launchctl enable "gui/$UID_NUM/$LABEL" 2>/dev/null || true
  launchctl kickstart "gui/$UID_NUM/$LABEL" 2>/dev/null || true
  sleep 1
  echo "Installed and started: $LABEL"
  cmd_status
}

cmd_status() {
  echo "--- launchd ---"
  launchctl print "gui/$UID_NUM/$LABEL" 2>/dev/null \
    | grep -E "state =|pid =|program =|last exit" | head || echo "(not loaded)"
  echo "--- log tail ($LOG) ---"
  [[ -e "$LOG" ]] && tail -n 5 "$LOG" || echo "(no log yet)"
}

cmd_restart() { launchctl kickstart -k "gui/$UID_NUM/$LABEL"; echo "restarted: $LABEL"; }
cmd_log()     { exec tail -n 20 -F "$LOG"; }
cmd_uninstall() {
  launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
  rm -f "$PLIST"
  echo "Uninstalled: $LABEL (log left at $LOG)"
}

case "${1:-install}" in
  install)   cmd_install ;;
  status)    cmd_status ;;
  restart)   cmd_restart ;;
  log)       cmd_log ;;
  uninstall) cmd_uninstall ;;
  -h|--help) sed -n '3,30p' "$0" ;;
  *) die "unknown subcommand '$1' (install|status|restart|log|uninstall)" ;;
esac
