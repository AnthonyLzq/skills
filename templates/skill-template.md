---
name: {skill-name}
description: "Trigger: {essential trigger words}. {What this skill does}."
---

# {Skill title}

{One paragraph of purpose: the problem this skill solves and what the agent must do. Write imperatively — a runtime instruction contract, not background prose.}

## Execution Steps

1. {First action, ending on a checkable completion criterion.}
2. {Next action.}
3. {Final action: how the agent proves the result is done.}

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/{skill-name}.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
