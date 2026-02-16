# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Project Overview

Logstash is a server-side data processing pipeline that ingests data from multiple sources, transforms it, and sends it to various destinations. It's part of the Elastic Stack and is a **hybrid Java/Ruby application** using JRuby.

### JRuby and versions

- The JRuby version is defined in **`versions.yml`** (repo root). The project uses **vendored JRuby only** — no external Ruby, rvm, or rbenv is required; Gradle installs JRuby into `vendor/jruby` via the bootstrap task.
- The gem path includes a Ruby compatibility version segment (e.g. `vendor/bundle/jruby/X.Y.0`). It is intentionally hardcoded in Gradle (`rubyUtils.gradle`), shell scripts (`bin/logstash.lib.sh`), and Java test helpers (e.g. `RubyEnvTestCase`). To find the current value, grep for `vendor/bundle/jruby/` in `bin/logstash.lib.sh`. Do not treat it as a bug or "dynamicize" it when working on the codebase.

### Single source of truth for versions

- **`versions.yml`** in the repository root is the single source of truth for Logstash version, JRuby version, bundled JDK, Jackson, and related coordinates. Gradle loads it in `settings.gradle`; the `logstash-core` and `logstash-core-plugin-api` gemspecs copy from it. When in doubt about a version, check or update `versions.yml`.

## Build Commands

Run all build and test commands from the **repository root** (where `gradlew` and `versions.yml` live), unless a specific task or doc says otherwise.

All commands require a JDK that meets the `sourceCompatibility` defined in `build.gradle` (currently 17+). JDK 21 is preferred and is the version bundled for distribution (see `bundled_jdk` in `versions.yml`). Ruby tests run via vendored JRuby — no external Ruby, rvm, or rbenv needed.

```bash
# Initial setup (required once)
./gradlew bootstrap

# Install development dependencies
./gradlew installDevelopmentGems

# Install default plugins (80+ plugins)
./gradlew installDefaultGems

# Build distribution artifact (tar.gz)
./gradlew assembleTarDistribution
# Other distribution formats (zip, deb, rpm) are built via rake tasks in rakelib/artifacts.rake
```

**Build performance (CI):** For faster `installDefaultGems`, use `JARS_SKIP=true`; required jars are already vendored or in JRuby stdlib.

## Running Tests

**Test layout:** Unit specs live under **`spec/`** (root) and **`logstash-core/spec/`**. Integration and acceptance tests live under **`qa/`** (e.g. **`qa/integration`** for integration tests). Use the commands below from the repo root; the single-integration-test example uses a path under `qa/integration`.

```bash
# All unit tests (Java + Ruby)
./gradlew test

# All Java tests
./gradlew :logstash-core:javaTests

# Single Java test class
./gradlew :logstash-core:javaTests --tests org.logstash.TimestampTest

# Single Java test method
./gradlew :logstash-core:javaTests --tests org.logstash.TimestampTest.testEpochMillis

# Java tests by pattern
./gradlew :logstash-core:javaTests --tests "org.logstash.settings.*"

# All Ruby tests (core)
./gradlew :logstash-core:rubyTests

# Single Ruby spec file
SPEC_OPTS="-fd -P logstash-core/spec/logstash/agent_spec.rb" \
  ./gradlew :logstash-core:rubyTests --tests org.logstash.RSpecTests

# All integration tests
./gradlew runIntegrationTests

# Single integration test
./gradlew runIntegrationTests -PrubyIntegrationSpecs=specs/slowlog_spec.rb

# All X-Pack Ruby tests
./gradlew :logstash-xpack:rubyTests
```

## Quick Verification

```bash
# Start Logstash with inline config
bin/logstash -e 'input { stdin { } } output { stdout {} }'
```

## Architecture

### Dual Java/Ruby Runtime
- **Java Core** (`logstash-core/src/main/java/org/logstash/`): Pipeline execution engine, event processing, persistent queue, configuration compilation
- **Ruby Core** (`logstash-core/lib/logstash/`): Agent lifecycle, plugin coordination, REST API, configuration loading

