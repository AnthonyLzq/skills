---
name: finish-pr
description: "Trigger: \"finish PR\", \"address comments then merge when green\", \"push and mark ready\". Drives your own PR from open feedback to the merge handoff, in one ordered pass."
---

# Finish PR

Drive your OWN pull request to a merge-ready state in one ordered pass: resolve it, address every review thread through the `pr-review-comments` skill, clear red CI through the `ci-failures` skill, resolve conflicts and staleness, run the local gates, then push, mark ready, and hand off the merge per the repo's merge policy. The order is the contract: comments → CI → conflicts → gates → push → ready → merge.

## Execution Steps

1. **Resolve the PR.** Argument, or from the current branch:

   ```bash
   gh pr view --json number,author,headRefName,reviewDecision,mergeStateStatus
   ```

   Confirm the `author` is the current user; someone else's PR routes to the reviewer flow instead — stop. Done: the PR and its merge state are on the table.

2. **Address review comments — required sub-skill: `pr-review-comments`.** Every thread from every reviewer: a verified fix or an evidence-cited reply. Done when no blocking thread is left unhandled.

3. **Fix red CI — required sub-skill: `ci-failures`.** Diagnose, then fix locally. A blind re-run without a diagnosis is never an option.

4. **Clear conflicts and staleness BEFORE pushing or marking ready.** From the PR view: a conflicting merge state → resolve the conflicts now; behind the base branch → merge the fresh remote base into the branch, then re-run step 5 (merging the base onto an older branch can trip the repo's own gates). Done when the merge state is clean and current.

5. **Run the local gates BEFORE pushing — this is why PRs land red.** The validate/lint/test commands from `.skills/config.md`, plus every local/CI divergence the host documents (see Adaptation). All green → push. Red → fix first; a sanctioned commit-hook override for one special commit (e.g. a merge commit the hook chokes on) makes step 5 mandatory, never optional.

6. **Mark ready and re-request review.** Only after steps 2–4: mark the PR ready (draft → ready) and re-request the reviewers per repo convention. **Never mark ready while the merge state is conflicting.** Done when the branch is ready and its reviewers are re-pinged.

7. **Merge handoff per the repo's merge policy** (`.skills/config.md`; documented fallback: squash-merge):
   - Auto-merge where the host enables it — set it and stop.
   - Otherwise wait for green in the foreground (watch the checks), then merge on the policy; background waiting follows the host's wait tooling — never a `sleep N && check` loop.
   - Never merge red, or with unresolved blocking threads.
   - **After the user confirms the merge:** remove the worktree BEFORE deleting the branch — deletion fails while a worktree holds it — and report the merged state back to the PR's tracker ticket per the config tracker.
   - Done when the merge state shows merged and the tracker ticket carries the PR's final status.

## Important rules

- **Own PRs only** — anyone else's PR routes to the reviewer flow.
- **Validate before push** — commit hooks having run locally is not CI; the divergences live in Adaptation.
- **Never mark ready with conflicts; never merge red or with open blocking threads.**
- **Never force-push**; merge happens only on explicit user confirmation.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions — the "before pushing" checks, worktree bootstrap, review-request conventions, merge tooling, (2) `.skills/config.md` — merge policy (documented fallback: squash-merge), validation commands, tracker and base branch for the post-merge report, (3) `.skills/finish-pr.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Worktrees: the host's conventions decide whether this runs in a dedicated worktree or the current checkout; this skill assumes neither.
- Local/CI divergences (checks commit hooks skip locally but CI enforces — docs lint, repo-wide budget files the base branch may have moved, multi-package typechecks) are documented here by the host and re-run in step 5.
- The commands are the documented default through the `gh` CLI. Hosts with auto-merge disabled or a merge-babysitting flow write that here — step 7 owns the handoff.
