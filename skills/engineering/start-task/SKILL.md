---
name: start-task
description: "Trigger: start or resume work on a ticket, \"next task\", \"start task\", \"vayamos con\", or a given ticket id. Prepares workspace, gates and claims it, drives dev to a PR."
---

# Start Task

Begin or resume work on the ticket the user names: prepare the workspace, gate and claim the ticket in the repo's tracker configured in `.skills/config.md`, plan it through the `plan` skill, then develop to a standard PR. Act through the tracker's MCP/CLI; unavailable → report it and stop. Ticket ids follow the config ticket-id format.

## Decision Gates

| Ticket state | Action |
| --- | --- |
| Startable (per config triage-source) | Gate passes → claim, then plan |
| In-progress, assignee = current user | Resume case → confirm with the user, skip claim |
| In-progress, assignee = someone else | Ask to take over or stop — never reassign silently |
| Terminal (done/fixed/verified/won't-fix/cancelled) | Report and stop |
| Missing acceptance criteria | Surface back to discussion; do not plan |

## Execution Steps

1. **Prepare the workspace — protected-path auto-stash (non-negotiable).** `git status --short`. Split uncommitted changes into two groups: local-workflow changes — the protected paths (agent/config dirs: `.claude/`, `.opencode/`, `.agents/`, `tasks/`, `.skills/`; the host `AGENTS.md`; agent config files; the list may be extended by overrides) — and everything else. `.gitignore` counts as protected ONLY when its complete staged and unstaged diffs contain nothing but ignore entries for those protected paths; any other change makes it an ordinary change. Protected changes: never discard, never offer to discard, never ask about them — if any exist (tracked or untracked), silently `git stash push -u -m "<name>: auto-stash local-workflow paths" -- <the changed protected paths>` (build the pathspec from what is actually changed; the command fails on a pathspec matching nothing). Everything else still dirty: ask the user — stage / stash / discard — and never discard without their explicit answer. Done when everything outside the protected paths is clean or resolved.

2. **Sync the base branch — skip-if-already-in-sync.** Read-only first: current branch + distance from the base branch (`git rev-list --left-right --count <base>...HEAD`). Already on base AND the count is 0/0 (nothing behind or ahead) → the workspace is in sync: skip the stash/checkout/pull/pop dance entirely (the stash exists only to survive the pull) and go to step 3. Otherwise `git checkout <base> && git pull --rebase`, then `git stash pop` when a stash was created. Pop conflicts → stop and hand to the user to resolve — never auto-resolve, never discard. The base branch comes from config. Feature branches are never checked out or created by these steps.

3. **Fetch everything from the tracker**: ticket fields (summary, description, state, custom fields, links) plus every comment; note cross-references to PRs or sibling tickets mentioned in the text. Informs both the branch suggestion and the planning phase.

4. **Gate and claim per the Decision Gates** — re-read the live state before deciding, never assume it moved. Claim = assign to the current user + set the in-progress state, run automatically once the gate passes; never reassign a ticket already owned by someone else without their explicit OK. A failed tracker write is reported in one line and does not block local work. After a successful claim, if `tasks/<TICKET-ID>/audit.md` exists, refresh it: set `ticket_updated_at` to the `updatedAt` the claim returned and add `refreshed_at: <now> (claim: status + assignee)` — the claim changes no audited content, so a fresh audit carries into planning instead of re-running. The resume case is already claimed; skip.

5. **Branch.** Suggest a name from the repo branch-naming config: work-type prefix + ticket id lowercase + short kebab description, from `--from` when the task builds on an unmerged branch. Create it ONLY with the user's explicit OK in this conversation; never run checkout or switch for feature branches unprompted.

6. **Plan — delegated, never re-implemented.** Invoke the `plan` skill for this ticket, passing `--context` files through. `plan` audits the ticket (or proves the existing audit fresh) on its own; the status gate here is status-only and does not replace that audit. Continue ONLY when `plan` produced an existing `plan.md`; if it stopped on a blocking question, a wrong-framing finding, or an audit verdict, relay that to the user and wait — never code without a `plan.md`.

7. **Develop.** Execute `plan.md` step by step, ticking each checkbox `[x]` as it completes. Run the validation commands from `.skills/config.md`, filtered to the namespaces the change touches when repo config allows it. Consult the host `AGENTS.md` and docs whenever unsure about conventions; never assume — read the code first.

8. **Wrap up.** Mark all remaining `plan.md` checkboxes complete. Suggest a oneliner commit `type(<TICKET-ID>): short description` — no multi-line body, no AI attribution — and WAIT for explicit confirmation before committing or pushing. After the first commit, offer the repo's pre-PR self-review skill; once its findings are addressed, offer the repo's PR-creation skill. After the PR opens, comment the ticket with the PR URL; after merge (user-confirmed), set the ticket to its done/fixed state.

## Important rules

- **`tasks/` is local-only** — never staged, never committed; the other protected paths may be committed only when the task scope calls for it and the user confirms.
- **Never commit or push without confirmation**; oneliner commits only. Never take destructive actions (closing a PR, deleting/renaming a branch, force push) without explicit consult.
- **Never reassign silently**; ask before taking over someone else's ticket.
- **Repo artifacts (commits, PR bodies, ticket comments) in English; chat replies in the user's language.**

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/start-task.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Tracker differences (fetch + claim, steps 3-4): youtrack — issue + comments fetch; claim sets State and Assignee. linear — issue fetch; claim via save-issue with assignee "me" + in-progress state. jira — issue + comments fetch; claim via transition/assign API. github — issue fetch; claim = assign + in-progress label. file-based — record claim state (assigned-to, in-progress) in the ticket file itself.
