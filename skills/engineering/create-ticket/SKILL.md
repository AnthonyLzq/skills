---
name: create-ticket
description: "Trigger: create a ticket, \"creemos el ticket\", \"haceme un ticket\", \"file a follow-up\", or turn findings into tickets. Drafts in the repo format, files only after approval."
---

# Create Ticket

Draft and file one follow-up ticket in the repo's ticket tracker configured in `.skills/config.md`, with a mandatory show-before-create gate: the complete ticket is rendered and approved before anything is created. Creation without the user's explicit approval is the one unforgivable failure of this skill.

## Execution Steps

1. **Gather the substance** from the conversation — an incident analysis, review findings, follow-up candidates — or by asking. Every claim that goes in the ticket is verified against evidence before it is written down: file paths, line anchors, run ids, and prior-ticket numbers are checked from the artifacts, never from recall. Done when each candidate claim has an evidence anchor or is dropped.

2. **Decide the ticket count.** One concern, one ticket is the default. Group related small items (each ~1 file) when they share one origin and one narrative, structured as numbered workstreams. Never group a large open-ended workstream (an audit, a migration) with quick fixes unless the user prefers fewer tickets — the cost is the ticket stays open until the slowest part lands. State that trade-off, let the user pick, and do not relitigate after they choose.

3. **Draft in the repo's ticket format and SHOW it.** Read the format from config/`AGENTS.md`; the default standard is non-negotiable: title formula `<Verb> <object> <location/context> so that <intended outcome>`; four sections, always this order — `## Why` (up to 3 sentences; cite prior incidents/PRs/tickets when the motivation is "this happened before"), `## What` (precise bullets a developer can act on; say "PR N of M" when the work may ship as several), `## Acceptance Criteria` (binary, testable conditions), `## Notes / References` optional (evidence links, related ticket ids, file:line anchors, prior-art PRs). Style is part of the standard: ticket content always English, even mid-Spanish conversation; simple language (reading age ~12); no em dashes; no bare `#N` references — they autolink wrongly, write "PR 3852". Render the complete ticket (title + all sections) in chat, wait for explicit approval, and iterate on shape as many times as asked. Never create before the user says go.

4. **Create through the tracker's MCP/CLI**, making sure the call CREATES (an id-shaped update parameter would overwrite an existing ticket instead). Defaults: state = the tracker's intake state, letting the team promote it to startable — EXCEPT when the work is already agreed and scoped in-conversation, then the startable state per config; say which you chose and why. Priority judged from impact: prod-broken/high disruption at the top tier, incident follow-ups and hardening in the middle, nice-to-have below; reserve the top tier for active incidents. Labels from the repo's existing set only — never invent one. Link the originating tickets and sibling follow-ups as relations. Project/cycle only when the user names one; never guess. Done when the tracker returns the new id and the creation call matches the shown draft.

5. **Report back**: the created id + URL, one line restating state/priority/labels, and — when the ticket is startable and the user is the natural owner — an offer of the `start-task` skill.

## Important rules

- **Show before create, always** — iterate until approved; never create on a silent assumption.
- **Don't invent acceptance criteria** — if the substance does not yield binary conditions, ask rather than pad.
- **Verify every reference before writing it** (file:line, run ids, PR numbers, prior tickets).
- **Ticket text in the standard's language and style** — content English, no em dashes, no bare `#N`.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/create-ticket.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Tracker differences: youtrack — issue-create command, then set state/priority/labels/comments. linear — save-issue without an update id; labels read from the label list call. jira — issue create with the repo's field map. github — issue-create CLI with label/assignee flags. file-based — write a formatted ticket file into the source dir from config.
