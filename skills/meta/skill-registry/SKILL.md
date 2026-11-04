---
name: skill-registry
description: "Trigger: skill registry, index skills, update skills index, after skill changes, \"what skills are available\". Rebuilds the registry of skills by trigger and path."
---

# Skill Registry

Index the available skills by trigger and path — the one place agents and delegators look before searching blindly. Run it after installing, removing, creating, moving, or renaming skills, whenever a delegator needs a fresh index, or on "what skills are available". A registry is an index, not a summary: `SKILL.md` files stay the source of truth, and delegation passes exact skill paths to subagents — never generated digests, which preserve nothing of author intent.

## Execution Steps

1. **Locate the registry and the skill sources.** The registry lives at `.skills/registry.md` in the host repo by default; a different path comes from `.skills/skill-registry.local.md` overrides. Skill sources, scan in this order: the host's project-level skills directory, the host agent's global skills directory, and the canonical skills repo's `skills/<category>/<name>/` tree when reachable. Done when both the registry path and the sources are known.
2. **Scan, dedupe, read frontmatter.** Scan `*/SKILL.md` under each source; skip the registry file itself, non-skill helpers (the skills repo's `templates/`, `assets/`, `references/` trees), and files without a usable `name` field. Deduplicate by skill name — project-level beats global, then scan order wins. For each survivor read frontmatter only: `name` and the `description` trigger text, verbatim.
3. **Render the registry.** `.skills/registry.md` carries a small header (generated timestamp, sources scanned, counts) and one row per skill: name, trigger/description verbatim, scope (project/global/source repo), and the exact `SKILL.md` path. Zero skills found → still write an empty registry, so agents stop searching. Done when the file exists and one row matches every surviving skill exactly.
4. **Cache discipline.** A registry newer than every change among its sources is reused, not rebuilt. The default registry file is a generated cache: gitignore it unless the host explicitly wants it committed.
5. **Report and hand over.** Return the registry path, skill count, whether it was reused or regenerated, and any skipped, duplicate, or broken-frontmatter files. When work is being delegated, select the matching rows and hand the subagent those exact `SKILL.md` paths.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` (any registry-location or scan-scope decisions belong here too), (3) `.skills/skill-registry.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
- Host skill directories are enumerated here as host facts; the documented default scan covers the project-level and global skills dirs the host's installer targets, plus the canonical skills repo tree when reachable.
