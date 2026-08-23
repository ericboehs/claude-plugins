---
name: gh-actions-security
description: Security checklist for GitHub Actions. Use whenever creating or editing anything under .github/workflows/ — pin SHAs, scope permissions, lint with zizmor, and harden repo settings.
disable-model-invocation: true
---

# GitHub Actions Security

Apply this checklist any time a workflow file is created or modified. Fix
what's cheap inline; flag the rest.

## 1. Pin actions to a full commit SHA

Tags are mutable — a compromised action repo can rewrite `v4` (see the
tj-actions attack). Pin the SHA and keep the tag as a comment:

```yaml
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
```

Resolve latest release → SHA:

```bash
tag=$(gh api repos/OWNER/ACTION/releases/latest --jq .tag_name)
gh api repos/OWNER/ACTION/git/ref/tags/$tag --jq '.object | "\(.type) \(.sha)"'
# if type is "tag" (annotated), deref once more: gh api repos/OWNER/ACTION/git/tags/SHA --jq .object.sha
```

Skim the major-version release notes for breaking changes before jumping
versions.

## 2. Least-privilege permissions

Default-deny at the top, request per-job with a comment saying why:

```yaml
permissions: {} # default-deny; jobs request exactly what they need

jobs:
  build:
    permissions:
      contents: write # push generated commits back to this repo
```

## 3. Lint with zizmor

```bash
zizmor .github/workflows/FILE.yml          # brew install zizmor
zizmor --persona=auditor .github/workflows/FILE.yml   # pedantic pass
```

Known-acceptable finding: `artipacked` (persist-credentials) when the job
pushes commits — otherwise add `persist-credentials: false` to checkout.

## 4. Untrusted input

- Never interpolate attacker-influenced context (`github.event.*` — PR
  titles, branch names, issue bodies, commit messages) directly into
  `run:`. Route through `env:` and use the variable quoted.
- Avoid `pull_request_target` and `workflow_run` with fork PRs unless you
  fully understand the checkout implications. Treat fork PRs as hostile.
- If the workflow runs a script that ingests external data (API responses,
  comments, filenames), verify the script's shell-out surface: sanitized
  interpolations, `-F file` for commit messages, no `eval`.

## 5. Secrets

- Reference secrets in step-level `env:`, never inline in `run:` commands.
- PATs: prefer fine-grained scoped to one repo; classic PATs are all-or-
  nothing per scope (e.g. `gist` scope = ALL gists). Set an expiration and
  rotate. Gotcha: fine-grained PATs do NOT cover the gist API.
- Never echo/log secret values; if one hits a log, delete the log AND
  rotate the secret.

## 6. One-time repo hardening (per repo)

```bash
R=owner/repo
gh api -X PUT repos/$R/actions/permissions -F enabled=true -f allowed_actions=selected
gh api -X PUT repos/$R/actions/permissions/selected-actions -F github_owned_allowed=true -F verified_allowed=false
gh api -X PUT repos/$R/actions/permissions/workflow -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
```

(`selected-actions` also takes `-f "patterns_allowed[]=owner/action@*"` if a
third-party action is genuinely needed.)

## 7. Dependabot for actions

Companion to SHA-pinning — PRs fresh SHAs so pins don't rot:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

## 8. Runners

Never attach self-hosted runners to a public repo — fork PRs can
persistently compromise them. Use GitHub-hosted (ephemeral) runners.

## Reference

- GitHub secure-use docs: https://docs.github.com/en/actions/reference/security/secure-use
- zizmor audits: https://docs.zizmor.sh/audits/
- Wiz hardening guide: https://www.wiz.io/blog/github-actions-security-guide
