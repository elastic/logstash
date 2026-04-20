# Changelog Fragments

Each pull request that affects the Logstash release notes should include a YAML fragment file in this directory named `<PR_NUMBER>.yaml`.

## Format

```yaml
pr: 12345
summary: "Brief, user-facing description of the change"
area: Pipeline
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

- `Pipeline` — pipeline execution, persistent queue, dead letter queue
- `Config` — configuration parsing, settings, logstash.yml
- `Monitoring` — x-pack monitoring, metrics, health API
- `API` — HTTP API endpoints
- `Performance` — throughput, memory, CPU improvements
- `Plugins` — plugin framework, plugin management, gem handling
- `Security` — TLS, authentication, keystore
- `Packaging` — Docker images, RPM/DEB/ZIP distributions
- `Build` — build system, Gradle, CI tooling
- `Core` — other core Logstash changes
- `Docs` — documentation-only changes

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
pr: 12345
summary: "Add native OpenTelemetry output support"
area: Plugins
type: feature
issues: []
highlight:
  title: "Native OpenTelemetry output"
  notable: true
  body: |-
    Logstash now ships a built-in output plugin for sending data directly to any
    OpenTelemetry-compatible endpoint, without requiring a separate collector.
```