### Key Components
- **Agent** (`logstash-core/lib/logstash/agent.rb`): Main orchestrator, manages pipeline lifecycle
- **JavaPipeline** (`logstash-core/lib/logstash/java_pipeline.rb`): Ruby class for core event processing with worker threads, backed by Java execution infrastructure in `logstash-core/src/main/java/org/logstash/execution/`
- **Plugin System** (`logstash-core/lib/logstash/plugins/`): Input/Filter/Output/Codec plugin infrastructure
- **Plugin API** (`logstash-core-plugin-api/`): Public interface for plugin developers

### Directory Structure
- `logstash-core/` - Core framework (Java + Ruby)
- `lib/pluginmanager/` - Plugin installation and management
- `x-pack/` - Elastic-licensed features (disable with `OSS=true`)
- `qa/` - Quality assurance: acceptance, integration, Docker tests
- `tools/` - Development tools (docgen, benchmarks, release automation)

### Gradle–Ruby interaction

- **`rubyUtils.gradle`** drives Ruby from Gradle: it uses JRuby's `ScriptingContainer`, `executeJruby`, and invokes bundle/rake. The vendored JRuby lives under **`vendor/jruby`** after `./gradlew bootstrap`. When debugging Gradle tasks that run Ruby (e.g. plugin install, Rake), this is where the wiring lives.

## Code Design Practices

When modifying code, don't just append to what's there — evaluate whether the surrounding code still makes sense with the change. If a method, class, or abstraction was designed for one case and you're adding a second, consider restructuring so the result reads as if both cases were planned from the start. Each distinct concept should have its own clearly-named unit, and higher-level code should compose those units so the intent is obvious without reading the implementation.

### Plugin System Conventions

- **Inherit from the type-specific base class.** Each plugin type has a base in `logstash-core/lib/logstash/{type}s/base.rb` (inputs, filters, outputs, codecs). Override `register` for setup plus the type-specific entry point: `run` (inputs), `filter` (filters), `receive`/`multi_receive` (outputs), `decode`/`encode` (codecs).
- **Declare configuration with the `config` DSL**, not raw `@params` access. Use `config :name, :validate => :type, :default => value` — defined in `logstash-core/lib/logstash/config/mixin.rb`. The framework handles validation, coercion, and documentation generation from these declarations.
- **Set output concurrency at the class level** with `concurrency :shared` or `concurrency :single` in `logstash-core/lib/logstash/outputs/base.rb`. This determines which `OutputStrategy` the pipeline uses to wrap the plugin. Most new outputs should use `:shared`.
- **Plugin lookup goes through `LogStash::Plugins::Registry#lookup`** (`logstash-core/lib/logstash/plugins/registry.rb`). New built-in plugins register in `logstash-core/lib/logstash/plugins/builtin.rb`. External plugins are discovered as gems.

### Delegator and Metrics Patterns

- **Every plugin runs behind a delegator** that adds metrics collection and thread-safety. Filters: `FilterDelegatorExt` (Java), outputs: `OutputDelegatorExt` (Java), codecs: `Codecs::Delegator` (`logstash-core/lib/logstash/codecs/delegator.rb`). When changing plugin behavior, determine whether the change belongs in the delegator (cross-cutting concern) or in the plugin itself.
- **Metrics follow a namespace hierarchy.** Use `metric.namespace(:sub)` to create children. `NullMetric` implements the same interface but discards data — it's the null-object stand-in when `enable_metric => false` or during testing. Never instantiate metric objects directly; accept them from the framework.
- **Standard mixins are included automatically.** All plugins get `LogStash::Util::Loggable` (provides `logger`, `slow_logger`, `deprecation_logger`) and `LogStash::Config::Mixin` (config DSL). Additional mixins like `ECSCompatibilitySupport` and `EventFactorySupport` are opt-in per plugin.

