# gh-copilot-review

Wait for GitHub Copilot PR reviews, address feedback, resolve threads, and push fixes — all in one command.

## Usage

```
/gh-copilot-review
```

## What it does

1. **Watches for Copilot review** — polls until Copilot submits its review (auto-requests @copilot as reviewer if needed)
2. **Fetches inline comments** — extracts all Copilot review comments with file paths, line numbers, and suggestion blocks
3. **Addresses each comment** — applies suggested changes or makes appropriate fixes
4. **Replies to comments** — posts a reply on each comment explaining what was done
5. **Resolves review threads** — marks all addressed threads as resolved via GraphQL
6. **Commits and pushes** — stages changes, commits, and pushes to origin

## Requirements

- `gh` (GitHub CLI) — authenticated
- `jq` — for JSON parsing
- A PR must exist for the current branch

## Included scripts

- `scripts/watch-copilot-reviews.sh` — standalone script that monitors Copilot review status, supports custom PR numbers and poll intervals
