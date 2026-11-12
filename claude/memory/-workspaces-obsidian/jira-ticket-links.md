---
name: jira-ticket-links
description: "Link every external reference (Jira, Slack messages/threads, PRs, docs) to its source"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 7d526939-c651-4fdd-9644-5a3360e59e7a
  modified: 2026-11-12T00:17:19.307Z
---

Every external reference in a reply must be a clickable link to its source:
- Jira keys: `[CTAUTO-2645](https://vanta.atlassian.net/browse/CTAUTO-2645)`
- Slack messages or threads: the permalink (`slack-vanta permalink <channel> <ts>`), e.g. "A teammate [posted a note](https://vantahq.slack.com/archives/...)" — never just "posted in #channel"
- GitHub PRs, docs, dashboards: full URLs

**Why:** The user asked for this explicitly (first for Jira, then generalized after I described a Slack post without linking it). They want to jump straight to the source.

**How to apply:** While gathering info, keep the permalink/URL for anything I might cite, so the final summary can link every claim without extra lookups.
