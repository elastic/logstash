# Observability Agentic Workflow — Issue Comment

Forwards created issue comments to the shared Observability Agentic Workflow event handler.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-issue-comment.yml`](../trigger-obs-aw-issue-comment.yml) |
| Trigger | Issue comment created |

## Purpose

Routes issue-comment events into the reusable Observability Agentic Workflow implementation.

## When it runs

On `issue_comment` events of type `created`, without additional filters in the caller.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-issue-comment` | Every created issue comment | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-issue-comment.yml@v0`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Caller defaults to `contents: read`; the job grants `actions: read`, `contents: write`, `copilot-requests: write`, `discussions: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |
| Outputs | No caller outputs or artifacts are declared; reusable workflow internals are unavailable here. |

## Operational notes

The reusable workflow is external and was not inspected. The caller does not pass explicit inputs or secrets.

## Sources

- Workflow: [`trigger-obs-aw-issue-comment.yml`](../trigger-obs-aw-issue-comment.yml)
- Reusable workflow reference: [`elastic/oblt-aw/.github/workflows/obs-aw-event-issue-comment.yml@v0`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-issue-comment.yml)
