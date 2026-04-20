# Changelog Fragments

Each pull request that affects the Logstash release notes should include a YAML fragment file in this directory named `<PR_NUMBER>.yaml`.

## Format

```yaml
pr: 12345
summary: "Brief, user-facing description of the change"
area: core
type: enhancement
issues:
  - 12344
```

### Required fields

| Field | Description |
|-------|-------------|
| `pr` | Pull request number (must match the filename) |
| `summary` | One-line, user-facing description. Write for the person upgrading, not the reviewer. |
| `area` | Component area — see allowed values below |
| `type` | Type of change — see allowed values below |

### Optional fields

| Field | Description |
|-------|-------------|
| `issues` | List of linked issue numbers (use `[]` if none) |
| `highlight` | For notable features — adds an extended description to release highlights |

### Allowed values for `area`

- `core` — general Logstash core changes
- `performance` — throughput, memory, or CPU improvements
- `pq` — persistent queue
- `dlq` — dead letter queue
- `docs` — documentation-only changes
- `monitoring` — x-pack monitoring, metrics, health API
- `central management` — Kibana-based central pipeline management
- `pipeline->pipeline` — pipeline-to-pipeline communication

### Allowed values for `type`

- `bug` — bug fix
- `enhancement` — improvement to an existing feature
- `feature` — new feature
- `breaking_change` — removes or incompatibly changes existing behaviour
- `deprecation` — marks something for future removal
- `dependency` — dependency update (include CVE number in summary if security-related)
- `doc` — documentation only

## Skipping release notes

If your PR should not appear in release notes (e.g. CI fixes, test-only changes), add `[rn:skip]` to the PR description instead of creating a fragment file.

## highlight format

For significant features, add a `highlight` block:

```yaml
pr: 18377
summary: "Add wait_for_status and timeout parameters to the Logstash root API endpoint"
area: monitoring
type: feature
issues: []
highlight:
  title: "Wait for status on the Logstash API"
  notable: true
  body: |-
    The Logstash root endpoint `/` now accepts `wait_for_status` and `timeout`
    query parameters. When set, the call blocks until Logstash reaches (or
    exceeds) the requested status, or the timeout expires. This makes it
    straightforward to script startup readiness checks without polling.
```
