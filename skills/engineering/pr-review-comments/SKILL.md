---
name: pr-review-comments
description: "Trigger: \"review comments\", \"address PR feedback\", \"check PR comments\", \"fix review comments\". Classifies and verifies each open PR comment, then fixes or replies."
---

# PR Review Comments

Work through the open review comments on a pull request in a structured flow: fetch every comment surface, classify blocking vs suggestions, verify every comment before complying with it or disputing it, then fix or draft replies — committing only after confirmation. Uses the `gh` CLI (the documented default) or the host's PR tooling.

## Execution Steps

1. **Identify the PR.** Argument, or resolve from the current branch (`gh pr view --json number,title,url`); none found → ask the user.

2. **Fetch all three comment surfaces — no skipping.** Each surface captures different feedback; skipping one means missing feedback the author must address. Resolve the repo identity first (`gh repo view --json nameWithOwner`).
   - **Inline review threads** (primary — comments plus resolution status in one call):

     ```bash
     gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$pr){reviewThreads(first:100){nodes{isResolved comments(first:50){nodes{databaseId body author{login} path line originalLine diffHunk}}}}}}}' -f owner=$OWNER -f repo=$REPO -F pr=$PR
     ```

   - **Review summaries** (`gh pr view $PR --json reviews`): keep non-empty bodies; always keep a CHANGES_REQUESTED review; an APPROVED review stays only when its body carries actionable feedback ("consider", "suggest", "nit:", concrete references) — classified Tier 2.
   - **General PR comments** (`gh api repos/$OWNER/$REPO/issues/$PR_NUMBER/comments --paginate`): conversation not attached to code lines.

   **Checkpoint:** all three fetched, or confirmed empty, before proceeding — a skipped surface means going back now.

3. **Filter.** Discard resolved threads; bot authors (login ending in `[bot]` or a known bot pattern); purely conversational bodies ("LGTM", "+1", "thanks").

4. **Classify into two tiers.**
   **Tier 1 — blocking:** bug or logic errors, security concerns, missing failure handling, convention violations, explicit request-changes reviews.
   **Tier 2 — suggestions:** style beyond what linters enforce, naming, minor refactors, questions implying no required change, nitpicks.

5. **Present the summary before fixing anything** — one numbered list per tier: `[file:line] @reviewer — "quote"`. Then ask: start with the blocking comments? adjust any priority?

6. **Work through the comments one at a time, blocking first.**
   - **Verify before complying — agreement is not verification.** Restate the comment as claim / mechanism / trigger / consequence against the code as it stands now. Then check its citation three ways: the thread's `line` has drifted from `originalLine` after later commits; the quoted hunk was already changed; an upstream guard the reviewer could not see blocks the mechanism. Any hit → the comment becomes a dispute case even though the user agreed — say so instead of implementing. This gate applies equally to bot comments, whose confident one-line suggestions are the easiest thing in the queue to apply unread — the same gate, not a faster lane.
   - **Agreed and verified → implement:** read the surrounding code first, fix, briefly explain, move to the next comment. Done per comment when the change is explained.
   - **Disputed → push back only on the user's OK**, with a reply that is friendly (assume good intent), objective (cites code, tests, or docs), and concise (one short paragraph). Present the draft, WAIT for confirmation, then post it as a reply using the comment's numeric `databaseId`, not the node id.
   - **Before any push-back, check temporal claims:** the PR may make a time-bound claim ("currently", "as of", "pre-X", "post-X", "not yet") stale the moment it merges. Grep the touched docs and comments over the pinned range — `git diff "$(git merge-base origin/<base> HEAD)...HEAD" -- '*.md'` against the freshly fetched base, never a bare base name (merge commits sweep other people's docs into an unpinned range). A reply defending a soon-false claim is worse than none: update the claim instead of defending it.

7. **Checkpoint between blocks.** Blocking done → ask: continue to the suggestions, cherry-pick, or skip? Skipping is a valid, judgment-free choice.

8. **Commit after confirmation.** Suggest `fix(<ticket-id>): address review feedback` — the id from the branch name per the config ticket-id format; no id → omit the scope. Then `git add <specific files> && git commit && git push`, only after the user confirms the message.

## Important rules

- **Present the full summary first** — never fix without the user seeing the whole picture.
- **Ask before posting replies, before committing, before pushing; never force-push.**
- **Never dismiss a review** — only the reviewer dismisses their own review.
- **One comment at a time** so progress is trackable; read the code before changing it.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions (push-back tone, review-request conventions after pushing), (2) `.skills/config.md` — ticket-id format for the commit message, base branch for the temporal-claims range, (3) `.skills/pr-review-comments.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- The three-surface fetch maps to GitHub's PR comment architecture through the `gh` CLI (GraphQL review threads, review objects, issue comments); other providers map their comment sources onto steps 2–3 unchanged.
- After pushing fixes, re-request the reviewers per repo convention — the host's finish-PR flow owns that tail.
