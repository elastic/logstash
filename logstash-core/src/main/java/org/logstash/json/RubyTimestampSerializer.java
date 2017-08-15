package org.logstash.json;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;
import java.io.IOException;
import org.logstash.ext.JrubyTimestampExtLibrary;

/**
 * Serializer for {@link JrubyTimestampExtLibrary.RubyTimestamp} that serializes it exactly the same
 * way {@link TimestampSerializer} serializes {@link org.logstash.Timestamp} to ensure consistent
 * serialization across Java and Ruby representation of {@link org.logstash.Timestamp}.
 */
public final class RubyTimestampSerializer
    extends JsonSerializer<JrubyTimestampExtLibrary.RubyTimestamp> {

    @Override
    public void serialize(final JrubyTimestampExtLibrary.RubyTimestamp value,
        final JsonGenerator jgen, final SerializerProvider provider) throws IOException {
        jgen.writeString(value.getTimestamp().toIso8601());
    }
}
