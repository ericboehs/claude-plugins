# Eric's Claude Code Plugins

A collection of Claude Code plugins for developer productivity.

## Installation

Add this marketplace to Claude Code:

```bash
claude plugins:add-marketplace ericboehs/claude-plugins
```

Then install individual plugins:

```bash
claude plugins:install session-improver
```

## Plugins

### session-improver

Analyze Claude Code session transcripts and recommend improvements to reduce token waste, prevent linter loops, and automate repetitive workflows.

**Usage:**
- `/improve-session` — Analyze the most recent session
- `/improve-session <session-id>` — Analyze a specific past session

**What it detects:**
- Linter loops (reek, rubocop, eslint smells triggering repeated edit cycles)
- Tool failures (commands retried 3+ times)
- Repeated workflow patterns
- Excessive file reads (token waste)
- Hook failures
- Permission friction

**What it recommends:**
- CLAUDE.md rules with BAD/GOOD code examples
- PostToolUse hooks for auto-formatting
- Permission rules for auto-approving safe commands
- Hookify rules for behavioral guards
- Skill stubs for reusable workflows

Includes pre-built fix templates for common Ruby linting issues (Reek + RuboCop).

### apple-reminders

Manage Apple Reminders from Claude Code using `remindctl` CLI.

**Usage:**
- `/reminders` — Show today's reminders
- `/reminders list` — Show all reminder lists
- `/reminders add Buy milk` — Quick add to default list
- `/reminders add Buy milk --list Groceries --due tomorrow` — Add with options

### cli-email

CLI email management using himalaya, mbsync, and neomutt with local Maildir sync and search.

**Skills:**
- `/check-email` — List unread, read messages, archive, search email
- `/setup-email` — Guided install/configure of the full CLI email stack

**Stack:** mbsync (IMAP sync) + himalaya (CLI) + neomutt (TUI) + goimapnotify (IMAP IDLE) + qmd (search)

## Contributing

Each plugin lives in `plugins/<plugin-name>/` and needs:
- `.claude-plugin/plugin.json` — Plugin manifest
- `skills/` and/or `commands/` — The actual skill/command definitions
- `README.md` — Documentation

## License

MIT
