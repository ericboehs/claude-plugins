---
name: x-fetch
description: Retrieve the full content of an X/Twitter link — tweet text, images, and gated long-form articles. Use when given an x.com or twitter.com URL, or when the user says "/x-fetch", "read this tweet", or "what does this X post say".
tools: Bash, Read
disable-model-invocation: true
---

# Fetch an X/Twitter link

Retrieve everything behind an X URL: $ARGUMENTS

`WebFetch` **cannot read x.com** — it returns `HTTP 402 Payment Required`, and the
usual reader proxies (`r.jina.ai`) are rate-blocked on the domain. Use the three
tiers below instead. Most links only need tiers 1–2.

## Step 0 — Normalize the URL

Strip tracking params and pull out the parts:

```bash
# https://x.com/starmexxx/status/2083468826390270401?s=46 → starmexxx / 2083468826390270401
URL="${1%%\?*}"
USER=$(echo "$URL" | sed -n 's#.*://[^/]*/\([^/]*\)/status/.*#\1#p')
ID=$(echo "$URL" | sed -n 's#.*/status/\([0-9]*\).*#\1#p')
```

`twitter.com`, `x.com`, and `fixupx.com` are interchangeable. A bare
`x.com/i/article/<id>` link has no user or status id — skip to **Tier 3**.

## Tier 1 — Tweet metadata and text (no auth)

```bash
curl -s "https://api.fxtwitter.com/$USER/status/$ID" > /tmp/fx.json
jq -r '{
  text:    .tweet.text,
  author:  .tweet.author.screen_name,
  created: .tweet.created_at,
  article: .tweet.article.title,
  links:   [.tweet.raw_text.urls[]?.url]
}' /tmp/fx.json
```

**The decisive field is `.tweet.article.title`.** If it is non-null, the tweet is a
stub — `.tweet.text` will be empty or a bare `t.co` link, and *all* the substance
lives in the article body and its images. Do not summarize from `.tweet.text`;
continue to tiers 2 and 3.

## Tier 2 — Images (this is usually where the content is)

These posts carry their argument in infographics, not prose. Schema varies by post
type, so grep the raw JSON rather than guessing a path:

```bash
grep -o 'https://pbs.twimg.com/media/[A-Za-z0-9_-]*\.\(jpg\|png\)' /tmp/fx.json | sort -u
```

Precise paths, if you want them: `.tweet.media.photos[].url` for ordinary photo
tweets; `.tweet.article.cover_media.media_info.original_img_url` and
`.tweet.article.media_entities[].media_info.original_img_url` for articles.

Download at full resolution and **Read each one** — hand-drawn diagrams and tables
are the payload:

```bash
curl -sL "$IMG?name=large" -o "$SCRATCH/<id>.jpg"   # ?name=large, or you get a thumbnail
```

Judge the images. A "benchmark table" is often just a vendor's launch chart
reproduced for authority, and a cover image may advertise a config the article
never mentions — say so rather than treating it as content.

## Tier 3 — Gated long-form articles (`/i/article/`)

Only needed when Tier 1 reported an `article.title`. Uses the real Safari session,
so there is no separate login and no stored cookie:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/x-article.sh "https://x.com/i/article/<id>" > "$SCRATCH/article.txt"
wc -c "$SCRATCH/article.txt"    # a real article is >5KB; ~600 bytes means a login wall
```

If `CLAUDE_PLUGIN_ROOT` is not set, find the script relative to this SKILL.md (`../../scripts/x-article.sh`).

Then Read the file. The script opens a throwaway window, waits for hydration,
scrolls twice for lazy-loaded tail content, and closes the window.

**Prerequisite:** Safari → Settings → Advanced → "Show features for web developers",
then Develop → "Allow JavaScript from Apple Events". Verify in one line:

```bash
osascript -e 'tell application "Safari" to do JavaScript "document.title" in document 1'
```

A privilege-violation error means the setting is off. If the output is a login
page, Eric needs to sign in to X in Safari — **never attempt to log in yourself.**

## Gotchas

- **`WebFetch` on any x.com URL returns 402.** Don't retry it; go to Tier 1.
- **`r.jina.ai` is blocked for x.com** (abuse rate-limiting on the whole domain).
- **`?name=large` matters** — without it `pbs.twimg.com` serves a thumbnail too small
  to read text in a diagram.
- **Hold `current tab of window 1`, not `document 1`.** A document reference goes
  stale the moment the page title changes, giving `Can't get document "Untitled"`.
- **`readyState === "complete"` is not enough** — X hydrates the body afterward.
  The script's extra 3s settle is load-bearing.
- **Close the window when done.** It's the user's real browser.
- Playwright (`playwright-cli -s=x`) also works, but starts logged out and needs a
  saved `state-save` cookie file. Safari is strictly less setup.

## Output

Report, in this order:

1. **Which tiers you used**, and say plainly if a tier failed.
2. **The actual thesis** of the tweet or article, not a paraphrase of the headline.
3. **Anything that doesn't hold up** — a title naming a model the body never uses,
   arithmetic that assumes a service limit it doesn't meet, a cover image promising
   a config that isn't in the text. Read these posts skeptically; they are written
   to be shared, not to be right.
