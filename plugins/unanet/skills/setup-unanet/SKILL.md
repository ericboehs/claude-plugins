---
name: setup-unanet
description: Set up the unanet CLI tool for timesheet automation. Use when user says "/setup-unanet" or needs to configure Unanet credentials.
tools: Bash
---

# Setup Unanet CLI

Interactive setup for the `unanet` CLI timesheet automation tool.

## Prerequisites

- **fnox** — secret management (`mise install fnox`)
- **1Password CLI** (`op`) with biometric unlock — needed only for TOTP codes
- **Playwright** installed (`npx playwright install chromium`)
- A 1Password item containing Okta credentials (username, password, TOTP)

## Setup Steps

1. Check prerequisites are installed (`fnox`, `op`, `playwright`)
2. Store Okta credentials in fnox keychain:
   ```bash
   fnox set UNANET_USERNAME "okta_username" --provider keychain --global
   fnox set UNANET_PASSWORD "okta_password" --provider keychain --global
   ```
3. Ask the user which 1Password item contains their Okta TOTP secret
4. Verify the item has a TOTP field: `op item get ITEM_ID --otp`
5. Create config at `~/.config/unanet/config.json`:
   ```json
   {
     "url": "https://COMPANY.unanet.biz/COMPANY",
     "okta_org": "COMPANY.okta.com",
     "op_item": "ITEM_ID",
     "default_project": "PROJECT_NAME"
   }
   ```
   Note: `op_item` is only used for TOTP code generation, not for username/password.
6. Symlink the CLI: `ln -sf PLUGIN_PATH/bin/unanet ~/bin/unanet`
7. Test with `unanet view`

## Behavior

- Walk the user through each step interactively
- Verify each prerequisite before proceeding
- Test the full auth chain before declaring success
