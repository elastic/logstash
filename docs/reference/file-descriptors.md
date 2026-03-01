---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/file-descriptors.html
---

# File descriptors [file-descriptors]

On Unix-like systems (Linux, macOS), every open file, network socket, and pipe consumes a file descriptor. {{ls}} can consume many file descriptors depending on your configuration:

* **Base overhead**: 50–100 file descriptors for JVM internals, logging, and core functionality.
* **Network inputs**: One file descriptor per concurrent connection ({{beats}}, TCP, HTTP, UDP).
* **File inputs**: One file descriptor per monitored file.
* **Outputs**: File descriptors for each connection to {{es}}, Kafka, Redis, and other destinations.
* **Persistent queues**: Approximately 3 file descriptors per pipeline with PQ enabled.
* **Dead letter queues**: Approximately 3 file descriptors per pipeline with DLQ enabled.

If {{ls}} runs out of available file descriptors, it may fail to accept new connections, fail to open files, or experience unexpected errors.

## Checking current limits [checking-file-descriptors]

### On Linux [checking-linux]

Check the soft and hard limits for a running {{ls}} process:

```sh
# Find the Logstash process ID
pgrep -f logstash

# Check limits for that process (replace <PID> with actual PID)
cat /proc/<PID>/limits | grep "open files"
```

Or check your shell's current limits:

```sh
# Soft limit
ulimit -Sn

# Hard limit
ulimit -Hn
```

### On macOS [checking-macos]

```sh
ulimit -n                     # Current limit
sysctl kern.maxfilesperproc   # System maximum per process
```

### Using the monitoring API [checking-api]

{{ls}} exposes file descriptor metrics through its monitoring API:

```sh
curl -s "localhost:9600/_node/stats/process" | jq '.process'
```

**Example** response:

```json
{
  "open_file_descriptors": 87,
  "peak_open_file_descriptors": 102,
  "max_file_descriptors": 16384
}
```

If `open_file_descriptors` approaches `max_file_descriptors`, increase the limit.

## Default operating system limits [default-os-limits]

Default file descriptor limits vary by operating system. The soft limit (what processes get by default) is often much lower than the hard limit (the maximum a process can request).

### Linux [default-limits-linux]

Most Linux distributions set a **soft limit of 1,024** by default. The hard limit depends on the systemd version:

* **systemd v240+** (most modern distributions): Hard limit of 524,288 or higher. These systems allow processes to request high limits without system-wide configuration changes.
* **systemd pre-v240** (older distributions like RHEL 7/8, SLES 12, Amazon Linux 2): Hard limit of only 4,096. You must increase system-wide limits before per-process limits can be raised above this value.

Check your systemd version with `systemctl --version` to determine which category your system falls into.

### macOS [default-limits-macos]

macOS has a low default soft limit (256) but allows higher limits up to `kern.maxfilesperproc`.

## Recommended settings [recommended-settings]

For most production deployments, set the file descriptor limit to at least **16384**, which is the default configured in the {{ls}} systemd service file. For high-throughput environments with many concurrent connections or multiple pipelines with persistent queues, consider **65536** or more.

When estimating your requirements, add a safety margin of 2–3x to accommodate spikes and growth.
