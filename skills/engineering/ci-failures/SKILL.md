---
name: ci-failures
description: "Trigger: \"ci failed\", \"fix ci\", \"check ci\", \"why is CI red\", \"pipeline broken\". Triages a PR's failed CI checks from raw logs to a proposed fix, diagnosis first."
---

# CI Failures

Inspect the failed CI checks on a pull request, extract the failing-step logs, diagnose the root cause, and propose the fix. The diagnosis is presented and understood before anything is changed. Uses the `gh` CLI (the documented default) or the host's PR/CI tooling.

## Inputs

- **PR number, run URL, or job URL** — given as an argument, inferred from the current branch, or asked for. A run URL inspects every failed job of that run; a job URL inspects one job.

## Execution Steps

1. **Identify the target.** A run or job URL → extract the run id (`actions/runs/<run_id>`) and, for a job URL, the job id too (`/job/<job_id>`) from the URL. Otherwise resolve the PR from the current branch:

   ```bash
   gh pr view --json number,title,url,headRefName
   ```

   None found → ask the user. Done: the target is identified.

2. **Fetch the failed checks.**

   ```bash
   gh pr checks $PR_NUMBER --json name,state,link,workflow,startedAt,completedAt \
     --jq '.[] | select(.bucket == "fail")'
   ```

   A PR may carry checks from several workflow runs: group by workflow and take the most recent run per flow; an older failed run whose latest re-run passed is skipped. No failures → report all checks green and stop.

3. **Fetch the failed jobs.** The job id inside a check's URL is NOT the `databaseId` the API commands need — always use the `databaseId` from the JSON.

   ```bash
   gh run view $RUN_ID --json jobs \
     --jq '.jobs[] | select(.conclusion == "failure") | {name, databaseId, conclusion, steps: [.steps[] | select(.conclusion == "failure") | {name, number}]}'
   ```

4. **Extract the failure logs** — failed steps only, ANSI stripped:

   ```bash
   gh run view $RUN_ID --log-failed 2>&1 | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
   ```

   Output over ~500 lines → focus on: error markers (`FAIL`, `ERROR`, assertion names), stack-trace lines, test-summary lines and the last ~100 lines of each failed job.

5. **Present the diagnosis** — a structured summary, one block per failure:

   ```
   ## CI Failures for PR #<n>
   #### <job> — workflow: <workflow>
   - Failed step / Root cause / Key error (verbatim) / Likely fix
   ```

   Classify each failure: **test assertion** (expected vs received, test path) · **golden/snapshot mismatch** (expected file out of date — offer the host's regeneration flow) · **lint or type error** (`file:line` + message) · **build failure** (broken import or module) · **timeout** (loops, missing teardown, resource exhaustion) · **infrastructure** (runner, docker, dependency install) · **flaky** (passed on re-run or non-deterministic — suggest a re-run).

6. **Propose next steps per class:** read the failing test and decide code bug vs test update · regenerate or update the expected files only when the change is intended · lint/type fixes with the exact violations shown · build → the broken module · timeout → the suspected cause · infrastructure → re-run. Then ask the user: **fix these issues, or re-run the failing checks first?**

7. **Fix on approval:** read the relevant source and test files first, implement the fixes, briefly explain each change, then run the validation commands from `.skills/config.md` scoped to the failing area locally before anything is pushed. Done: fixes applied with each explained, and local verification green.

8. **Re-run on request only** (suspected flake, or the user's explicit choice): `gh run rerun $RUN_ID --failed` — failed jobs only, never the entire workflow.

## Important rules

- **Diagnosis first** — never start fixing before the user has seen what failed.
- **Strip the noise** — ANSI codes, timestamps, runner boilerplate; keep errors and stack traces.
- **Read code before fixing** — understand why it failed before changing anything.
- **Local verification before push** — the failing suite in isolation, per step 7.
- **Never push blind retries; never force-push.**
- **Respect the user's judgment** — re-running instead of fixing is a valid choice.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions (how CI results are checked, multi-run grouping), (2) `.skills/config.md` — the validation commands used for local verification, (3) `.skills/ci-failures.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- The commands are the documented default against GitHub Actions through the `gh` CLI; other CI providers map their checks/logs onto steps 2–4 unchanged.
- Known repo failure patterns (e.g. golden-file regeneration flows or a repo-local fix skill) are documented here as a pointer from the host — step 5 offers them when the classification matches.
