#!/usr/bin/env bash
# Read a gated X/Twitter page (long-form article, or any logged-in-only view)
# through the user's real Safari session and print its text to stdout.
#
# Usage: x-article.sh <url> [max-wait-seconds]
#
# Requires Safari's Develop menu → "Allow JavaScript from Apple Events".
# Opens a throwaway window and closes it again; existing tabs are untouched.
set -euo pipefail

URL="${1:?usage: x-article.sh <url> [max-wait-seconds]}"
MAX_WAIT="${2:-30}"

osascript <<APPLESCRIPT
tell application "Safari"
	make new document
	-- Hold the tab, not the document: a document reference goes stale as soon
	-- as the page title changes, which throws "Can't get document "Untitled"".
	set theTab to current tab of window 1
	set URL of theTab to "$URL"

	repeat $((MAX_WAIT * 2)) times
		delay 0.5
		try
			if (do JavaScript "document.readyState" in theTab) is "complete" then exit repeat
		end try
	end repeat

	-- X hydrates the article body after readyState complete, and lazy-loads the
	-- tail on scroll. Settle, then scroll twice.
	delay 3
	try
		do JavaScript "window.scrollTo(0, document.body.scrollHeight)" in theTab
		delay 2
		do JavaScript "window.scrollTo(0, document.body.scrollHeight)" in theTab
		delay 2
	end try

	set theText to (do JavaScript "document.body.innerText" in theTab)
	close window 1
	return theText
end tell
APPLESCRIPT
