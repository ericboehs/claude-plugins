# Wengage CLI

Check student grades, attendance, assignments, and lunch balances from the Wengage (Sylogist Ed) Guardian Portal.

## Prerequisites

- Node.js 18+
- [1Password CLI](https://developer.1password.com/docs/cli/) (`op`)
- Playwright (`npm install` in this directory)
- macOS Keychain with 1Password master password (service: `op-master`)

## Setup

```bash
# Install dependencies
cd plugins/wengage && npm install

# Create config (students are auto-discovered from the portal)
mkdir -p ~/.config/wengage
cat > ~/.config/wengage/config.json << 'EOF'
{
  "url": "https://ok.wengage.com/YourDistrict",
  "op_item": "YOUR_1PASSWORD_ITEM_ID"
}
EOF

# Add to PATH
ln -sf "$(pwd)/bin/wengage" ~/bin/wengage

# Test
wengage grades
```

## Usage

```bash
# Quick grade overview
wengage grades              # All students
wengage grades allie        # Filter by name

# Full detail (grades, attendance, assignments, notes)
wengage view                # All students
wengage view layla          # Filter by name

# Download PDF report cards
wengage report              # All students, saves to /tmp
wengage report allie --output ~/Downloads

# Raw JSON output
wengage json
```

## Claude Code Skills

- `/wengage` — Check grades (invokes `wengage grades`)
- `/setup-wengage` — Interactive setup wizard

## Architecture

- **Login:** Playwright (headless) for form-based login, captures session cookies
- **Data:** Plain `fetch()` with cookie authentication — no browser rendering needed
- **Session:** Cookies cached at `~/.config/wengage/cookies.json`, auto-refreshes on expiry
- **Parsing:** Regex extraction from server-rendered HTML (DevExpress/ASP.NET MVC)

### Endpoints Used

| Endpoint | Method | Returns |
|----------|--------|---------|
| `/gradebook/guardianportal` | GET | Main page (student IDs) |
| `StudentOverviewPartial?ID={student}` | POST | Session ID extraction |
| `ShowSummary?ID={student}` | POST | Balances |
| `SectionDetailPartialInit` | POST | Grades, attendance, assignments |
| `GetGradeDetail?ID={grade}` | GET | PDF report card |
