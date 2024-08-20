package org.logstash.health;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import java.io.IOException;
import java.util.Objects;
import java.util.function.UnaryOperator;

@JsonSerialize(using = Diagnosis.JsonSerializer.class)
public final class Diagnosis {
    final String cause;
    final String action;
    final String helpUrl;

    private Diagnosis(final Builder builder) {
        this.cause = builder.cause;
        this.action = builder.action;
        this.helpUrl = builder.helpUrl;
    }

    String cause() {
        return cause;
    }
    String action() {
        return action;
    }
    String helpUrl() {
        return helpUrl;
    }

    static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private String cause;
        private String action;
        private String helpUrl;
        public synchronized Builder setCause(final String cause) {
            assert Objects.isNull(this.cause) : "cause has already been set";
            this.cause = cause;
            return this;
        }
        public synchronized Builder setAction(final String action) {
            assert Objects.isNull(this.action) : "action has already been set";
            this.action = action;
            return this;
        }
        public synchronized Builder setHelpUrl(final String helpUrl) {
            assert Objects.isNull(this.helpUrl) : "helpUrl has already been set";
            this.helpUrl = helpUrl;
            return this;
        }
        public synchronized Builder configure(final UnaryOperator<Builder> configurator) {
            return configurator.apply(this);
        }
        public synchronized Diagnosis build() {
            return new Diagnosis(this);
        }
    }

    public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<Diagnosis> {
        @Override
        public void serialize(Diagnosis diagnosis, JsonGenerator jsonGenerator, SerializerProvider serializerProvider) throws IOException {
            jsonGenerator.writeStartObject();
            jsonGenerator.writeStringField("cause", diagnosis.cause());
            jsonGenerator.writeStringField("action", diagnosis.action());
            jsonGenerator.writeStringField("help_url", diagnosis.helpUrl());
            jsonGenerator.writeEndObject();
        }
    }
}
