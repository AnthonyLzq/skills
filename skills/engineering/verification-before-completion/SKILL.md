---
name: verification-before-completion
description: "Trigger: about to claim work is complete, fixed, or passing, before committing or opening a PR. Requires running verification commands and reading output before any success claim."
---

# Verification Before Completion

Claiming work is complete without verification is dishonesty, not efficiency. Core principle: evidence before claims, always. Violating the letter of this rule is violating the spirit of it.

## The Iron Law

```text
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If the verification command has not run in this exchange, the claim cannot be made.

## Execution Steps

Run this gate function BEFORE claiming any status or expressing satisfaction:

1. **Identify**: which command proves this exact claim? The test command for "tests pass", the build command for "build succeeds", the original failing symptom for "bug fixed", the requirement checklist for "requirements met". Done when the command is named.
2. **Run**: execute the FULL command now — fresh and complete, not a remembered or partial check.
3. **Read**: the full output, the exit code, the failure count. Skimming is not reading.
4. **Decide**: does this output confirm the claim? NO → state the actual status with the evidence ("failing on X: <output line>"); never "should pass". YES → state the claim together with its evidence: `[command] → 34/34 passed — all tests pass`.
5. **Only then** make the claim. Skipping any step turns the statement into a lie, not a verification.

Apply this to every variation of success: completion statements (any wording, synonym, or paraphrase), satisfaction expressions ("Done!", "Fixed!"), committing or pushing, PR creation, task completion, moving to the next task, and success reports received from delegated agents.

## Common Failures

| Claim | Requires | Not sufficient |
| --- | --- | --- |
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Original symptom re-run: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows its changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags — STOP

- Any wording implying success without having run verification: "should", "probably", "seems to", "nearly done".
- Satisfaction before evidence ("Great!", "Perfect!").
- About to commit, push, or open a PR without verification.
- Trusting a delegated agent's report — verify the VCS diff and re-run independently.
- Relying on partial verification, or thinking "just this once".

## Key Patterns

```text
Tests:        [run test command] → see 34/34 pass → "All tests pass"
              vs "Should pass now" / "Looks correct"
Regression:   write → run (pass) → revert the fix → run (MUST fail) → restore → run (pass)
Build:        [run build] → exit 0 → "Build passes"; a passing linter proves nothing about compilation
Requirements: re-read the plan → checklist each item → verify each → report gaps or completion
Delegation:   agent reports success → check the VCS diff → verify the changes → report actual state
```

## Why This Matters

An unverified claim tells the human partner something false ("I don't believe you" — trust broken), ships undefined behavior that a test would have caught, and converts honest rework into dishonest rework. Confidence is not evidence, exhaustion is not an excuse, and different words do not exempt the same claim.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/verification-before-completion.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- The proving commands come from the config validation commands; the gate (identify → run → read → decide → claim) itself is never replaced.
