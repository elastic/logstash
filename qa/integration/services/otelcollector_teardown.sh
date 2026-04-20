#!/bin/bash
set -ex

OTEL_DATA_DIR="/tmp/ls_integration/otel"
OTEL_PID_FILE="$OTEL_DATA_DIR/otel.pid"

if [[ -f "$OTEL_PID_FILE" ]]; then
    PID=$(cat "$OTEL_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping OTel Collector (PID: $PID)"
        kill "$PID" || true
        sleep 2
        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" || true
        fi
    fi
    rm -f "$OTEL_PID_FILE"
fi

OTEL_METRICS_FILE="$OTEL_DATA_DIR/metrics.json"
rm -f "$OTEL_METRICS_FILE"

echo "OTel Collector stopped"
