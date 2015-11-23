package com.logstash;

import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.map.JsonSerializer;
import org.codehaus.jackson.map.SerializerProvider;

import java.io.IOException;

public class TimestampSerializer extends JsonSerializer<Timestamp> {

    @Override
    public void serialize(Timestamp value, JsonGenerator jgen, SerializerProvider provider)
            throws IOException
    {
        jgen.writeString(value.toIso8601());
    }
}
