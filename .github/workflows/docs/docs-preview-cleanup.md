# docs-preview-cleanup

Delegates cleanup of documentation previews when a pull request closes.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`docs-preview-cleanup.yml`](../docs-preview-cleanup.yml) |
| Trigger | Pull request closed (`pull_request_target`) |

## Purpose

Calls the shared documentation preview cleanup workflow for closed pull requests.

## When it runs

On `pull_request_target` events of type `closed`; no branch filter is configured.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `cleanup` | Every matching close event | None declared | Calls `elastic/docs-actions/.github/workflows/docs-preview-cleanup.yml@v1`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | `contents: none`, `deployments: write`, and `id-token: write`. |
| Outputs | Caller declares no outputs, artifacts, or caches. |

## Operational notes

The called workflow is external and was not inspected. Its cleanup behavior and target environment are not exposed by this caller.

## Sources

- Workflow: [`docs-preview-cleanup.yml`](../docs-preview-cleanup.yml)
- Reusable workflow reference: [`elastic/docs-actions/.github/workflows/docs-preview-cleanup.yml@v1`](https://github.com/elastic/docs-actions/blob/v1/.github/workflows/docs-preview-cleanup.yml)
