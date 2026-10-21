# Backport to active branches

Automatically backports a merged pull request when a matching active-branch backport label is applied.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`backport-active.yml`](../backport-active.yml) |
| Trigger | `pull_request_target` on `main`, when a pull request is closed or labeled |

## Purpose

Routes opted-in merged changes to active release branches through the shared Elastic backport action. The workflow comment defines the merged-and-labeled requirement.

## When it runs

It receives close and label events for pull requests targeting `main`. The job runs only when the pull request is merged and either a close event already has a label containing `backport-active-`, or a newly applied label starts with that string. Merely closing an unmerged pull request does not qualify.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `backport` | Job condition above | None declared | Calls `elastic/oblt-actions/github/backport-active@v1` on `ubuntu-latest`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow grants `contents: read` and `pull-requests: write`. |
| Outputs | No workflow outputs or artifacts are declared. |

## Operational notes

The implementation of the referenced action is maintained outside this repository and was not inspected; the workflow provides no action inputs.

## Sources

- Workflow: [`backport-active.yml`](../backport-active.yml)
