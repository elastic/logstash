# github-commands-comment

Adds the shared GitHub commands comment to newly opened pull requests.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`github-commands-comment.yml`](../github-commands-comment.yml) |
| Trigger | Pull request opened (`pull_request_target`) |

## Purpose

Makes the Elastic GitHub commands interface available on new pull requests by invoking the shared action.

## When it runs

On `pull_request_target` events of type `opened`, without a branch or path filter.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `comment` | Every matching event | None declared | Runs on `ubuntu-latest` and calls `elastic/oblt-actions/elastic/github-commands@v1`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow grants `contents: read`; the job adds `pull-requests: write`. |
| Outputs | No workflow outputs, artifacts, or caches are declared. |

## Operational notes

The shared action implementation is external and was not inspected; no inputs are configured in this workflow.

## Sources

- Workflow: [`github-commands-comment.yml`](../github-commands-comment.yml)
