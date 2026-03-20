---
name: dev-lifecycle
description: Full feature development lifecycle — plan, implement, test, review, PR, Copilot review, verify CI, QA demo, and merge. Use when user says "/dev-lifecycle", "full lifecycle", "implement and PR", or describes a feature needing the full plan-to-merge workflow.
argument-hint: "<feature description> [--skip-copilot] [--skip-review] [--skip-ci] [--skip-qa] [--skip-merge] [--branch NAME]"
tools: Bash, Read, Edit, Write, Glob, Grep, Agent, AskUserQuestion
---

# Dev Lifecycle

End-to-end feature development: plan, implement, test, validate, review, PR, verify CI, QA demo, merge, and clean up.

**Feature request:** "$ARGUMENTS"

If `$ARGUMENTS` is empty, ask the user what feature to implement before proceeding.

## Phase 1: Understand the project

Before writing any code, understand the project conventions:

1. Read the project's `CLAUDE.md` (if present) for architecture, testing, linting, and commit conventions.
2. Check for a `bin/ci` script or equivalent CI pipeline to understand quality gates.
3. Note any coverage thresholds, linter configurations (`.rubocop.yml`, `.reek.yml`, `eslint.config.*`, etc.), and testing frameworks.
4. Identify the default branch:
   ```bash
   DEFAULT_BRANCH=$(git remote show origin | sed -n 's/.*HEAD branch: //p')
   ```

## Phase 2: Plan

Think through the implementation before writing code:

1. Identify which files need to change and which new files are needed.
2. Consider edge cases, backward compatibility, and test coverage.
3. Draft a brief plan (3-7 bullet points) of what you'll implement.
4. Present the plan to the user and wait for approval before proceeding. Use AskUserQuestion with the plan summary.

If the user provides specific instructions (e.g., coverage thresholds, linting rules), note them as hard requirements for later validation.

## Phase 3: Create a branch

```bash
# Ensure we're on the default branch and up to date
git checkout $DEFAULT_BRANCH
git pull

# Create a feature branch
# Use conventional branch naming: feat/, fix/, refactor/, etc.
git checkout -b <branch-name>
```

Parse `--branch NAME` from arguments if provided. Otherwise, derive a branch name from the feature description using conventional prefixes (e.g., `feat/per-heartbeat-model`, `fix/session-timeout`).

## Phase 4: Implement

Write the code and tests:

1. **Code changes** — implement the feature, following project conventions from CLAUDE.md.
2. **Tests** — write tests for the new functionality. Match the project's testing framework and style.
3. **Documentation** — update inline docs, README sections, or CLAUDE.md if the feature changes architecture or public interfaces. Only add docs that are necessary — don't create new markdown files unless explicitly requested.

### Quality rules

- Do NOT add linter disable comments (`# rubocop:disable`, `# :reek:`, `// eslint-disable`, `# nosemgrep`, etc.) — refactor the code to satisfy the linter instead.
- Do NOT lower coverage thresholds or weaken linter configs.
- Follow the project's existing patterns for naming, structure, and style.

## Phase 5: Local validation

Run the project's full CI pipeline locally and fix any issues:

```bash
# If a bin/ci script exists, use it
bin/ci

# Otherwise, run linters and tests individually:
# Ruby: rubocop && bundle exec rake test
# JS/TS: npm test or yarn test
# Python: ruff check . && pytest
# Go: golangci-lint run && go test ./...
```

### Validation loop

Repeat until all checks pass:

1. Run the full CI pipeline.
2. If linters fail — fix the code (do NOT add disable comments).
3. If tests fail — fix the code or tests.
4. If coverage is below the project threshold — add more tests.
5. Run CI again to confirm the fix.

Cap at 5 iterations. If still failing after 5 attempts, report what's broken and ask the user for guidance.

## Phase 6: Self-review

Run `/pr-review-toolkit:review-pr all` to catch issues before the PR. If the pr-review-toolkit skill is not available, do a manual review:

1. `git diff $DEFAULT_BRANCH` — review all changes for correctness, style, and security.
2. Check for any leftover debug code, TODOs, or commented-out code.
3. Verify test coverage is adequate for the changes.

Address any critical or important findings from the review. Re-run local validation after fixes.

## Phase 7: Commit and push

Stage all changes and commit with a conventional commit message:

```bash
git add <files>
```

```bash
git commit -m "<type>: <description>"
```

```bash
git push -u origin HEAD
```

Do NOT chain git commands with `&&` — run each as a separate Bash call. Use a concise conventional commit message. If the changes span multiple concerns, use multiple commits.

## Phase 8: Create PR

