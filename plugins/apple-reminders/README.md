# Apple Reminders

Manage Apple Reminders from Claude Code using [`remindctl`](https://github.com/steipete/remindctl) CLI.

## Skills

### `/reminders`

Daily reminders operations — list, create, complete, edit, and delete reminders and lists.

- `/reminders` — Show today's reminders
- `/reminders list` — Show all reminder lists
- `/reminders add Buy milk` — Quick add to default list
- `/reminders add Buy milk --list Groceries --due tomorrow` — Add with options

Uses `--json` output for stable UUID-based IDs, enabling reliable follow-up operations (complete, edit, delete) without index-based ambiguity.

## Features

- Show reminders by filter: today, tomorrow, week, overdue, upcoming, completed, all
- Filter by list or specific date
- Create reminders with due dates, priority, notes, and list assignment
- Edit reminders (title, due date, priority, notes, list)
- Complete and delete reminders by UUID prefix
- Full list management (create, rename, delete)

## Requirements

- macOS
- [`remindctl`](https://github.com/steipete/remindctl) — install via `brew install steipete/tap/remindctl`
- Reminders access granted: `remindctl authorize`
