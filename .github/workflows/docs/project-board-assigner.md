# Add issue to Ingest or Logstash project

Routes newly labeled issues to the Ingest or Logstash GitHub project based on the team label.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`project-board-assigner.yml`](../project-board-assigner.yml) |
| Trigger | Issue labeled |

## Purpose

Adds Docs issues to the Ingest project, Logstash issues to the Logstash project, and sets the Ingest Docs area for Docs issues.

## When it runs

On `issues` events of type `labeled`. The Ingest addition and area update are conditioned on the exact `Team:Docs` label; the Logstash addition is conditioned on exact `Team:Logstash`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `add_to_ingest_project` | Label is `Team:Docs` | None declared | Adds the issue node to the Ingest project. |
| `add_to_logstash_project` | Label is `Team:Logstash` | None declared | Adds the issue node to the Logstash project. |
| `set_data_processing_area` | Label is `Team:Docs` | References the added item output | Sets the Area field for the Ingest project item to the Docs option. |

Each operation is a separate `octokit/graphql-action@v2.x` step.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow sets `contents: none`; no explicit job token permissions are declared. |
| Secrets | `PROJECT_TOKEN` is passed to each GraphQL step. |
| Outputs | Project mutation item IDs are consumed for field assignment; no workflow-level output is declared. |

## Operational notes

The Area update's `item_id` expression references `steps.add_to_project.outputs.data`, but this workflow assigns IDs `add_to_ingest_project` and `add_to_logstash_project` instead. Verify this step output reference if the field update fails. IDs, team labels, and option are configured inline.

## Sources

- Workflow: [`project-board-assigner.yml`](../project-board-assigner.yml)
