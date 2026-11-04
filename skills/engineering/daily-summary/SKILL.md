---
name: daily-summary
description: "Trigger: \"daily\", \"standup\", \"what did I ship yesterday/today\", \"resumen del daily\", agent handoff brief. Builds both from one day's merged work."
---

# Daily Summary

Build two reports of the same work from the same facts: the tickets the user finished on the target day, counting only work whose PR is merged to the base branch from the config branch model. The human report is one short plain line per ticket to read out in the standup; the agent report is one detailed JSON brief another agent reads cold — files, decisions, evidence, follow-ups. Both come out every time unless the user asks for only one. PR evidence comes from the `gh` CLI (the documented default); ticket reads go through the tracker's MCP/CLI from `.skills/config.md`.

## Language

- Chat in the user's language. Both written reports are in English — the human one natural, first person, how it sounds said out loud; the agent brief precise third person.
- No internal bookkeeping or review codes in either report; name things by what they do.

## Execution Steps

1. **Pick the day.** `today` → today; `yesterday` or no argument → yesterday, and on a Monday the last working day (say so). A date is used as given. A range `A..B` (each end `yesterday`/`today`/a date, inclusive; accept spoken synonyms like "the last 2 days") runs steps 2–5 once, assigning each PR to its local merge day; a ticket whose PRs merged on different days sits under its last merged PR, with all PRs listed. Judge "the day" in the user's local time — merged timestamps arrive in UTC, so convert (`python3`, not `date`): `python3 -c "from datetime import datetime; print(datetime.fromisoformat('2026-10-14T03:30:00Z'.replace('Z','+00:00')).astimezone().strftime('%Y-%m-%d %H:%M'))"`. Done when the window is fixed and stated.

2. **Find the merged PRs.** Fetch one day of slack on each side, then keep only PRs whose merged timestamps, in local time, fall in the window. Only merges into the base branch count — an open PR, a closed-unmerged PR, or one merged elsewhere does not count and is never listed as done. Pass the host repo explicitly (`-R <owner/repo>`) when running outside it; the current user (`@me`) is the author.

   ```bash
   gh pr list -R <owner/repo> --author "@me" --state merged --base <base> \
     --search "merged:>=<window start minus 1>" --limit 100 \
     --json number,title,body,headRefName,baseRefName,mergedAt,url
   ```

3. **Map PRs to tickets.** The ticket key is the config ticket-id format matched in the branch name, then the PR title, then the body. Several PRs for one ticket become one line: the human report lists only the main PR; the brief lists every one with a `role` — `main` carries the code, `bookkeeping` (registry rows, docs-only chores) folds into the ticket's line and is not its own line. A merged PR with no ticket key still counts: its title becomes the row, flagged in chat.

4. **Read each ticket and verify.** Through the tracker's MCP/CLI, read-only: summary, state, every comment, parent, links, transition dates — never transition or comment. Write the line from what the ticket asked and what the PR actually changed, never copied from commit subjects. Where ticket and PR disagree (partial coverage, ticket still open, item dropped as unnecessary), say what really landed and flag the mismatch in chat; a merged PR counts even if the ticket is not done. Claims stay modest: "merged to the base branch" — never "live" or "deployed" unless actually checked. For the brief also gather, read-only: per PR the files, commits, reviews, and checks (`gh pr view <N> --json number,title,body,url,headRefName,mergedAt,additions,deletions,files,commits,reviews,statusCheckRollup`); which files are tests, bookkeeping, or product code; the diff (`gh pr diff`) when the body leaves a non-obvious choice unexplained — describe only what was read; decisions and recorded rejected alternatives; verification actually shown, keeping shown separate from claimed.

5. **Write the lines.** One line per ticket, ≤25 words, plain language about what changed for the app's user — no file names, function names, or PR jargon. Start with the outcome, never "Worked on"; vary openings naturally. Order by ticket id. Good: "You can now search for a work order by its full number with the prefix — before, only the digits worked." Bad: "Implemented prefix-aware matching in the search predicate."

