---
name: watch-ci
description: Monitor GitHub Actions CI status for the current branch, waiting until checks pass or fail. Use when user says "/watch-ci", "watch ci", "wait for ci", or "monitor ci".
tools: Bash
---

# watch-ci

Monitor GitHub Actions CI status for the current branch, waiting until all checks pass or fail.

## Steps

### 1. Run the watch script

Run `${CLAUDE_PLUGIN_ROOT}/scripts/watch-ci.sh` and wait for it to exit. It auto-detects the current branch, checks for a PR first (using `gh pr checks --json`), and falls back to workflow runs if no PR exists. It polls every 10 seconds by default. To use a custom interval, pass it as the first argument (e.g., `watch-ci.sh 30`). Minimum is 5 seconds.

If `CLAUDE_PLUGIN_ROOT` is not set, find the script relative to this SKILL.md (`../../scripts/watch-ci.sh`).

### 2. Report the result

When the script exits:
- **Exit code 0** means all checks passed. Report success.
- **Non-zero exit** means checks failed. The script will have printed failure logs. Summarize the failures for the user.

If the user wants to investigate failures, offer to:
- Read the failure logs in detail
- Open the GitHub Actions run URL
- Help fix the failing code

## Important notes

- This skill just monitors — it does not push, commit, or modify code.
- If no CI runs are found, suggest the user push their branch first.
- The script exits automatically when checks complete. Do not kill it early unless the user asks.
