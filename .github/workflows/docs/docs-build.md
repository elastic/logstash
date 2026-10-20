# docs-build

Builds and Vale-lints documentation for pull requests, release-branch pushes, and merge queues.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`docs-build.yml`](../docs-build.yml) |
| Trigger | Pull request opened, synchronized, or reopened; push to `main` or a matching numeric release branch; merge group |

## Purpose

Delegates documentation builds to the shared Elastic Docs workflow, enabling Vale linting and release-branch handling.

## When it runs

On pull request `opened`, `synchronize`, or `reopened`; pushes to `main` or branches matching `[0-9]+.[0-9]+`; and `merge_group`. No path filter is defined.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `build` | Every matching event | None declared | Calls `elastic/docs-actions/.github/workflows/docs-build.yml@v1`, passing `enable-vale-linting: true` and `use-release-branches: true`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow grants `contents: read` and `pull-requests: read`. |
| Outputs | The caller declares no outputs, artifacts, or caches; reusable-workflow internals are not available here. |

## Operational notes

The called reusable workflow is maintained in `elastic/docs-actions` and was not inspected. Its runtime jobs, artifacts, and cache behavior cannot be established from this caller file.

## Sources

- Workflow: [`docs-build.yml`](../docs-build.yml)
- Reusable workflow reference: [`elastic/docs-actions/.github/workflows/docs-build.yml@v1`](https://github.com/elastic/docs-actions/blob/v1/.github/workflows/docs-build.yml)
