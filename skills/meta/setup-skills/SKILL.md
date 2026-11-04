---
name: setup-skills
description: "Configure this repo for these skills: issue tracker, ticket id format, triage source, branch model, docs layout, validation commands. Run once per repo before using the other skills."
---

# setup-skills

Configure the host repo once so every installed skill personalizes itself without asking again. The answers become `.skills/config.md` — the one canonical config the skills read after the host `AGENTS.md` and before per-skill overrides.

## Execution Steps

1. Detect what the repo already answers, filling keys in this order: tracker, ticket id format, triage source, ready order, base branch, branch naming, docs layout, validation commands. Read the host `AGENTS.md`; check whether `.skills/config.md` exists — if it does, confirm every key is still accurate, update only what the user says changed, and exit; detect issue-tracker MCPs (YouTrack, Linear, Jira) and the `gh` CLI (`gh auth status`) for a GitHub tracker; read the repo manifests (scripts, config files) for validate/lint/test commands. Done when each key has an evidence-backed answer or is staged as a question for step 2.
2. Ask the user ONLY what detection could not answer — 5 questions max, one at a time: (1) ticket tracker + ticket id format; (2) triage source — states or labels, and how ready tickets rank; (3) docs layout for plans (default: `tasks/<TICKET-ID>/analysis.md` + `plan.md`); (4) base branch + branch naming; (5) validate/lint/test commands. Every key detection already answered is stated as a confirmed default, never re-asked.
3. Propose defaults for every key, get the user's confirmation, then write `.skills/config.md` from [`templates/config-template.md`](../../templates/config-template.md) in this skills repo, and print a 3-line "what's configured" summary — tracker + ticket id format, branch model, validation commands — followed by the install hint: run `./install.sh --project .` from this repo. Done when the file exists, matches what the user confirmed, and the summary and hint are printed.

## Adaptation

- Personalize in this read order, stopping at the first source that answers: (1) host `AGENTS.md` conventions, (2) `.skills/config.md` — the host repo's one canonical config (ticket tracker, ticket id format, triage source, branch model, docs layout, validation commands), (3) `.skills/setup-skills.local.md` — per-skill overrides.
- Overrides refine the steps; they never change this skill's core behavior or completion criteria.