6. **Write the agent brief.** Valid JSON, built by script (`python3` + `json.dump`, never typed by hand), parsed before saving; UTF-8, 2-space indent, keys in this order, every key stays present (`None` or `[]` when empty); tickets ordered by id in one flat list (`merged_day` carries the grouping, no day nesting); facts only — every statement traces to a ticket, PR, diff, or command output read; unknown → `Unknown` / `Not verified`, never a plausible fill.

   ```json
   {
     "report": "daily-agent-brief",
     "window": { "from": "YYYY-MM-DD", "to": "YYYY-MM-DD", "timezone": "<local zone>, days judged in local time" },
     "generated_local": "YYYY-MM-DD HH:MM",
     "repo": "<owner/repo>",
     "base_branch": "<base>",
     "scope": "PRs by the current user merged to <base> in the window",
     "counts": { "tickets": 0, "prs_merged": 0 },
     "left_out": [ "<PR or item excluded, and why>" ],
     "context": "What these tickets have in common, plus what is verified about deployment (only 'merged to <base>' unless actually checked).",
     "conventions": { "Not verified": "...", "Unknown": "...", "pr_roles": "main = carries the code; bookkeeping = registry rows or docs-only chores" },
     "tickets": [
       {
         "key": "<TICKET-ID>",
         "title": "<ticket title>",
         "merged_day": "YYYY-MM-DD",
         "ticket": { "url": "...", "state": "done-state or current", "epic": null, "assignee": "<name or Unassigned>" },
         "prs": [
           { "number": 0, "url": "...", "branch": "...", "merged_local": "YYYY-MM-DD HH:MM", "additions": 0, "deletions": 0, "role": "main", "note": "what it replaces or supersedes, optional" }
         ],
         "problem": "What was wrong or missing.",
         "change": "What the merged code does now (behavior first, then mechanism).",
         "files": { "product_code": [ "path" ], "tests": [ "path (what changed)" ], "status_and_evidence": [ "path" ] },
         "decisions": "Choices made and why, including deliberate divergences and rejected alternatives.",
         "verified": "What was actually shown (tests run, measurements, screenshots); claimed-but-not-shown is Not verified.",
         "bookkeeping": "Registry or status rows added or moved, by id, or None.",
         "pending_follow_ups": "What is still owed, known gaps, things noticed and left alone.",
         "gotchas": "What a next agent touching this area must know (shared components, ordering, flags).",
         "mismatches": "Where the ticket and the merged PR disagree, or None."
       }
     ],
     "cross_cutting": [ "Pattern shared by several tickets, PR ordering or conflicts, superseded PRs closed unmerged, open questions for the next agent." ]
   }
   ```

7. **Deliver.** In chat: one bullet per ticket — `- <KEY>: <line> (#<PR>)` — with a `Oct 13:` day header above each day's bullets for a range, oldest day first, skipping days with nothing merged. Save the brief as a file — the documented default is `~/.claude/daily-briefs/daily-brief-<YYYY-MM-DD>.json` (`<start>_to_<end>` for a range; create the folder if missing; overwrite only when redoing the same day) — that path is the handoff an agent can read directly. End with one short note: the window used, ticket count, the brief file path, mismatches, PRs left out and why, anything `Not verified`. Nothing merged → say so plainly; never invent lines or write an empty brief. Open or in-progress tickets are excluded from both reports unless asked — then an "In progress" heading / `in_progress` array, with the PR state stated exactly (open, draft, none).

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — ticket tracker, ticket-id format, and the branch model whose base branch defines both "merged" and the PR query's `--base`, (3) `.skills/daily-summary.local.md` — per-skill overrides (richer day pages, artifact publishing from an HTML template, alternate brief paths live here).
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Tracker differences (step 4 ticket reads, read-only): youtrack — issue + comments + links. linear — issue with relations + comments. jira — issue with `issuelinks` + comments. github — issue + timeline. file-based — the ticket file's sections.
- The `gh` commands are the documented default against a git forge through the `gh` CLI; other providers map their merged-PR evidence onto step 2. `~/.claude/...` is the documented default brief path; hosts under a different agent directory remap it here.
