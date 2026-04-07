---
name: setup-wengage
description: Set up the wengage CLI tool for checking school grades. Use when user says "/setup-wengage" or needs to configure Wengage credentials.
tools: Bash
---

# Setup Wengage CLI

Interactive setup for the `wengage` CLI grade checker tool.

## Prerequisites

- **fnox** — secret management (`mise install fnox`)
- **Playwright** installed (will install via npm if needed)
- Wengage account credentials (username and password)

## Setup Steps

1. Check prerequisites are installed (`fnox`, Playwright)
2. Store credentials in fnox keychain:
   ```bash
   fnox set WENGAGE_USERNAME "your_username" --provider keychain --global
   fnox set WENGAGE_PASSWORD "your_password" --provider keychain --global
   ```
3. Create config at `~/.config/wengage/config.json`:
   ```json
   {
     "url": "https://ok.wengage.com/YourDistrict"
   }
   ```
   Student names and grade levels are auto-discovered from the portal. Optionally add a `students` array to override names/grades.
4. Install Playwright if needed:
   ```bash
   cd PLUGIN_PATH && npm install
   ```
5. Symlink the CLI: `ln -sf PLUGIN_PATH/bin/wengage ~/bin/wengage`
6. Test with `wengage grades`

## Config notes

- `url`: The base URL for your school district's Wengage instance
- `students` (optional): Array of student objects with `id`, `name`, and `grade` to override auto-discovery
