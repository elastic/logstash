# Bump dependencies

Updates the release lockfile's gem dependencies according to a selected version bump policy and opens a pull request.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`version_bumps.yml`](../version_bumps.yml) |
| Trigger | Manual dispatch |

## Purpose

Automates dependency lockfile updates for the selected branch, with controls for patch, minor, and major updates plus selected gem overrides.

## When it runs

Only runs through `workflow_dispatch` on the selected branch. `bump` is required and supports `patch`, `minor`, or `major` (default `patch`). `extra_gems_minor` is a space-separated optional list used for patch runs; AWS gems are included automatically. `extra_gems_major` is an optional space-separated list used for patch or minor runs.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `version_bumper` | Every manual dispatch | None declared | Sets up Temurin JDK 21; queries whether the actor belongs to the Elastic `logstash` team; checks out the selected branch with full history; installs default gems; performs the requested Bundler update; moves the generated lockfile to the release lockfile name; creates and pushes a working branch; and opens a PR. |
| Selected minor bumps | Only for patch runs | Main job steps | Includes AWS gems plus `extra_gems_minor`, and updates those conservatively at minor level. |
| Selected major bumps | When bump is not `major` and `extra_gems_major` is non-empty | Main job steps | Updates the requested gems conservatively at major level. |
| Mergify configuration and label | Only for minor runs; each is `continue-on-error` | Main job steps | Runs the repository's `.ci` make targets to update Mergify and create a backport label. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `bump`, `extra_gems_minor`, and `extra_gems_major` as described above. |
| Outputs | Pushes a lockfile-update branch and creates a pull request; no workflow outputs or artifacts are declared. |
| Permissions | `pull-requests: write` and `contents: write`. |
| Secrets | `READ_ORG_SECRET_JSVD` is used by the team-membership action; `GITHUB_TOKEN` is used for PR API creation and GitHub CLI operations. |

## Operational notes

The source checks out the branch named by `github.ref_name`; updates use vendored JRuby and installed default gems. The team membership conditional refers to `steps.checkUserMember.outputs.isTeamMember`, while the membership action step has no `id` assigned in this workflow; this should be checked if the guard behaves unexpectedly. Minor-only Mergify steps are explicitly allowed to fail without failing the job.

## Sources

- Workflow: [`version_bumps.yml`](../version_bumps.yml)
