---
name: rank-ready-tickets
description: "Trigger: triage ready tickets, \"ranquea los tickets\", \"what should I pick up next\", \"orden de los tickets\". Lists the pickable tickets ordered fastest-to-ship, flagging blockers."
---

# Rank Ready Tickets

Produce one ordered list of the pickable tickets in the repo's ticket tracker configured in `.skills/config.md`, sorted from simplest + least impact (fastest to ship) to most complex + highest impact (slowest, biggest blast radius). Read-only triage aid: never write to the tracker, never start work — claiming is the `start-task` skill's job. Act through the tracker's MCP/CLI only; unavailable → report it and stop.

## Execution Steps

1. **Pull the pickable tickets.** Read `.skills/config.md` (tracker, ticket id format, triage states) and query the tracker for tickets in the requested states: the triage state by default, or the explicit state filter the user gave (allow comma-separated states when both are startable). Paginate while more pages remain, so nothing past the first page is silently missed. Done when every matching ticket is captured with id, title, priority and state fields, assignee, and last update.

2. **Filter by ownership.** Resolve the current user in the tracker. Drop every ticket assigned to another teammate; keep unassigned tickets and the current user's own — still theirs to schedule. If zero tickets survive, briefly list which pickable tickets were skipped because of ownership so the user can sanity-check, and stop — never render an empty ranking.

3. **Detect blockers.** For each survivor, query the tracker's "blocked by" links. Blocked = a blocker still in a non-terminal state; terminal means done/fixed/verified/won't-fix/obsolete/duplicate/cancelled in the tracker's own workflow. Record blocker id, title, and state. Do NOT drop blocked tickets — they rank, but sink to the bottom and are never offered as the next step.

4. **Score and rank.** Build rough complexity and impact scores from ticket metadata plus summary/description. Never ask the user — make a defensible call and cite it in the report. Signals — complexity: surface area (single file vs cross-cutting infra), new abstractions vs edits inside an existing structure, regression risk, dependencies (a hub ticket gating follow-ups, or a blocker that is itself pickable); impact: priority field, blast radius if wrong (silent-wrong-result and data risks outrank cosmetic UX), hub scope. Sort complexity asc then impact asc; when close, prefer the simpler ticket. Break exact ties so the more urgent one goes LATER — urgency raises impact, it does not make the work simpler. A blocked ticket ranks below every unblocked ticket, ordered among themselves by the same rule, and appears below its own blocker. Done when each ticket has scores and a final position.

5. **Render the report.** Header: `## Ranking of <state> tickets (as of <date>)`, naming the actual state filter used. One row per ticket — `# | Ticket | Short title | Prio | Why ranked here` — ticket id bold, priority in the tracker's naming (`—` as missing-value placeholder only), the why in one short sentence citing the deciding signal (scope, dependency, blast radius, blocker). Blocked rows: prefix the title with 🔒 and name the blocker, e.g. "Blocked by ABC-12 (In Progress); not startable until it resolves." A blocked row never sits above an unblocked one. After the table, a Notes section (3 bullets max) for what the table cannot show: blocking relations, dependency chains or hub tickets, data gaps (complexity is inferred from descriptions — the tracker carries no estimates). Done when the table matches the step-4 ordering and every blocker is visible.

6. **Offer the next step in one line** on the top unblocked ticket via the `start-task` skill. Never offer a blocked ticket — if the topmost is blocked, offer the highest unblocked one instead. If EVERY pickable ticket is blocked, offer nothing: point at the blockers that must clear first, suggesting the blocker itself when it is something the user could pick up.

Output the report in the requester's language.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/rank-ready-tickets.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Tracker differences: youtrack — search `project: <project> State: <filter>`; blockers via a type-filtered "blocked by" search; paginate with limit/offset. linear — issues by status label; blockers via issue relations (`blockedBy`). jira — JQL `project = P AND status IN (...)`; blockers via `issuelinks`. github — issues filtered by label; blockers via linked issues. file-based — the ticket source defined in config; blockers are explicit "blocked by" entries there; the current user is whoever `start-task` claims as.
