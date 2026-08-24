---
name: watch-slack
description: Watch Slack #notifications for replies addressed to this Claude pane, so the user can wake the agent by replying in the pane's notification thread. Use when the user says "/watch-slack", "watch slack", "listen for slack", or "monitor slack for me".
tools: Bash
---

# watch-slack

Surface Slack replies that are addressed to **this** Claude pane, so the user can
reply in the pane's `:claude:` notification thread to wake the agent.

## How it works

- A single **shared launchd service** runs `slack-noti-listen` *untargeted*. It
  holds the one Slack Socket Mode connection and writes every #notifications
  message — pre-tagged with the pane it belongs to — to a shared log
  (`~/.local/state/slack-noti/stream.log`).
- This skill arms a **per-pane consumer** (`watch-pane.sh`) that tails that log
  and emits only the lines tagged for the current pane, re-resolving the pane's
  live `session:window.pane` on every line so tmux window moves just work.

Why one shared listener: Slack delivers each Socket Mode event to only **one**
connection sharing the app token. Running a listener per pane would make Slack
round-robin events and starve panes. One socket, many local consumers.

## Steps

### 1. Ensure the shared listener service is running

Run `${CLAUDE_PLUGIN_ROOT}/scripts/watch-slack-service.sh status`. If it reports
`(not loaded)` or there is no log, run
`${CLAUDE_PLUGIN_ROOT}/scripts/watch-slack-service.sh install` to generate the
plist, bootstrap it, and start it. Confirm the log shows `connected`.

If `CLAUDE_PLUGIN_ROOT` is not set, resolve the scripts relative to this
SKILL.md (`../../scripts/`).

The listener needs `BOEHS_SLACK_NOTI_SOCKET_XAPP` (Socket Mode app token) and,
for pane-targeted threads, `BOEHS_SLACK_NOTI_BOT_XOXB` (bot token). The service
injects these via `fnox exec` when `fnox` is available. See the README for setup.

### 2. Arm the per-pane consumer with a persistent Monitor

Use the **Monitor** tool (persistent, long timeout) to run:

```
${CLAUDE_PLUGIN_ROOT}/scripts/watch-pane.sh
```

Each line the script emits is one event: a Slack reply addressed to this pane
(format `[time] session:window.pane ⤷ who: text`), or a socket reconnect/
disconnect notice. The script self-resolves the current pane from `$TMUX_PANE`,
so do **not** hardcode a pane id.

### 3. React to events

- A reply line is the user talking to **this** agent — treat it as input and
  respond. An event arriving while waiting is not necessarily the user's main
  reply; read it and decide.
- A `retrying` / `server asked to disconnect` line is just the socket bouncing;
  the service auto-reconnects. No action needed unless it loops.

## Important notes

- The skill never posts to Slack; it only listens. The user's own notification
  hook (e.g. `agent-notify`) is what creates the `:claude:` threads.
- One residual gap: a reply to a thread whose root was posted **before** a tmux
  move keeps the old pane id, so the move-aware consumer won't match it. Routing
  on the stable `$TMUX_PANE` id in the notify hook closes this; mention it if the
  user moves panes often.
- Other panes can watch too: each runs its own `watch-pane.sh` against the same
  shared log. They do not compete — the single socket lives in the service.
