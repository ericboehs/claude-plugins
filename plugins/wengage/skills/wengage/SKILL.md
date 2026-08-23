---
name: wengage
description: Check student grades, attendance, assignments, and balances from Wengage Guardian Portal. Use when user asks about grades, school, report cards, attendance, or says "/wengage".
tools: Bash, Read
---

# Wengage Grade Checker

Check grades, attendance, assignments, and lunch balances for students via the `wengage` CLI tool.

## Prerequisites

`wengage` must be installed. If any command fails with "command not found" or "No config found", suggest running `/setup-wengage`.

## Usage

- `/wengage` — Show grades for all students
- `/wengage grades allie` — Show Allie's grades
- `/wengage view` — Full detail view with attendance and assignments
- `/wengage assignments allie reading` — Show every graded assignment for a class
- `/wengage report` — Download PDF report cards

## Commands

### Quick grades overview

```bash
wengage grades
wengage grades allie
wengage grades layla
```

Shows letter grades and percentages for each class. Compact format.

### Full detail view

```bash
wengage view
wengage view allie
```

Shows grades, instructor info, attendance (absences/tardies), assignment counts (scored/pending/incomplete/zero), and notes.

### Individual assignments

```bash
wengage assignments allie reading
wengage assignments allie reading --type zero
wengage assignments layla math --type pending
```

Shows every graded assignment with title, due date, points, and score. Filter by type:
- `scored` (default) — graded assignments
- `pending` — assignments not yet graded
- `zero` — assignments with zero points
- `incomplete` — incomplete assignments

### Download PDF report cards

```bash
wengage report
wengage report allie --output ~/Downloads
```

Downloads PDF report cards for each class that has grades. Default output: `/tmp/`.

After downloading, show the PDF to the user with the Read tool:
```
Read /tmp/wengage-report-boehs-allie-language---05.pdf
```

### JSON output

```bash
wengage json
wengage json layla
```

Raw JSON for programmatic use.

## Student filter

Student names are matched partially, case-insensitive:
- `allie` → Boehs, Allie (5th Grade)
- `layla` → Boehs, Layla (2nd Grade)
- Omit to show all students

## Behavior

1. Parse the user's request to determine which command and student filter to use
2. Run the command
3. For `report` command, show downloaded PDFs with the Read tool
4. Summarize the results conversationally
