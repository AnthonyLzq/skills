---
name: audit-artifact
description: "Trigger: \"audit this artifact/page\", \"revisá los claims\", \"check the doc before I send it\". Falsifies every factual claim of a document against its sources before it is shared."
---

# Audit Artifact

Check the factual claims of a document you wrote before anyone reads it as truth. Read-only on every source: no code edits, no tracker writes, no republish. The output is a verdict, a per-claim table, and the corrected wording, which the user applies (or asks for) after reading.

Why this exists: measured on one audited page, every claim copied verbatim from the source held, while **14 of 30 claims written for the reader were false**, two of them decision-changing. Prose written from memory about a system you just worked on feels like the safest part of a document and is the most dangerous, because (1) you recall the shape of the mechanism, not the mechanism; (2) simplifying for a reader drops qualifiers, and a dropped qualifier reads as a claim; (3) **the reader was chosen precisely because they cannot check** — a false claim in code is caught by a test; a false claim in a document gets acted on.

## Inputs

- **Target** (required): the reader-facing URL, a file path, or "the page we just made".
- **Audience**: optional but worth asking for — it sets the severity bar: Critical (changes a decision the reader must make), High (teaches a wrong mechanism), Medium (an off number, count, or quote), Low (imprecise but self-correcting on contact with the system). A claim about the reader's own past decisions is always Critical — it is the one class they cannot sanity-check.

## Execution Steps

1. **Audit what is PUBLISHED, not your draft.** Fetch the page the reader will open (browser or fetch tool), or read the file; the local draft and the live version drift. Extract the rendered text to a scratch file so every lens reads the same content.

2. **Enumerate every claim, and classify by KIND.** Number them; a claim is any sentence a reader could act on: an assertion about the system, a quoted string, a count, a causal explanation, a statement about who decided what. Kinds fail differently and need different lenses:

   | Kind | What it asserts | How it fails |
   | --- | --- | --- |
   | **Quoted** | "the message says X" | truncated, or altered mid-sentence |
   | **Numeric** | "seven fixtures" | counted a different population than the one named |
   | **Process** | "the team approved this" | never happened, or happened differently |
   | **Causal** | "X because Y" | the real mechanism differs, or the reason is invented |

   Causal is the highest-yield kind and the most waved through — it reads as explanation, not assertion. **Route by SOURCE as well as by kind:** a quote living in the tracker, a PR, or a chat log never goes to a repo-only lens (it returns `unverifiable` and wastes the dispatch); split the quoted set by where each quote lives before sending sub-agents.

3. **Dispatch one adversarial lens per kind** (at most 3 concurrent; merge Quoted + Numeric into one lens on small documents). Every prompt carries: **the polarity stated explicitly** ("each claim asserts the document is accurate; falsifying one means it is wrong, and your artifact is the true value from the source") — without it the agent defends the document; the audience; read-only on the source, no skill invocation, no nested sub-agents; and the claims themselves, numbered — never a pointer to "the page". Per-kind riders: Quoted → compare character by character and classify identical, visible-elision (`…`) that keeps every word shown, or ALTERATION that drops words mid-sentence; Numeric → report every plausible population count, not just the matching one; Causal → a claim true by accident but for the wrong reason counts as false, and claims about pre-change behavior are verified by reconstructing that state and measuring it, not by reasoning from the code as it stands. When the document admits one of your own errors, add the self-flattery check: does the correction soften the framing (a personal note called a "decision", a skipped gate "deferred", hours ago "earlier")? Facts can be right while the framing quietly exculpates.

4. **Verify the criticals yourself.** Agent reports are input, not evidence. Re-derive every Critical, and any High you will publish, from a clean tree — if lenses ran mutation experiments, snapshot before and after each wave, and read verification sources only from the clean tree.

5. **Run the coherence pass — no lens does it, expect the best finding here.** Check claims against each other: a section defending against a risk another section says is impossible; the document's own examples contradicting its legend or framing; a property presented as the system's when it belongs to a test, a convention, or a person's habit; numbers that must compose ("three per rule", "seven rules") but don't; an ask ("approve these four") exceeding the evidence shown; one fact under two different vocabularies; one guarantee hedged in one section and asserted in another — on the same mechanism at least one of them is wrong.

6. **Verdict**:

   ```markdown
   ## Audit: <document name>
   Verdict: SEND | SEND AFTER EDITS | DO NOT SEND
   Claims examined: N · false: N · overstated: N · holds: N
   ### Critical            | # | Claim | Verdict | Evidence |
   ### High / Medium       | # | Claim | Verdict | Real value |
   ### Internal coherence  | # | Finding |
   ### Corrected wording
   1. <exact replacement text, ready to paste>
   ```

   Every row cites an artifact: a `file:line`, a ticket, a command and its output. A row without one is `unverifiable`, never promoted to `holds`. End with the PATTERN observed — which KIND of claim failed — because that is what the author carries into the next document.

7. **Record it** next to the work the document belongs to (the config docs layout, or beside the document): what was audited, the URL, the source revision, the verdict, the counts. A corrected causal explanation is a NEW unverified claim — measured across audit passes, fixed quotations stayed fixed while rewritten causal explanations failed at the same rate as the originals (6 of 8, then 6 of 10); re-audit corrected causal claims before the re-share.

## Important rules

- **Read-only everywhere** — correcting the document is a separate, authorized step.
- **A claim about the reader's own past decisions is Critical** — verify against the record, never against memory; this is the class that redirects a conversation.
- **A quotation is exact or visibly elided** — dropping words mid-sentence is an alteration and a defect, however small: a quoted string is a promise about a system's output.
- **Causal claims need a cited mechanism, not plausibility** — if the source is silent, the claim is `unverifiable` and gets softened, not shipped; an invented reason survives review because it sounds like understanding.
- **Numbers name their population** — "nine" is unfalsifiable until you say nine of what, in which file.
- **Verify criticals yourself, from a clean tree** — and run the coherence pass (step 5); it is where the framing errors live.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/audit-artifact.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Host specifics: which tool fetches published pages (artifact/browser/fetch), which sources count for Process claims (tracker/PR/chat access), and where the audit record lands come from overrides; the four-kind taxonomy, the coherence pass, and the verify-criticals rule are core and never replaced.