### Pipeline Execution Model

- **The worker loop is the hot path.** `WorkerLoop` (`logstash-core/src/main/java/org/logstash/execution/WorkerLoop.java`) pulls batches from the queue, runs them through the compiled pipeline, and signals completion. Shutdown is coordinated via `AtomicBoolean` flags — do not add blocking calls or heavy allocations inside this loop.
- **Pipeline lifecycle follows a strict ordering** in `JavaPipeline` (`logstash-core/lib/logstash/java_pipeline.rb`): outputs and filters register first, then workers start, then inputs start last. On shutdown the reverse applies: inputs stop first, workers drain, then filters and outputs close. Violating this ordering causes data loss or deadlocks.
- **Use `Concurrent::AtomicBoolean` (Ruby) or `java.util.concurrent.atomic.AtomicBoolean` (Java) for cross-thread signaling.** Do not use plain boolean instance variables for state shared across threads — Ruby's GIL does not guarantee visibility, and JRuby runs without one.

### Java/Ruby Boundary

- **JRuby extensions use `@JRubyClass`/`@JRubyMethod` annotations.** Classes register in `RubyUtil` (`logstash-core/src/main/java/org/logstash/RubyUtil.java`) via `setupLogstashClass` or `defineClassUnder`. Follow existing patterns in `RubyUtil`'s static initializer when adding new Java-backed Ruby classes.
- **`ThreadContext` must be obtained at point of use** via `RubyUtil.RUBY.getCurrentContext()`, never stored at construction time. Storing it causes `NullPointerException` when used from a different thread (JRuby 10+). See `RubyCodecDelegator` for the correct pattern.
- **Test the round-trip through Java.** Integration tests should exercise the full path from Ruby through the Java layer and back, not just the Ruby classes in isolation. This catches type coercion issues and metric namespace registration bugs that unit tests miss.
- **Java tests that load Ruby:** Some Java tests (e.g. `RubyEnvTestCase` and subclasses) set **GEM_HOME** / **GEM_PATH** to the vendored bundle path (`vendor/bundle/jruby/<ruby-compat-version>`) so they can load Logstash Ruby code. Check `bin/logstash.lib.sh` or `rubyUtils.gradle` for the current version segment. That path is intentional; do not change it when touching those tests.

### Test Practices

- **Use `sample_one` helper for filter pipeline tests.** `PipelineHelpers#sample_one` (`logstash-core/spec/support/pipeline/pipeline_helpers.rb`) spins up a real pipeline, feeds events through a filter config, and captures results — preferred over manually constructing pipeline objects.
- **Create dummy plugin classes inside spec files for isolation.** Define throwaway classes inheriting from the appropriate base, register with `LogStash::PLUGIN_REGISTRY.add`. See `pipeline_helpers.rb` for examples.
- **Use `shared_examples` for interface contracts and `shared_context` for common setup.** Examples: `"metrics commons operations"` in `spec/support/shared_examples.rb`, `"execution_context"` in `spec/support/shared_contexts.rb`.
- **Integration tests use the Fixture + Service pattern.** `Fixture` (`qa/integration/framework/fixture.rb`) bootstraps services and loads config from YAML fixture files under `qa/integration/fixtures/`.
- **Test that existing rescue blocks catch new code paths.** When a method has a `rescue => e` that returns `nil`, verify that exceptions raised in newly added branches are caught by it. It is easy to accidentally add code outside the `begin...rescue` scope.
- **Clean up JVM state in `after` blocks.** Any `java.lang.System.setProperty` call in a test must have a corresponding `clearProperty` in `after` to avoid leaking state to other specs.

### Test Validity

