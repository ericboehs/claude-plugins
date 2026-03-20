---
name: setup-wengage
description: Set up the wengage CLI tool for checking school grades. Use when user says "/setup-wengage" or needs to configure Wengage credentials.
tools: Bash
---

# Setup Wengage CLI

Interactive setup for the `wengage` CLI grade checker tool.

## Prerequisites

- **1Password CLI** (`op`) installed and configured
- **macOS Keychain** with 1Password master password stored (service: `op-master`)
- **Playwright** installed (will install via npm if needed)
- A 1Password item for ok.wengage.com with username and password

## Setup Steps

1. Check prerequisites are installed (`op`, Playwright)
2. Verify 1Password master password is in Keychain: `security find-generic-password -s "op-master" -w`
3. Sign in to 1Password and find the Wengage entry:
   ```bash
   OP_SESSION=$(security find-generic-password -s "op-master" -w | op signin --account my --raw)
   OP_SESSION_my="$OP_SESSION" op item list | grep -i wengage
   ```
4. Verify the item has username and password fields
5. Create config at `~/.config/wengage/config.json`:
   ```json
   {
     "url": "https://ok.wengage.com/YourDistrict",
     "op_item": "ITEM_ID_FROM_1PASSWORD"
   }
   ```
   Student names and grade levels are auto-discovered from the portal. Optionally add a `students` array to override names/grades.
6. Install Playwright if needed:
   ```bash
   cd PLUGIN_PATH && npm install
   ```
7. Symlink the CLI: `ln -sf PLUGIN_PATH/bin/wengage ~/bin/wengage`
8. Test with `wengage grades`

## Config notes

- `url`: The base URL for your school district's Wengage instance
- `op_item`: The 1Password item ID containing login credentials
- `students` (optional): Array of student objects with `id`, `name`, and `grade` to override auto-discovery
