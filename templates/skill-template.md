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

- Read the host repo's `AGENTS.md` first and apply its conventions — ticket tracker, branch model, commands — to the steps above.
- If `.skills/{skill-name}.local.md` exists in the host repo, apply it as host-specific overrides. Overrides refine the steps; they never change this skill's core behavior or completion criteria.
