---
name: work-unit-commits
description: "Trigger: implementation, commit splitting, chained PRs, tests or docs riding with code. Plans commits as reviewable work units, one deliverable behavior each."
---

# Work Unit Commits

Plan commits as reviewable work units before anything is staged: one commit = one deliverable behavior, fix, migration, or docs unit, with the verification that proves it inside the same commit. Load this when deciding what belongs in each commit or PR — splitting a feature into reviewable work, preparing commits before a PR, or turning an oversized change into chained PRs.

## Critical Rules

| Rule | Requirement |
| --- | --- |
| Commit by work unit | A commit represents a deliverable behavior, fix, migration, or docs unit. |
| Never commit by file type | `models`, then `services`, then `tests` is a weak split — no one of those commits works alone. |
| Keep tests with code | Tests belong in the same commit as the behavior they verify. |
| Keep docs with the change | Docs belong with the feature or workflow they explain. |
| Tell a story | A reviewer understands why each commit exists from its diff and message alone. |
| Every commit is PR-ready | Each commit should stand as a candidate chained PR when the change grows. |

## Execution Steps

1. **Inventory the whole change before staging anything.** `git status --short`, `git diff --stat`, `git diff --cached --stat`. Group the working tree into work units. Done when every file is assigned to exactly one unit.
2. **Order the units so the repo builds and tests green after each commit.** Dependencies go first; a commit consumed by a later one was not self-contained. Rework the grouping until each unit's rollback is reasonable without touching unrelated work.
3. **Stage and commit unit by unit.** The message states the outcome, not the file list; match the repo's convention read fresh from `git log --oneline -5`. One clear purpose per commit.
4. **Record evidence with each unit**: the focused test command and its exact result; the runtime check or scenario and its exact result (or explicit `N/A` with the reason no runtime boundary exists); and the rollback boundary — the exact files/behavior removable without unrelated work. Uncommitted units still carry this evidence; the boundary is stated independently of commit creation.
5. **Size gate.** As the authored changed lines (additions + deletions) approach the repo's PR budget — default 400 — stop growing one PR: promote whole commits or commit groups into chained PRs, smallest independent unit first, each with its verification included.
6. **Final story check.** Read the commit list from the first commit: it should narrate the feature. Any commit that only makes sense together with a later one is not done — re-split or re-order.

## Work Unit Checklist

- [ ] One clear purpose.
- [ ] The repo still makes sense applying only this commit.
- [ ] Tests or docs for this unit are included when relevant.
- [ ] Rollback is reasonable without reverting unrelated work.
- [ ] Focused test command and exact result recorded.
- [ ] Runtime check and exact result, or `N/A` with the reason.
- [ ] Rollback boundary names the exact files/behavior.
- [ ] The message explains the outcome, not the file list.

## Split Examples

| Weak split | Work-unit split |
| --- | --- |
| `add models` | behavior (+ its tests) in one commit |
| `add services` | wire the behavior into its flow in the next |
| `add tests` | tests included with each behavior commit |
| `update docs` | docs included with the user-facing change they explain |

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/work-unit-commits.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Host-specific values: the PR line budget, the commit message convention, and any delivery-strategy policy (e.g. a spec-driven slice plan that forecasts the change exceeds budget before implementation) come from overrides; the defaults here are 400 authored lines and conventional commits.
