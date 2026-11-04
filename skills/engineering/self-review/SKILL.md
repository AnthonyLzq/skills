---
name: self-review
description: "Trigger: \"self review\", \"review my changes\", \"check my work\", \"pre-review\", \"before PR\". Reviews the branch against its ticket spec and repo standards before a PR opens."
---

# Self-Review

Review the current branch against its base branch so problems are caught locally, before the repo's PR-creation skill runs. Entirely local: the review lands in chat, never on the host or tracker. The review pipeline always runs to completion — every lens wave, finding verification, consumer sweep, triggered suites, checks, and the full report — before the skill stops for anything; the user's gate sits only between the completed report and the fix cycle (step 9).

## Inputs

- Base branch, from the config branch model, resolved strictly as the freshly fetched remote ref `origin/<base>` — never a local twin of the base and never `origin/HEAD` (a symbolic ref that goes stale silently). Ticket id follows the config ticket-id format, parsed from the branch name when present.

## Execution Steps

1. **Pin the base once, from the remote.** Run strictly in order — the fetch completes before `BASE` is computed:

   ```bash
   git branch --show-current
   git fetch origin <base> --quiet
   BASE=$(git merge-base origin/<base> HEAD)
   git log $BASE..HEAD --oneline
   git diff $BASE...HEAD --stat
   git status --short
   ```

   Every later command uses `$BASE`, never a bare base-branch name. A stale local ref reports other people's merged work as this branch's; `origin/HEAD` drifts silently. Sanity check: a diff counting far more files than the branch plausibly touched means the base was not pinned — re-derive it, never review the inflated diff. Uncommitted changes → warn exactly once: the review excludes worktree content. Commits ahead but an empty `$BASE...HEAD` diff → the branch's work is already upstream (squash-merged back): report and stop.

2. **Read the full diff** (`git diff $BASE...HEAD`): every changed file and the change's shape. This is the input for the checklist triggers and the consumer sweep.

3. **Resolve the spec axis first, the standards axis second.**
   **Spec** (what the branch was asked to do), in order, stop at the first hit: the ticket's plan documents: `tasks/<TICKET-ID>/plan.md` steps plus `analysis.md` follow-up candidates, from the config docs layout; the ticket's acceptance criteria fetched live from the tracker; the user, in one question. Never infer ACs from the diff — a spec reverse-engineered from the code it judges passes by construction. No spec → record "no spec available" and review on the standards axis alone. Follow-up candidates mark work deliberately ruled out of scope; branch behavior beyond them and beyond the ACs is scope creep.
   **Standards** (what the repo says): host `AGENTS.md`, plus the nearest `AGENTS.md` for each changed directory, plus the PR-creation skill's title and base-branch rules when repo skills changed.

4. **Route the diff through diff-shape checklists when the repo provides them.** The trigger → checklist mapping is host material (see `## Adaptation`); each triggered checklist's per-site questions join the review-pass prompts in step 5. No mapping matches → record "no checklist triggered: <shapes seen>" in the report.

5. **Run bounded review passes** — one delegated sub-agent per lens, waves of at most 3 concurrent, only for what the diff touches:

   - **Correctness** — bugs, error handling, dropped failures, wrong conditionals; every claim cites `file:line` at HEAD.
   - **Conventions** — standards-axis compliance.
   - **Tests** — does the existing suite cover the change; gap criticality 1-10.
   - **Spec draft** — AC table skeleton below, evidence only, no grading.

   Every prompt carries the exact lens question, the file list, the standards-axis sources, and the no-delegation clause: review directly, invoke no skills, spawn nothing. Uncited lens output is discarded at synthesis, not weakened to a suggestion.

6. **Verify every finding before scoring** — yours and every lens': restate (claim / mechanism / trigger / consequence) → reachability (path where it executes) → pre-existing (`git log -S<symbol> $BASE -- <file>`, or read the base version; pre-existing rot is bounded by the scope rule below) → upstream guard (a type or another layer blocks the trigger) → evidence (red test, run log, verified citation). Verdict sets the score; the score sets the tier:

   | Verdict | Score | Lands as |
   | --- | --- | --- |
   | CONFIRMED, executed (failing test or run log) | 100 | Critical / Important |
   | CONFIRMED, traced (citation chain) | 75 | Critical / Important |
   | UNRESOLVED (a gate unanswered) | 25 | Open questions, gate named |
   | REFUTED (died at a gate) | 0 | dropped |

   Report only CONFIRMED findings as issues. An agent's re-report is input, not evidence — re-derive the artifact yourself or mark it UNRESOLVED.
   - **Adversarial pass** — findings about code this session wrote are refuted only by a separate delegated sub-agent holding the claim, the artifact, its contract, and the adversarial frame ("refuting means naming the guard that blocks the trigger"), with this session's reasoning stripped.
   - **Variant sweep** — for each CONFIRMED mechanism shared across files, anchor an exact search on the original site, generalize one element at a time, and triage every match: fix in this branch / follow-up ticket with the pasted search / refuted. Three or more variants, or a silently-regressible class → propose a guard (a script, lint rule, or test), not prose.
   - **Ceiling** — three verify-and-fix cycles maximum on one branch, counted from the first approved verdict that schedules fixes; beyond that, the remainder goes to a follow-up ticket.

