package org.logstash.log;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;

import java.io.IOException;
import java.util.Map;

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
