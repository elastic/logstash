# Add Logstash issue to Logstash Ingest Project

Adds issues labeled `Team:Logstash` to the Logstash project and sets their Area field.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`platform_logstash_project_board.yml`](../platform_logstash_project_board.yml) |
| Trigger | Issue labeled |

## Purpose

Routes Logstash-team issues into the configured Logstash project and selects its Data Processing area option.

## When it runs

On `issues` events of type `labeled`. Both GraphQL steps run only when the added label is exactly `Team:Logstash`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `add_to_logstash_project` | Label is `Team:Logstash` | None declared | Adds the issue node to the configured project and returns the created item ID. |
| `set_data_processing_area` | Label is `Team:Logstash` | First step's returned item ID | Sets the item's Area field to the configured Data Processing option. |

The steps use `octokit/graphql-action@v2.x` to execute Projects GraphQL mutations.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow sets `contents: none`; no explicit job token permissions are declared. |
| Secrets | `PROJECT_TOKEN` is passed as `GITHUB_TOKEN` to each GraphQL step. |
| Outputs | The project item ID from the first step is consumed by the second; no workflow-level output is declared. |

## Operational notes

Project ID, Area field ID, option ID, and label are embedded in the workflow. The area update depends on the add-item mutation succeeding.

## Sources

- Workflow: [`platform_logstash_project_board.yml`](../platform_logstash_project_board.yml)