7. **Run the checks the diff can reach.**
   **Consumer sweep, always:** search the repo for every export symbol the diff changed, tests included; run every consumer file found plus the co-located tests of changed files. A test consuming a changed symbol outside the diff is exactly what nothing else forces you to look at.
   **Standards commands, always:** the lint and typecheck commands from `.skills/config.md`.
   **Triggered suites, only on a named trigger:** a shared type/contract/wire-format change, a schema or migration, a helper with reach ≥ 10 non-test files, a red or suspiciously empty consumer sweep, consumers not cheaply enumerable → run the config's full validation command (or the suite covering the trigger) and record pass/fail. An untriggered, recorded skip is a decision; silence is not.
   Never report green evidence collected mid-batch; rerun a red suite in isolation before blaming the diff (passes alone → contamination or timeout, report both timings). A suite that cannot run locally is reported NOT RUN with the reason, never skipped silently.

8. **Present the review** in this shape: header `# Self-Review: <branch> → <base>` with `N commits, M files (+A, -D)`; **Spec compliance** — AC table (AC / evidence `file:line` / satisfied / partial / not addressed), always emitted ("no spec available" when none resolved); **Critical** and **Important Issues** — numbered, `file:line`, why it matters, `Fix:` concrete change; **Test Coverage Gaps** with criticality 1-10; **Open questions** naming the unanswered gate; **Verification and sweep** — `N confirmed, M refuted, K unresolved`, one line per triggered checklist; **Build checks** — `<command>: PASS / FAIL / NOT RUN (reason)`; **Tests** — sweep + triggered suites; **Suggestions** — brief, non-blocking; **Lower-Confidence Observations** — confidence + the artifact that would settle it; **Verdict** — one line Spec, one line Standards, then Ready for PR / Needs fixes first. Two axes, always separate: a clean standards line never clears a `not addressed` AC. Scope creep is listed under Spec, never under Suggestions. Short form when nothing found: header, spec table, "No issues found. Reviewed for correctness, conventions, test coverage.", verdict lines.

9. **Stop for the user's verdict.** Present the complete report, ask "fix any of these before the PR?", then apply NOTHING until answered — this ask is the gate between report and fix cycle, not a formality. Valid, combinable verdicts: **code fixes** (critical-first, re-run the touched checks, then suggest the oneliner commit — commits happen only on explicit confirmation); **delivery decisions** (split into stacked PRs over budget, reorder slices, change the PR lane); **approve as-is** (hand off to the repo's PR-creation skill); **open questions / UNRESOLVED** → follow-up tickets or scheduled fixes. Fix-scheduling verdicts start a fix cycle; the step-6 ceiling counts from the first one.

## Important rules

- **Pin the base from the remote once**; never review an inflated diff.
- **Spec from the plan documents and ticket, never from the diff** — two axes, two verdict lines, never averaged.
- **Verify before score**: only CONFIRMED findings are issues; UNRESOLVED goes to Open questions; only REFUTED disappears.
- **Never apply fixes in the cycle that produced the findings** — the completed report and an explicit verdict exist first.
- **Own-work findings go to the adversarial pass** with this session's reasoning stripped; consumer sweep always, triggered suites named or recorded.
- **Scope:** what the branch changed, plus adjacent rot in files it already touches when the branch relies on it; rot elsewhere is a follow-up ticket.
- **Local-only** — commit nothing, post nothing; every issue carries a `Fix:` line; linter/typecheck ground routes to Build checks.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions (root plus nearest per-directory, the standards axis), (2) `.skills/config.md` — base branch, ticket id format, docs layout, validation commands, (3) `.skills/self-review.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Host specifics: the step-4 trigger → checklist table is defined here as a pointer to checklist files the host repo materializes; the tracker fetch in step 3 (ACs) goes through the tracker's MCP/CLI; the repo's PR-creation skill replaces the hand-off whenever the host provides one.
