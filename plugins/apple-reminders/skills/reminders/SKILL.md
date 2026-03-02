---
name: reminders
description: Manage Apple Reminders using remindctl CLI. Use when user asks about reminders, todos, tasks, or says "/reminders". Handles listing, creating, completing, editing, and deleting reminders and reminder lists.
tools: Bash
---

# Apple Reminders (remindctl)

Manage Apple Reminders from the command line using `remindctl`.

## Prerequisites

`remindctl` must be installed. If any command fails with "command not found", tell the user to install it:

```bash
brew install steipete/tap/remindctl
```

After install, they may need to grant Reminders access: `remindctl authorize`

## Usage

- `/reminders` — Show today's reminders
- `/reminders list` — Show all reminder lists
- `/reminders add Buy milk` — Quick add to default list
- `/reminders add Buy milk --list Groceries --due tomorrow` — Add with options

Arguments after `/reminders` are passed directly to `remindctl`.

## Commands

Always use `--no-color --no-input` flags to ensure clean output without ANSI codes or interactive prompts.

### Show reminders

Use `--json` when you need stable IDs for subsequent complete/edit/delete operations.

```bash
# Today's reminders (default) — use --json to get stable IDs
remindctl show today --json --no-color --no-input

# Other filters
remindctl show tomorrow --json --no-color --no-input
remindctl show week --json --no-color --no-input
remindctl show overdue --json --no-color --no-input
remindctl show upcoming --json --no-color --no-input
remindctl show completed --json --no-color --no-input
remindctl show all --json --no-color --no-input

# Specific date
remindctl show 2026-03-01 --json --no-color --no-input

# Filter by list
remindctl show today --list "Work" --json --no-color --no-input
```

JSON output returns an array of objects with stable `id` fields (UUIDs):
```json
[
  {
    "id": "58E13B6F-32B0-4587-879F-E81AE06F581C",
    "title": "Buy milk",
    "listName": "Groceries",
    "dueDate": "2026-03-01T14:00:00Z",
    "isCompleted": false,
    "priority": "none"
  }
]
```

### List management

```bash
# Show all lists
remindctl list --no-color --no-input

# Show reminders in a specific list
remindctl list "Groceries" --no-color --no-input

# Create a new list
remindctl list "Groceries" --create --no-color --no-input

# Rename a list
remindctl list "Old Name" --rename "New Name" --no-color --no-input

# Delete a list
remindctl list "Old Name" --delete --force --no-color --no-input
```

### Add reminders

```bash
# Simple add
remindctl add "Buy milk" --no-color --no-input

# Add with list, due date, priority, and notes
remindctl add "Call dentist" --list "Personal" --due "tomorrow 9am" --priority high --notes "Reschedule appointment" --no-color --no-input
```

Due date accepts: `today`, `tomorrow`, `YYYY-MM-DD`, `YYYY-MM-DD HH:mm`, ISO 8601.
Priority accepts: `none`, `low`, `medium`, `high`.

### Edit reminders

Use an ID prefix from `--json` output (first 6+ chars of the UUID):

```bash
remindctl edit 58E13B --title "New title" --no-color --no-input
remindctl edit 58E13B --due tomorrow --no-color --no-input
remindctl edit 58E13B --priority high --notes "Updated notes" --no-color --no-input
remindctl edit 58E13B --clear-due --no-color --no-input
remindctl edit 58E13B --list "Work" --no-color --no-input  # Move to different list
```

### Complete reminders

Use ID prefixes from `--json` output:

```bash
remindctl complete 58E13B --no-color --no-input
remindctl complete 58E13B A3F2C1 B7D4E9 --no-color --no-input  # Multiple at once
```

### Delete reminders

Use ID prefixes from `--json` output:

```bash
remindctl delete 58E13B --force --no-color --no-input
remindctl delete 58E13B A3F2C1 B7D4E9 --force --no-color --no-input
```

## Behavior

1. If the user just says `/reminders` with no arguments, show today's reminders
2. If arguments are provided, pass them to `remindctl` as a subcommand
3. Always use `--no-color --no-input` for clean non-interactive output
4. **Always use `--json` when listing reminders** so you have stable IDs for follow-up operations (complete, edit, delete). Numeric indexes are unstable and may reference the wrong reminder.
5. Use ID prefixes (first 6+ characters of the UUID) for complete, edit, and delete — never use numeric indexes
6. Use `--force` on destructive operations (delete) to skip confirmation prompts
7. When showing reminders to the user, format the JSON output into a clean readable list — don't dump raw JSON
8. If a list doesn't exist when adding a reminder, suggest creating it first
9. When the user asks to "check my reminders" or "what's on my todo list", use `show today` or `show upcoming`
