# Session Improver

Analyze Claude Code session transcripts and recommend improvements to reduce token waste, prevent linter loops, and automate repetitive workflows.

## Commands

### `/improve-session [session-id]`

Analyze a session and get actionable recommendations.

- No args: analyze the most recent session
- With session ID: analyze a specific past session
- `--current`: analyze the current live session

## What It Detects

| Pattern | Description |
|---------|-------------|
| Linter loops | Reek/RuboCop/ESLint smells triggering repeated edit cycles |
| Tool failures | Commands retried 3+ times with errors |
| Repeated workflows | Tool call patterns that repeat (e.g., Read-Edit-Bash cycle) |
| Excessive file reads | Files read 3+ times in one session (token waste) |
| Hook failures | Hooks failing repeatedly |
| Permission friction | Tools needing human approval that could be auto-approved |

## What It Recommends

- **CLAUDE.md rules** with BAD/GOOD code examples for specific linter smells
- **PostToolUse hooks** for auto-formatting after edits
- **Permission rules** for auto-approving safe commands
- **Hookify rules** for behavioral guards
- **Skill stubs** for reusable workflows

Each recommendation includes the exact code/config to add and WHERE to put it (project, global, user level).

## How It Works

1. A Ruby script (`scripts/parse-session.rb`) parses the session JSONL file and extracts a compact structured summary
2. Claude analyzes the summary against reference patterns
3. Reads existing project configuration to avoid duplicates
4. Presents ranked findings with interactive apply/skip choices

## Includes

- Pre-built fix templates for common Ruby linting issues (Reek FeatureEnvy, TooManyStatements, DuplicateMethodCall, etc.)
- Pre-built fix templates for common RuboCop cops (Metrics/MethodLength, Layout/MultilineMethodCallBraceLayout, etc.)
- Generic templates for hooks, permissions, hookify rules, and skills

## Requirements

- Ruby (for the parser script)
- Claude Code session history (`~/.claude/projects/`)

## License

MIT
