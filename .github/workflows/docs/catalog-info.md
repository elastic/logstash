# catalog-info

Validates changes to the repository's Backstage catalog descriptor.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`catalog-info.yml`](../catalog-info.yml) |
| Trigger | Pull requests targeting `main` that change `catalog-info.yaml` |

## Purpose

Runs the shared Elastic catalog validation action when the catalog descriptor is changed. No more specific rationale is stated in the workflow.

## When it runs

On pull requests targeting `main` with a path change to `catalog-info.yaml`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `validate` | Matching pull request | None declared | Runs on `ubuntu-latest`, checks out the repository, and invokes `elastic/oblt-actions/elastic/validate-catalog@v1`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow and job grant `contents: read`; job additionally grants `packages: read`. |
| Outputs | No workflow outputs, artifacts, or caches are declared. |

## Operational notes

The shared validation action is external to this repository; its implementation was not inspected.

## Sources

- Workflow: [`catalog-info.yml`](../catalog-info.yml)
