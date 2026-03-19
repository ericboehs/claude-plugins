# Unanet Timesheet Manager

Automate Unanet timesheet entry via Playwright browser automation. Logs in through Okta SSO (with TOTP), fills hours, saves, and returns screenshots.

## Prerequisites

- **Node.js** (v18+)
- **1Password CLI** (`op`) with biometric or Keychain-stored master password
- **Playwright** (`npx playwright install chromium` after `npm install`)
- A 1Password item containing your Okta credentials (username, password, TOTP)

## Setup

Install the plugin, then run `/setup-unanet` to configure credentials and create `~/.config/unanet/config.json`.

Or manually:

```bash
# Store your 1Password master password in macOS Keychain
security add-generic-password -s "op-master" -a "your-email" -w

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
```

## Claude Code Skills

- `/unanet` — Natural language timesheet management ("fill 8 hours EERT for Monday through Friday")
- `/setup-unanet` — Interactive setup wizard

## How It Works

1. Retrieves Okta credentials and TOTP from 1Password via `op` CLI
2. Launches headless Chromium via Playwright
3. Authenticates through Okta SSO (username → password → TOTP)
4. Navigates to the Unanet timesheet and performs the requested operation
5. Handles audit trail prompts automatically when correcting existing entries
6. Returns JSON state and a screenshot
