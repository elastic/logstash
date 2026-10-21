# bump-java-version

Checks active Logstash branches for an available newer bundled JDK and opens update pull requests.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`bump-java-version.yml`](../bump-java-version.yml) |
| Trigger | Schedule and manual dispatch |

## Purpose

Keeps the bundled JDK revision and build current across active branches. The update configuration also verifies availability for supported platform builds before creating a pull request.

## When it runs

Runs on a schedule or through `workflow_dispatch`. The schedule timing is defined in the workflow source.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `filter` | Every scheduled or manual run | None declared | On `ubuntu-latest`, invokes the active-branches action with branch filtering; exposes its generated matrix as a job output. Timeout is one minute. |
| `bump` | After `filter` succeeds | `filter` | Runs once per matrix branch; checks out that branch and runs Updatecli `apply` with the JDK update policy and SCM values. |
| `notify-failure` | If `filter` or `bump` fails | `filter`, `bump` | Sends a failure notification to the `#logstash-build` Slack channel. |

The local policy derives the JDK major from `versions.yml`, reads the latest Linux JDK version/build from the JVM catalog, checks other platform downloads, then updates `versions.yml` and opens a non-automerge PR labeled `automation`.

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | No dispatch inputs. `LOGSTASH_BRANCH` is supplied per matrix item. |
| Outputs | `filter` exposes a JSON `matrix` consumed by `bump`; Updatecli may create branch changes and pull requests. |
| Permissions | Top-level `contents: read`; `filter` also has `contents: read`. `bump` has `contents: write` and `pull-requests: write`. |
| Secrets | `GITHUB_TOKEN` is passed to Updatecli; `SLACK_BOT_TOKEN` is used by the failure notification. |

## Operational notes

The active-branches action and Updatecli runner are external actions; their implementation was not inspected. The local policy is [`bump-java-version.yml`](../../../.ci/updatecli/bump-java-version.yml), with repository settings in [`scm.yml`](../../../.ci/updatecli/values.d/scm.yml). The workflow source has the current schedule.

## Sources

- Workflow: [`bump-java-version.yml`](../bump-java-version.yml)
- Updatecli policy: [`bump-java-version.yml`](../../../.ci/updatecli/bump-java-version.yml)
- SCM values: [`scm.yml`](../../../.ci/updatecli/values.d/scm.yml)
