---
name: catching-up-after-time-off
description: Use when the user is back from PTO, vacation, leave, or a long absence and asks to be caught up, or asks what they missed in Slack, GitHub PRs, Jira, Google Docs, or meeting notes over a recent window.
---

# Catching up after time off

## Overview
Build one digest of what the user missed, from five sources: Slack, GitHub, the repo, Jira and Drive. Every claim in it must name the right person and link to its source.

Look up IDs at runtime; this skill lives in a public dotfiles repo, so it stores none.

| Thing | How to get it |
|---|---|
| User email | `$ONA_INSTANCE_OWNER_EMAIL`, else `git config user.email` |
| GitHub login | `gh api user --jq .login` (repo `VantaInc/obsidian`) |
| Slack user ID | `slack-vanta users <email>` |
| Team | Customer Trust Automation |
| Team channels | `slack-vanta channels --filter customer-trust-automation --json`, plus any `proj-*` channels found through @-mentions |
| Repo area | packages and apps whose `vanta.businessDomain` is `customer-trust` |
| Jira project | `CTAUTO` |
| Meeting notes | Drive search for docs named "Customer Trust Automation] Eng Weekly" and "CTAuto EPD Team Meeting Notes". Eng Weekly puts the newest entry at the top; EPD notes put the current quarter's tab first. |

If the user hasn't given an absence window, use the last 14 days without waiting for an answer, and state the window at the top of the digest.

## Before reading anything
Check auth for each source: `gh auth status`, `slack-vanta auth status`, `acli jira auth status`, `gws auth status`. **Follow the service-clis skill.**
- If `gws` isn't on PATH, add the nvm node bin to PATH (`/usr/local/share/nvm/versions/node/*/bin`) and check again before reporting it missing.
- If a source is unavailable, say so in the digest and give its setup step: Slack and gws use [go/agent-cli-tool-setup](https://go/agent-cli-tool-setup); Jira and Datadog use Stratus Settings → Integrations. Don't silently drop the source.
- Never answer a hook error ("Blocked shell file write via >") by writing to files. Pipe straight into `jq` instead.

## Gather (one source at a time; each is independent)

**GitHub**
- `gh search prs --review-requested=@me --state=open`, and the same query with `user-review-requested:@me` to separate direct requests from team requests.
- Then `gh pr view N --json reviewDecision,reviews,additions,deletions,createdAt,statusCheckRollup` for each PR.
- Rank review requests in this order: the PR is in the user's team area, someone DM'd the user about it, it already has the other approvals it needs, then age.
- The user's own open PRs: unresolved review threads through the GraphQL `reviewThreads` query.
- Check for file overlap between the user's PRs and the PRs they've been asked to review: `gh pr diff N --name-only`.

**Repo:** `git log --since=<start> --no-merges` over the area's paths. Filter out bot, lint, Bazel, i18n and flaky-test commits, then group what's left by project.

**Slack**
- Mentions: `slack-vanta search "<@USERID> after:<date>" --count 100 --json`. Drop review-reminder bot posts (text matching `Pending review|Reviews assigned to you`).
- DMs: `slack-vanta search "to:me after:<date>" --json`, keeping only items where `.channel.is_im`.
- Team channels: `slack-vanta history <C…> --count 80 --json`. Open the threads with `reply_count >= 1`, keeping only top-level posts dated inside the window.
- `slack-vanta thread <channel> <ts>` for every thread where someone asked the user something.
- Engineering-wide announcements: `"\"Tier 1\" \"All Engineering\" after:<date>"`.

**Jira:** `acli jira workitem search --jql '<query>' --csv`, run separately for:
- tickets assigned to the user and not done
- tickets that mention the user
- new unassigned or High-priority tickets in the team project

`--fields` doesn't accept `updated`.

**Drive and meeting notes**
- Run `gws drive files list` with `corpora:"allDrives"` and `name contains` queries, one term per call: "Notes", team or project names, "retro", "spec", "PRD".
- Read docs with `bash ~/.claude/skills/catching-up-after-time-off/scripts/gdoc-text.sh <docId>`. It covers every tab, and keeps dates and @-mentions.
- For notes docs, read only the entries dated inside the window.
- Drive rate-limits quickly. Pause between bursts, and report any queries left unsearched.

## Verify before writing
1. **Attribute only resolved names.** Slack JSON often has just a `U…` ID. Batch-resolve every ID you'll cite with `slack-vanta users <ID>` before naming anyone. Never infer a name from context, such as who approved a related PR. If an ID won't resolve, write "unknown user (U…)".
2. **Collect a link for every item as you gather it:** Slack `.permalink` (or `slack-vanta permalink <ch> <ts>`), PR URLs, `https://vanta.atlassian.net/browse/KEY`, and doc URLs with `?tab=` where it helps.
3. **Check ticket and PR state against the code** before calling something done or stale: is the fix merged and on main?

## Digest shape
Sections in this order, each item one line plus a link:
1. **Needs you:** unanswered asks, review requests ranked by team relevance and staleness, overlaps with the user's own work.
2. **Your open PRs:** CI status, unresolved threads.
3. **What shipped in your area:** grouped by project.
4. **Jira:** tickets that look closable (with evidence), tickets still open (with the reason), new tickets that may land on the user.
5. **Team and company news.**
6. **Docs and meeting notes:** what was decided and what's asked of the user.
7. **Gaps:** sources or channels not covered.

## Actions on request only
Closing Jira tickets, replying in Slack and approving PRs are outward-facing. Do them only when the user asks.
- Closing a CTAUTO ticket fails unless **Investment Mix** (`customfield_10042`) is set. Allowed values: KTLO, Foundational, Continuous Improvement, New Capabilities. Ask the user which value to use.
- acli can't set custom fields. Check whether REST works: `curl -s -o /dev/null -w '%{http_code}' -u "$JIRA_EMAIL:$JIRA_API_TOKEN" https://vanta.atlassian.net/rest/api/3/myself`. On 200, set the field with a PUT to `/rest/api/3/issue/<KEY>`. Otherwise ask the user to set it in the Jira UI.
- Then close it: `acli jira workitem transition --key <KEY> --status Done --yes`.

## Common mistakes
| Mistake | Fix |
|---|---|
| Naming the wrong person as a message's author | Resolve the ID first (Verify, step 1) |
| "Posted in #channel" with no link | Use the message permalink |
| Bare `CTAUTO-123` | Link it to vanta.atlassian.net/browse |
| Reporting gws or Slack as unavailable after one failed check | Re-check PATH and auth, then give setup steps |
| Treating every review reminder as an ask | Keep only humans asking the user directly |
| Reading a whole notes doc as new | Read only the entries dated inside the window |
