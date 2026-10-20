# bump-logstash-version

Updates Logstash version metadata and its release lock-file dependency, then asks Updatecli to open a pull request.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`bump-logstash.yml`](../bump-logstash.yml) |
| Trigger | Manual dispatch |

## Purpose

Provides an operator-driven way to set the Logstash version and branch for a release update. The optional release track can be changed as part of the same operation.

## When it runs

Only runs through `workflow_dispatch`. Required string inputs are `logstash-version` and `logstash-branch`. Optional `logstash-release-track` is left unchanged when empty.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `bump` | Every manual dispatch | None declared | Checks out the repository, then runs Updatecli `apply` with the version bump policy and SCM values. |

The policy updates `logstash` and `logstash-core` in `versions.yml`; if the optional release-track value is provided, it updates that field too. When the release lockfile exists, it adjusts its `logstash-core` dependency and gem spec. The policy creates an automation-labeled, non-automerge pull request.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `logstash-version` (required), `logstash-branch` (required), `logstash-release-track` (optional). |
| Outputs | Updatecli can create changes and a pull request; no workflow outputs or artifacts are declared. |
| Permissions | Top-level `contents: read`; `bump` has `contents: write` and `pull-requests: write`. |
| Secrets | `GITHUB_TOKEN` is passed to Updatecli. |

## Operational notes

Updatecli execution is provided by an external action whose implementation was not inspected. The checked-in policy requires `Gemfile.jruby-3.4.lock.release` before attempting lockfile edits. Sources: [`bump-logstash-version.yml`](../../../.ci/updatecli/bump-logstash-version.yml) and [`scm.yml`](../../../.ci/updatecli/values.d/scm.yml).

## Sources

- Workflow: [`bump-logstash.yml`](../bump-logstash.yml)
- Updatecli policy: [`bump-logstash-version.yml`](../../../.ci/updatecli/bump-logstash-version.yml)
- SCM values: [`scm.yml`](../../../.ci/updatecli/values.d/scm.yml)
