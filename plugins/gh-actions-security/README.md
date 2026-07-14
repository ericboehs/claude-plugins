# gh-actions-security

A checklist skill Claude applies whenever it creates or edits GitHub Actions
workflows (`.github/workflows/`).

## What it covers

- **SHA-pinning** actions to full commit SHAs (with tag-resolution commands)
- **Least-privilege permissions** — default-deny top-level, per-job grants
- **zizmor** linting (default + auditor personas, known-acceptable findings)
- **Untrusted input** rules — no `github.event.*` interpolation in `run:`,
  fork-PR trigger hazards
- **Secret/PAT handling** — env-scoped refs, expiration/rotation, classic vs
  fine-grained scope gotchas
- **One-time repo hardening** — `gh api` commands to restrict allowed actions,
  default token permissions, and workflow PR approvals
- **Dependabot** config to keep SHA pins fresh
- Self-hosted runner warnings

## Requirements

- `gh` CLI (authenticated)
- `zizmor` (`brew install zizmor`) — optional but recommended
