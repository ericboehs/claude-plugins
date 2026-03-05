# git-utils

Git workflow utilities for Claude Code. Automates common branch lifecycle tasks like merging PRs, cleaning up branches, and handling worktrees.

## Skills

### /merge-and-cleanup

Merge the current branch's PR (squash), delete the remote branch, switch to the default branch, pull latest, and clean up the worktree if applicable — all in one command.

**Usage:**
- `/merge-and-cleanup` — Merge and clean up the current branch

**What it does:**
1. Detects current branch and whether you're in a worktree
2. Finds the PR for the current branch via `gh pr view`
3. Squash merges the PR and deletes the remote branch
4. Switches to the default branch and pulls latest
5. Removes the worktree (if applicable) and prunes stale references

**Prerequisites:**
- `gh` CLI installed and authenticated
- A PR must exist for the current branch

**Edge cases handled:**
- Already on default branch — reports nothing to do
- No PR for branch — suggests creating one
- Uncommitted changes — warns before proceeding
- Failing CI checks — warns and asks before merging
- Worktree cleanup failures — reports manual cleanup command

### /commit-and-push

Stage all changes, commit with a semantic commit message, and push to origin.

**Usage:**
- `/commit-and-push` — Stage, commit, and push

**What it does:**
1. Stages all modified and new files
2. Asks if any files should be excluded or split into separate commits
3. Commits with a clear one-line semantic commit message
4. Pushes to origin
