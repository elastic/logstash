# docs-deploy

Deploys documentation after a run of the `docs-build` workflow completes.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`docs-deploy.yml`](../docs-deploy.yml) |
| Trigger | Completion of the `docs-build` workflow |

## Purpose

Delegates documentation deployment to the shared Elastic Docs reusable workflow. The caller enables Vale linting and release-branch handling.

## When it runs

On `workflow_run` completion for a workflow named `docs-build`. The caller has no conclusion filter, so it does not restrict invocation to successful conclusions.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `deploy` | Every matching workflow completion | None declared | Calls `elastic/docs-actions/.github/workflows/docs-deploy.yml@v1` with `enable-vale-linting: true` and `use-release-branches: true`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow grants `contents: read`, `deployments: write`, `id-token: write`, `pull-requests: write`, and `actions: read`. |
| Outputs | Caller declares no outputs, artifacts, or caches; reusable-workflow internals are not available here. |

## Operational notes

The external reusable workflow was not inspected; its deployment environment, internal conditions, and artifact handoff are not visible in this repository's caller definition.

## Sources

- Workflow: [`docs-deploy.yml`](../docs-deploy.yml)
- Reusable workflow reference: [`elastic/docs-actions/.github/workflows/docs-deploy.yml@v1`](https://github.com/elastic/docs-actions/blob/v1/.github/workflows/docs-deploy.yml)
