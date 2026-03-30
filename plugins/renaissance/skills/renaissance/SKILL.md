---
name: renaissance
description: Check Accelerated Reader progress, quiz scores, reading goals, and completed books from Renaissance. Use when user asks about AR, reading progress, Allie's or Layla's books, quiz scores, or says "/renaissance".
tools: Bash, Read
---

# Renaissance AR Progress

Check Accelerated Reader goals, completed quizzes, and reading stats via the `renaissance` CLI tool.
Pure curl — no browser needed. Authenticates via 1Password.

## Prerequisites

`renaissance` must be installed. If any command fails with "command not found" or "No config found", suggest running `/setup-renaissance`.

## Usage

- `/renaissance` — Show AR goals for all students
- `/renaissance goals allie` — Show Allie's goals
- `/renaissance books layla` — Show Layla's recent quizzes
- `/renaissance books --all` — Show all completed quizzes

## Commands

### AR Goals

```bash
renaissance goals
renaissance goals allie
renaissance goals layla
```

Shows current marking period goals: points progress, average quiz score, quizzes passed, words read, STAR scores, and reading range.

### Completed Quizzes

```bash
renaissance books
renaissance books allie
renaissance books allie --all
```

Shows completed AR quizzes with title, score, and date. Default shows recent 10; `--all` shows full history.

### Force Login

```bash
renaissance login
renaissance login allie
```

Re-authenticates. Useful if session expired.

### JSON output

```bash
renaissance json goals
renaissance json goals allie
renaissance json books layla
```

Raw JSON for programmatic use.

## Student filter

Student names are matched partially, case-insensitive:
- `allie` → Allie Boehs
- `layla` → Layla Boehs
- Omit to show all configured students

## Behavior

1. Parse the user's request to determine which command and student filter to use
2. Run the command
3. Summarize the results conversationally
