# AnthonyLzq Skills

Your personal engineering skills for riding agents across any repo: one canonical `SKILL.md` per skill, installable into Claude Code, OpenCode, and Copilot, personalized per repo by the `setup-skills` skill. Small and composable, built to be adapted — hack them, make them yours.

## Why agnostic

Every skill is written tracker- and host-free: no tracker names, no branch model, no repo commands in the body. Instead, each one ends with an **Adaptation** section that reads the host repo's conventions plus `.skills/config.md`. One canonical source per skill — any tracker, any host.

## How it works

1. `./install.sh` installs the skills into your agent (table below).
2. Run `/setup-skills` once per repo — it asks just what detection can't answer and materializes `.skills/config.md`, the one canonical config for that repo.
3. Every skill personalizes itself at run time by reading, in order: host `AGENTS.md` conventions → `.skills/config.md` → `.skills/<name>.local.md` per-skill overrides. Core behavior never changes.

```
skills/
├── engineering/<name>/SKILL.md   # tickets → code → shipped
└── meta/<name>/SKILL.md          # skills that manage skills
```

Engineering skill folders land in later commits; `skills/meta/setup-skills` exists today.

## Install

```bash
./install.sh --agent claude                          # project scope of the cwd
./install.sh --agent opencode --project .            # project scope, explicit repo
./install.sh --skills plan,setup-skills --project .  # only these skills
```

| Agent       | Global                      | Project scope      |
| ----------- | --------------------------- | ------------------ |
| Claude Code | `~/.claude/skills`          | `.claude/skills`   |
| OpenCode    | `~/.config/opencode/skills` | `.opencode/skills` |
| Copilot     | — (project only)            | `.github/skills`   |

The installer links (or copies, with `--copy`) each `skills/<category>/<name>` folder flat as `<name>` into the target dir. `--skills` accepts plain names or `category/name`; other flags: `--agent <auto|opencode|claude|copilot>`, `--global`, `--project [dir]`, `--copy`, `--unlink`, `--force` — full details in `./install.sh --help`.

## Skills

Split by category and by axis: **user-invoked** — you type them, they orchestrate the run; **model-invoked** — you or the agent reach for them mid-task, the reusable discipline.

### Engineering (16)

_Land in later commits — the catalog to come:_

User-invoked:

- **rank-ready-tickets**: Ranks the pickable tickets so the next task can be chosen
- **start-task**: Claims a ticket, prepares the workspace, and kicks off the flow
- **plan**: Produces the analysis and implementation plan without coding
- **self-review**: Reviews local changes against the ticket spec before opening a PR
- **ci-failures**: Triages and fixes CI failures on the open PR
- **pr-review-comments**: Addresses reviewer comments and re-requests review
- **finish-pr**: Drives the PR to a clean merge state
- **pending-reviews**: Lists the PRs waiting for the user's review
- **create-ticket**: Drafts and files an approved follow-up ticket
- **daily-summary**: Summarizes the day's merged work for standup and agent handoff

Model-invoked:

- **audit-ticket**: Verifies a ticket's claims against the current code before planning or coding
- **work-unit-commits**: Splits the work into reviewable commit units
- **verification-before-completion**: Proves completion with checks before claiming done
- **systematic-debugging**: Hunts the root cause evidence-first before writing any fix
- **audit-artifact**: Falsifies every factual claim of a document before it is shared
- **create-standard-pr**: Opens a PR following the repo's base-branch rules and body structure

### Meta (5)

The skills that manage the skills.

- **setup-skills** (user-invoked, once per repo): Configures the host repo — tracker, ticket id format, triage source, branch model, docs layout, validation commands → `.skills/config.md`
- **skill-registry** (model-invoked): Indexes the available skills by trigger and path
- **skill-creator** (user-invoked): Creates LLM-first skills with valid frontmatter
- **skill-improver** (user-invoked): Audits and upgrades existing skills
- **writing-for-agents** (model-invoked): Reference for writing documents that agents consume

## Personalization

- `.skills/config.md`, created by `setup-skills`, holds one canonical config per repo: ticket tracker (`youtrack|linear|jira|github|file-based`), ticket id format, triage/ranking source, branch model + base branch, docs layout for plans (default `tasks/<TICKET-ID>/analysis.md` + `plan.md`), validate/lint/test commands, and notes.
- Every skill reads its personalization in order: host `AGENTS.md` conventions → `.skills/config.md` → `.skills/<name>.local.md` per-skill overrides.
- Overrides refine the steps; they never change the skill's core behavior.

## Contributing

- One folder per skill under its category: `skills/<category>/<name>/SKILL.md`, plus optional extra files (`assets/`, `references/`).
- Start from [`templates/skill-template.md`](templates/skill-template.md); the config skeleton is [`templates/config-template.md`](templates/config-template.md).
- Required YAML frontmatter: `name` and `description` (triggers first, one physical line).
- LLM-first writing: imperative steps with checkable completion criteria, concise, no host-specific values in the body — host details belong in `## Adaptation`.

## License

MIT — see [`LICENSE`](LICENSE).
