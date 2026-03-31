---
name: renaissance
description: Check Accelerated Reader progress, quiz scores, reading goals, completed books, and search for AR books. Use when user asks about AR, reading progress, Allie's or Layla's books, quiz scores, book search, or says "/renaissance".
tools: Bash, Read
---

# Renaissance AR Progress

Check Accelerated Reader goals, completed quizzes, and reading stats via the `renaissance` CLI tool.
Pure curl — no browser, no dependencies. Authenticates via 1Password.

## Prerequisites

`renaissance` must be installed. If any command fails with "command not found" or "No config found", suggest running `/setup-renaissance`.

## Usage

- `/renaissance` — Show AR goals for all students
- `/renaissance goals allie` — Show Allie's goals
- `/renaissance books layla -d` — Show Layla's quizzes with points and ATOS
- `/renaissance search harry potter` — Search AR books

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
renaissance books layla 20
renaissance books allie -d
renaissance books --all
```

Shows completed AR quizzes with title, score, and date. Default shows recent 10.
- Add a number for a custom limit: `renaissance books layla 20`
- `--all` shows full history
- `--detail` (`-d`) adds points earned/possible and ATOS book level per quiz (slower — fetches each quiz)

### Search Books

```bash
renaissance search "diary of a wimpy kid"
renaissance search hatchet
renaissance search "magic tree house"
```

Searches the AR book catalog. Shows title, author, ATOS level, points, Lexile, interest level, and quiz number. Useful for finding books in a student's reading range.

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
renaissance json books layla -d
```

Raw JSON for programmatic use.

## Flags

- `--detail` (`-d`) — Show per-book points and ATOS in books command
- `--all` — Show all quizzes in books command
- `--verbose` (`-v`) — Log each API call to stderr

## Student filter

Student names are matched partially, case-insensitive:
- `allie` → Allie Boehs
- `layla` → Layla Boehs
- Omit to show all configured students (except search, which uses first student)

## Behavior

1. Parse the user's request to determine which command and student filter to use
2. Run the command
3. Summarize the results conversationally
