#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

OTEL_VERSION="0.150.1"
OTEL_DATA_DIR="/tmp/ls_integration/otel"
OTEL_BINARY="$OTEL_DATA_DIR/otelcol-contrib"
OTEL_VERSION_FILE="$OTEL_DATA_DIR/otelcol-version"
OTEL_CONFIG="$OTEL_DATA_DIR/otel-config.yaml"
OTEL_PID_FILE="$OTEL_DATA_DIR/otel.pid"
OTEL_METRICS_FILE="$OTEL_DATA_DIR/metrics.json"
OTEL_LOG_FILE="$OTEL_DATA_DIR/otel.log"

# Ports
HTTP_PORT=4318
GRPC_PORT=4317
AUTH_HTTP_PORT=4319
AUTH_TOKEN="test-integration-key"

# Create data directory
mkdir -p "$OTEL_DATA_DIR"
rm -f "$OTEL_METRICS_FILE"

# Determine OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
esac

# Download OTel Collector if not present or if version has changed
CACHED_VERSION=""
[[ -f "$OTEL_VERSION_FILE" ]] && CACHED_VERSION=$(cat "$OTEL_VERSION_FILE")
if [[ ! -f "$OTEL_BINARY" || "$CACHED_VERSION" != "$OTEL_VERSION" ]]; then
    echo "Downloading OpenTelemetry Collector v${OTEL_VERSION}..."
    OTEL_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_${OS}_${ARCH}.tar.gz"
    curl -L "$OTEL_URL" -o "$OTEL_DATA_DIR/otelcol.tar.gz"
    tar -xzf "$OTEL_DATA_DIR/otelcol.tar.gz" -C "$OTEL_DATA_DIR"
    chmod +x "$OTEL_BINARY"
    rm -f "$OTEL_DATA_DIR/otelcol.tar.gz"
    echo "$OTEL_VERSION" > "$OTEL_VERSION_FILE"
fi

# Create OTel Collector config
cat > "$OTEL_CONFIG" <<EOF
extensions:
  bearertokenauth:
    token: "${AUTH_TOKEN}"

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: "0.0.0.0:${GRPC_PORT}"
      http:
        endpoint: "0.0.0.0:${HTTP_PORT}"
        include_metadata: true
  otlp/auth:
    protocols:
      http:
        endpoint: "0.0.0.0:${AUTH_HTTP_PORT}"
        auth:
          authenticator: bearertokenauth

processors:
  batch:
    timeout: 1s

exporters:
  file:
    path: "${OTEL_METRICS_FILE}"
    flush_interval: 1s
  debug:
    verbosity: detailed

service:
  extensions: [bearertokenauth]
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [file, debug]
    metrics/auth:
      receivers: [otlp/auth]
      processors: [batch]
      exporters: [file, debug]
EOF

# Stop any existing collector
if [[ -f "$OTEL_PID_FILE" ]]; then
    OLD_PID=$(cat "$OTEL_PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Stopping existing OTel Collector (PID: $OLD_PID)"
        kill "$OLD_PID" || true
        sleep 2
    fi
    rm -f "$OTEL_PID_FILE"
fi

# Start OTel Collector
echo "Starting OpenTelemetry Collector..."
"$OTEL_BINARY" --config "$OTEL_CONFIG" > "$OTEL_LOG_FILE" 2>&1 &
OTEL_PID=$!
echo $OTEL_PID > "$OTEL_PID_FILE"

# Wait for collector to be ready
echo "Waiting for OTel Collector to be ready..."
count=30
while ! curl -s "http://localhost:${HTTP_PORT}/v1/metrics" -X POST -H "Content-Type: application/json" -d '{}' > /dev/null 2>&1 && [[ $count -ne 0 ]]; do
    count=$(( $count - 1 ))
    if [[ $count -eq 0 ]]; then
        echo "OTel Collector failed to start. Log output:"
        cat "$OTEL_LOG_FILE"
        exit 1
    fi
    sleep 1
done

echo "OpenTelemetry Collector is ready (PID: $OTEL_PID)"
echo "  gRPC endpoint: http://localhost:${GRPC_PORT}"
echo "  HTTP endpoint: http://localhost:${HTTP_PORT}"
echo "  Metrics file: ${OTEL_METRICS_FILE}"
