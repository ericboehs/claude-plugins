# watch-ci

Monitor GitHub Actions CI status for the current branch, auto-exiting when checks pass or fail.

## Usage

```
/watch-ci
```

## What it does

1. **Detects the current branch** and checks for an associated PR
2. **PR mode** — if a PR exists, monitors `gh pr checks` for pass/fail/pending status
3. **Branch mode** — if no PR, monitors the latest workflow run via `gh run list`
4. **Auto-exits** when all checks pass (exit 0) or reports failure logs when checks fail
5. **Polls every 10 seconds** (configurable via argument)

## Requirements

- `gh` (GitHub CLI) — authenticated
- `jq` — for JSON parsing
- Branch must be pushed to remote

## Included scripts

- `scripts/watch-ci.sh` — standalone CI monitoring script, supports custom poll intervals and `--help`