```bash
gh pr create --title "<conventional title>" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points describing what changed and why>

## Changes
<bulleted list of notable changes>

## Test plan
- [ ] Local CI passes (linters, tests, coverage)
- [ ] Self-review completed
- [ ] <feature-specific test steps>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Keep the PR title under 70 characters. The summary should explain the "why", not just the "what".

## Phase 9: Copilot review

Request a GitHub Copilot review and address feedback. Run `/gh-copilot-review` if the skill is available. If not, do it manually:

1. **Request the review:**
   ```bash
   gh pr edit --add-reviewer @copilot
   ```
   Note: the `@` in `@copilot` is critical — without it, it looks for a human user named "copilot".

2. **Wait for the review** — poll until Copilot's review is submitted:
   ```bash
   REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
   PR_NUMBER=$(gh pr view --json number --jq '.number')

   # Check for pending review request
   gh api "repos/$REPO/pulls/$PR_NUMBER/requested_reviewers" --jq '.users[] | select(.login | test("copilot"; "i")) | .login'

   # Check for submitted reviews
   gh api "repos/$REPO/pulls/$PR_NUMBER/reviews" --jq '[.[] | select(.user.login | test("copilot"; "i"))] | last | .state'
   ```
   Poll every 15 seconds until the review is no longer pending (typically 1-3 minutes).

3. **Address feedback** — for each inline comment:
   - If it contains a ```` ```suggestion ```` block, apply the exact suggested change.
   - If it's general feedback, make the appropriate fix.
   - Reply to each comment explaining what was done:
     ```bash
     gh api "repos/$REPO/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies" -f body="Done — applied the suggested change."
     ```

4. **Resolve threads** — use GraphQL to resolve addressed review threads:
   ```bash
   OWNER=$(echo "$REPO" | cut -d/ -f1)
   REPO_NAME=$(echo "$REPO" | cut -d/ -f2)

   # Get unresolved Copilot threads
   gh api graphql -f query='query { repository(owner: "'"$OWNER"'", name: "'"$REPO_NAME"'") { pullRequest(number: '"$PR_NUMBER"') { reviewThreads(first: 100) { nodes { id isResolved comments(first: 1) { nodes { author { login } } } } } } } }'

   # Resolve each thread
   gh api graphql -f query='mutation { resolveReviewThread(input: { threadId: "'"$THREAD_ID"'" }) { thread { isResolved } } }'
   ```

5. **Commit and push fixes:**
   ```bash
   git add <files>
   ```
   ```bash
   git commit -m "fix: address Copilot review feedback"
   ```
   ```bash
   git push
   ```

Skip this phase if `--skip-copilot` was passed in arguments.

## Phase 10: Verify CI

Wait for CI to pass on the PR. Run `/watch-ci` if the skill is available. If not, monitor manually:

```bash
# Poll PR checks until they complete
gh pr checks --watch
```

If CI fails:
1. Read the failure logs: `gh pr checks --json name,state,conclusion`
2. Fix the failing code.
3. Run local CI to verify the fix.
4. Commit and push the fix.
5. Wait for CI again.

Cap at 3 CI fix iterations. If still failing, report what's broken and ask the user.

Skip this phase if `--skip-ci` was passed in arguments.

## Phase 11: QA + Demo

Before merging, demo the feature for the user to manually approve. The approach depends on what was built.

### Detect the demo strategy

Determine which strategy fits the feature:

1. **CLI/terminal feature** — the feature is invoked from a shell (commands, scripts, CLI tools, background services).
2. **Web app feature** — the feature has a browser-visible UI (routes, pages, components, API responses viewable in a browser).
3. **Library/internal change** — no direct user-facing interface (refactors, internal APIs, config changes). Fall back to a test-output demo.

### Strategy A: CLI / Terminal demo (tmux)

Use tmux to demo in a split pane so the user can watch live:

1. **Split the pane:**
   ```bash
   # Create a horizontal split (demo pane below)
   tmux split-window -v -l 15
   DEMO_PANE=$(tmux display-message -p '#{pane_id}')
   ```

2. **Run the demo** — send commands to the demo pane:
   ```bash
   # Send a command to the demo pane
   tmux send-keys -t "$DEMO_PANE" '<demo command>' Enter
   ```
   Wait for output to settle, then capture it:
   ```bash
   tmux capture-pane -t "$DEMO_PANE" -p
   ```

3. **Walk through the feature** — run 2-5 commands that exercise the new functionality, capturing output after each. Narrate what each step demonstrates (post narration as text output between commands).

4. **Ask for approval:**
   Use AskUserQuestion: "QA Demo complete. The feature works as shown above. Approve to merge, or describe what needs fixing."

5. **Clean up the demo pane:**
   ```bash
   tmux kill-pane -t "$DEMO_PANE"
   ```

If any demo step fails or produces unexpected output, investigate and fix before asking for approval. If a fix is needed, re-run local CI (Phase 5) and push before re-demoing.

