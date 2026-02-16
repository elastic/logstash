# x-pack/AGENTS.md

Guidance for coding agents working with X-Pack (Elastic-licensed) features. See also the root `AGENTS.md` for general project conventions.

## Overview

X-Pack provides commercial features that integrate with the Logstash core via the **UniversalPlugin** extension pattern. It is a separate Ruby package under `x-pack/` with its own test suite. Build without X-Pack by setting `OSS=true`.

## Features

| Feature | Path | Purpose |
|---------|------|---------|
| **Monitoring** | `lib/monitoring/` | Collects JVM, system, and pipeline metrics; ships to Elasticsearch |
| **Config Management** | `lib/config_management/` | Fetches pipeline configs from Elasticsearch/Kibana |
| **GeoIP Database Management** | `lib/geoip_database_management/` | Auto-downloads and updates GeoIP databases from Elastic CDN |
| **License Checking** | `lib/license_checker/` | Validates Elasticsearch license for feature gating |

## Extension Pattern

All X-Pack features follow the same integration pattern. Each feature has an **extension class** inheriting from `LogStash::UniversalPlugin` that implements two methods:

1. **`additionals_settings(settings)`** — Registers `xpack.*` configuration settings with the core settings registry.
2. **`register_hooks(hooks)`** — Registers lifecycle callbacks with `LogStash::Runner` (e.g. `before_bootstrap_checks`, `after_bootstrap_checks`).

**Entry point:** `lib/x-pack/logstash_registry.rb` registers all three extensions plus built-in input/output plugins with `PLUGIN_REGISTRY`.

**Extension files:**
- `lib/config_management/extension.rb`
- `lib/geoip_database_management/extension.rb`
- `lib/monitoring/monitoring.rb` (extension at bottom of file)

### Adding New Settings

Use `LogStash::Setting::*` classes in `additionals_settings`:

```ruby
def additionals_settings(settings)
  settings.register(LogStash::Setting::BooleanSetting.new("xpack.feature.enabled", false))
  settings.register(LogStash::Setting::TimeValue.new("xpack.feature.interval", "5s"))
  settings.register(LogStash::Setting::ArrayCoercible.new("xpack.feature.hosts", String, ["localhost"]))
  settings.register(LogStash::Setting::NullableStringSetting.new("xpack.feature.password"))
end
```

All X-Pack settings use the `xpack.` prefix. Elasticsearch connection options (hosts, SSL, auth, proxy) are shared across features via the `ElasticsearchOptions` helper mixin.

## License Checking

Features that require a commercial license use the `Licensed` mixin (`lib/license_checker/licensed.rb`):

1. Call `setup_license_checker(FEATURE_NAME)` during initialization.
2. Wrap feature logic in `with_license_check(raise_on_error) { ... }`.
3. Override `populate_license_state(xpack_info, is_serverless)` to return `{ :state => :ok | :error, :log_level => ..., :log_message => ... }`.

The `LicenseManager` (`lib/license_checker/license_manager.rb`) polls Elasticsearch every 30 seconds and notifies observers on state changes. License types: `trial`, `basic`, `standard`, `gold`, `platinum`, `enterprise`. Config management requires trial or above (not basic).

## Running Tests

```bash
# Unit tests (from repo root)
./gradlew :logstash-xpack:rubyTests

# Integration tests (requires running Elasticsearch)
./gradlew :logstash-xpack:rubyIntegrationTests
```

### Test Structure

- **Unit specs:** `x-pack/spec/` — Organized by feature (`spec/monitoring/`, `spec/config_management/`, `spec/geoip_database_management/`, `spec/license_checker/`).
- **Integration tests:** `x-pack/qa/integration/` — Subdirectories for `management/`, `monitoring/`, and `fips-validation/`.
- **Test helpers:** `x-pack/spec/support/helpers.rb` and `x-pack/spec/support/matchers.rb`.
- **Test runners:** JUnit-based RSpec invokers in `x-pack/src/test/java/org/logstash/xpack/test/` (`RSpecTests.java` for unit, `RSpecIntegrationTests.java` for integration).

### GeoIP Test Data

The `unzipGeolite` Gradle task downloads GeoLite2 test databases. Unit tests for GeoIP depend on this task running first (handled automatically by the `rubyTests` dependency chain).

## Key Architectural Patterns

- **Hook-based integration.** Config management intercepts bootstrap checks to swap the local config source with an Elasticsearch source. Monitoring adds an internal pipeline after the agent starts. Neither modifies core code directly.
- **Singleton managers.** `GeoipDatabaseManagement::Manager` and `LicenseChecker::LicenseManager` are singletons with thread-safe initialization via Mutex.
- **Observer pattern.** Database subscriptions and license managers notify observers on state changes, enabling features to react dynamically without polling.
- **Internal pipelines.** Monitoring generates its pipeline config from an ERB template (`lib/monitoring/template.cfg.erb`) and injects it via `InternalPipelineSource`. These run alongside user pipelines but are hidden from the user-facing API.
