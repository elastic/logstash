package org.logstash.instrument.metrics;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;

import java.io.IOException;

/**
 * Created by andrewvc on 5/25/17.
 */
public class AbstractMetricSerializer extends JsonSerializer<AbstractMetric> {
    @Override
    public void serialize(AbstractMetric metric, JsonGenerator gen, SerializerProvider serializers) throws IOException, JsonProcessingException {
        Object value = metric.getValue();
        if (value == null) {
            gen.writeNull();
        }
        else if (value instanceof String) {
            gen.writeString((String) value);
        } else if (value instanceof Double) {
            gen.writeNumber((Double) value);
        } else if (value instanceof Float) {
            gen.writeNumber((Float) value);
        } else if (value instanceof Long) {
            gen.writeNumber((Long) value);
        } else if (value instanceof Integer) {
            gen.writeNumber((Integer) value);
        } else if (value instanceof Boolean) {
            gen.writeBoolean((Boolean) value);
        } else {
            gen.writeString(value.toString());
        }
    }
}
