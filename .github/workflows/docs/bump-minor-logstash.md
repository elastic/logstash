# bump-minor-logstash-version

Performs the mechanical branch and version-file preparation for a minor Logstash release.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`bump-minor-logstash.yml`](../bump-minor-logstash.yml) |
| Trigger | Manual dispatch |

## Purpose

Cuts a release branch, prepares its baseline release lockfile, and moves the source branch's version metadata to the next minor. The workflow comments explicitly leave dependency updates and pin review as manual work.

## When it runs

Only runs through `workflow_dispatch`. Required strings: `logstash-version` and `logstash-branch`. Optional inputs are `source-branch` (default `main`), `next-minor-version` (computed if omitted), `previous-branch` (computed if omitted), and boolean `skip-branch-creation` (default `false`, for a last minor of a major).

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `create-release-branch` | Unless branch creation is skipped | None declared | Checks out the source branch with full history, then creates the release branch unless it already exists. |
| `add-release-lockfile` | Branch creation is not skipped | `create-release-branch` | Checks out the release branch, resolves the previous branch (explicit value or preceding minor), copies its release lockfile, pins `logstash-core`, updates version metadata, and pushes a branch/opens a PR unless there are no changes or the PR branch already exists. |
| `bump-source-branch-versions` | `always()` and branch creation succeeded or was skipped | `create-release-branch` | Resolves the next minor (explicit value or computed), updates source-branch versions, and pushes a branch/opens a PR unless there are no changes or the PR branch already exists. |

Both PR-creation jobs use the GitHub CLI after pushing their generated branch. The lockfile job is skipped when release-branch creation is skipped; the source-version job still runs after that skipped dependency.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `logstash-version`, `logstash-branch`, `source-branch`, `next-minor-version`, `previous-branch`, and `skip-branch-creation` as described above. |
| Outputs | May create release and working branches and open pull requests; no declared workflow outputs or artifacts. |
| Permissions | Top-level `contents: read`; branch creation has `contents: write`; both PR jobs have `contents: write` and `pull-requests: write`. |
| Secrets | `GITHUB_TOKEN` is used for pushes, Git setup, and GitHub CLI pull-request creation. |

## Operational notes

All release edits and branch creation are inline shell steps in the workflow; no local scripts or reusable workflows are called. A pre-existing target branch or generated PR branch is treated as a skip. The workflow source is the complete available implementation.

## Sources

- Workflow: [`bump-minor-logstash.yml`](../bump-minor-logstash.yml)
