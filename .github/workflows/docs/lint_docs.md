# Lint the docs!

Runs the Elastic documentation linter for AsciiDoc files and reports failures in a pull-request comment.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`lint_docs.yml`](../lint_docs.yml) |
| Trigger | Pull request targeting `main` |

## Purpose

Checks documentation under `docs/` with `@elastic/docs-lint`, reports findings to the PR, and fails the workflow when the report is non-empty.

## When it runs

On pull requests targeting `main`; no event-type or path filters are declared.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `lint-docs` | Every matching pull request | None declared | On `ubuntu-latest`, checks out code, sets up Node 16.13.2 with npm caching, globally installs `@elastic/docs-lint`, locally installs `strip-ansi`, then runs `docs-lint` against `docs/` in AsciiDoc mode. |
| Add PR comment | After lint report is captured | `Run docs-lint` | If the report is non-empty, strips ANSI codes and comments the report on the PR. |
| Throw error if linter fails | After report capture | `Run docs-lint` | Marks the job failed for a non-empty report. |

The shell captures linter output while allowing the step to continue so later steps can comment and set the final result.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow grants `pull-requests: write` and `contents: read`. |
| Outputs | The lint step exposes `LINT_RESULT` using the legacy `set-output` command; no artifacts are declared. |
| Secrets | `GITHUB_TOKEN` is supplied to the commenting step. |

## Operational notes

The comment step imports `strip-ansi` from the runner's docs-lint checkout path. The workflow does not configure a job timeout or deployment environment.

## Sources

- Workflow: [`lint_docs.yml`](../lint_docs.yml)
