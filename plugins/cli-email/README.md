# CLI Email Plugin

CLI email management for Claude Code using himalaya, mbsync, neomutt, and qmd.

## Skills

### `/check-email`

Daily email operations — list unread, read messages, archive, search.

Uses `himalaya` for fast CLI access to local Maildir, `mail-archive` for archiving with mbsync compatibility, and `qmd` for full-text email search.

### `/setup-email`

Guided installation and configuration of the full CLI email stack:

- **mbsync** (isync) — two-way IMAP sync to local Maildir
- **himalaya** — fast CLI for listing, reading, flagging
- **neomutt** — full TUI with sidebar, vim keys, colors
- **goimapnotify** — IMAP IDLE push notifications
- **qmd** — full-text search across all indexed email

Based on [CLI Email on macOS](https://boehs.com/blog/2026/03/01/cli-email-macos).

## Scripts

### `mail-archive`

Archive wrapper that moves messages via himalaya then strips UIDs from newly created Maildir files to avoid mbsync sync conflicts. Handles both Fastmail (move to Archive) and Gmail (move to All Mail).

```bash
mail-archive <id> [id...]              # Archive from personal (default)
mail-archive -a oddball <id> [id...]   # Archive from oddball/Gmail
```

## Requirements

- macOS with Homebrew
- `himalaya`, `isync` (mbsync), `neomutt`, `w3m` — via `brew install`
- `goimapnotify` — via `go install`
- `qmd` — for email search indexing
- App passwords stored in macOS Keychain
