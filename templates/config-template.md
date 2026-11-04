# Skills config

One canonical personalization config for the installed skills in this repo, materialized by the `setup-skills` skill. Skills read, in order: host `AGENTS.md` conventions → this file → `.skills/<skill>.local.md` per-skill overrides.

Fill every key; leave `## Notes` for anything else the skills should know.

## Tracker

<!-- youtrack | linear | jira | github | file-based -->
tracker:

## Ticket id format

<!-- e.g. EC-<number>, PLU-<number>, GH-<number>, TASK-<number> -->
ticket-id-format:

## Triage

<!-- Where "ready" work is recognized: tracker states or labels — list them. -->
triage-source:

<!-- How ready tickets are ordered from "pick next" to "last resort". -->
ready-order:

## Branch model

<!-- The branch work lands on before merge, e.g. develop, master. -->
base-branch:

<!-- Naming convention, e.g. feature/<ticket-id>-<short-description>. -->
branch-naming:

## Docs layout

<!-- Where ticket plans live. Default: tasks/<TICKET-ID>/analysis.md + plan.md -->
plans-path:

## Validation commands

<!-- Exact commands for this repo: validate / lint / test (kept repo-local). -->
validate:
lint:
test:

## Notes

<!-- Anything else the skills should know. -->
