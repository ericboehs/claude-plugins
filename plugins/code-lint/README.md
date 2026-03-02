# code-lint

Multi-language linting via PostToolUse hooks. Automatically runs configured linters when Claude edits or creates files, feeding errors back for immediate correction.

## How It Works

1. **Install** the plugin — hooks are registered automatically
2. **Run `/setup-lint`** in your project — detects languages, interviews you, writes config
3. **Edit files normally** — the hook runs matching linters after each Edit/Write and feeds errors back to Claude via exit code 2

Config is stored per-project at `~/.claude/code-lint/<project-hash>/config.json` — nothing is written to the project repo.

## Skills

### /setup-lint

Interactive setup wizard:
- Auto-detects languages and available linters in the current project
- Asks which linters to enable, autofix preferences, and paths to exclude
- Tests each linter to verify it works
- Writes the config file

### /lint

Full-project lint (includes whole-project-only linters like brakeman and clippy):
- `/lint` — Run all enabled linters
- `/lint ruby` — Run only Ruby linters
- `/lint reek` — Run only reek
- `/lint --fix` — Autofix first, then lint

## Supported Languages & Linters

| Language | Linters | Autofix | Notes |
|----------|---------|---------|-------|
| Ruby | [rubocop](https://github.com/rubocop/rubocop), [reek](https://github.com/troessner/reek), [brakeman](https://github.com/presidentbeef/brakeman) | rubocop -A | brakeman is whole-project only |
| JS/TS | [eslint](https://github.com/eslint/eslint), [biome](https://github.com/biomejs/biome) | eslint --fix, biome --write | |
| Python | [ruff](https://github.com/astral-sh/ruff), [mypy](https://github.com/python/mypy), [flake8](https://github.com/PyCQA/flake8) | ruff --fix | |
| Go | [golangci-lint](https://github.com/golangci/golangci-lint) | | |
| Rust | [clippy](https://github.com/rust-lang/rust-clippy) | | whole-project only |
| Markdown | [markdownlint](https://github.com/DavidAnson/markdownlint) | markdownlint --fix | via markdownlint-cli |
| HTML | [htmlhint](https://github.com/htmlhint/HTMLHint), [prettier](https://github.com/prettier/prettier) | prettier --write | prettier also handles CSS |
| Shell | [shellcheck](https://github.com/koalaman/shellcheck) | | static analysis for sh/bash/zsh |

## Hook Behavior

The PostToolUse hook fires on every Edit/Write and:
1. Maps the file extension to a language (also checks shebang for extensionless files)
2. Loads the per-project config (no config = silent no-op)
3. Checks if the language is enabled and the path isn't excluded
4. Optionally runs autofix commands first
5. Runs each enabled linter on the file
6. Aggregates errors and exits 2 (feeding them back to Claude) or exits 0 (all clear)

## Config Example

```json
{
  "version": 1,
  "project_dir": "/Users/eric/Code/myapp",
  "languages": {
    "ruby": {
      "enabled": true,
      "linters": {
        "rubocop": {
          "enabled": true,
          "command": "bundle exec rubocop",
          "autofix_command": "bundle exec rubocop -A --fail-level=error",
          "file_patterns": ["\\.rb$"],
          "exclude_patterns": ["test/", "spec/", "db/schema\\.rb$"],
          "timeout": 30
        },
        "reek": {
          "enabled": true,
          "command": "bundle exec reek",
          "file_patterns": ["\\.rb$"],
          "exclude_patterns": ["test/", "spec/"],
          "timeout": 30
        }
      }
    }
  },
  "hook_settings": {
    "stop_on_first_failure": false,
    "autofix_before_lint": true,
    "skip_generated_files": true
  }
}
```

## Reference Docs

The `references/` directory contains BAD/GOOD fix patterns for each language, helping Claude fix lint errors correctly the first time. These are loaded by the `/lint` skill when presenting results.
