package org.logstash.log;

import com.fasterxml.jackson.core.JsonGenerationException;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;
import org.apache.logging.log4j.core.impl.Log4jLogEvent;

import java.io.IOException;
import java.lang.reflect.Field;
import java.util.Map;

public class CustomLogEventSerializer extends JsonSerializer<CustomLogEvent> {
    @Override
    public void serialize(CustomLogEvent event, JsonGenerator generator, SerializerProvider provider) throws JsonGenerationException, IOException {
        generator.writeStartObject();
        generator.writeObjectField("level", event.getLevel());
        generator.writeObjectField("loggerName", event.getLoggerName());
        generator.writeObjectField("timeMillis", event.getTimeMillis());
        generator.writeObjectField("thread", event.getThreadName());
        generator.writeObjectField("endOfBatch", event.isEndOfBatch());
        generator.writeObjectField("loggerFqcn", event.getLoggerFqcn());
        generator.writeFieldName("logEvent");
        generator.writeStartObject();
        if (event.getMessage() instanceof StructuredMessage) {
            StructuredMessage message = (StructuredMessage) event.getMessage();
            generator.writeStringField("message", message.getMessage());
            if (message.getParams() != null) {
                for (Map.Entry<String, Object> entry : message.getParams().entrySet()) {
                    generator.writeObjectField(entry.getKey(), entry.getValue());
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
