---
name: setup-renaissance
description: Set up the Renaissance AR CLI tool. Use when user says "/setup-renaissance" or when renaissance commands fail with config errors.
tools: Bash
---

# Setup Renaissance CLI

Interactive setup for the `renaissance` CLI tool that checks Accelerated Reader progress.
Uses pure curl for authentication (no browser/Playwright needed). Supports multiple students.

## Steps

1. **Link the CLI:**
```bash
cd /Users/ericboehs/Code/ericboehs/claude-plugins/plugins/renaissance && npm link
```

2. **Create config directory:**
```bash
mkdir -p ~/.config/renaissance
```

3. **Write config** at `~/.config/renaissance/config.json`:
```json
{
  "school_id": "6e86d58e-91b4-4b66-8620-a24a71751415",
  "realm_id": "10955dcf-583c-4c4d-8e9c-eb0ca12c2ef4",
  "rpid": "CPS-88RB",
  "client_id": "341411",
  "students": [
    {
      "name": "Allie",
      "op_item": "cxckp6sfjwhq4r3l5gxhjlbou4",
      "user_id": "7fecd686-7cef-46d6-b557-fef2a819f01d"
    },
    {
      "name": "Layla",
      "op_item": "",
      "user_id": ""
    }
  ]
}
```

4. **Test it:**
```bash
renaissance login allie
renaissance goals allie
```

## Adding a new student

1. Create a 1Password item with their Renaissance username/password
2. Get the item ID: `op item list | grep -i renaissance`
3. Add them to the `students` array in config.json with `name` and `op_item`
4. Run `renaissance login <name>` — the first login will authenticate and cache the session
5. To find their `user_id`: check `~/.config/renaissance/tokens-<name>.json` after login, or it comes from the gateway auth response (`identity.rgpRosterId`)

## Config Fields

| Field | Description | How to find |
|-------|-------------|-------------|
| `school_id` | School UUID in Renaissance | From marking period API calls |
| `realm_id` | School district realm UUID | From login.renaissance.com redirect URL |
| `rpid` | School's Renaissance ID | Search at schools.renaissance.com, click school, check `/organizations/{id}` API response for `loginUrl` |
| `client_id` | School's CRM ID | From gateway auth response `identity.crmId` |
| `students[].name` | Display name for CLI filter | Your choice |
| `students[].op_item` | 1Password item ID | `op item list \| grep -i <name>` |
| `students[].user_id` | Student's roster GUID | From gateway auth `identity.rgpRosterId` |

## Per-student files

Each student gets their own session files in `~/.config/renaissance/`:
- `cookies-allie.txt` — curl cookie jar
- `tokens-allie.json` — cached user_id/clientId

## Known Values

- **School:** Chisholm Elementary School, Enid, OK
- **RPID:** `CPS-88RB`
- **Base URL:** `https://global-zone05.renaissance-go.com`
