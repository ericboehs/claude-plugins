# agent-desktop

Automate native macOS apps through the OS accessibility tree using the [`agent-desktop`](https://github.com/lahfir/agent-desktop) CLI — no screenshots or pixel matching. Snapshot a UI, then click/type/select elements by deterministic ref.

## Skills

### `/agent-desktop`

Observe and control Mac apps. Snapshot the accessibility tree, act on element refs, manage windows.

- `/agent-desktop` — Drive a Mac app via the observe→act loop
- Snapshot an app: `agent-desktop snapshot --app Finder -i --compact`
- Dense apps: `--skeleton` overview, then `--root @eN --snapshot <id>` to drill one region (saves 60–96% tokens)
- Act: `click`, `type`, `select`, `toggle`, `press`, headless by default

### `/setup-agent-desktop`

Guided install honoring the aube supply-chain gates (verify binary via checksum + Sigstore, `--allow-low-downloads`, `approve-builds` + `rebuild`), plus Accessibility/Screen Recording permissions.

## Features

- **Observe:** `snapshot` (full / skeleton / drill-down), `find` by role/name/value, `get`/`is` element properties, `screenshot`
- **Act (headless AX):** click, type, set-value, select, toggle, check/uncheck, expand/collapse, scroll — no cursor or focus theft unless `--headed`
- **Keyboard/mouse:** `press` combos; physical `hover`/`drag`/`mouse-*` behind `--headed`
- **Apps & windows:** launch, close, list, focus/resize/move/minimize/maximize
- **More:** clipboard, `wait` predicates, `batch`, notifications (macOS), `status`/`permissions`
- **Self-documenting:** `agent-desktop skills get desktop` prints version-matched reference docs

## Requirements

- macOS 13+ with **Accessibility** permission granted to your terminal (**Screen Recording** too for screenshots)
- [`agent-desktop`](https://github.com/lahfir/agent-desktop) on PATH — install via `/setup-agent-desktop`

## Notes

- Works on **native AppKit apps** (Finder, Xcode, Mail, System Settings, Safari, TextEdit). **Electron apps** (Slack, VS Code, Discord, Notion) expose only a stub tree because they gate accessibility behind `AXManualAccessibility`, which the CLI doesn't set.
- This is a thin pointer skill: it teaches the loop and the gotchas, then delegates deep reference to the binary's built-in `agent-desktop skills` docs so it never drifts from the installed version.
