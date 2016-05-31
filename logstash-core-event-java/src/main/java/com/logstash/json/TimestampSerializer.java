package com.logstash.json;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.logstash.Timestamp;

import java.io.IOException;

public class TimestampSerializer extends JsonSerializer<Timestamp> {

    @Override
    public void serialize(Timestamp value, JsonGenerator jgen, SerializerProvider provider)
            throws IOException
    {
        jgen.writeString(value.toIso8601());
    }
}
