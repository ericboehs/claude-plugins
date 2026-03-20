---
name: unanet
description: Fill timesheets, view time entries, submit timesheets, create and view leave requests on Unanet. Use when user asks about timesheets, time entry, logging hours, PTO, leave requests, taking time off, viewing leave, or says "/unanet".
tools: Bash, Read
---

# Unanet Timesheet Manager

Manage Unanet timesheets and leave requests via the `unanet` CLI tool.

## Prerequisites

`unanet` must be installed. If any command fails with "command not found" or "No config found", suggest running `/setup-unanet`.

## Usage

- `/unanet` — View current timesheet
- `/unanet fill 8h EERT for Wednesday and Thursday` — Fill time entries
- `/unanet submit` — Submit completed timesheet
- `/unanet I want to take off April 3rd` — Create a leave request
- `/unanet show my leave requests` — View all leave requests

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

### Create a leave request

```bash
# Single leave request
unanet leave --data '{"begin":"2026-04-03","end":"2026-04-03","hours":8}'

# Batch multiple leave requests in one session (preferred for multiple dates)
unanet leave --data '[{"begin":"2026-04-03","end":"2026-04-03","hours":8},{"begin":"2026-05-15","end":"2026-05-15","hours":8}]'
```

**Field mapping:**
- `begin`: Start date (YYYY-MM-DD)
- `end`: End date (YYYY-MM-DD), same as begin for single-day requests
- `hours`: Total hours for the leave period (8 per day typically)
- `comments`: Optional comment text
- `submit`: Set to `true` to submit for approval (default: save only)
- `includeNonWorkDays`: Set to `true` to include weekends (default: false)

**Batch leave requests:** When the user requests multiple leave dates, always use a JSON array to create them all in one CLI invocation. This uses a single browser session and avoids repeated Okta logins. Each request gets its own numbered screenshot (`-1.png`, `-2.png`, etc.).

**Interpreting natural language:**
- "take off April 3rd" → `{"begin":"2026-04-03","end":"2026-04-03","hours":8}`
- "take off April 3-4" → `{"begin":"2026-04-03","end":"2026-04-04","hours":16}`
- "PTO next Friday" → calculate the date, 8 hours
- "take off Oct 15, 16, and 19" → batch: `[{"begin":"2026-10-15","end":"2026-10-16","hours":16},{"begin":"2026-10-19","end":"2026-10-19","hours":8}]` (group consecutive days into ranges)

Use `--no-save` to preview without saving.

### View leave requests

```bash
unanet leave-list
```

Returns JSON array of all current leave requests with begin/end dates, hours, status, and comments. Also saves a screenshot. Always show the screenshot to the user.

## Options

- `--visible` — Show the browser window (useful for debugging)
- `--no-save` — Preview without saving (works with fill and leave)
- `--screenshot PATH` — Custom screenshot path (default: `/tmp/unanet-screenshot.png`)

## Behavior

1. Parse the user's natural language into the appropriate command and JSON data
2. Run the command
3. Show the screenshot to the user using the Read tool: `Read /tmp/unanet-screenshot.png`
4. Summarize what was done (hours filled, which days, total)
5. If the command fails, show the error screenshot and suggest fixes
