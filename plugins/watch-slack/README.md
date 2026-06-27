# watch-slack

Let the user **wake a Claude pane by replying in Slack**. A shared Socket Mode
listener streams a `#notifications` channel; a move-aware per-pane consumer
surfaces only the replies addressed to the current tmux pane.

## Usage

```
/watch-slack
```

## What it does

1. **Ensures a shared launchd service** is running `slack-noti-listen`
   *untargeted* — one Slack Socket Mode connection writing every #notifications
   message (pre-tagged by pane) to `~/.local/state/slack-noti/stream.log`.
2. **Arms a per-pane consumer** (`watch-pane.sh`) via a persistent Monitor that
   emits only the lines tagged for the current pane.
3. **Re-resolves the pane id on every line** from the stable `$TMUX_PANE`, so
   moving tmux windows around routes new messages correctly with no restart.

### Why one shared listener (not one per pane)

Slack delivers each Socket Mode event to exactly **one** connection sharing the
app-level token. N per-pane listeners would make Slack round-robin events and
starve panes. So: one supervised socket in launchd, many cheap local consumers.

## Requirements

- **macOS** (uses `launchctl` / `plutil` for the LaunchAgent).
- **tmux** — pane routing is keyed on `$TMUX_PANE`.
- **A mise-managed Ruby** with the `async` / `async-websocket` gems available to
  `slack-noti-listen`. The service puts `~/.local/share/mise/shims` first on
  `PATH` so `#!/usr/bin/env ruby` resolves there, not to system Ruby.
- **A Slack app with Socket Mode** enabled, subscribed to `message.channels`
  (and/or `message.groups`), with its bot invited to the channel. To also stream
  **reactions**, subscribe to the `reaction_added` bot event.
- **Tokens**, supplied to the listener's environment:
  - `BOEHS_SLACK_NOTI_SOCKET_XAPP` — app-level token (`xapp-…`, `connections:write`).
  - `BOEHS_SLACK_NOTI_BOT_XOXB` — bot token (`xoxb-…`, `groups:history` /
    `channels:history`) — needed to resolve a reply's `:claude:` thread root to a
    pane target.
  - Optional: `BOEHS_SLACK_NOTI_CHANNEL`, `BOEHS_SLACK_NOTI_USER`.
- **Token injection:** if [`fnox`](https://github.com/jdx/fnox) is on `PATH`, the
  service runs the listener under `fnox exec --` so tokens come from the keychain.
  Otherwise the tokens must already be present in launchd's environment.
- **Name resolution** (optional, cosmetic): user/channel IDs are mapped to names
  via the `slk` cache (`~/.cache/slk/{users,channels}-boehs.json`). Unknown IDs
  fall back to the raw ID.

## The notification thread convention

The agent's own notification hook posts to #notifications with a header like
`:claude: code:1.0`, creating a thread per pane. When the user replies in that
thread, the listener tags the reply with the pane (`code:1.0`) and `watch-pane.sh`
routes it to the matching pane. This plugin is the **listener half**; the hook
that posts the threads (e.g. `claude-notify`) is separate.

## Service management

```
scripts/watch-slack-service.sh install     # generate plist, bootstrap, start (default)
scripts/watch-slack-service.sh status      # launchd state + log tail
scripts/watch-slack-service.sh restart     # kickstart
scripts/watch-slack-service.sh log         # tail -F the stream log
scripts/watch-slack-service.sh uninstall   # bootout + remove plist
```

Override the launchd label or log path with `WATCH_SLACK_LABEL` / `WATCH_SLACK_LOG`.

## Included scripts

- `scripts/slack-noti-listen` — Ruby Socket Mode listener (the bundled source of
  truth). Streams messages + thread replies; tags replies into `:claude:` panes.
- `scripts/watch-slack-service.sh` — install/manage the shared launchd service.
- `scripts/watch-pane.sh` — move-aware per-pane consumer of the shared log.

## Reactions

If the Slack app subscribes to `reaction_added`, an emoji reaction on a pane's
notification message is surfaced to that pane just like a reply:

```
[2026-06-27 17:48] code:2.0 ⤷ Eric reacted with :thumbsup:
```

Reactions obey the same user allowlist as messages — with `BOEHS_SLACK_NOTI_USER`
set to yourself, you only see your own reactions, never other people's. (Setting
the user filter to your own ID is the recommended config: it keeps the stream to
the messages and reactions that are actually you talking to the agent.)

## Resilience

The listener holds the socket open with the high-level read (which transparently
handles permessage-deflate and frame reassembly) and hooks the connection's
control-frame handlers to stamp a liveness clock on every server ping (~10s). A
watchdog reconnects if the socket goes silent for `BOEHS_SLACK_NOTI_IDLE_TIMEOUT`
seconds (default 30) — closing the silent-TCP-death gap where a dead socket left
`read` blocked forever with no reconnect.

## Known limitation

A reply to a thread whose root was posted **before** a tmux move keeps the old
positional pane id, so the consumer (now on the new id) won't match it. Routing
on the stable `$TMUX_PANE` handle inside the notify hook closes this gap.
