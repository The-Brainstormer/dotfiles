---
name: slack-attribution
description: Resolve Slack user IDs with slack-vanta users before attributing any message to a person
metadata:
  node_type: memory
  type: feedback
  originSessionId: 7d526939-c651-4fdd-9644-5a3360e59e7a
  modified: 2026-11-12T00:17:09.745Z
---

`slack-vanta history`/`search` JSON often gives only a user ID (U...), not a name. Resolve each ID with `slack-vanta users <ID>` before naming who said something. Never infer the name from context (e.g. who approved a related PR).

**Why:** I once guessed a user ID's owner from a related PR approval and attributed three messages to the wrong teammate. The user caught it and asked that it never happen again.

**How to apply:** Batch-resolve every user ID I plan to cite before writing a summary. Pairs with [[jira-ticket-links]] (link the message permalink too).
