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


package org.logstash.log;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.io.SegmentedStringWriter;
import com.fasterxml.jackson.core.util.BufferRecycler;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.google.common.primitives.Primitives;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import java.io.IOException;
import java.util.Map;

import static org.logstash.ObjectMappers.LOG4J_JSON_MAPPER;

/**
 * Json serializer for logging messages, use in json appender.
 */
public class CustomLogEventSerializer extends JsonSerializer<CustomLogEvent> {

    private static final Logger LOGGER = LogManager.getLogger(CustomLogEventSerializer.class);

    @Override
    public void serialize(CustomLogEvent event, JsonGenerator generator, SerializerProvider provider) throws IOException {
        generator.writeStartObject();
        generator.writeObjectField("level", event.getLevel());
        generator.writeObjectField("loggerName", event.getLoggerName());
        generator.writeObjectField("timeMillis", event.getTimeMillis());
        generator.writeObjectField("thread", event.getThreadName());
        generator.writeFieldName("logEvent");
        generator.writeStartObject();

        if (event.getMessage() instanceof StructuredMessage) {
            writeStructuredMessage((StructuredMessage) event.getMessage(), generator);
        } else {
            generator.writeStringField("message", event.getMessage().getFormattedMessage());
        }

        generator.writeEndObject();
        generator.writeEndObject();
    }

    private void writeStructuredMessage(StructuredMessage message, JsonGenerator generator) throws IOException {
        generator.writeStringField("message", message.getMessage());

        if (message.getParams() == null || message.getParams().isEmpty()) {
            return;
        }

        for (final Map.Entry<Object, Object> entry : message.getParams().entrySet()) {
            final String paramName = entry.getKey().toString();
            final Object paramValue = entry.getValue();

            try {
                if (isValueSafeToWrite(paramValue)) {
                    generator.writeObjectField(paramName, paramValue);
                    continue;
                }

                // Create a new Jackson's generator for each entry, that way, the main generator is not compromised/invalidated
                // in case any key/value fails to write. It also uses the JSON_LOGGER_MAPPER instead of the default Log4's one,
                // leveraging all necessary custom Ruby serializers.
                try (final SegmentedStringWriter entryJsonWriter = new SegmentedStringWriter(new BufferRecycler());
                     final JsonGenerator entryGenerator = LOG4J_JSON_MAPPER.getFactory().createGenerator(entryJsonWriter)) {
                    entryGenerator.writeObject(paramValue);
                    generator.writeFieldName(paramName);
                    generator.writeRawValue(entryJsonWriter.getAndClear());
                }
            } catch (JsonMappingException e) {
                LOGGER.debug("Failed to serialize message param type {}", paramValue.getClass(), e);
                generator.writeObjectField(paramName, paramValue.toString());
            }
        }
    }

    private boolean isValueSafeToWrite(Object value) {
        return value == null ||
               value instanceof String ||
               value.getClass().isPrimitive() ||
               Primitives.isWrapperType(value.getClass());
    }

    @Override
    public Class<CustomLogEvent> handledType() {
        return CustomLogEvent.class;
    }
}
