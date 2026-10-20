# Observability Agentic Workflow — Issues

Forwards selected issue events and manual dispatches to the shared Observability Agentic Workflow handler.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-issues.yml`](../trigger-obs-aw-issues.yml) |
| Trigger | Issue opened, labeled, or edited; manual dispatch |

## Purpose

Routes issue lifecycle events into the shared Observability Agentic Workflow event handler.

## When it runs

On `issues` events of type `opened`, `labeled`, or `edited`, or on `workflow_dispatch`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-issues` | Every matching event | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-issues.yml@v0`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Caller defaults to `contents: read`; job grants `actions: read`, `contents: write`, `copilot-requests: write`, `discussions: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |
| Outputs | No caller outputs or artifacts are declared; reusable workflow internals are unavailable here. |

## Operational notes

The external reusable workflow's routing and outputs were not inspected. The caller does not define inputs or explicit secrets.

## Sources

- Workflow: [`trigger-obs-aw-issues.yml`](../trigger-obs-aw-issues.yml)
- Reusable workflow reference: [`elastic/oblt-aw/.github/workflows/obs-aw-event-issues.yml@v0`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-issues.yml)
