# Observability Agentic Workflow — Schedule (frequent)

Runs the shared scheduled Observability Agentic Workflow with the `frequent` profile.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-schedule-frequent.yml`](../trigger-obs-aw-schedule-frequent.yml) |
| Trigger | Schedule and manual dispatch |

## Purpose

Provides a separate high-cadence schedule lane for the frequent profile. The workflow comment explains that the shared schedule implementation has both daily- and frequent-specific routes and that the caller needs separate profiles.

## When it runs

Runs on a schedule or through `workflow_dispatch`. See the [workflow definition](../trigger-obs-aw-schedule-frequent.yml) for current scheduler configuration; exact timing is intentionally not reproduced here.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-schedule-frequent` | Every scheduled or manual run | None declared | Calls the shared schedule workflow with `schedule-profile: frequent`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Caller defaults to `contents: read`; job grants the union of `actions: read`, `contents: write`, `copilot-requests: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |
| Outputs | No caller outputs or artifacts are declared; reusable workflow internals are unavailable here. |

## Operational notes

The source comment states that GitHub evaluates caller permissions against all declared jobs in the shared workflow, including routes skipped by profile conditions. The external reusable workflow was not inspected.

## Sources

- Workflow: [`trigger-obs-aw-schedule-frequent.yml`](../trigger-obs-aw-schedule-frequent.yml)
- Reusable workflow reference: [`elastic/oblt-aw/.github/workflows/obs-aw-event-schedule.yml@v0`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-schedule.yml)
