# qa/AGENTS.md

Guidance for coding agents working with the QA test infrastructure. See also the root `AGENTS.md` for general project conventions.

## Overview

The `qa/` directory contains three independent test suites:

| Suite | Path | Purpose |
|-------|------|---------|
| **Integration** | `qa/integration/` | End-to-end tests with live services (Elasticsearch, Kafka, etc.) |
| **Acceptance** | `qa/acceptance/` | Package artifact testing (deb, rpm install/upgrade) |
| **Docker** | `qa/docker/` | Docker image and container verification |

Each suite has its own dependencies and execution workflow.

## Integration Tests (qa/integration/)

### Running

```bash
# All integration tests (from repo root)
./gradlew runIntegrationTests

# Single test
./gradlew runIntegrationTests -PrubyIntegrationSpecs=specs/dlq_spec.rb

# Manual (from qa/integration/)
bundle exec rspec specs/dlq_spec.rb
```

### Architecture: Fixture + Service Pattern

Every integration test has a matching YAML fixture file:
- Test: `qa/integration/specs/dlq_spec.rb`
- Fixture: `qa/integration/fixtures/dlq_spec.yml`

**Fixture YAML structure:**
```yaml
---
services:
  - logstash
  - elasticsearch
config: |-
  input { generator { count => 100 } }
  output { elasticsearch { index => "test" } }
```

Fixtures can also use ERB for dynamic values and define multiple named configs as a hash.

**In test code:**
```ruby
@fixture = Fixture.new(__FILE__)           # Loads matching YAML
@logstash = @fixture.get_service("logstash")
config = @fixture.config("root", { :port => 9200 })  # ERB interpolation
```

### Key Framework Classes

- **`Fixture`** (`framework/fixture.rb`) — Bootstraps services and loads config from YAML fixtures.
- **`TestSettings`** (`framework/settings.rb`) — Merges per-test YAML with global `suite.yml`, performs ERB expansion.
- **`LogstashService`** (`services/logstash_service.rb`) — Manages a Logstash process from the built tarball. Key methods: `start_with_config_string(config)`, `start_background(config_file)`, `wait_for_logstash`, `teardown`.
- **`MonitoringAPI`** (`services/monitoring_api.rb`) — HTTP wrapper for the Logstash REST API (`pipeline_stats`, `node_info`, `health_report`).
- **Helpers** (`framework/helpers.rb`) — `wait_for_port`, `is_port_open?`, `send_data`, `config_to_temp_file`, `random_port`.

### Service Management

Services are auto-discovered by naming convention (`*_service.rb` in `services/`). Each service consists of:
1. A Ruby class extending `Service` (e.g. `ElasticsearchService`)
2. A `<name>_setup.sh` script (called during test setup)
3. A `<name>_teardown.sh` script (called during cleanup)

To add a new service: create all three files in `qa/integration/services/` and reference the service name in your fixture YAML.

### Test File Pattern

```ruby
require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'

describe "Feature under test" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
  }

  after(:all) { @fixture.teardown }
  after(:each) { @logstash.teardown }

  it "should behave correctly" do
    @logstash.start_with_config_string(@fixture.config)
    # ... assertions ...
  end
end
```

### Dependencies

Defined in `qa/integration/integration_tests.gemspec`: `elasticsearch`, `childprocess`, `rspec-wait`, `manticore`, `stud`, `logstash-devutils`, `flores`, `rubyzip`.

## Acceptance Tests (qa/acceptance/)

### Purpose

Verify that Logstash packages (`.deb`, `.rpm`) install, start, and upgrade correctly on target platforms. These test the artifact, not pipeline behavior.

### Running

```bash
cd qa && bundle install && rake qa:acceptance:all
# Or single test:
bundle exec rspec acceptance/spec/lib/artifact_operation_spec.rb
```

### Architecture

Tests use RSpec `shared_examples` for reusable test sequences:
- `"installable"` — Download, install, start, stop
- `"installable_with_jdk"` — Install and verify bundled JDK
- `"running"` — Verify process is running
- `"updated"` — Test upgrade from previous version

Shared examples live in `qa/acceptance/spec/shared_examples/`.

## Docker Tests (qa/docker/)

### Purpose

Verify Docker image build correctness (labels, working directory, architecture), container startup, health checks, and X-Pack features.

### Running

```bash
cd qa/docker && bundle install
bundle exec rspec spec/              # All flavors
bundle exec rspec spec/full/         # Specific flavor (full, oss, wolfi, ironbank)
```

### Architecture

Tests use shared examples across image flavors (`full`, `oss`, `wolfi`, `ironbank`). Key helpers in `spec/spec_helper.rb`: `find_image`, `start_container`, `exec_in_container`, `wait_for_logstash`, `cleanup_container`.

## Debugging

```bash
# Integration: verbose output
cd qa/integration
VERBOSE=true bundle exec rspec specs/my_spec.rb -fd

# Docker: inspect container
docker run -it logstash-test /bin/bash
```
