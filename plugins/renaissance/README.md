# Renaissance CLI

Check Accelerated Reader progress, quiz scores, reading goals, and search for AR books from Renaissance.

## Prerequisites

- Node.js 18+ (for JSON parsing only — no npm packages)
- [1Password CLI](https://developer.1password.com/docs/cli/) (`op`)
- `curl`
- macOS Keychain with 1Password master password (service: `op-master`)

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
    { "name": "Kid1", "op_item": "1PASSWORD_ITEM_ID", "user_id": "STUDENT_ROSTER_UUID" },
    { "name": "Kid2", "op_item": "1PASSWORD_ITEM_ID", "user_id": "" }
  ]
}
EOF

# Login and test
renaissance login
renaissance goals
```

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
- **Dependencies:** Zero. Only Node.js built-ins (`child_process`, `fs`, `path`) + `curl` + `op`

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
