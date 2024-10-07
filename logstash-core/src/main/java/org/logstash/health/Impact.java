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
import java.util.*;
import java.util.function.UnaryOperator;

@JsonSerialize(using=Impact.JsonSerializer.class)
public final class Impact {
    public final String id;
    public final int severity;
    public final String description;
    public final Set<ImpactArea> impactAreas;

    public Impact(final Builder builder) {
        this.id = builder.id;
        this.severity = Objects.requireNonNullElse(builder.severity, 0);
        this.description = builder.description;
        this.impactAreas = Set.copyOf(builder.impactAreas);
    }

    static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private String id;
        private Integer severity;
        private String description;
        private Set<ImpactArea> impactAreas;

        public Builder() {
            this.impactAreas = Set.of();
        }

        private Builder(String id, Integer severity, String description, Set<ImpactArea> impactAreas) {
            this.id = id;
            this.severity = severity;
            this.description = description;
            this.impactAreas = Set.copyOf(impactAreas);
        }

        public synchronized Builder withId(final String id) {
            return new Builder(id, severity, description, impactAreas);
        }

        public synchronized Builder withSeverity(int severity) {
            return new Builder(id, severity, description, impactAreas);
        }

        public synchronized Builder withDescription(String description) {
            return new Builder(id, severity, description, impactAreas);
        }

        public synchronized Builder withAdditionalImpactArea(ImpactArea impactArea) {
            final Set<ImpactArea> mergedImpactAreas = new HashSet<>(impactAreas);
            if (!mergedImpactAreas.add(impactArea)) {
                return this;
            } else {
                return this.withImpactAreas(mergedImpactAreas);
            }
        }

        public synchronized Builder withImpactAreas(Collection<ImpactArea> impactAreas) {
            return new Builder(id, severity, description, Set.copyOf(impactAreas));
        }

        public synchronized Builder transform(final UnaryOperator<Builder> configurator) {
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
            if (impact.id != null) {
                jsonGenerator.writeStringField("id", impact.id);
            }
            jsonGenerator.writeNumberField("severity", impact.severity);
            jsonGenerator.writeStringField("description", impact.description);
            jsonGenerator.writeObjectField("impact_areas", impact.impactAreas);
            jsonGenerator.writeEndObject();
        }
    }
}
