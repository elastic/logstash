package org.logstash.health;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import java.io.IOException;
import java.util.Map;

@JsonSerialize(using = ApiHealthReport.JsonSerializer.class)
public class ApiHealthReport {
    private final MultiIndicator.Report delegate;

    public ApiHealthReport(final MultiIndicator.Report delegate) {
        this.delegate = delegate;
    }

    public Status getStatus() {
        return delegate.status();
    }

    public String getSymptom() {
        return delegate.symptom();
    }

    public Map<String, Indicator.Report> getIndicators() {
        return delegate.indicators();
    }

    public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<ApiHealthReport> {
        @Override
        public void serialize(final ApiHealthReport apiHealthReport,
                              final JsonGenerator jsonGenerator,
                              final SerializerProvider serializerProvider) throws IOException {
            jsonGenerator.writeStartObject();
            jsonGenerator.writeObjectField("status", apiHealthReport.getStatus());
            jsonGenerator.writeObjectField("symptom", apiHealthReport.getSymptom());
            jsonGenerator.writeObjectField("indicators", apiHealthReport.getIndicators());
            jsonGenerator.writeEndObject();
        }
    }
}
