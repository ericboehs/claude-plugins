---
name: setup-lint
description: Configure per-project linting for the code-lint plugin. Detects languages and linters, interviews the user, writes config. Use when user says "/setup-lint".
tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Setup Lint

Interactive setup wizard for the code-lint plugin. Detects project languages and linters, asks what to enable, writes per-project config.

## Step 1: Detect Project

Run the detection script to discover languages, linter configs, and available binaries:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/setup-lint/scripts/detect-project.sh" "${CLAUDE_PROJECT_DIR:-$(pwd)}"
```

If `CLAUDE_PLUGIN_ROOT` is not set, find the script relative to this SKILL.md file (`./scripts/detect-project.sh`).

Parse the JSON output — it describes which languages are present and which linters are available/configured.

## Step 2: Interview User

For each detected language, use AskUserQuestion to confirm:

1. **Language enablement:** "I found Ruby files (Gemfile, .rubocop.yml). Enable Ruby linting?"
2. **Linter selection:** "rubocop and reek are available. Which linters do you want to enable?"
3. **Autofix:** "Auto-fix style issues before checking? (rubocop -A will run before rubocop lint)"
4. **Exclusions:** "Any paths to exclude beyond defaults? (Current defaults: test/, spec/, db/schema.rb)"

### Defaults to suggest

**Ruby:**
- Enable: rubocop, reek
- Exclude: `test/`, `spec/`, `db/schema.rb`
- Autofix: rubocop only

**JavaScript/TypeScript:**
- Enable: eslint (or biome if configured)
- Exclude: `node_modules/`, `dist/`, `build/`
- Autofix: eslint --fix (or biome --write)

**Python:**
- Enable: ruff (preferred), flake8 as fallback
- Exclude: `.venv/`, `__pycache__/`, `migrations/`
- Autofix: ruff --fix

**Go:**
- Enable: golangci-lint
- Exclude: `vendor/`

**Rust:**
- Enable: clippy (whole-project only — won't run in hooks, only in /lint)

**Markdown:**
- Enable: markdownlint
- Exclude: `node_modules/`, `vendor/`
- Autofix: markdownlint --fix

**HTML:**
- Enable: prettier (for check + format)
- Exclude: `node_modules/`, `dist/`, `build/`
- Autofix: prettier --write

**Shell:**
- Enable: shellcheck
- Exclude: `node_modules/`, `vendor/`

### Tool linters (language-agnostic)

After the per-language interview, check for tool linters detected in the JSON output (`tool_linters` key).

**Semgrep** (if detected as available):
1. **Enable Semgrep?** "Semgrep (language-agnostic SAST scanner) is available. Enable it?"
2. **Rulesets:** "Which rulesets? (default: `p/default`). Other options: `p/security-audit`, `p/owasp-top-ten`, or a local `.semgrep.yml` if present."
3. **Hook mode:** "Run Semgrep in the PostToolUse hook (per-file) or only via `/lint`? (default: `/lint` only — recommended, as per-file scanning is slow)"

If Semgrep is not installed, note it and suggest: `pip install semgrep` or `brew install semgrep`.

### Hook settings (ask once)

- **Stop on first failure:** false (default) — run all linters and aggregate
- **Autofix before lint:** true (default) — run autofix commands before checking
- **Skip generated files:** true (default) — skip files with "auto-generated" headers

## Step 3: Write Config

Compute the config path:

```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_HASH=$(echo "$PROJECT_DIR" | tr '/' '-' | sed 's/^-//')
CONFIG_DIR="$HOME/.claude/code-lint/$PROJECT_HASH"
mkdir -p "$CONFIG_DIR"
```

Write config to `$CONFIG_DIR/config.json` using the schema below. Only include languages/linters that the user enabled.

### Config Schema

```json
{
  "version": 1,
  "project_dir": "/absolute/path/to/project",
  "languages": {
    "<language>": {
      "enabled": true,
      "linters": {
        "<linter>": {
          "enabled": true,
          "command": "the lint command",
          "autofix_command": "the autofix command (optional)",
          "file_patterns": ["regex patterns for file extensions"],
          "exclude_patterns": ["regex patterns for paths to skip"],
          "timeout": 30,
          "whole_project_only": false
        }
      }
    }
  },
  "tool_linters": {
    "semgrep": {
      "enabled": true,
      "command": "semgrep scan --quiet",
      "autofix_command": "semgrep scan --autofix --quiet",
      "rulesets": ["p/default"],
      "exclude_patterns": ["node_modules/", "vendor/", ".venv/", "dist/", "build/"],
      "timeout": 120,
      "hook_mode": "off"
    }
  },
  "hook_settings": {
    "stop_on_first_failure": false,
    "autofix_before_lint": true,
    "skip_generated_files": true
  }
}
```

#### tool_linters fields

- **enabled**: Whether the tool linter is active
- **command**: The lint command (file path appended in hook mode, runs on `.` in `/lint` mode)
- **autofix_command**: Optional autofix variant
- **rulesets**: Semgrep-specific — list of ruleset IDs (e.g. `p/default`, `p/security-audit`)
- **exclude_patterns**: Regex patterns for paths to skip
- **timeout**: Seconds before the command is killed (default: 120)
- **hook_mode**: `"off"` (only runs via `/lint`) or `"per-file"` (runs in PostToolUse hook on each edited file)

#### File patterns by language

- **Ruby:** `["\\.rb$", "\\.rake$", "\\.gemspec$"]`
- **JavaScript/TypeScript:** `["\\.js$", "\\.jsx$", "\\.ts$", "\\.tsx$", "\\.mjs$", "\\.cjs$"]`
- **Python:** `["\\.py$"]`
- **Go:** `["\\.go$"]`
- **Rust:** `["\\.rs$"]`
- **Markdown:** `["\\.md$", "\\.mdx$"]`
- **HTML:** `["\\.html$", "\\.htm$"]` (prettier also: `["\\.html$", "\\.htm$", "\\.css$"]`)
- **Shell:** `["\\.sh$", "\\.bash$", "\\.zsh$"]`

## Step 4: Test Linters

For each enabled linter, run a quick test on an existing file to verify it works:

```bash
# Find a sample file
SAMPLE=$(find "$PROJECT_DIR" -name "*.rb" -not -path "*/vendor/*" -not -path "*/node_modules/*" | head -1)

# Test the linter command
cd "$PROJECT_DIR" && bundle exec rubocop "$SAMPLE"
```

Report results: which linters passed, which failed (with error output). If a linter fails, offer to disable it or help troubleshoot.

## Step 5: Summary

Print a summary of what was configured:

```
## Lint Setup Complete

**Project:** /path/to/project
**Config:** ~/.claude/code-lint/<hash>/config.json

**Enabled linters:**
- Ruby: rubocop (autofix), reek
- Shell: shellcheck

**Hook behavior:**
- Runs on Edit/Write of matching files
- Auto-fixes style issues before checking
- Skips generated files

**Usage:**
- Edit any .rb file — linters run automatically via hook
- `/lint` — Run all linters across the full project
- `/lint ruby` — Run only Ruby linters
- `/lint --fix` — Run autofix on all files
```

## Behavior

1. Run through steps sequentially
2. If config already exists, show current config and ask if user wants to reconfigure
3. Be concise in the interview — group related questions when possible
4. If only one language is detected, skip the "enable language?" question (assume yes)
5. If a linter binary is not found, note it and suggest how to install
6. After setup, suggest editing a file to test the hook
