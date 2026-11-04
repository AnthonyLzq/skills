---
name: systematic-debugging
description: "Trigger: any bug, test failure, unexpected behavior, build or integration failure, before proposing fixes. Hunts the root cause evidence-first before writing any fix."
---

# Systematic Debugging

Random fixes waste time and create new bugs; quick patches mask underlying issues. Core principle: ALWAYS find the root cause before attempting fixes. Symptom fixes are failure. Violating the letter of this process is violating the spirit of debugging.

## The Iron Law

```text
NO FIXES WITHOUT ROOT-CAUSE INVESTIGATION FIRST
```

Phases 1-3 are not complete → no fix may be proposed. No exceptions for emergencies: under pressure, systematic is faster than thrashing (measured: 15-30 min systematic vs 2-3 h guess-and-check; first-time fix rate 95% vs 40%).

## Execution Steps

1. **Phase 1 — Root-cause investigation** (before ANY fix):
   1. Read the whole error: full stack trace, line numbers, file paths, error codes. Errors often contain the exact solution.
   2. Reproduce consistently: exact steps, every time or note what varies. Not reproducible → gather more data, do not guess.
   3. Check recent changes: the diff, recent commits, new dependencies, config or environment changes.
   4. Multi-component system (CI → build → signing, API → service → database)? Instrument each component boundary — log what enters and what exits — run once, and let the evidence name the failing layer before investigating that component.
   5. Error deep in a call stack? Trace the bad value backward: where does it originate, who passed it along. Fix at the source, not at the symptom.
   Done when you can state WHAT is broken and WHY, with evidence.

2. **Phase 2 — Pattern analysis.** Find similar working code in the same codebase. If implementing a pattern, read the reference implementation COMPLETELY — every line, not skimmed — before applying it. List every difference between working and broken, however small; never assume a difference can't matter. Name the dependencies, settings, and assumptions the broken path makes. Done when the differences are enumerated.

3. **Phase 3 — Single hypothesis, tested minimally.** State it explicitly: "X is the root cause because Y". Test it with the SMALLEST possible change, one variable at a time — never fix multiple things at once. Verified → Phase 4. Not verified → form a new hypothesis; never stack more fixes on top. When you don't know, say so and research; don't pretend to know.

4. **Phase 4 — Implement the fix at the root cause**:
   1. Write the failing test first: the simplest reproduction, automated if possible, a one-off script when no framework fits (TDD's red-green cycle).
   2. Implement ONE fix addressing the root cause — no "while I'm here" improvements, no bundled refactoring.
   3. Verify: the test passes now, no other tests broke, the symptom is actually resolved — close it out through the `verification-before-completion` skill.
   Done when the red-green cycle is verified.

5. **Count failed fixes, and stop at three.** A fix that didn't work → STOP and count the attempts. Fewer than 3 → return to Phase 1 with the new information. 3 or more → question the architecture: each fix revealing new shared state or coupling in a different place, or fixes demanding "massive refactoring", is a wrong architecture, not three failed hypotheses. STOP and discuss with your human partner before attempting fix #4 — never attempt it without that conversation.

Truly environmental, timing-dependent, or external cases: the process is complete — document what was investigated, add appropriate handling (retry, timeout, error message), and add monitoring. Expect this to be the answer of ~5% of investigations only; "no root cause" usually means incomplete Phase 1.

## Red Flags — STOP and return to Phase 1

- "Quick fix for now, investigate later" · "Just try changing X and see if it works"
- Adding multiple changes before running anything · skipping the test ("I'll manually verify")
- "It's probably X, let me fix that" · "I don't fully understand but this might work"
- Proposing solutions before tracing data flow · a "one more fix attempt" when 2+ already failed
- Each fix revealing a new problem in a different place

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "Issue is simple, skip the process" | Simple issues have root causes too; the process is fast for simple bugs |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing |
| "I'll write the test after confirming the fix" | The untested fix doesn't stick; the red test is what proves it |
| "Multiple fixes at once save time" | You cannot isolate what worked, and it causes new bugs |
| "The reference is too long, I'll adapt the pattern" | Partial understanding guarantees bugs — read it completely |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding the root cause |

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/systematic-debugging.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- The four phases, the evidence-first rule, and the 3-fix architecture stop are core behavior and are never overridden; overrides only add host instrumentation recipes (log points, tracing tools) and the sibling skills the host installs for TDD and verification.
