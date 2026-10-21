# update-compose

Checks and applies Updatecli compose policies, notifying the Logstash build channel if a step fails.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`update-compose.yml`](../update-compose.yml) |
| Trigger | Schedule and manual dispatch |

## Purpose

Runs the repository's Updatecli compose diff and apply operations to maintain generated or policy-managed files.

## When it runs

Runs on a schedule or through `workflow_dispatch`. The exact schedule is available in the workflow source.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `compose` | Every scheduled or manual run | None declared | Checks out the repository, logs in to GHCR, runs Updatecli `compose diff`, then `compose apply`. |
| Slack notification | When a prior step fails | Compose job steps | Calls the shared Slack action to report the repository, ref, and run URL in `#logstash-build`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow grants `contents: read`; job grants `contents: write`, `pull-requests: write`, and `packages: read`. |
| Secrets | `GITHUB_TOKEN` is used for GHCR login and Updatecli; `SLACK_BOT_TOKEN` is passed to the Slack action. |
| Outputs | No workflow outputs or artifacts are declared. |

## Operational notes

The notification step is guarded by `failure()`. Docker login uses a commit-pinned action; Updatecli and Slack actions are shared external actions. The source workflow contains current scheduler configuration.

## Sources

- Workflow: [`update-compose.yml`](../update-compose.yml)
