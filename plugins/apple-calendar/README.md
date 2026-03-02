# Apple Calendar

Manage Apple Calendar from Claude Code using [`ical`](https://github.com/BRO3886/ical) CLI with full CRUD, search, and calendar filtering.

## Skills

### `/calendar`

View agenda, create/update/delete events, and search calendar.

- `/calendar` — Show today's events
- `/calendar tomorrow` — Show tomorrow's events
- `/calendar week` — Show the next 7 days
- `/calendar add "Team standup" -s "tomorrow 9am" -e "tomorrow 9:30am"` — Create event
- `/calendar search "standup"` — Search events

Uses `-o json` output for stable event IDs, enabling reliable update and delete operations.

### `/setup-calendar`

Guided installation and configuration of the `ical` CLI tool, including macOS Calendar permission setup.

## Features

- List events by day, date range, or upcoming days
- Create events with location, notes, alerts, and recurrence
- Update events by full ID (title, time, location, notes, calendar)
- Delete single or recurring event occurrences
- Search events by keyword, date range, and calendar
- Calendar filtering with `--exclude-calendar` for shared calendars
- Natural language dates (e.g., "tomorrow 9am", "next monday")
- All-day events, recurring events, and per-occurrence editing

## Requirements

- macOS
- [`ical`](https://github.com/BRO3886/ical) — install via `curl -fsSL https://ical.sidv.dev/install | bash`
- Calendar access granted via System Settings > Privacy & Security > Calendars
