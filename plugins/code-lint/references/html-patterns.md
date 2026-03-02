# HTML Linter Patterns

Fix guidance for common HTMLHint and Prettier issues. Use these BAD/GOOD patterns to fix lint errors correctly the first time.

## HTMLHint Rules

### tag-pair — Missing Closing Tags

Every opened tag must have a matching closing tag (except void elements like `<br>`, `<img>`, `<input>`).

BAD:
```html
<div>
  <p>Hello
</div>
```

GOOD:
```html
<div>
  <p>Hello</p>
</div>
```

### attr-lowercase — Uppercase Attributes

All attribute names must be lowercase.

BAD: `<div CLASS="container" onClick="handler()">`
GOOD: `<div class="container" onclick="handler()">`

### id-unique — Duplicate IDs

Each `id` value must appear exactly once per document. Use classes for repeated styling hooks.

BAD: `<div id="header">` appearing twice on the same page.
GOOD: Use `id="header"` once; apply `class="header-section"` to additional elements.

### src-not-empty — Empty src Attributes

Never use an empty `src` on `<img>`, `<script>`, or `<iframe>`. Empty `src` triggers a redundant browser request.

BAD: `<img src="">` / `<script src="">`
GOOD: Remove the attribute entirely or provide a valid path.

### alt-require — Missing alt on Images

Every `<img>` must have an `alt` attribute. Use an empty string for decorative images.

BAD: `<img src="logo.png">`
GOOD: `<img src="logo.png" alt="Company logo">` (descriptive) or `<img src="divider.png" alt="">` (decorative)

## Prettier Formatting

### Indentation

Use 2-space indentation. Never mix tabs and spaces.

BAD:
```html
<ul>
    <li>Item</li>
</ul>
```

GOOD:
```html
<ul>
  <li>Item</li>
</ul>
```

### Quotes

Use double quotes for attribute values. Never use single quotes or unquoted values.

BAD: `<div class='container'>` / `<input type=text>`
GOOD: `<div class="container">` / `<input type="text">`

### Trailing Commas and Whitespace

Prettier removes trailing whitespace and normalizes blank lines. Run `prettier --write` to auto-fix formatting issues rather than editing manually — Prettier's output is the authoritative format.
