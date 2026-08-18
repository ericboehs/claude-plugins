# archive

Plugins that are no longer installed or listed in the marketplace, kept because
the code may be worth resurrecting. Nothing here is loaded by Claude Code — the
marketplace only lists `./plugins/*`.

## watch-slack — retired 2026-08-18

Routed replies from a Claude notification's Slack thread back into the tmux pane
that posted it, via one Socket Mode listener (`slack-noti-listen`) writing a
shared stream log, plus a per-pane consumer (`watch-pane.sh`) that grepped it.
The Claude mobile app covers answering from away now, so the return path is not
worth a long-lived listener.

Outbound notifications are unaffected: `claude-notify` posts through `slack-noti`
(an incoming-webhook one-liner in dotfiles), which was never part of this plugin.

To bring it back, know that it had been silently dead since 2026-06-29:
`com.boehs.slack-noti-listen.plist` pointed at `~/Code/ericboehs/claude-plugins/…`,
missing the `github.com/` path segment, so the listener exited immediately and
launchd restarted it every 10s (`KeepAlive` + `ThrottleInterval 10`) for seven
weeks, growing the stream log to 97MB. Fix the path that
`scripts/watch-slack-service.sh` writes into the plist before reinstalling.

Also removed when it was retired: `~/bin/slack-noti-listen`,
`~/.local/libexec/slack-noti-forward-gfe` (the ssh relay feeding the GFE box a
copy of the stream, since Slack delivers each Socket Mode event to only one
connection), both launchd plists, and `~/.local/state/slack-noti/` on both hosts.
