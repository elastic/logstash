# Observability Agentic Workflow — Pull Request

Forwards selected pull request events to the shared Observability Agentic Workflow handler.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-pull-request.yml`](../trigger-obs-aw-pull-request.yml) |
| Trigger | Pull request opened, synchronized, reopened, or labeled |

## Purpose

Routes pull request activity to the shared Observability Agentic Workflow event handler.

## When it runs

On `pull_request` events of type `opened`, `synchronize`, `reopened`, or `labeled`; no branch or path filter is configured.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-pull-request` | Every matching pull request event | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-pull-request.yml@v0`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Caller defaults to `contents: read`; job grants `actions: read`, `contents: write`, `copilot-requests: write`, `discussions: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |
| Outputs | No caller outputs or artifacts are declared; reusable workflow internals are unavailable here. |

## Operational notes

The called reusable workflow is external and was not inspected. This caller supplies no additional inputs or secrets.

## Sources

- Workflow: [`trigger-obs-aw-pull-request.yml`](../trigger-obs-aw-pull-request.yml)
- Reusable workflow reference: [`elastic/oblt-aw/.github/workflows/obs-aw-event-pull-request.yml@v0`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-pull-request.yml)
