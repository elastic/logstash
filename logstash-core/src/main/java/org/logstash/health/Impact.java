package org.logstash.health;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import java.io.IOException;
import java.util.Collection;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.function.UnaryOperator;

@JsonSerialize(using=Impact.JsonSerializer.class)
public final class Impact {
    private final int severity;
    private final String description;
    private final Set<ImpactArea> impactAreas;

    public Impact(final Builder builder) {
        this.severity = Objects.requireNonNullElse(builder.severity, 0);
        this.description = builder.description;
        this.impactAreas = Set.copyOf(builder.impactAreas);
    }

    int severity() {
        return severity;
    }
    String description() {
        return description;
    }
    Set<ImpactArea> impactAreas() {
        return impactAreas;
    }

    static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private Integer severity;
        private String description;
        private Set<ImpactArea> impactAreas = new HashSet<>();

        public synchronized Builder setSeverity(int severity) {
            assert Objects.isNull(this.severity) : "severity is already set";
            this.severity = severity;
            return this;
        }

        public synchronized Builder setDescription(String description) {
            assert Objects.isNull(this.description) : "description is already set";
            this.description = description;
            return this;
        }

        public synchronized Builder addImpactArea(ImpactArea impactArea) {
            this.impactAreas.add(impactArea);
            return this;
        }

        public synchronized Builder addImpactAreas(Collection<ImpactArea> impactAreas) {
            this.impactAreas.addAll(impactAreas);
            return this;
        }

        public synchronized Builder configure(final UnaryOperator<Builder> configurator) {
            return configurator.apply(this);
        }

        public synchronized Impact build() {
            return new Impact(this);
        }
    }

    public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<Impact> {
        @Override
        public void serialize(Impact impact, JsonGenerator jsonGenerator, SerializerProvider serializerProvider) throws IOException {
            jsonGenerator.writeStartObject();
            jsonGenerator.writeNumberField("severity", impact.severity());
            jsonGenerator.writeStringField("description", impact.description());
            jsonGenerator.writeObjectField("impactAreas", impact.impactAreas());
            jsonGenerator.writeEndObject();
        }
    }
}
