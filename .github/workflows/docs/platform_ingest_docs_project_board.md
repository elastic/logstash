# Add Docs issue to Ingest project

Adds issues labeled `Team:Docs` to the Ingest project and assigns the configured Docs area option.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`platform_ingest_docs_project_board.yml`](../platform_ingest_docs_project_board.yml) |
| Trigger | Issue labeled |

## Purpose

Routes Docs-team issues to the Ingest project and sets the project's Area field to the Docs option.

## When it runs

On `issues` events of type `labeled`. Both steps run only when the newly applied label is exactly `Team:Docs`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `add_to_ingest_project` | Label is `Team:Docs` | None declared | Adds the issue node to the configured Ingest project and returns the new project item ID. |
| `set_data_processing_area` | Label is `Team:Docs` | `add_to_ingest_project` output is referenced | Sets the item's Area field to the configured Docs option ID. |

Both steps use the Projects GraphQL API through `octokit/graphql-action@v2.x`.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow sets `contents: none`; no explicit job token permissions are declared. |
| Secrets | `PROJECT_TOKEN` is supplied to both GraphQL steps. |
| Outputs | First mutation's item ID is consumed by the second; no workflow output is declared. |

## Operational notes

Project and field IDs and label/option values are configured in the workflow. The second mutation depends on successful creation of the project item.

## Sources

- Workflow: [`platform_ingest_docs_project_board.yml`](../platform_ingest_docs_project_board.yml)
