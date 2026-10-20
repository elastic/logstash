# Observability Agentic Workflow — Schedule (daily)

Runs the shared scheduled Observability Agentic Workflow with the `daily` profile.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-schedule-daily.yml`](../trigger-obs-aw-schedule-daily.yml) |
| Trigger | Schedule and manual dispatch |

## Purpose

Invokes the shared scheduled handler for the daily profile. The source comment notes that schedule lanes are kept in separate caller workflows because the reusable workflow does not receive which cron expression fired.

## When it runs

Runs on a schedule or through `workflow_dispatch`. See the [workflow definition](../trigger-obs-aw-schedule-daily.yml) for current scheduler configuration; exact timing is intentionally not reproduced here.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-schedule-daily` | Every scheduled or manual run | None declared | Calls the shared schedule workflow with `schedule-profile: daily`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Caller defaults to `contents: read`; job grants `actions: read`, `contents: write`, `copilot-requests: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |
| Outputs | No caller outputs or artifacts are declared; reusable workflow internals are unavailable here. |

## Operational notes

The reusable workflow is external and was not inspected; its daily-profile job routing cannot be confirmed from this checkout.

## Sources

- Workflow: [`trigger-obs-aw-schedule-daily.yml`](../trigger-obs-aw-schedule-daily.yml)
- Reusable workflow reference: [`elastic/oblt-aw/.github/workflows/obs-aw-event-schedule.yml@v0`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-schedule.yml)
