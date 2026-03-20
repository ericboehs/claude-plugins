# Unanet Timesheet Manager

Automate Unanet timesheet entry and leave requests via Playwright browser automation. Logs in through Okta SSO (with TOTP), fills hours, creates leave requests, saves, and returns screenshots.

## Prerequisites

- **Node.js** (v18+)
- **1Password CLI** (`op`) with biometric unlock enabled
- **Playwright** (`npx playwright install chromium` after `npm install`)
- A 1Password item containing your Okta credentials (username, password, TOTP)

## Setup

Install the plugin, then run `/setup-unanet` to configure credentials and create `~/.config/unanet/config.json`.

Or manually:

```bash
# Create config
mkdir -p ~/.config/unanet
cat > ~/.config/unanet/config.json <<EOF
{
  "url": "https://COMPANY.unanet.biz/COMPANY",
  "okta_org": "COMPANY.okta.com",
  "op_item": "YOUR_1PASSWORD_ITEM_ID",
  "default_project": "YOUR_PROJECT"
}
EOF

# Install dependencies and symlink
cd plugins/unanet && npm install
npx playwright install chromium
ln -sf "$(pwd)/bin/unanet" ~/bin/unanet
```

## CLI Usage

```bash
# View current timesheet
unanet view

# Fill hours (saves automatically)
unanet fill --data '{"project":"EERT","hours":8,"days":["2026-03-18","2026-03-19"]}'

# Fill multiple projects at once
unanet fill --data '[{"project":"EERT","hours":4,"days":["2026-03-18"]},{"project":"PTO","hours":4,"days":["2026-03-18"]}]'

# Preview without saving
unanet fill --no-save --data '{"project":"EERT","hours":8,"days":["2026-03-18"]}'

# Clear hours (set to 0)
unanet fill --data '{"project":"EERT","hours":0,"days":["2026-03-19"]}'

# Show browser for debugging
unanet view --visible

# Submit timesheet
unanet submit

# Create a leave request (saves only)
unanet leave --data '{"begin":"2026-04-03","end":"2026-04-03","hours":8}'

# Create and submit a leave request for approval
unanet leave --data '{"begin":"2026-04-03","end":"2026-04-03","hours":8,"submit":true}'

# Multi-day leave request with comment
unanet leave --data '{"begin":"2026-04-03","end":"2026-04-04","hours":16,"comments":"Vacation","submit":true}'

# Batch multiple leave requests in one session (avoids repeated Okta logins)
unanet leave --data '[{"begin":"2026-04-03","end":"2026-04-03","hours":8},{"begin":"2026-05-15","end":"2026-05-15","hours":8}]'

# Preview leave request without saving
unanet leave --no-save --data '{"begin":"2026-04-03","end":"2026-04-03","hours":8}'
```

## Claude Code Skills

- `/unanet` — Natural language timesheet and leave management ("fill 8 hours EERT for Monday through Friday", "take off April 3rd")
- `/setup-unanet` — Interactive setup wizard

## How It Works

1. Retrieves Okta credentials and TOTP from 1Password via `op` CLI
2. Launches headless Chromium via Playwright
3. Loads saved session from `~/.config/unanet/storage-state.json` if available — skips Okta login entirely when session is still valid
4. Falls back to full Okta SSO authentication (username → password → TOTP) if no session or session expired
5. Saves session state after successful login for reuse by future invocations
6. Navigates to the Unanet timesheet and performs the requested operation
7. Handles audit trail prompts automatically when correcting existing entries
8. Returns JSON state and a screenshot
