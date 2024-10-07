/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.logstash.health;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import java.io.IOException;
import java.util.Objects;
import java.util.function.UnaryOperator;

@JsonSerialize(using = Diagnosis.JsonSerializer.class)
public final class Diagnosis {
    public final String id;
    public final String cause;
    public final String action;
    public final String helpUrl;

    private Diagnosis(final Builder builder) {
        this.id = builder.id;
        this.cause = builder.cause;
        this.action = builder.action;
        this.helpUrl = builder.helpUrl;
    }

    static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private final String id;
        private final String cause;
        private final String action;
        private final String helpUrl;

        public Builder() {
            this(null, null, null, null);
        }

        Builder(final String id,
                final String cause,
                final String action,
                final String helpUrl) {
            this.id = id;
            this.cause = cause;
            this.action = action;
            this.helpUrl = helpUrl;
        }

        public Builder withId(final String id) {
            if (Objects.equals(id, this.id)) {
                return this;
            }
            return new Builder(id, cause, action, helpUrl);
        }

        public Builder withCause(final String cause) {
            if (Objects.equals(cause, this.cause)) {
                return this;
            }
            return new Builder(id, cause, action, helpUrl);
        }
        public Builder withAction(final String action) {
            if (Objects.equals(action, this.action)) {
                return this;
            }
            return new Builder(id, cause, action, helpUrl);
        }
        public Builder withHelpUrl(final String helpUrl) {
            if (Objects.equals(helpUrl, this.helpUrl)) {
                return this;
            }
            return new Builder(id, cause, action, helpUrl);
        }
        public Builder transform(final UnaryOperator<Builder> configurator) {
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
            if (diagnosis.id != null) {
                jsonGenerator.writeStringField("id", diagnosis.id);
            }
            jsonGenerator.writeStringField("cause", diagnosis.cause);
            jsonGenerator.writeStringField("action", diagnosis.action);
            jsonGenerator.writeStringField("help_url", diagnosis.helpUrl);
            jsonGenerator.writeEndObject();
        }
    }
}
