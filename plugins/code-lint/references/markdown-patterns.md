# Markdown Linter Patterns

Fix guidance for common markdownlint issues. Use these BAD/GOOD patterns to fix lint errors correctly the first time.

## MD001 — Heading Increment

Heading levels must increment by one. Never skip levels (e.g., h1 → h3).

BAD:
```markdown
# Title

### Section
```

GOOD:
```markdown
# Title

## Section
```

## MD009 — Trailing Spaces

Remove trailing whitespace from line ends. Intentional line breaks use a backslash or HTML `<br>`, not trailing spaces.

BAD: `This line has spaces   `
GOOD: `This line is clean`

## MD012 — Multiple Consecutive Blank Lines

Never use more than one consecutive blank line. Collapse double-blank lines to single.

## MD013 — Line Length

Keep lines under the configured max (usually 80 or 120 chars). Break prose at natural sentence or clause boundaries. URLs on their own line are often exempt — check the project config.

## MD022 — Headings Should Be Surrounded by Blank Lines

Every heading needs a blank line before and after it (except at the very start of the file).

BAD:
```markdown
Some text.
## Heading
More text.
```

GOOD:
```markdown
Some text.

## Heading

More text.
```

## MD031 — Fenced Code Blocks Should Be Surrounded by Blank Lines

Code fences need a blank line before the opening ` ``` ` and after the closing ` ``` `.

BAD:
```markdown
Some text.
```bash
echo hello
```
More text.
```

GOOD:
```markdown
Some text.

```bash
echo hello
```

More text.
```

## MD032 — Lists Should Be Surrounded by Blank Lines

A list needs a blank line before the first item and after the last item.

BAD:
```markdown
Some text.
- item one
- item two
More text.
```

GOOD:
```markdown
Some text.

- item one
- item two

More text.
```

## MD034 — Bare URLs

Wrap raw URLs in angle brackets or use link syntax. Never leave a bare URL in prose.

BAD: `See https://example.com for details.`
GOOD: `See <https://example.com> for details.` or `See [Example](https://example.com) for details.`

## MD041 — First Line Should Be a Top-Level Heading

The first non-empty line of every file must be an h1 heading.

BAD: File starts with a paragraph or h2.
GOOD: File starts with `# Title`.
