---
name: agent-desktop
description: Automate macOS apps via the accessibility tree using the agent-desktop CLI. Snapshot UI, click/type/select by element ref, manage windows, screenshot. Use when asked to control, drive, or automate a Mac app, read or act on on-screen UI, "snapshot an app", or "/agent-desktop".
tools: Bash
---

# agent-desktop (macOS accessibility automation)

Drive native macOS apps through the OS accessibility tree with the `agent-desktop` CLI. It is NOT an agent; it is a tool you (the agent) invoke. Every command prints a JSON envelope on stdout; you run the observe→act→observe loop.

## Prerequisites

`agent-desktop` must be on PATH and the launching terminal needs Accessibility permission (Screen Recording too, for screenshots). Check with `agent-desktop status`; it reports both permissions and the latest snapshot. If the command is missing or a binary error appears, suggest `/setup-agent-desktop`.

## The loop

```
snapshot → decide → act → snapshot → decide → act → ...
```

Refs (`@e1`, `@e2`, …) are assigned per snapshot and scoped to a `snapshot_id` (e.g. `s8f3k2p9`). Pass `--snapshot <id>` on ref commands for determinism; it does not require `--session`.

### Dense apps: skeleton then drill (saves 60–96% tokens)

```bash
# 1. shallow depth-3 map; truncated containers show children_count and get refs
agent-desktop snapshot --skeleton --app Xcode -i --compact   # keep snapshot_id

# 2. drill into ONE region instead of re-dumping the whole tree
agent-desktop snapshot --root @e11 --snapshot <id> -i --compact

# 3. act on something revealed in the drill
agent-desktop click @e57 --snapshot <id>

# 4. re-drill the same region to verify (scoped invalidation: only @e11's subtree refs change)
agent-desktop snapshot --root @e11 --snapshot <id> -i --compact
```

### Simple apps: full snapshot is fine

```bash
agent-desktop snapshot --app Finder -i --compact   # or use `find` if you know the element
agent-desktop find --role button --app TextEdit
```

### Electron apps: enable accessibility first, THEN snapshot

Electron/Chromium apps (Slack, VS Code, Discord, Notion, Obsidian, Teams, Figma) ship their full a11y tree turned OFF for performance. Until something flips it on, every snapshot returns only a ~3-ref stub. Set `AXManualAccessibility=YES` on the app once per launch with the bundled helper, then proceed as normal. On a live test this took Slack from 3 refs to 534.

```bash
# 1. wake the tree (idempotent; once per app launch). Prints a JSON line: {"ok":true,...}
"${CLAUDE_PLUGIN_ROOT}/scripts/enable-electron-a11y.sh" Slack   # app name, bundle id, or pid

# 2. now snapshot normally. Electron trees are dense, so use skeleton + drill
agent-desktop snapshot --skeleton --app Slack -i --compact      # keep snapshot_id
agent-desktop snapshot --root @e11 --snapshot <id> -i --compact
```

If `CLAUDE_PLUGIN_ROOT` is unset, the script lives next to this SKILL at `../../scripts/enable-electron-a11y.sh`. It needs `swift` (Xcode or Command Line Tools) and inherits the terminal's Accessibility grant. The toggle persists for the running process; re-run it after the app restarts or if a snapshot drops back to ~3 refs.

## Common commands

```bash
# observe
agent-desktop snapshot --app Safari -i --compact     # tree with refs (+ --skeleton, --root, --include-bounds)
agent-desktop find --role button --app TextEdit       # search by role/name/value/text
agent-desktop get @e3 --snapshot <id> --property value
agent-desktop screenshot --app Finder                 # PNG (base64 in JSON)

# act (headless AX by default; no cursor/focus theft)
agent-desktop click @e3 --snapshot <id>
agent-desktop type @e5 --snapshot <id> "text"         # set-value, clear, select, toggle, check/uncheck, expand/collapse, scroll
agent-desktop press cmd+s                              # keyboard combo (press/key-down/key-up)

# apps & windows
agent-desktop launch Safari                            # or bundle id; close-app, list-apps, list-windows
agent-desktop focus-window --window-id w-4521          # resize/move/minimize/maximize/restore-window

# misc: clipboard-get/set/clear, wait, batch, list-notifications (macOS), status, permissions
```

## Gotchas (learned the hard way)

- **Electron apps need a11y woken first.** Slack, VS Code, Discord, Notion, Obsidian, Teams ship their tree OFF and return a ~3-ref stub until `AXManualAccessibility=YES` is set on the app (Chromium enables a11y on demand). Run `"${CLAUDE_PLUGIN_ROOT}/scripts/enable-electron-a11y.sh" <app>` once per launch, then snapshot (see the Electron section above). agent-desktop does not do this itself yet (it's roadmap item P2-O15). Native AppKit apps (Finder, Xcode, Mail, System Settings, TextEdit, Safari) work with no prep.
- **README examples are shorthand; flags are real.** `focus-window w-4521` is actually `focus-window --window-id w-4521`. Same for `--snapshot`, `--window-id`, `--root`.
- **Keystrokes are global, not app-scoped.** `press`/`key-down` go to whatever is frontmost, not necessarily the `--app` you snapshotted. If the target app or its window isn't focused (e.g. behind a modal), `focus-window` first or input lands elsewhere.
- **Roles vary by app.** TextEdit's editable body is a `textfield` with `SetValue`, not `textarea`. Snapshot and read the actual roles instead of assuming.
- **Re-snapshot after any UI change.** Stale refs fail closed with `STALE_REF`; ambiguous matches return `AMBIGUOUS_TARGET` (it won't guess). Re-drill the affected region or take a fresh snapshot.
- **`--headed` for physical gestures only.** `hover`, `drag`, `mouse-*`, `triple-click` need the global `--headed` flag (permits cursor movement / focus stealing). Everything else stays headless.

## Output contract

`{ "version": "2.0", "ok": true, "command": "...", "data": {...} }` on success; `ok: false` with `error.code` + `error.suggestion` on failure. Parse leniently; fields are additive. Exit codes: `0` ok, `1` structured error, `2` arg error. Key error codes: `PERM_DENIED`, `ELEMENT_NOT_FOUND`, `APP_NOT_FOUND`, `STALE_REF`, `AMBIGUOUS_TARGET`, `SNAPSHOT_NOT_FOUND`, `POLICY_DENIED`, `TIMEOUT`.

## Deeper reference (version-matched, self-updating)

The binary ships its own docs, always matching the installed version. Read them instead of guessing:

```bash
agent-desktop skills                       # list bundled skill docs
agent-desktop skills get desktop           # primary guide: full observe-act loop, all 54 commands
# topic files: commands-observation, commands-interaction, commands-system, workflows, macos
```