- **Verify every new test fails without the corresponding change.** Before treating a test as done, confirm it fails against the pre-change code. A test that passes with or without the fix proves nothing. This is the most basic check that a test is load-bearing.
- **Assert on the specific behaviour the change introduces, not on pre-existing conditions.** If the system already returned `200 OK` before your fix, asserting `200 OK` does not validate the fix. Pin the assertion to an observable difference — a new field, a changed value, a previously-missing log line.
- **For bug fixes, reproduce the bug in the test first.** Write the test, watch it fail for the same reason the bug manifests, then apply the fix and watch it pass. If you cannot make the test fail, either the bug is not what you think or the test is not targeting it.
- **Beware of tautological mocks.** Stubbing a method to return the value you then assert is a circular proof. Mocks should simulate collaborators, not replace the code under test. If removing the implementation and keeping only the mock still passes the test, the test is testing the mock.

## Plugin Development

Plugins live in separate repositories under [logstash-plugins](https://github.com/logstash-plugins). Each plugin is a self-contained Ruby gem. Plugin types: input, filter, output, codec.

- The **`logstash-core-plugin-api`** version is in **`versions.yml`**; plugins (in separate repos) depend on it.
- Templates for new plugins are in **`lib/pluginmanager/templates/`**.
- Supported plugin versions and compatibility are tracked in the [logstash-plugins `.ci`](https://github.com/logstash-plugins/.ci) repo (e.g. `logstash-versions.yml`).

## Sensitive Data Handling

When adding configuration parameters for sensitive data:
- In Ruby: Apply `:password` validation or wrap with `Logstash::Util::Password`
- In Java: See `Password.java` and `SecretVariable.java` for patterns
- Override `toString()` to mask sensitive values
- Never log secrets at any log level by default

Example:
```ruby
:my_auth => { :validate => :password }
# Or wrap manually:
::LogStash::Util::Password.new(my_auth)
```

## Environment Variables

```bash
export LOGSTASH_SOURCE=1
export LOGSTASH_PATH=/path/to/logstash
export JAVA_HOME=/path/to/jdk  # JDK 17+ (see build.gradle sourceCompatibility)
export OSS=true                 # Build without X-Pack
```

## Debugging

```bash
# Attach debugger to running Logstash
LS_JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005" bin/logstash ...
```

## Breaking Changes Policy

1. Implement new behavior as opt-in (MINOR)
2. Add deprecation warnings (MINOR)
3. Change default, keep opt-out option (MAJOR)
4. Remove old behavior (MAJOR)

## Documentation

### Directory Structure
- `docs/reference/` - Main user-facing documentation (Markdown)
- `docs/extend/` - Plugin development and contribution guides (Markdown)
- `docs/release-notes/` - Version-specific release notes, breaking changes, deprecations
- `docs/static/` - Static assets (images, OpenAPI specs)
- `tools/logstash-docgen/` - Auto-generates plugin documentation from code

### Formats
- **Reference docs**: Markdown (`.md`) with front matter and admonition syntax
- **Plugin docs**: AsciiDoc (`.asciidoc`) with dynamic ID variables

### Markdown Conventions (Reference Docs)
```markdown
---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/page.html
---

# Heading Title [anchor-id]

::::{admonition} Note title
:class: note
Content here
::::
```

### AsciiDoc Conventions (Plugin Docs)
```asciidoc
:plugin: example
:type: filter

[id="plugins-{type}s-{plugin}"]
=== Example filter plugin

[id="plugins-{type}s-{plugin}-options"]
==== Configuration Options
```

Use dynamic IDs (`{type}`, `{plugin}`) to prevent ID duplication across plugin versions.

### Guidelines
- All PRs must include documentation updates when applicable
- Plugin documentation is required before merging
- Follow [Elastic's documentation standards](https://github.com/elastic/docs#asciidoc-guide)
- Images go in `docs/reference/images/` (PNG format)

## See also

- **CONTRIBUTING.md** — Contribution process, sensitive data, and where to ask questions
- **STYLE.md** — Ruby style (indentation, logging, hash syntax) and consistency
