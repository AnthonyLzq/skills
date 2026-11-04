---
name: skill-improver
description: "Trigger: improve skills, audit skills, refactor a skill, skill quality. Audits and upgrades existing SKILL.md files against the repo's LLM-first standard."
---

# Skill Improver

Audit existing skills against this repo's Contributing rules and LLM-first standard, then upgrade them only when asked. `skill-creator` handles new skills; this one makes old ones load faster and act more reliably. Default is audit-only: report findings and proposed changes — modify files only on an explicit "apply".

## Audit standard

- **Frontmatter**: exactly `name` and `description`; description one physical line, quoted, triggers first, ≤180 chars.
- **Body**: ≤110 lines; imperative numbered steps, each ending on a checkable completion criterion; branching in compact tables, not prose.
- **Agnosticism**: no tracker names, host commands, or host values in the body — all in `## Adaptation`.
- **Adaptation**: present, with the read order (host `AGENTS.md` → `.skills/config.md` → `.skills/<name>.local.md`) and the overrides-refine line.
- **Supporting material**: long explanation lives in `assets/`/`references/`, not the body; references point to local files, never external URLs as the source of truth.

## Execution Steps

1. **Select the skills in scope.** From the arguments, the `skill-registry` index (`.skills/registry.md`), or a scan for `*/SKILL.md` — default the current repo's tree, or the host agent's global skills dir when the request is about installed skills. State the resolved set before auditing. Done when scope is named.

2. **Audit each skill against the standard**, read fully first, plus intent preservation: flag rules that conflict with each other, activation semantics a rewrite could break, and anything that looks wrong but might be deliberate — those are review items, not findings. Done when every skill has a per-section pass or finding.

3. **Report, ordered by severity.** Per skill: what fails the standard, the exact proposed change, what can be applied mechanically, and what needs the human (ambiguous intent, invented content). A clean skill is reported clean; silence is not a verdict.

4. **Apply mode — only on an explicit ask.** Fix the safe findings: convert tutorial prose to runtime instructions, collapse prose branches into decision tables, move long explanation, examples, and schemas into `assets/`/`references/` — never delete meaning. Preserve author intent, activation triggers, and output requirements; preserve working frontmatter unless it fails the standard. Re-run the full audit after editing and report zero findings, or name the leftovers. When names, paths, or descriptions changed, refresh `.skills/registry.md` through the `skill-registry` skill.

## Never

- Delete meaningful content silently — relocate it; deletion is a human decision.
- Invent triggers, policies, or domain rules; ambiguity goes back to the human.
- Rewrite an activation contract without flagging exactly what would run differently afterwards.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions (extra required frontmatter, host style guides that add to checkout), (2) `.skills/config.md`, (3) `.skills/skill-improver.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Host agents with stricter frontmatter contracts (license, version, invocation flags) audit against those keys here, in addition to this repo's standard — additions never weaken it.
