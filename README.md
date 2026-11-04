# AnthonyLzq Skills

Agent-agnostic AI skills: one canonical `SKILL.md` per skill, installable into Claude Code, OpenCode, and Copilot, personalized per host repo.

## Why agnostic

Skills here are written tracker- and host-free: the body never names a ticket tracker, a branch model, or repo-specific commands. Instead, every skill ends with an **Adaptation** section that tells the agent how to personalize itself at run time — by reading the host repo's conventions (ticket tracker, branch model, commands, `AGENTS.md` rules) and an optional `.skills/<name>.local.md` override file. One canonical source per skill; every host repo gets the same core behavior adapted to its own conventions.

## Install

```bash
./install.sh --agent claude                          # project scope of the cwd
./install.sh --agent opencode --project .            # project scope, explicit repo
./install.sh --skills audit-branch,plan --project .  # only these skills
```

Flags: `--agent <auto|opencode|claude|copilot>` (default `auto` — every agent whose target dir can be created), `--global`, `--project [dir]` (default scope: project, cwd), `--skills all|<name,…>`, `--copy`, `--unlink`, `--force`. Details: `./install.sh --help`.

| Agent      | Global                      | Project scope      |
| ---------- | --------------------------- | ------------------ |
| Claude Code | `~/.claude/skills`         | `.claude/skills`   |
| OpenCode   | `~/.config/opencode/skills` | `.opencode/skills` |
| Copilot    | — (project only)            | `.github/skills`   |

Skills are symlinked into the target dir (copied with `--copy`), one entry per `skills/<name>` folder.

## Skill catalog

Skill folders land in later commits; this scaffold ships the installer and the template.

| Skill | Phase | What it does |
| ----- | ----- | ------------ |
| rank-ready-tickets | preload | Ranks the pickable tickets so the next task can be chosen |
| audit-ticket | preload | Verifies a ticket's claims against the current code before planning or coding |
| start-task | start | Claims a ticket, prepares the workspace, and kicks off the flow |
| plan | plan | Produces the analysis and implementation plan without coding |
| work-unit-commits | implement | Splits the work into reviewable commit units |
| verification-before-completion | implement | Proves completion with checks before claiming done |
| systematic-debugging | implement | Hunts the root cause evidence-first before writing any fix |
| self-review | implement | Reviews local changes against the ticket spec before opening a PR |
| audit-artifact | implement | Falsifies every factual claim of a document before it is shared |
| create-standard-pr | ship | Opens a PR following the repo's base-branch rules and body structure |
| ci-failures | ship | Triages and fixes CI failures on the open PR |
| pr-review-comments | ship | Addresses reviewer comments and re-requests review |
| finish-pr | ship | Drives the PR to a clean merge state |
| pending-reviews | ship | Lists the PRs waiting for the user's review |
| create-ticket | close | Drafts and files an approved follow-up ticket |
| daily-summary | close | Summarizes the day's merged work for standup and agent handoff |
| skill-registry | meta | Indexes the available skills by trigger and path |
| skill-creator | meta | Creates LLM-first skills with valid frontmatter |
| skill-improver | meta | Audits and upgrades existing skills |
| writing-for-agents | meta | Reference for writing documents that agents consume |

## Personalization

The personalization contract: every `SKILL.md` ends with `## Adaptation`, which instructs the agent to

- read the host repo's `AGENTS.md` and apply its conventions — ticket tracker, branch model, commands — to the skill's steps;
- apply `.skills/<name>.local.md` (when present in the host repo) as host-specific overrides. Overrides refine the steps; they never change the skill's core behavior.

## Contributing

- One folder per skill: `skills/<name>/SKILL.md`, plus optional extra files (`assets/`, `references/`).
- Start from [`templates/skill-template.md`](templates/skill-template.md).
- Required YAML frontmatter: `name` and `description` (triggers first, one physical line).
- LLM-first writing: imperative steps with checkable completion criteria, concise, no host-specific values in the body — host details belong in `## Adaptation`.

## License

MIT — see [`LICENSE`](LICENSE).
