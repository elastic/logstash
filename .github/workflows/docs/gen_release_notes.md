# Release Notes Draft generator

Generates release-note content for a selected branch and opens a draft pull request assigned to the dispatching user.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`gen_release_notes.yml`](../gen_release_notes.yml) |
| Trigger | Manual dispatch |

## Purpose

Automates assembling release notes from closed release-labeled pull requests and plugin lockfile changes. The workflow chooses the legacy AsciiDoc or newer Markdown generator based on the target branch series.

## When it runs

Only on `workflow_dispatch`. Inputs are `branch` (required, default `9.0`) and `last_release` (required, default `9.0.0`). Before generation, the job verifies that the remote target branch and corresponding `v<last_release>` tag exist.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `main` | Every manual dispatch | None declared | Checks out full history and tags, validates branch/tag, sets up Ruby 3.0, configures the `logstashmachine` git identity, then runs a release notes generator. |

Branches matching the legacy major range use [`generate_release_notes.rb`](../../../tools/release/generate_release_notes.rb), which edits the AsciiDoc release notes; other branches use [`generate_release_notes_md.rb`](../../../tools/release/generate_release_notes_md.rb), which edits Markdown. Both gather release pull requests and plugin changelog information, then create and push a branch, open a draft PR against the selected branch, and assign it to the actor.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `branch` and `last_release` strings (both required, with defaults shown above). |
| Outputs | Pushes a generated branch and creates a draft pull request; no declared workflow outputs or artifacts. |
| Permissions | `contents: write`, `pull-requests: write`, and `issues: write`. |
| Secrets | `GITHUB_TOKEN` is passed to the selected Ruby script. |

## Operational notes

Generation depends on the selected branch and release tag being fetchable, GitHub API responses, and plugin changelogs hosted in their repositories. The workflow and scripts do not declare a deployment environment or artifact upload.

## Sources

- Workflow: [`gen_release_notes.yml`](../gen_release_notes.yml)
- AsciiDoc generator: [`generate_release_notes.rb`](../../../tools/release/generate_release_notes.rb)
- Markdown generator: [`generate_release_notes_md.rb`](../../../tools/release/generate_release_notes_md.rb)
