# dev-lifecycle

Full feature development lifecycle — plan, implement, test, review, PR, Copilot review, verify CI, QA demo, merge, and clean up in one command.

## Usage

```
/dev-lifecycle <feature description>
```

## What it does

1. **Understand** — reads CLAUDE.md for project conventions, CI pipeline, linter configs
2. **Plan** — drafts an implementation plan and asks for approval
3. **Branch** — creates a conventionally-named feature branch
4. **Implement** — writes code and tests following project conventions
5. **Validate** — runs the full local CI pipeline (linters, tests, coverage) in a fix loop
6. **Self-review** — runs `/pr-review-toolkit:review-pr` and addresses findings
7. **Commit & push** — conventional commits, pushes to origin
8. **Create PR** — opens a PR with summary, changes, and test plan
9. **Copilot review** — requests @copilot review, addresses feedback, resolves threads
10. **Verify CI** — waits for remote CI to pass, fixes failures if needed
11. **QA + Demo** — live demo for user approval (tmux split for CLI, headed browser for web, verbose tests for libraries)
12. **Merge & cleanup** — squash merges the PR, deletes the branch, cleans up worktrees and transient artifacts

## Flags

- `--skip-copilot` — skip the Copilot review phase
- `--skip-review` — skip the self-review phase
- `--skip-ci` — skip the remote CI verification phase
- `--skip-qa` — skip the QA demo phase
- `--skip-merge` — stop after CI passes; do not merge or clean up
- `--branch NAME` — use a specific branch name

## Examples

```bash
# Full lifecycle (plan through merge)
/dev-lifecycle add per-heartbeat model configuration for cost optimization

# Skip Copilot review
/dev-lifecycle add rate limiting to API endpoints --skip-copilot

# Stop before merge (for manual review)
/dev-lifecycle fix session timeout bug --skip-merge

# Specify branch name
/dev-lifecycle refactor auth middleware --branch refactor/auth-middleware
```

## QA demo strategies

The skill auto-detects the right demo approach:

| Feature type | Demo strategy | How it works |
|-------------|--------------|--------------|
| CLI / terminal | tmux split pane | Splits the window, runs commands via `send-keys`, captures output |
| Web app | Headed browser | Starts dev server, walks through with Playwright MCP or browser automation |
| Library / internal | Verbose test output | Runs relevant tests with `-v`, shows before/after if applicable |

The user must approve the demo before the PR is merged. If issues are found, the skill fixes them, re-validates, re-pushes, and re-demos (up to 3 iterations).

## Quality gates

- No new linter disable comments (rubocop, reek, eslint, semgrep, etc.)
- Coverage thresholds maintained (reads from project CI config)
- All local and remote CI checks pass
- Self-review and Copilot review feedback addressed
- QA demo approved by user

## Companion plugins

Works best with these plugins installed:

- **pr-review-toolkit** — comprehensive multi-agent PR review (Phase 6)
- **gh-copilot-review** — automated Copilot review handling (Phase 9)
- **watch-ci** — CI status monitoring (Phase 10)
- **code-lint** — per-file lint-on-edit hooks (catches issues early)

All companion plugins are optional — the skill includes fallback steps for each.

## Requirements

- `gh` (GitHub CLI) — authenticated
- `git` — configured with push access
- `tmux` — for CLI demos (split pane)
- Project should have a CI pipeline (bin/ci, GitHub Actions, etc.)
