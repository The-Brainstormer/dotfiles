#!/usr/bin/env bash
# Print a Google Doc as plain text, every tab included, via gws.
# Dates, @-mentions and smart chips are rendered inline, so meeting-note
# headers like "[Nov 10, 2026]" and attendee names survive.
# Usage: bash gdoc-text.sh <documentId>
set -euo pipefail
doc_id="${1:?usage: gdoc-text.sh <documentId>}"

# gws prints a "Using keyring backend" banner before the JSON; awk drops it.
gws docs documents get --params "{\"documentId\":\"${doc_id}\",\"includeTabsContent\":true}" 2>/dev/null \
  | awk 'f || /^\{/ { f = 1; print }' \
  | jq -r '
def el:
  .textRun?.content?
  // (.dateElement?.dateElementProperties?.displayText // empty | "[\(.)] ")
  // (.person?.personProperties?.name // empty | "@\(.) ")
  // (.richLink?.richLinkProperties | select(.) | "<\(.title)|\(.uri)> ")
  // empty;
def txt:
  [ .content[]?
    | (.paragraph? | select(.)
        | ((.paragraphStyle.namedStyleType // "") as $s
           | ([.elements[]? | el] | join("")) as $t
           | (if ($s | test("HEADING")) then "## " else "" end) + $t)),
      (.table? | select(.)
        | [.. | .paragraph? // empty | [.elements[]? | el] | join("")] | join(" | ") + "\n")
  ] | join("");
def walk_tabs:
  ("\n=== TAB: \(.tabProperties.title) (?tab=\(.tabProperties.tabId))\n" + (.documentTab.body | txt)),
  (.childTabs[]? | walk_tabs);
if .tabs then (.tabs[] | walk_tabs) else (.error.message // "no tabs in response") end' \
  | grep -v '^\s*$'
