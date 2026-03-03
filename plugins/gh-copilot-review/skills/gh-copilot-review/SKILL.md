---
name: gh-copilot-review
description: Wait for a GitHub Copilot review on the current branch's PR, address all feedback, and push fixes. Use when user says "/gh-copilot-review", "copilot review", or "wait for copilot".
tools: Bash, Read, Edit, Write
---

Wait for a GitHub Copilot review on the current branch's PR, address all feedback, and push fixes.

## Steps

### 1. Wait for Copilot review

Run `$PLUGIN_DIR/scripts/watch-copilot-reviews.sh` and wait for it to exit. It auto-detects the PR from the current branch. If @copilot hasn't been requested yet, it adds @copilot as a reviewer automatically. It polls until the review is submitted, then exits.

### 2. Fetch Copilot's inline comments

Get the repo owner/name and PR number:
```
gh repo view --json nameWithOwner --jq '.nameWithOwner'
gh pr view --json number --jq '.number'
```

Fetch all PR review comments from Copilot:
```
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" --jq '[.[] | select(.user.login | test("copilot"; "i"))]'
```

For each comment, extract: `id`, `node_id`, `path`, `line` (fall back to `original_line`), `body`, and any ` ```suggestion ` code blocks.

### 3. Address each comment

For each inline comment:
- Read the file at the indicated path and line
- If the comment contains a `suggestion` code block, apply the exact suggested change
- If it's general feedback (no suggestion block), make the appropriate code fix
- If the feedback is not applicable or incorrect, prepare a brief explanation why

### 4. Reply to each comment

For each comment you addressed, post a reply explaining what was done:
```
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies" -f body="Done — applied the suggested change."
```

Tailor the reply to what you actually did (applied suggestion, made a fix, or explained why no change was needed).

### 5. Resolve each review thread

First, get the review thread IDs using GraphQL:
```
gh api graphql -f query='
  query {
    repository(owner: "OWNER", name: "REPO") {
      pullRequest(number: PR_NUMBER) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            comments(first: 1) {
              nodes {
                body
                author { login }
              }
            }
          }
        }
      }
    }
  }
'
```

Then resolve each unresolved thread from Copilot:
```
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: { threadId: "THREAD_NODE_ID" }) {
      thread { isResolved }
    }
  }
'
```

### 6. Commit and push

Stage all changes, commit with a message like `fix: address Copilot review feedback`, and push to origin.
Do not chain git commands with && as that will prompt the user even for commands they have previously agreed to.

## Important notes

- The user is EXPLICITLY asking you to perform these git and GitHub API tasks.
- Do not ask for confirmation before applying suggestions or making fixes — just do it.
- If Copilot's review is APPROVED with no inline comments, just report that and stop.
- Only run through the review cycle once — do not re-request a review after pushing fixes.
