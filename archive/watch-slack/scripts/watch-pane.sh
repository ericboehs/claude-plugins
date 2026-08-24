#!/usr/bin/env bash

# watch-pane.sh — tail the shared slack-noti stream and emit only the lines
# destined for THIS tmux pane's :claude: notification thread.
#
# The shared listener (slack-noti-listen, run untargeted by the launchd service)
# pre-tags every reply with the pane it belongs to, e.g.
#   [2026-06-27 15:08] code:1.0 ⤷ Eric: Testing it now
# This consumer re-resolves its OWN pane's live `session:window.pane` from the
# stable $TMUX_PANE handle on EVERY line, so moving windows around in tmux is
# handled automatically — the next message just routes to the new id.
#
# Reconnect / disconnect notices are NOT surfaced individually: Slack routinely
# asks Socket Mode clients to reconnect (~hourly, to rebalance load) and the
# listener self-heals, so each bounce is benign noise. We only emit a notice
# when the socket is genuinely LOOPING — RECONNECT_THRESHOLD bounces within
# RECONNECT_WINDOW seconds — which is the case a supervising agent should act on.
#
# Usage: watch-pane.sh [stream_log_path]
#   Default log: $HOME/.local/state/slack-noti/stream.log

LOG="${1:-$HOME/.local/state/slack-noti/stream.log}"

# Loop detection for socket reconnects (see note above).
RECONNECT_THRESHOLD="${BOEHS_SLACK_NOTI_RECONNECT_THRESHOLD:-3}"
RECONNECT_WINDOW="${BOEHS_SLACK_NOTI_RECONNECT_WINDOW:-120}"

# Optional host label, mirroring agent-notify's AGENT_NOTIFY_HOST. When set, this
# pane's target is matched as "<host>:session:window.pane" (e.g. "gfe:code:1.0"),
# so a stream forwarded from another machine — whose listener tagged lines with the
# host-prefixed pane id — routes to the right pane here. Unset = bare pane id.
HOST_LABEL="${BOEHS_SLACK_NOTI_HOST:-${AGENT_NOTIFY_HOST:-}}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $(basename "$0") [stream_log_path]"
  echo ""
  echo "Tail the shared slack-noti stream and surface only messages tagged for"
  echo "the current tmux pane (re-resolved live, so tmux moves just work)."
  exit 0
fi

if [[ -z "$TMUX_PANE" ]]; then
  echo "watch-pane: not running inside tmux (\$TMUX_PANE unset); nothing to route." >&2
  echo "watch-pane: messages are tagged by pane, so a pane id is required." >&2
  exit 1
fi

if [[ ! -e "$LOG" ]]; then
  echo "watch-pane: stream log not found at $LOG" >&2
  echo "watch-pane: start the shared listener first (watch-slack-service.sh install)." >&2
  exit 1
fi

# -n0: start at end (no replay). -F: keep following across rotation/recreate.
recon_times=()  # epoch seconds of recent reconnect notices (sliding window)
tail -n0 -F "$LOG" | while IFS= read -r line; do
  # Re-resolve our pane's CURRENT positional id every line: $TMUX_PANE (%N) is
  # stable across moves, but session:window.pane changes when windows move.
  me=$(tmux display-message -t "$TMUX_PANE" -p '#S:#{window_index}.#{pane_index}' 2>/dev/null)
  # When HOST_LABEL is set this machine consumes a stream forwarded from another
  # host, whose lines are tagged with the host-prefixed pane id (e.g. gfe:code:1.0).
  [[ -n "$HOST_LABEL" ]] && me="${HOST_LABEL}:${me}"
  case "$line" in
    *" $me ⤷ "*)
      printf '%s\n' "$line"
      # Engaging with this pane's thread (a reply or reaction) means you've
      # already seen it — clear the pane's @special_activity (⊙) indicator,
      # the same way focusing the pane does (see .tmux.conf pane-focus-in hook).
      tmux set-window-option -t "$TMUX_PANE" -u @special_activity 2>/dev/null || true
      ;;
    *retrying*|*"server asked to disconnect"*)
      # Record this bounce and prune anything outside the sliding window.
      now=$(date +%s)
      kept=()
      for t in "${recon_times[@]}"; do
        (( now - t < RECONNECT_WINDOW )) && kept+=("$t")
      done
      kept+=("$now")
      recon_times=("${kept[@]}")
      # Only surface when the socket is actually looping; then reset so we warn
      # once per burst rather than on every line.
      if (( ${#recon_times[@]} >= RECONNECT_THRESHOLD )); then
        printf '[watch-pane] Slack socket reconnecting repeatedly (%d times in %ds) — possible loop\n' \
          "${#recon_times[@]}" "$RECONNECT_WINDOW"
        recon_times=()
      fi
      ;;
  esac
done
