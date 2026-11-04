---
name: pending-reviews
description: "Trigger: \"pending reviews\", \"review queue\", \"PRs to review\", \"what do I need to review\". Lists open PRs awaiting the user's review, flagging pushes since it."
---

# Pending Reviews

Build the queue of open PRs that need the current user's review: never reviewed by them, or reviewed but the author has pushed commits since. Excludes their own PRs, drafts, PRs already approved by any reviewer, and any PR they approved themselves — even if the author pushed after. Read-only: this skill never posts, approves, or mutates anything. Uses the `gh` CLI (the documented default) or the host's PR tooling.

## Execution Steps

1. **Resolve identity and open PRs.**

   ```bash
   gh api user --jq .login
   gh pr list --state open --limit 100 --json number,title,author,headRefOid,headRefName,isDraft,baseRefName,reviewDecision,updatedAt,url
   ```

   Exactly 100 rows returned → raise `--limit` and re-run (truncation). Resolve `owner/repo` explicitly, not from the cwd's remote — the shell's cwd can drift.
   Drop, in this order, into the excluded list of step 4: **own PRs** (`author.login` = the user) → **drafts** (`isDraft`) → **PRs with `reviewDecision == APPROVED`** (approved by someone). That global drop is the one sanctioned use of `reviewDecision` here: empty (e.g. the base requires no reviews) is NOT approved — keep the PR; its per-user blind spots stay downstream. Keep `headRefOid` (step 3) and `headRefName` (stacked-PR mapping, step 5) — kept for dropped drafts too, since a non-draft PR can stack on a draft parent.

2. **Fetch the user's latest review per PR.** `reviewDecision` is global (any reviewer) — it cannot answer "did *I* review this". Use the per-PR reviews endpoint:

   ```bash
   for pr in <numbers>; do
     gh api repos/$OWNER/$REPO/pulls/$pr/reviews --paginate | jq -rn \
       '[inputs[] | select(.user.login=="'$LOGIN'" and .state!="PENDING")] | sort_by(.submitted_at) | last
        | if . == null then "NONE" else "\(.state) \(.commit_id)" end'
   done
   ```

   Pitfalls encoded: pipe into `jq -n '[inputs[] | ...]'`, not `--jq` — with `--paginate` a built-in `--jq` runs per page, so `sort_by | last` becomes page-local, not global · filter `state != "PENDING"` — unsubmitted reviews have null `submitted_at` and corrupt the sort · take the latest by `submitted_at` — an APPROVED superseded by a later CHANGES_REQUESTED must not count as approved · only submitted reviews count as "reviewed"; issue comments do not.

3. **Classify.** "New commits since my review" = the latest review's `commit_id != headRefOid` (also catches force-pushes):

   | My latest review | commit vs head | Verdict |
   | --- | --- | --- |
   | none | — | **include** — never reviewed |
   | COMMENTED / CHANGES_REQUESTED | == head | exclude — reviewed at current head |
   | COMMENTED / CHANGES_REQUESTED | != head | **include** — new commits since my review |
   | APPROVED | == head | exclude — approved, up to date |
   | APPROVED | != head | exclude — approved; later pushes don't re-queue it (note both short SHAs in the excluded list) |

   An APPROVED counts only as the *latest* review — step 2 already guarantees that.

4. **Render the queue.** One table, `PR | Author | Title | Base | Status | Reason`: the PR number rendered as a link to the PR (never a bare number), Status = the user's latest review state on it, Reason = never reviewed / new commits since my review (short SHAs when reviewed before). Labels in the user's language; PR titles verbatim. Then list the **excluded** PRs compactly — one line each with its drop reason — so the result stays auditable.

5. **Flag stacked PRs.** A base that is another feature branch rather than the config base branch → match that base against the other PRs' `headRefName` (dropped drafts included) to name the parent PR; parent in the queue → suggest reviewing it first; parent a draft → note the child is blocked on an unreviewable parent.

## Common mistakes

- Using `reviewDecision` (beyond the step-1 global drop) or a search-by-reviewer query for per-user state — both miss "I commented but the author pushed since" and mis-attribute.
- Timestamps as the primary signal — merges and rebases skew dates; `commit_id` vs `headRefOid` is exact (timestamps stay an optional secondary check).
- Counting a COMMENTED review as "not reviewed" — any submitted non-PENDING state counts as reviewed.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the base branch used to tell stacked PRs from ordinary ones, (3) `.skills/pending-reviews.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- The commands are the documented default against GitHub through the `gh` CLI; other providers map their per-user review attribution onto steps 2–3.