### Strategy B: Web app demo (headed browser)

Use Playwright MCP (if available) or a headed browser to walk through the feature:

1. **Ensure the dev server is running.** If not, start it in a tmux split:
   ```bash
   tmux split-window -v -l 5
   DEV_PANE=$(tmux display-message -p '#{pane_id}')
   tmux send-keys -t "$DEV_PANE" '<start command>' Enter
   ```
   Wait for the server to be ready (poll the health endpoint or watch for the "ready" log line).

2. **Navigate to the feature** using Playwright MCP or browser automation:
   - Navigate to the relevant URL.
   - Take a screenshot at each key step.
   - Interact with the feature (click buttons, fill forms, verify responses).

3. **Present the walkthrough** — describe what each screenshot shows and what the expected behavior is.

4. **Ask for approval:**
   Use AskUserQuestion: "QA Demo complete. Screenshots above show the feature working end-to-end. Approve to merge, or describe what needs fixing."

5. **Clean up** — stop the dev server pane if you started one:
   ```bash
   tmux kill-pane -t "$DEV_PANE"
   ```

### Strategy C: Library / internal change demo

For changes with no direct UI:

1. Run the relevant tests with verbose output so the user can see what's being exercised:
   ```bash
   # Ruby example
   bundle exec ruby -Itest test/path/to/relevant_test.rb -v
   ```

2. If the change affects configuration or internal behavior, show a before/after comparison (e.g., `git stash && <run command> && git stash pop && <run command>`).

3. **Ask for approval:**
   Use AskUserQuestion: "QA Demo complete. Test output above exercises the new functionality. Approve to merge, or describe what needs fixing."

### Demo fix loop

If the user rejects the demo:

1. Note the feedback.
2. Fix the issue.
3. Re-run local CI (Phase 5 validation loop).
4. Commit and push the fix.
5. Wait for CI to pass.
6. Re-demo.

Cap at 3 demo iterations. If still not approved, stop and discuss with the user.

Skip this phase if `--skip-qa` was passed in arguments.

## Phase 12: Merge and cleanup

Once the user approves the demo, merge the PR and clean up everything:

### Merge

```bash
gh pr merge --squash --delete-branch
```

If the merge fails (e.g., branch protection, required reviews), report the blocker and ask the user how to proceed.

### Switch to default branch

```bash
git checkout $DEFAULT_BRANCH
```

```bash
git pull
```

### Worktree cleanup

If running in a git worktree (detected when `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`):

```bash
WORKTREE_PATH=$(pwd)
MAIN_REPO=$(git rev-parse --git-common-dir | sed 's|/\.git$||')

git -C "$MAIN_REPO" checkout "$DEFAULT_BRANCH" && \
git -C "$MAIN_REPO" pull && \
git -C "$MAIN_REPO" worktree remove "$WORKTREE_PATH" && \
git -C "$MAIN_REPO" worktree prune
```

### Leftover cleanup

Check for and clean up any artifacts from the lifecycle:

- Kill any tmux panes created during the demo phase.
- Stop any dev servers started for QA.
- Remove any temporary files created during testing (but NOT test fixtures that were committed).

Do NOT delete or modify any committed files during cleanup. Only clean up transient runtime artifacts.

Skip this phase if `--skip-merge` was passed in arguments.

## Phase 13: Done

Report the final status:

```markdown
## Feature Complete

**PR:** <url> (merged)
**Branch:** <branch-name> (deleted)

### What was implemented
- <summary of changes>

### Quality checks
- Local CI: passed
- Self-review: passed
- Copilot review: addressed
- Remote CI: passed
- QA demo: approved

### Cleanup
- Switched to <default-branch>, pulled latest
- <worktree removed / branch deleted / etc.>
```

If any phase was skipped, note it in the report.

## Flags

- `--skip-copilot` — Skip the Copilot review phase
- `--skip-review` — Skip the self-review phase (Phase 6)
- `--skip-ci` — Skip the remote CI verification phase
- `--skip-qa` — Skip the QA demo phase
- `--skip-merge` — Stop after CI passes; do not merge or clean up
- `--branch NAME` — Use a specific branch name instead of auto-generating one

## Important notes

- The user is EXPLICITLY asking you to perform all git, GitHub, and code operations autonomously.
- Do not ask for confirmation between phases unless the plan (Phase 2) needs approval, the QA demo (Phase 11) needs sign-off, or you encounter an unexpected blocker.
- If a phase fails and you cannot recover after the specified retry limit, stop and report clearly.
- Always follow the project's CLAUDE.md conventions — they override any defaults in this skill.
- When fixing linter/review issues, fix the root cause. Never suppress warnings.
- During cleanup, be careful — only remove transient artifacts. Never delete committed files, user data, or running processes you didn't start.
