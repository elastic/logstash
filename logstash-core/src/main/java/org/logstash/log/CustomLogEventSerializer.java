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
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;

import java.io.IOException;
import java.util.Map;

/**
 * Json serializer for logging messages, use in json appender.
 * */
public class CustomLogEventSerializer extends JsonSerializer<CustomLogEvent> {
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
            StructuredMessage message = (StructuredMessage) event.getMessage();
            generator.writeStringField("message", message.getMessage());
            if (message.getParams() != null) {
                for (Map.Entry<Object, Object> entry : message.getParams().entrySet()) {
                    Object value = entry.getValue();
                    try {
                        generator.writeObjectField(entry.getKey().toString(), value);
                    } catch (JsonMappingException e) {
                        generator.writeObjectField(entry.getKey().toString(), value.toString());
                    }
                }
            }

        } else {
            generator.writeStringField("message", event.getMessage().getFormattedMessage());
        }

        generator.writeEndObject();
        generator.writeEndObject();
    }

    @Override
    public Class<CustomLogEvent> handledType() {

        return CustomLogEvent.class;
    }
}
