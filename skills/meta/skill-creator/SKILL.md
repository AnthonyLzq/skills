---
name: skill-creator
description: "Trigger: create a skill, new skill, write a SKILL.md, document a repeated pattern. Creates LLM-first skills with valid frontmatter from this repo's template."
---

# Skill Creator

Create a new skill as a runtime instruction contract for an LLM — not human documentation. Create one when a pattern recurs and the guidance changes what the agent does; do not create one when the pattern is trivial, a one-off, or better served by ordinary documentation.

## Execution Steps

1. **Confirm the pattern earns a skill.** It must be repeatable, and it must change behavior versus the model's defaults — otherwise say so and stop. Check the skill does not already exist: the `skill-registry` output (`.skills/registry.md`) or a scan of `skills/<category>/<name>/`. Done when reuse and non-existence are both confirmed.

2. **Start from the template.** Copy this repo's `templates/skill-template.md` into `skills/<category>/<name>/SKILL.md` — `engineering` for ticket-to-shipped work, `meta` for skills managing skills; ask when the fit is unclear. Supporting material goes in the skill folder's `assets/` (templates, schemas, fixtures) or `references/` (local docs), never inline in the body.

3. **Write the frontmatter.** Exactly `name` and `description`: the description is one physical YAML line, quoted, triggers first, ≤180 chars — `"Trigger: {what users type}. {What it does}."` No other keys; host agents that demand more are a host fact documented in `## Adaptation`.

4. **Write the body as the runtime contract.** A title, one imperative purpose paragraph, then numbered `## Execution Steps` — every step an action ending on a checkable completion criterion ("Done when…"). Branching goes in compact tables, not prose. Total ≤110 lines. Nothing host-specific in the body: no tracker names, no repo commands, no host paths — all of it moves to `## Adaptation`.

5. **Close with `## Adaptation`.** The read order: (1) host `AGENTS.md` conventions, (2) `.skills/config.md`, (3) `.skills/<name>.local.md` overrides; plus the one line that overrides refine steps and never change core behavior. Per-skill facts (tracker differences, documented fallbacks, extension points) live here, not in the body.

6. **Lint what you wrote.** The description is single-line and trigger-first; every step ends on a condition the agent can check; every meaning sits in one place — the environment (`--help`, manifests, config files) is consulted, not restated; prohibitions are reframed as the positive behavior where possible. The writing craft — context pointers, progressive disclosure, leading words, pruning — is the `writing-for-agents` skill; apply it before declaring done. Done when the file parses as YAML and the body budget holds.

7. **Refresh the index and register.** Rebuild `.skills/registry.md` through the `skill-registry` skill. A host-level skill is also named where the host documents its skills (the host `AGENTS.md` conventions). Done when the index reflects the new skill path exactly.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md`, (3) `.skills/skill-creator.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Host agents that require extra frontmatter (license, version, invocation flags, comment conventions) document that here: the canonical repo standard is `name` + `description` only, and additions are per-host, never folded into `templates/skill-template.md`.
