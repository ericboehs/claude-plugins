---
name: setup-unanet
description: Set up the unanet CLI tool for timesheet automation. Use when user says "/setup-unanet" or needs to configure Unanet credentials.
tools: Bash
---

# Setup Unanet CLI

Interactive setup for the `unanet` CLI timesheet automation tool.

## Prerequisites

- **1Password CLI** (`op`) installed and configured with at least one account
- **macOS Keychain** with 1Password master password stored (service: `op-master`)
- **Playwright** installed (`npx playwright install chromium`)
- A 1Password item containing Okta credentials (username, password, TOTP)

## Setup Steps

1. Check prerequisites are installed (`op`, `playwright`)
2. Verify 1Password master password is in Keychain: `security find-generic-password -s "op-master" -w`
   - If not: prompt user to run `security add-generic-password -s "op-master" -a "their-email" -w`
3. Sign in to 1Password and list items to find the Okta/Unanet entry
4. Ask the user which 1Password item contains their Okta credentials
5. Verify the item has username, password, and TOTP fields
6. Create config at `~/.config/unanet/config.json`:
   ```json
   {
     "url": "https://COMPANY.unanet.biz/COMPANY",
     "okta_org": "COMPANY.okta.com",
     "op_item": "ITEM_ID",
     "default_project": "PROJECT_NAME"
   }
   ```
7. Symlink the CLI: `ln -sf PLUGIN_PATH/bin/unanet ~/bin/unanet`
8. Test with `unanet view`

## Behavior

- Walk the user through each step interactively
- Verify each prerequisite before proceeding
- Test the full auth chain before declaring success
