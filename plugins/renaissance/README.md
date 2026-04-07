# Renaissance CLI

Check Accelerated Reader progress, quiz scores, reading goals, and search for AR books from Renaissance.

## Prerequisites

- Node.js 18+ (for JSON parsing only — no npm packages)
- [fnox](https://github.com/jdx/fnox) — secret management (installed via `mise install fnox`)
- `curl`

## Setup

```bash
# Symlink to PATH
ln -sf "$(pwd)/bin/renaissance" /usr/local/bin/renaissance

# Create config
mkdir -p ~/.config/renaissance
cat > ~/.config/renaissance/config.json << 'EOF'
{
  "school_id": "YOUR_SCHOOL_UUID",
  "realm_id": "YOUR_REALM_UUID",
  "rpid": "YOUR-RPID",
  "client_id": "YOUR_CLIENT_ID",
  "students": [
    { "name": "Kid1", "credentials_key": "KID1", "user_id": "STUDENT_ROSTER_UUID" },
    { "name": "Kid2", "credentials_key": "KID2", "user_id": "" }
  ]
}
EOF

# Store credentials in fnox (one per student, using keychain provider)
fnox set RENAISSANCE_KID1_USERNAME "student_username" --provider keychain --global
fnox set RENAISSANCE_KID1_PASSWORD "student_password" --provider keychain --global

# Login and test
renaissance login
renaissance goals
```

### Credential format

Environment variables are keyed by `credentials_key` from config.json:

| `credentials_key` | Username env var | Password env var |
|-------------------|-----------------|-----------------|
| `KID1` | `RENAISSANCE_KID1_USERNAME` | `RENAISSANCE_KID1_PASSWORD` |
| `KID2` | `RENAISSANCE_KID2_USERNAME` | `RENAISSANCE_KID2_PASSWORD` |

The script auto-wraps itself with `fnox exec` if secrets aren't in the environment, so no shell activation is needed.

## Usage

```bash
# AR goals and progress
renaissance goals              # All students
renaissance goals allie        # Filter by name

# Completed quizzes
renaissance books              # Recent 10
renaissance books layla 20     # Last 20
renaissance books allie -d     # With points earned and ATOS level
renaissance books --all        # Full history

# Search AR book catalog
renaissance search "diary of a wimpy kid"
renaissance search hatchet

# Force re-authentication
renaissance login
renaissance login allie

# Raw JSON output
renaissance json goals
renaissance json books layla -d
```

## Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--detail` | `-d` | Show per-book points and ATOS level (books command) |
| `--all` | | Show all quizzes (books command) |
| `--verbose` | `-v` | Log each API call to stderr |

## Claude Code Skills

- `/renaissance` — Check AR progress (invokes `renaissance goals`)
- `/setup-renaissance` — Interactive setup wizard

## Architecture

- **Login:** Pure `curl` — 6-step OIDC chain through Ory Hydra, no browser needed
- **Data:** GraphQL API + REST endpoints via `curl` with session cookies
- **Search:** Bearer token from SDP + recommendation service API
- **Session:** Cookies cached per-student at `~/.config/renaissance/cookies-{name}.txt`
- **Secrets:** `fnox exec` injects credentials from macOS Keychain (no biometric prompt)
- **Dependencies:** Zero npm packages. Only Node.js built-ins (`child_process`, `fs`, `path`) + `curl` + `fnox`

### Auth Flow

```
studentprogress/ → OIDC redirects → tenant form (POST RPID)
  → auth.renaissance.com (Ory Hydra) → login.renaissance.com
  → POST /auth with credentials → /auth/redirect
  → follow auto-submit forms → session cookies
```

### Endpoints Used

| Endpoint | Method | Returns |
|----------|--------|---------|
| `studentprogress/api/GraphQl/GetStudentData` | POST | Goals, STAR scores, completed quizzes |
| `studentprogress/api/goal/GetIndependentReaderGoals` | POST | Point & accuracy goal progress |
| `studentprogress/api/GraphQl/GetStudentReadingRanges` | GET | ATOS & Lexile reading ranges |
| `studentprogress/api/MarkingPeriod` | GET | Grading periods (9 weeks) |
| `studentprogress/AssignmentPlatformService/resultsinfo/{id}` | GET | Per-quiz detail (points, ATOS, word count) |
| `sdp/api/authorization/refreshtoken` | GET | Bearer token for search |
| `recommendationservice/Search/V1/InstructionalResources` | POST | AR book catalog search |
