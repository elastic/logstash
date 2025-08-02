package org.logstash;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;

public class OTelUtil {
    // Get the global OpenTelemetry instance configured by the agent
    public static final OpenTelemetry openTelemetry = GlobalOpenTelemetry.get();

    // Create a tracer for this class/service
    public static final Tracer tracer = openTelemetry.getTracer("Logstash");
    public static final String METADATA_OTEL_CONTEXT = "otel_context";
    public static final String METADATA_OTEL_FULLCONTEXT = "otel_full_context";

    public static Span newSpan(String name) {
        return tracer.spanBuilder(name)
                .setNoParent()
                .startSpan();
    }
}
