# pre-commit

Runs the shared Elastic pre-commit checks for pull requests and pushes to selected branches.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`pre-commit.yml`](../pre-commit.yml) |
| Trigger | Pull requests; pushes to `main`, `8.19`, or `9.*` |

## Purpose

Applies the repository's shared pre-commit checks to proposed changes and selected branch updates.

## When it runs

On pull requests with no target branch or path restriction. Also runs on pushes to `main`, `8.19`, and branches matching `9.*`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `pre-commit` | Every matching event | None declared | Runs the shared `elastic/oblt-actions/pre-commit@v1` action on `ubuntu-latest`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | `contents: read`. |
| Outputs | No outputs, artifacts, or caches are declared by the caller. |

## Operational notes

The shared action is external and no action inputs are specified in the workflow.

## Sources

- Workflow: [`pre-commit.yml`](../pre-commit.yml)
