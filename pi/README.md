# pi integration

The Claude plugins use the Agent Skills format, so pi can load their `skills/`
directories without copying or rewriting them. Configure selected directories in
`~/.pi/agent/settings.json` under `skills`.

## Code-lint extension

`extensions/code-lint.ts` adapts pi's `edit` and `write` tool results to the JSON
input expected by `plugins/code-lint/hooks/lint.sh`. The existing Claude hook and
its configuration remain the source of truth:

```text
~/.claude/code-lint/<project-hash>/config.json
```

Add the extension to pi's global settings:

```json
{
  "extensions": [
    "~/Code/github.com/ericboehs/claude-plugins/pi/extensions/code-lint.ts"
  ]
}
```

The adapter does not mark a successful edit/write as failed when lint finds an
issue. Instead, it appends the lint output to that tool result so the agent can
fix it.
