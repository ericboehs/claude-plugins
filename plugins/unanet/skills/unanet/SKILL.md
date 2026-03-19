---
name: unanet
description: Fill timesheets, view time entries, and submit timesheets on Unanet. Use when user asks about timesheets, time entry, logging hours, or says "/unanet".
tools: Bash, Read
---

# Unanet Timesheet Manager

Manage Unanet timesheets via the `unanet` CLI tool.

## Prerequisites

`unanet` must be installed. If any command fails with "command not found" or "No config found", suggest running `/setup-unanet`.

## Usage

- `/unanet` — View current timesheet
- `/unanet fill 8h EERT for Wednesday and Thursday` — Fill time entries
- `/unanet submit` — Submit completed timesheet

## Commands

### View current timesheet

```bash
unanet view
```

Returns JSON with current timesheet state and saves a screenshot to `/tmp/unanet-screenshot.png`. Always show the screenshot to the user with the Read tool.

### Fill time entries

Parse the user's natural language request into structured JSON:

```bash
unanet fill --data '{"project":"EERT","hours":8,"days":["2026-03-18","2026-03-19"]}'
```

**Field mapping:**
- `project`: Match against project names on the timesheet (partial match, case-insensitive)
  - "EERT" → matches "C-ODDCORE ODDCORE-EERT"
  - "PTO" → matches "ODDBALL PTO"
  - "PROF_DEV" → matches "ODDBALL PROF_DEV"
- `hours`: Number of hours per day
- `days`: Array of ISO date strings (YYYY-MM-DD)

**Interpreting natural language dates:**
- "Wednesday and Thursday" → calculate the actual dates based on today's date and the timesheet period
- "this week" → Mon-Fri of the current week
- "last week" → Mon-Fri of the previous week
- "remaining weekdays" → all unfilled weekdays in the period

After filling, the tool saves and takes a screenshot. Always show the screenshot to the user.

### Submit timesheet

```bash
unanet submit
```

Only use when the user explicitly asks to submit. This is different from Save (which happens automatically after fill).

## Options

- `--visible` — Show the browser window (useful for debugging)
- `--screenshot PATH` — Custom screenshot path (default: `/tmp/unanet-screenshot.png`)

## Behavior

1. Parse the user's natural language into the appropriate command and JSON data
2. Run the command
3. Show the screenshot to the user using the Read tool: `Read /tmp/unanet-screenshot.png`
4. Summarize what was done (hours filled, which days, total)
5. If the command fails, show the error screenshot and suggest fixes
