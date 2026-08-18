---
name: md-to-pdf
description: Convert a GitHub-flavored markdown file to a GitHub-styled PDF using pandoc + headless Chrome. Use when the user asks to convert markdown to PDF, render an .md as PDF, or says "/md-to-pdf".
---

# md-to-pdf Skill

Convert a GitHub-flavored markdown file to a PDF that looks like github.com's rendering (real `github-markdown-css` through headless Chrome, not LaTeX).

## Usage

User says: "/md-to-pdf", "convert this markdown to pdf", "render X.md as a pdf", "make a pdf out of this doc".

Optional arguments:
- **Input path** — the `.md` file to convert (required)
- **Output path** — where to write the PDF (defaults to `<input>.pdf` next to the source)

## Running It

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/md2pdf" "/path/to/input.md"                    # writes /path/to/input.pdf
"${CLAUDE_PLUGIN_ROOT}/scripts/md2pdf" "/path/to/input.md" "/tmp/output.pdf"  # custom output path
```

If `CLAUDE_PLUGIN_ROOT` is not set, find the script relative to this SKILL.md (`../../scripts/md2pdf`).

Then open the result:

```bash
open "/path/to/input.pdf"
```

## How It Works

1. **pandoc** — parses GFM into standalone HTML5, embedding local images
2. **github-markdown-css** — fetched once into `~/.cache/md2pdf/` and concatenated with the plugin's `assets/github-print.css`, which adds page size, wide-table wrapping, and avoid-break rules
3. **headless Chrome** — prints the HTML to PDF via `--print-to-pdf`

The script wraps pandoc's output in `<article class="markdown-body">` because `github-markdown-css` scopes all of its selectors to that class — without the wrapper, none of the GitHub styling applies.

## Prerequisites

- **pandoc** — `brew install pandoc` (or your package manager)
- **Chrome or Chromium** — the script checks Google Chrome, Chromium, and Chrome Canary in `/Applications`, then `google-chrome`/`chromium`/`chromium-browser` on `PATH`
- **Network access on first run only** — to cache `github-markdown-css`

## Options

- **Dark mode** — `MD2PDF_THEME=dark md2pdf input.md` (fetches the dark stylesheet and forces the page background)

## When Things Go Wrong

- **Tables still overflow** — in `assets/github-print.css`, drop `.markdown-body table` `font-size` to 8pt, or change `@page size` to `Letter landscape`
- **Images missing** — pandoc uses `--embed-resources`, so make sure paths in the markdown resolve from the source file's directory
- **Blank PDF or Chrome errors** — try `--headless` (old) instead of `--headless=new` in the script
- **Stale styling** — delete `~/.cache/md2pdf/` to refetch the base stylesheet

## Alternatives (if this output isn't right)

- **Eisvogel (LaTeX)** — more "academic paper" look, but struggles with wide tables. Use when the output should read like a typeset document rather than github.com.
- **npx md-to-pdf** — similar Chromium-based approach via npm, no local scripts, but requires npm on PATH.
