---
name: audit-ticket
description: "Trigger: audit a ticket, \"audit ticket\", \"sigue vigente?\", \"revisá <id> antes de arrancar\", before planning or coding. Verifies claims vs code, AC viability, relations, comments."
---

# Audit Ticket

Decide whether the ticket is still worth planning against, and say exactly what must change if it is not. Read-only on the repo and on the repo's ticket tracker configured in `.skills/config.md`: no git mutation, no tracker writes. The output is a verdict plus an edit list the user applies afterwards, plus one local record — `tasks/<TICKET-ID>/audit.md` (path from config docs layout) — that `plan` and `start-task` read to tell a fresh audit from a stale one. Ticket ids follow the format in config.

## Execution Steps

1. **Fetch the ticket and its surroundings** in parallel through the tracker's MCP/CLI: the ticket with relations (`blockedBy`, `blocks`, `related`, `duplicate`, parent), every comment (including inline ones and the text they quote), the parent and its siblings (title, assignee, state), and each related ticket's state/assignee/title. Also read the host `AGENTS.md` — the conventions the ticket's claims get measured against. Done when the ticket, its web of relations, and every comment are in context.

2. **Check format and status.** Validate the description against the repo's ticket format from config/`AGENTS.md` (default: Why | What | Acceptance Criteria | Notes). Missing sections go in the edit list; they do not by themselves fail the audit. Record the status first: only a startable state — or in-progress assigned to the current user (the resume case) — is startable per the config triage rules; anything else is the first line of the verdict, because `start-task` stops on it regardless of the rest of the audit.

3. **Verify the claims.** Extract every factual assertion in the description: "X does Y today", "Z lives in file.ts:12-40", "there is no way to do W". For each: find the artifact — a cited path read at HEAD, a named symbol grepped, a behavioral claim traced to the code implementing it — then classify: **holds** (cite `file:line` at HEAD), **drifted** (exists but moved/renamed/reshaped; give the new location), **superseded** (a merged PR or a done sibling already did what the ticket asks; cite the PR or ticket), **false** (cite what you found instead). For "there is no X" claims search the whole tree, not just the cited directory — one counter-example kills the claim. When a claim looks stale, check source history on its key symbols and search the PR tool for the key nouns. Done when every claim carries one of the four verdicts with evidence.

4. **Test the acceptance criteria.** For every AC: **viable** — can it still be satisfied and verified as written? Name the current equivalent, or that there is none. **Already met** — does HEAD already satisfy it? Cite the test/code; drop it from the plan, never re-prove it. **Testable** — does it name a concrete observable (a status, a rendered string, a refusal reason), or "works correctly"? Untestable ones get a proposed wording. **Coupling** — one deliverable, or two that could ship independently? Propose the split explicitly: which ACs go where, which half starts now. Propose annul ONLY for an AC already met or retired by a recorded decision — never because it is hard.

5. **Check relations.** Any non-terminal blocker = hard stop — name it, its state, its assignee; do not soften this. Blocks = what this ticket unblocks; it weighs toward doing it soon. Siblings: flag one that should go first when this ticket assumes a contract/table/endpoint it creates, is smaller and lands a shared foundation, or is already being worked on the same files — one line each, only with a real dependency, otherwise report "no ordering constraint". A duplicate relation is a stop; a done related ticket may have superseded part of this one (back to step 3). Search open PRs for the ticket id and its parent; an open PR on this ticket by someone else makes the verdict "coordinate first".

6. **Judge currency.** Read every comment for signals the description is out of date ("let's split this", "blocked on", "after <TICKET-ID>", "descoped", "see the new ticket", an unanswered question, a dated decision) and map each inline comment to the description sentence it challenges. Compare the ticket's last update against the last change of each file it cites (`git log -1 -- <path>`); a description last edited before its cited files changed is one nobody re-read after the code moved — report the gap in days, not as an adjective. Decide one: **current** / **needs correction** (list the edits) / **should be split** (name the two deliverables) / **should be dropped** (say why, with evidence).

7. **Render the verdict.** `## Audit: <TICKET-ID> <title>`, then verdict — PLANNABLE | PLANNABLE AFTER EDITS | BLOCKED | SPLIT FIRST | DROP — plus a status line, `### Claims` table (Claim | Verdict | Evidence), `### Acceptance criteria` table (AC | Viable | Already met | Testable | Proposal), `### Relations` (blocked by / do first / blocks / open PRs), `### Currency`, `### Edit list for the ticket` — exact section + replacement text, written so the user can paste it into the tracker. Every row cites an artifact at HEAD: a `file:line`, a PR, a ticket id, or a comment. A row without one is marked `unverified`, never promoted to holds.

8. **Write the record.** Write `tasks/<TICKET-ID>/audit.md` (create the directory; always written, whatever the verdict). Machine-readable header — `audited_at` (ISO-8601 UTC), `ticket_updated_at` (verbatim from the tracker), `latest_comment_at`, `related_updated_at` (max across parent/siblings/relations), `head_sha` (`git rev-parse HEAD` at audit time), `verdict`, `cited_files` (every path evidence cited, held or not) — with the full verdict below. Overwrite an existing audit; the previous verdict is not history worth keeping once a new audit ran. If PLANNABLE (or AFTER EDITS), close with one line offering the `plan` skill — or, when the edits are blocking, offering a re-run of this audit once they are applied.

## Important rules

- **Read-only except the record** — the only write is `tasks/<TICKET-ID>/audit.md`; the edit list is never applied by this skill.
- **Superseded beats everything** — a ticket whose Why is already satisfied is reported DROP even when its ACs read fine.
- **A live blocker is BLOCKED** — no "start the unblocked half" unless a step-4 split exists.
- **Never annul an AC for difficulty**; sibling ordering needs a named dependency.
- **Ticket content stays English**, also in the edit list, even mid-Spanish conversation; no bare `#NNNN` references — write "PR 5348".

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/audit-ticket.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Tracker differences: youtrack — issue fetch + comments + a "blocked by" link search per related id. linear — issue with `includeRelations`, comment list, siblings by parent id. jira — issue with `issuelinks`, comment list, JQL for siblings. github — issue timeline/linked issues + `gh` for open-PR search. file-based — the ticket file defined in config carries comments/relations as sections; parent/sibling scope is what the file records.
