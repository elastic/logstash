# Add to project

Adds newly opened issues to the configured Logstash GitHub Project.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`logstash_project_board.yml`](../logstash_project_board.yml) |
| Trigger | Issue opened |

## Purpose

Keeps newly created issues represented on the Logstash project board by adding the issue through the Projects GraphQL API.

## When it runs

On `issues` events of type `opened`, without additional filters.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `add-to-project` | Every issue-opened event | None declared | On `ubuntu-latest`, invokes `octokit/graphql-action@v2.x` with the Projects GraphQL feature header and `addProjectV2ItemById` mutation, using the issue node ID and configured project ID. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow sets `contents: none`; no explicit job token permissions are declared. |
| Secrets | `PROJECT_TOKEN` is passed as `GITHUB_TOKEN` to the GraphQL action. |
| Outputs | The mutation returns a client mutation ID; no workflow output is declared. |

## Operational notes

Project ID and mutation are embedded in the workflow. Access to the project depends on the configured `PROJECT_TOKEN` secret.

## Sources

- Workflow: [`logstash_project_board.yml`](../logstash_project_board.yml)
