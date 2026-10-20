# mergify backport labels copier

Copies applicable labels when a Mergify-generated backport pull request is opened.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`mergify-labels-copier.yml`](../mergify-labels-copier.yml) |
| Trigger | Pull request opened |

## Purpose

Uses the shared labels-copier action for pull requests whose head branch follows the `mergify/bp/` prefix; labels matching the configured exclusion expression are excluded.

## When it runs

On pull request `opened`; the job runs only when `github.head_ref` starts with `mergify/bp/`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `mergify-backport-labels-copier` | Head branch condition is true | None declared | Runs on `ubuntu-latest`, calling `elastic/oblt-actions/mergify/labels-copier@v1` with `excluded-labels-regex: "^backport-*"`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow grants `contents: read`; the job grants `pull-requests: write` and `repository-projects: read`. |
| Outputs | No outputs, artifacts, or caches are declared. |

## Operational notes

The shared labels-copier action is external and was not inspected. The exclusion pattern is documented exactly as configured; its matching semantics are determined by that action's implementation.

## Sources

- Workflow: [`mergify-labels-copier.yml`](../mergify-labels-copier.yml)
