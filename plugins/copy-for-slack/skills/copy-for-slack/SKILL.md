# Copy for Slack Skill

Copies the last assistant message to the clipboard, converted to Slack-compatible formatting.

## Usage

User says: "/copy-for-slack", "copy for slack", "copy that for slack"

## Instructions

1. Look at your most recent assistant message (before this skill was invoked)
2. Convert the markdown to Slack-compatible format using these rules:
   - `**bold**` → `*bold*`
   - `_italic_` or `*italic*` (single) → `_italic_`
   - `## Headings` or `### Headings` → `*Heading text*` (bold, on its own line)
   - `# Headings` → `*Heading text*` (bold, on its own line)
   - `- list items` → `• list items`
   - Nested `  - items` → `  • items`
   - `[link text](url)` → `<url|link text>`
   - `` `inline code` `` → `` `inline code` `` (unchanged, Slack supports this)
   - Code fences (```) → ``` (unchanged, Slack supports this)
   - `> blockquotes` → `> blockquotes` (unchanged, Slack supports this)
   - Horizontal rules (`---`) → `———`
   - Remove any HTML tags
3. Copy the converted text to the clipboard using: `pbcopy`
4. Report the character count and confirm it was copied
