# Logstash pull request pipeline

Runs Logstash and X-Pack unit and integration tests, license checks, and Observability SRE container checks for pull requests.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-pull-request-pipeline`](https://buildkite.com/elastic/logstash-pull-request-pipeline) |
| Source | [`pull_request_pipeline.yml`](../pull_request_pipeline.yml) and [`pull-requests.json`](../pull-requests.json) |
| Trigger | Pull requests and commits enabled through the repository's Buildkite pull-request integration; matching comments can also request a build. |

## Purpose

This is the main pull-request test suite. It covers Ruby and Java, normal and FIPS-mode suites, license checks, and the Observability SRE container build/smoke test.

## When it runs

Live pipeline settings enable GitHub pull requests, disable fork builds, and filter to builds created by `elasticmachine` with a pull-request ID. `.buildkite/pull-requests.json` enables commit and comment triggers and commit-status publication. Its comment expressions are case-sensitive and have no end anchor:

- `trigger_comment_regex` and `always_trigger_comment_regex`: `^(?:(?:buildkite\W+)?(?:build|test)\W+(?:this|it))`
- Thus the configured command starts with optional `buildkite` plus a non-word separator, then `build` or `test`, another non-word separator, then `this` or `it`; additional trailing text is permitted.

Builds are skipped when changes are exclusively within `^.github/`, `^docs/`, `^.mergify.yml$`, `^.pre-commit-config.yaml`, `\.md$`, `^.buildkite/pull-requests.json`, or `^catalog-info.yaml$`. No skip labels, target branches, or always-require paths are configured. Organization users are allowed; repository permissions `admin` and `write` qualify, with `dependabot[bot]`, `mergify[bot]`, `github-actions[bot]`, and `elastic-vault-github-plugin-prod[bot]` on the allowlist.

## Execution flow

The static pipeline contains parallel checks unless a dependency is stated. Test and container steps that declare retry settings allow up to three automatic retries; the JUnit annotation step has no retry setting.

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| License checks | Pipeline start | None declared | Checks license compliance in normal and FedRAMP High container modes. |
| Ruby and Java unit tests | Pipeline start | None declared | Runs each language's unit tests in normal and FIPS modes. |
| Integration tests | Pipeline start | None declared | Runs six normal and six FIPS splits, plus six persistent-queue splits. |
| X-Pack tests | Pipeline start | None declared | Runs X-Pack unit and integration suites in normal and FIPS modes. |
| Observability SRE container build | Pipeline start | None declared | Builds the container. |
| Observability SRE container smoke test | After container build | `observability-sre-container-build` | Downloads the image and runs smoke tests. |
| JUnit annotation | After Java unit tests | `java-unit-tests` | Annotates JUnit XML results, including skipped tests. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Buildkite checkout and pull-request metadata. FedRAMP checks set `FEDRAMP_HIGH_MODE` or `fedrampHighMode`. |
| Outputs | Coverage JSON, Java test XML, JaCoCo XML, compiled Java classes, and Buildkite JUnit annotations. |
| Artifacts | Ruby jobs upload `coverage/coverage.json`; Java jobs upload `**/build/test-results/javaTests/TEST-*.xml`, `**/jacocoTestReport.xml`, and `**/build/classes/**/*.*`. |
| Permissions | Buildkite pull-request integration publishes commit status. Repository permission and allowlist behavior is described above. |
| Environment | The live bootstrap defines `ELASTIC_PR_COMMENTS_ENABLED`, `ELASTIC_SLACK_NOTIFICATIONS_ENABLED`, `SLACK_NOTIFICATIONS_CHANNEL`, `SLACK_NOTIFICATIONS_ON_SUCCESS`, and `SLACK_NOTIFICATIONS_SKIP_FOR_RETRIES`. |
| Secrets | No secret values appear in the YAML or live bootstrap. |

## Operational notes

The pipeline's live remote configuration is a bootstrap that uploads this checked-in YAML. The agent image and test runners vary by step; some checks run inside containers. This table groups the repeated split steps for readability.

## Sources

- Pipeline: [`pull_request_pipeline.yml`](../pull_request_pipeline.yml)
- Pull-request integration: [`pull-requests.json`](../pull-requests.json)
- Container agent bootstrap: [`container-agent.sh`](../scripts/common/container-agent.sh)
- VM agent bootstrap: [`vm-agent.sh`](../scripts/common/vm-agent.sh)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-pull-request-pipeline)
