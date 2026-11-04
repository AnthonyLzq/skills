---
name: create-standard-pr
description: "Trigger: \"create PR\", \"open a pull request\", \"PR from this branch\". Opens the PR with the repo's base-branch rules, title convention, and body structure."
---

# Create Standard PR

Open a pull request from the current branch with the repo's expected base branch, title convention, and body structure. The base branch and its precedence rules come from `.skills/config.md`'s branch model; the body fills the host's PR template, falling back to the documented default shape below. Open the PR through the `gh` CLI or the host's PR tooling, then report the URL and the chosen base branch.

## Execution Steps

1. **Inspect the current branch and worktree.** `git branch --show-current` and `git status --short`; dirty tree → ask the user how to land the leftovers before opening. Skim `git --no-pager log --oneline origin/<base>..HEAD` for the summary material. Done: branch name, tree state, and summary in hand.

2. **Resolve the base branch, stopping at the first answer:**
   - The user explicitly named a base in this conversation.
   - The config branch model — the branch normal work lands on, the branch reserved for hotfix branches and for promotions of the base branch into production, and the mandatory sync-back PR from the production branch into the base branch.
   State the chosen base to the user. Never open a PR that fails the repo's branch guard.

3. **Build the title from the branch prefix**, keeping the config-format ticket id when the branch carries one. Derive the concise summary from the user request, the ticket, or the recent commits:

   | Branch prefix | Title |
   | --- | --- |
   | `feature/` | `feat(<ticket-id>): concise summary` |
   | `fix/`, `bugfix/` | `fix(<ticket-id>): concise summary` |
   | `docs/` | `docs(<ticket-id>): concise summary` |
   | `chore/` | `chore(<ticket-id>): concise summary` |
   | `refactor/` | `refactor(<ticket-id>): concise summary` |
   | `test/` | `test(<ticket-id>): concise summary` |
   | hotfix branch | `fix(<ticket-id>): concise summary`, unless the user asks for a release-oriented title |
   | base branch → production | `Release: promote <base> to <production>` |
   | production → base (sync-back) | `Sync <production> back into <base>` |

4. **Draft the body, stopping at the first template found:** the host's PR template (path documented in Adaptation) → the documented default here, filled with concrete content:
   - `## Summary` — 2–4 bullets with the main change.
   - `## Testing` — the commands actually run, or an explicit note when none were.
   - `## Context` — the ticket id, the chosen base branch, and any rollout or follow-up note.
   Add extra sections only when the change genuinely needs them.

5. **Open the PR and report.** `gh pr create --base <base> --title "<title>" --body-file <file>`, or the host's equivalent. `--draft` only when the user asks for it or the branch is intentionally not ready for review. Done when the PR URL and the chosen base branch are both reported.

## Important rules

- Never open a PR that violates the repo's branch guard — the config's precedence rules decide, not the current branch's convenience.
- The title's type maps from the branch prefix; the ticket id stays in the title when present.
- Body concise and repository-style; an empty `## Testing` is wrong — state what ran or that nothing did.
- Non-default lanes (a different base, draft, release title) only on the user's explicit say-so.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions (PR template path, title conventions, reviewer rules), (2) `.skills/config.md` — the branch model: `base-branch`, production branch, hotfix and sync-back precedence, ticket-id format, (3) `.skills/create-standard-pr.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Documented branch-model fallback (GitFlow): normal work → the `develop` branch; `master` reserved for `hotfix/*` branches and promotions; the sync-back PR runs `master` → `develop`.
- The documented default body (Summary/Testing/Context) yields to the host's PR template when one exists; the template's path is a host fact and lives here, not in the body.
- The commands are the documented default through the `gh` CLI; other providers map their PR tooling onto step 5 unchanged.
